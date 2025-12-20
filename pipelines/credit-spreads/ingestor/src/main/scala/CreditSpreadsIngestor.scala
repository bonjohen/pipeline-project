import requests._
import ujson._
import java.time.{Instant, LocalDate}
import java.util.{Properties, UUID}
import org.apache.kafka.clients.producer.{KafkaProducer, ProducerRecord}

object CreditSpreadsIngestor {

  private val Endpoint = "https://api.stlouisfed.org/fred/series/observations"
  // BAMLH0A0HYM2EY = ICE BofA US High Yield Index Effective Yield
  // DGS10 = 10-Year Treasury Constant Maturity Rate
  private val Series = Seq("BAMLH0A0HYM2EY", "DGS10")

  def main(args: Array[String]): Unit = {
    val apiKey = sys.env("FRED_API_KEY")
    val bootstrap = sys.env.getOrElse("KAFKA_BOOTSTRAP", "localhost:29092")
    val topic = "norm.macro.rate"

    val props = new Properties()
    props.put("bootstrap.servers", bootstrap)
    props.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer")
    props.put("value.serializer", "org.apache.kafka.common.serialization.StringSerializer")

    val producer = new KafkaProducer[String, String](props)

    val endDate = LocalDate.now()
    val startDate = endDate.minusDays(30)

    println(s"Fetching credit spreads data from FRED...")
    println(s"Series: ${Series.mkString(", ")}")
    println(s"Date range: $startDate to $endDate")

    Series.foreach { seriesId =>
      println(s"Fetching $seriesId...")
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

      var count = 0
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
          count += 1
        }
      }
      println(s"  Published $count records for $seriesId")
    }

    producer.flush()
    producer.close()
    println(s"✅ Data ingested to Kafka topic: $topic")
  }
}

