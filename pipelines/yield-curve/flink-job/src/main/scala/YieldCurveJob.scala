import org.apache.flink.streaming.api.scala._
import org.apache.flink.connector.kafka.source.KafkaSource
import org.apache.flink.connector.kafka.sink._
import org.apache.flink.api.common.serialization.SimpleStringSchema
import org.apache.flink.api.common.eventtime.WatermarkStrategy
import ujson._

case class Rate(series: String, date: String, value: Double)

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
      .map { msg =>
        val j = ujson.read(msg)
        Rate(j("series_id").str, j("event_date").str, j("value_pct").num)
      }

    val signals = rates
      .keyBy(_.date)
      .reduce { (a, b) =>
        val spread = (a.value - b.value) * 100.0
        val inverted = spread < 0
        val payload = Obj(
          "schema_version" -> 1,
          "signal_id" -> "UST_10Y_2Y",
          "event_date" -> a.date,
          "spread_bps" -> spread,
          "is_inverted" -> inverted,
          "regime" -> (if (inverted) "INVERTED" else "NORMAL")
        )
        Rate("signal", a.date, spread)
      }
      .map(_.value.toString)

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
