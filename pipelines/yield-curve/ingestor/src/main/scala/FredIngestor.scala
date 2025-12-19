import requests._
import ujson._
import java.time.{Instant, LocalDate}
import java.util.{Properties, UUID}
import org.apache.kafka.clients.producer.{KafkaProducer, ProducerRecord}

object FredIngestor {

  private val Endpoint = "https://api.stlouisfed.org/fred/series/observations"
  private val Series = Seq("DGS10", "DGS2")

  def main(args: Array[String]): Unit = {
    val apiKey = sys.env("FRED_API_KEY")
    val bootstrap = sys.env.getOrElse("KAFKA_BOOTSTRAP", "yield-kafka.internal:9092")
    val topic = "norm.macro.rate"

    val props = new Properties()
    props.put("bootstrap.servers", bootstrap)
    props.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer")
    props.put("value.serializer", "org.apache.kafka.common.serialization.StringSerializer")

    val producer = new KafkaProducer[String, String](props)

    val endDate = LocalDate.now()
    val startDate = endDate.minusDays(10)

    Series.foreach { seriesId =>
      val resp = requests.get(
        Endpoint,
        params = Map(
          "series_id" -> seriesId,
          "api_key" -> apiKey,
          "file_type" -> "json",
          "observation_start" -> startDate.toString,
          "observation_end" -> endDate.toString
        )
      )

      val observations = ujson.read(resp.text)("observations").arr

      observations.foreach { obs =>
        val value = obs("value").str
        if (value != ".") {
          val payload = ujson.Obj(
            "schema_version" -> 1,
            "event_id" -> UUID.randomUUID().toString,
            "source" -> "fred",
            "series_id" -> seriesId,
            "event_date" -> obs("date").str,
            "value_pct" -> value.toDouble,
            "ingest_ts_utc" -> Instant.now().toString
          )

          producer.send(new ProducerRecord(topic, seriesId, payload.render()))
        }
      }
    }

    producer.flush()
    producer.close()
  }
}
