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

case class CreditRate(series: String, date: String, value: Double)

class CreditRateMapper extends MapFunction[String, CreditRate] {
  override def map(msg: String): CreditRate = {
    val j = ujson.read(msg)
    CreditRate(j("series_id").str, j("event_date").str, j("value_pct").num)
  }
}

class CreditRateFilter extends FilterFunction[CreditRate] {
  override def filter(r: CreditRate): Boolean = {
    r.series == "BAMLH0A0HYM2EY" || r.series == "DGS10"
  }
}

class CreditDateKeySelector extends KeySelector[CreditRate, String] {
  override def getKey(rate: CreditRate): String = rate.date
}

class CreditNotNullFilter extends FilterFunction[String] {
  override def filter(value: String): Boolean = value != null
}

class CreditSpreadsProcessor extends KeyedProcessFunction[String, CreditRate, String] {

  var hyYield: Double = 0.0
  var treasuryYield: Double = 0.0
  var hasData: Boolean = false

  override def processElement(
    value: CreditRate,
    ctx: KeyedProcessFunction[String, CreditRate, String]#Context,
    out: Collector[String]
  ): Unit = {
    // Collect values
    if (value.series == "BAMLH0A0HYM2EY") {
      hyYield = value.value
      hasData = true
    } else if (value.series == "DGS10") {
      treasuryYield = value.value
      hasData = true
    }

    // Emit signal if we have both values
    if (hasData && hyYield > 0 && treasuryYield > 0) {
      val spreadBps = (hyYield - treasuryYield) * 100.0

      val regime = spreadBps match {
        case s if s < 300 => "COMPRESSED"
        case s if s < 500 => "NORMAL"
        case s if s < 700 => "ELEVATED"
        case _ => "DISTRESSED"
      }

      val stressLevel = spreadBps match {
        case s if s < 400 => "LOW"
        case s if s < 600 => "MODERATE"
        case s if s < 800 => "HIGH"
        case _ => "EXTREME"
      }

      val payload = Obj(
        "schema_version" -> 1,
        "signal_id" -> "CREDIT_SPREAD_HY_10Y",
        "event_date" -> value.date,
        "spread_bps" -> spreadBps,
        "regime" -> regime,
        "stress_level" -> stressLevel
      )
      out.collect(payload.render())
    }
  }
}

object CreditSpreadsJob {

  def main(args: Array[String]): Unit = {
    val env = StreamExecutionEnvironment.getExecutionEnvironment

    val kafka = sys.env.getOrElse("KAFKA_BOOTSTRAP", "kafka:9092")

    val source = KafkaSource.builder[String]()
      .setBootstrapServers(kafka)
      .setTopics("norm.macro.rate")
      .setGroupId("credit-spreads")
      .setValueOnlyDeserializer(new SimpleStringSchema)
      .build()

    val rates = env
      .fromSource(source, WatermarkStrategy.noWatermarks(), "rates")
      .map(new CreditRateMapper())
      .filter(new CreditRateFilter())

    // Group by date and calculate spread
    val signals = rates
      .keyBy(new CreditDateKeySelector())
      .process(new CreditSpreadsProcessor())
      .filter(new CreditNotNullFilter())

    val sink = KafkaSink.builder[String]()
      .setBootstrapServers(kafka)
      .setRecordSerializer(
        KafkaRecordSerializationSchema.builder[String]()
          .setTopic("signal.credit_spread")
          .setValueSerializationSchema(new SimpleStringSchema)
          .build()
      )
      .build()

    signals.sinkTo(sink)

    env.execute("Credit Spreads Signal")
  }
}

