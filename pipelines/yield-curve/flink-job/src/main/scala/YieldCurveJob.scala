import org.apache.flink.streaming.api.scala._
import org.apache.flink.connector.kafka.source.KafkaSource
import org.apache.flink.connector.kafka.sink._
import org.apache.flink.api.common.serialization.SimpleStringSchema
import org.apache.flink.api.common.eventtime.WatermarkStrategy
import org.apache.flink.streaming.api.functions.KeyedProcessFunction
import org.apache.flink.api.common.functions.{MapFunction, FilterFunction}
import org.apache.flink.api.java.functions.KeySelector
import org.apache.flink.util.Collector
import ujson._

case class Rate(series: String, date: String, value: Double)

class RateMapper extends MapFunction[String, Rate] {
  override def map(msg: String): Rate = {
    val j = ujson.read(msg)
    Rate(j("series_id").str, j("event_date").str, j("value_pct").num)
  }
}

class RateFilter extends FilterFunction[Rate] {
  override def filter(r: Rate): Boolean = {
    r.series == "DGS10" || r.series == "DGS2"
  }
}

class DateKeySelector extends KeySelector[Rate, String] {
  override def getKey(rate: Rate): String = rate.date
}

class NotNullFilter extends FilterFunction[String] {
  override def filter(value: String): Boolean = value != null
}

class YieldCurveProcessor extends KeyedProcessFunction[String, Rate, String] {

  var dgs10: Double = 0.0
  var dgs2: Double = 0.0
  var hasData: Boolean = false

  override def processElement(
    value: Rate,
    ctx: KeyedProcessFunction[String, Rate, String]#Context,
    out: Collector[String]
  ): Unit = {
    // Collect values
    if (value.series == "DGS10") {
      dgs10 = value.value
      hasData = true
    } else if (value.series == "DGS2") {
      dgs2 = value.value
      hasData = true
    }

    // Emit signal if we have both values
    if (hasData && dgs10 > 0 && dgs2 > 0) {
      val spread = (dgs10 - dgs2) * 100.0
      val inverted = spread < 0

      val payload = Obj(
        "schema_version" -> 1,
        "signal_id" -> "UST_10Y_2Y",
        "event_date" -> value.date,
        "spread_bps" -> spread,
        "is_inverted" -> inverted,
        "regime" -> (if (inverted) "INVERTED" else "NORMAL")
      )
      out.collect(payload.render())
    }
  }
}

object YieldCurveJob {

  def main(args: Array[String]): Unit = {
    val env = StreamExecutionEnvironment.getExecutionEnvironment

    val kafka = sys.env.getOrElse("KAFKA_BOOTSTRAP", "kafka:9092")

    val source = KafkaSource.builder[String]()
      .setBootstrapServers(kafka)
      .setTopics("norm.macro.rate")
      .setGroupId("yield-curve")
      .setValueOnlyDeserializer(new SimpleStringSchema)
      .build()

    val rates = env
      .fromSource(source, WatermarkStrategy.noWatermarks(), "rates")
      .map(new RateMapper())
      .filter(new RateFilter())

    val signals = rates
      .keyBy(new DateKeySelector())
      .process(new YieldCurveProcessor())
      .filter(new NotNullFilter())

    val sink = KafkaSink.builder[String]()
      .setBootstrapServers(kafka)
      .setRecordSerializer(
        KafkaRecordSerializationSchema.builder[String]()
          .setTopic("signal.yield_curve")
          .setValueSerializationSchema(new SimpleStringSchema)
          .build()
      )
      .build()

    signals.sinkTo(sink)

    env.execute("Yield Curve Signal")
  }
}
