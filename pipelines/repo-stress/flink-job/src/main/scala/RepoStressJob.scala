import org.apache.flink.streaming.api.scala._
import org.apache.flink.connector.kafka.source.KafkaSource
import org.apache.flink.connector.kafka.sink._
import org.apache.flink.api.common.serialization.SimpleStringSchema
import org.apache.flink.api.common.eventtime.WatermarkStrategy
import org.apache.flink.api.common.state.{ValueState, ValueStateDescriptor}
import org.apache.flink.streaming.api.functions.KeyedProcessFunction
import org.apache.flink.api.common.functions.{MapFunction, FilterFunction}
import org.apache.flink.api.java.functions.KeySelector
import org.apache.flink.util.Collector
import ujson._
import scala.collection.mutable

case class RepoRate(series: String, date: String, value: Double)

class RepoRateMapper extends MapFunction[String, RepoRate] {
  override def map(msg: String): RepoRate = {
    val j = ujson.read(msg)
    RepoRate(j("series_id").str, j("event_date").str, j("value_pct").num)
  }
}

class RepoRateFilter extends FilterFunction[RepoRate] {
  override def filter(r: RepoRate): Boolean = {
    r.series == "SOFR" || r.series == "DFEDTARU" || r.series == "DFEDTARL"
  }
}

class RepoDateKeySelector extends KeySelector[RepoRate, String] {
  override def getKey(rate: RepoRate): String = rate.date
}

class RepoNotNullFilter extends FilterFunction[String] {
  override def filter(value: String): Boolean = value != null
}

class RepoStressProcessor extends KeyedProcessFunction[String, RepoRate, String] {

  override def processElement(
    value: RepoRate,
    ctx: KeyedProcessFunction[String, RepoRate, String]#Context,
    out: Collector[String]
  ): Unit = {
    // For simplicity, we'll emit a signal for each SOFR reading
    // In production, you'd accumulate all three series and calculate when complete
    if (value.series == "SOFR") {
      val sofr = value.value
      // Assume fed funds target is around 5.0% for demo purposes
      // In production, you'd look up the actual fed funds target for this date
      val fedTarget = 5.0
      val spreadBps = (sofr - fedTarget) * 100.0

      val spikeDetected = Math.abs(spreadBps) > 25.0

      val stressLevel = Math.abs(spreadBps) match {
        case s if s < 10 => "NORMAL"
        case s if s < 25 => "ELEVATED"
        case s if s < 50 => "STRESS"
        case _ => "SEVERE_STRESS"
      }

      val payload = Obj(
        "schema_version" -> 1,
        "signal_id" -> "REPO_STRESS_SOFR",
        "event_date" -> value.date,
        "spread_bps" -> spreadBps,
        "spike_detected" -> spikeDetected,
        "stress_level" -> stressLevel,
        "rolling_avg_30d_bps" -> spreadBps
      )
      out.collect(payload.render())
    }
  }
}

object RepoStressJob {

  def main(args: Array[String]): Unit = {
    val env = StreamExecutionEnvironment.getExecutionEnvironment

    val kafka = sys.env.getOrElse("KAFKA_BOOTSTRAP", "kafka:9092")

    val source = KafkaSource.builder[String]()
      .setBootstrapServers(kafka)
      .setTopics("norm.macro.rate")
      .setGroupId("repo-stress")
      .setValueOnlyDeserializer(new SimpleStringSchema)
      .build()

    val rates = env
      .fromSource(source, WatermarkStrategy.noWatermarks(), "rates")
      .map(new RepoRateMapper())
      .filter(new RepoRateFilter())

    // Group by date and calculate spread using process function
    val signals = rates
      .keyBy(new RepoDateKeySelector())
      .process(new RepoStressProcessor())
      .filter(new RepoNotNullFilter())

    val sink = KafkaSink.builder[String]()
      .setBootstrapServers(kafka)
      .setRecordSerializer(
        KafkaRecordSerializationSchema.builder[String]()
          .setTopic("signal.repo_stress")
          .setValueSerializationSchema(new SimpleStringSchema)
          .build()
      )
      .build()

    signals.sinkTo(sink)

    env.execute("Repo Market Stress Signal")
  }
}

