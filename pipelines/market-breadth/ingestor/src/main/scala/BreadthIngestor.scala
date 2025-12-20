import requests._
import ujson._
import java.time.{Instant, LocalDate}
import java.util.{Properties, UUID}
import org.apache.kafka.clients.producer.{KafkaProducer, ProducerRecord}

object BreadthIngestor {

  // Nasdaq Data Link (formerly Quandl) endpoint
  private val Endpoint = "https://data.nasdaq.com/api/v3/datasets"
  
  // Example dataset code - replace with actual NYSE breadth dataset
  // Common options: "FINRA/FNSQ_NYSE" or similar breadth datasets
  private val DatasetCode = "FINRA/FNSQ_NYSE"  // Placeholder - update with actual dataset

  def main(args: Array[String]): Unit = {
    val apiKey = sys.env("NASDAQ_DATA_LINK_API_KEY")
    val bootstrap = sys.env.getOrElse("KAFKA_BOOTSTRAP", "yield-kafka.internal:9092")
    val rawTopic = "market.breadth.raw"
    val normalizedTopic = "market.breadth.normalized"

    val props = new Properties()
    props.put("bootstrap.servers", bootstrap)
    props.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer")
    props.put("value.serializer", "org.apache.kafka.common.serialization.StringSerializer")

    val producer = new KafkaProducer[String, String](props)

    val endDate = LocalDate.now()
    val startDate = endDate.minusDays(30)  // Fetch last 30 days

    println(s"Fetching NYSE breadth data from Nasdaq Data Link...")
    println(s"Dataset: $DatasetCode")
    println(s"Date range: $startDate to $endDate")

    try {
      val resp = requests.get(
        s"$Endpoint/$DatasetCode.json",
        params = Map(
          "api_key" -> apiKey,
          "start_date" -> startDate.toString,
          "end_date" -> endDate.toString
        )
      )

      val dataset = ujson.read(resp.text)("dataset")
      val data = dataset("data").arr
      val columnNames = dataset("column_names").arr.map(_.str)

      println(s"Received ${data.length} records")
      println(s"Columns: ${columnNames.mkString(", ")}")

      var count = 0
      data.foreach { row =>
        val rowData = row.arr
        
        // Typical structure: [date, advancing, declining, unchanged, ...]
        // Adjust indices based on actual dataset structure
        val date = rowData(0).str
        val advancing = rowData(1).num.toInt
        val declining = rowData(2).num.toInt
        val unchanged = if (rowData.length > 3) rowData(3).num.toInt else 0

        // Publish raw data
        val rawPayload = ujson.Obj(
          "schema_version" -> 1,
          "source" -> "nasdaq_data_link",
          "dataset" -> DatasetCode,
          "exchange" -> "NYSE",
          "date" -> date,
          "advancing" -> advancing,
          "declining" -> declining,
          "unchanged" -> unchanged,
          "ingested_at" -> Instant.now().toString
        )

        producer.send(new ProducerRecord(rawTopic, date, rawPayload.render()))

        // Calculate and publish normalized data
        val totalIssues = advancing + declining + unchanged
        val breadthRatio = if (totalIssues > 0) {
          advancing.toDouble / (advancing + declining).toDouble
        } else 0.0
        val netAdvances = advancing - declining

        val normalizedPayload = ujson.Obj(
          "schema_version" -> 1,
          "event_id" -> UUID.randomUUID().toString,
          "source" -> "nasdaq_data_link",
          "exchange" -> "NYSE",
          "event_date" -> date,
          "advancing" -> advancing,
          "declining" -> declining,
          "unchanged" -> unchanged,
          "total_issues" -> totalIssues,
          "breadth_ratio" -> breadthRatio,
          "net_advances" -> netAdvances,
          "ingest_ts_utc" -> Instant.now().toString
        )

        producer.send(new ProducerRecord(normalizedTopic, date, normalizedPayload.render()))
        count += 1
      }

      producer.flush()
      producer.close()

      println(s"✅ Successfully ingested $count breadth records")
      println(s"   Raw data → Kafka topic: $rawTopic")
      println(s"   Normalized data → Kafka topic: $normalizedTopic")

    } catch {
      case e: Exception =>
        println(s"❌ Error fetching data: ${e.getMessage}")
        e.printStackTrace()
        producer.close()
        sys.exit(1)
    }
  }
}

