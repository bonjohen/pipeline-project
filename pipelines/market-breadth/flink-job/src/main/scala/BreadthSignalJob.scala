import org.apache.flink.api.common.eventtime.WatermarkStrategy
import org.apache.flink.api.common.functions.{FilterFunction, MapFunction}
import org.apache.flink.api.common.serialization.SimpleStringSchema
import org.apache.flink.api.java.functions.KeySelector
import org.apache.flink.connector.kafka.source.KafkaSource
import org.apache.flink.connector.kafka.sink.{KafkaRecordSerializationSchema, KafkaSink}
import org.apache.flink.streaming.api.scala._
import org.apache.flink.streaming.api.functions.KeyedProcessFunction
import org.apache.flink.util.Collector
import ujson._

import scala.collection.mutable

case class BreadthData(
  date: String,
  exchange: String,
  advancing: Int,
  declining: Int,
  breadthRatio: Double
)

class BreadthMapper extends MapFunction[String, BreadthData] {
  override def map(msg: String): BreadthData = {
    val j = ujson.read(msg)
    BreadthData(
      j("event_date").str,
      j("exchange").str,
      j("advancing").num.toInt,
      j("declining").num.toInt,
      j("breadth_ratio").num
    )
  }
}

class BreadthFilter extends FilterFunction[BreadthData] {
  override def filter(b: BreadthData): Boolean = {
    b.exchange == "NYSE" && b.breadthRatio >= 0.0
  }
}

class ExchangeKeySelector extends KeySelector[BreadthData, String] {
  override def getKey(data: BreadthData): String = data.exchange
}

class NotNullFilter extends FilterFunction[String] {
  override def filter(value: String): Boolean = value != null
}

class ZweigThrustDetector extends KeyedProcessFunction[String, BreadthData, String] {

  // Keep a sliding window of the last 10 breadth ratios
  private val window = mutable.Queue[(String, Double)]()
  private val maxWindowSize = 10

  override def processElement(
    value: BreadthData,
    ctx: KeyedProcessFunction[String, BreadthData, String]#Context,
    out: Collector[String]
  ): Unit = {

    // Add current value to window
    window.enqueue((value.date, value.breadthRatio))

    // Keep only last 10 values
    while (window.size > maxWindowSize) {
      window.dequeue()
    }

    // Need at least 2 data points to detect a thrust
    if (window.size < 2) return

    // Zweig Breadth Thrust conditions:
    // 1. Ratio rises from below 0.40 to above 0.615
    // 2. Occurs within 10 trading days (our window)

    val ratios = window.map(_._2).toSeq
    val minRatio = ratios.min
    val maxRatio = ratios.max

    // Check if we have a thrust pattern
    var thrustDetected = false
    var fromRatio = 0.0
    var toRatio = 0.0

    // Look for transition from below 0.40 to above 0.615
    for (i <- 0 until window.size - 1) {
      val current = window(i)._2
      val next = window(i + 1)._2

      if (current < 0.40 && next > 0.615) {
        thrustDetected = true
        fromRatio = current
        toRatio = next
      }
    }

    // Alternative: check if minimum is below 0.40 and maximum is above 0.615
    if (!thrustDetected && minRatio < 0.40 && maxRatio > 0.615) {
      thrustDetected = true
      fromRatio = minRatio
      toRatio = maxRatio
    }

    if (thrustDetected) {
      val confidence = if (toRatio > 0.65) "HIGH" else "MODERATE"

      val payload = Obj(
        "schema_version" -> 1,
        "signal_id" -> "ZWEIG_BREADTH_THRUST",
        "exchange" -> value.exchange,
        "trigger_date" -> value.date,
        "window_days" -> window.size,
        "from_ratio" -> fromRatio,
        "to_ratio" -> toRatio,
        "threshold_low" -> 0.40,
        "threshold_high" -> 0.615,
        "thrust_detected" -> true,
        "confidence" -> confidence
      )

      out.collect(payload.render())

      // Clear window after detecting a thrust to avoid duplicate signals
      window.clear()
    }
  }
}

object BreadthSignalJob {

  def main(args: Array[String]): Unit = {
    val env = StreamExecutionEnvironment.getExecutionEnvironment

    val kafka = sys.env.getOrElse("KAFKA_BOOTSTRAP", "kafka:9092")

    val source = KafkaSource.builder[String]()
      .setBootstrapServers(kafka)
      .setTopics("market.breadth.normalized")
      .setGroupId("breadth-signal")
      .setValueOnlyDeserializer(new SimpleStringSchema)
      .build()

    val breadthData = env
      .fromSource(source, WatermarkStrategy.noWatermarks(), "breadth")
      .map(new BreadthMapper())
      .filter(new BreadthFilter())

    // Detect Zweig Thrust using a keyed process function with sliding window
    val signals = breadthData
      .keyBy(new ExchangeKeySelector())
      .process(new ZweigThrustDetector())
      .filter(new NotNullFilter())

    val sink = KafkaSink.builder[String]()
      .setBootstrapServers(kafka)
      .setRecordSerializer(
        KafkaRecordSerializationSchema.builder[String]()
          .setTopic("signals.breadth.zweig")
          .setValueSerializationSchema(new SimpleStringSchema)
          .build()
      )
      .build()

    signals.sinkTo(sink)

    env.execute("Market Breadth Thrust Signal")
  }
}

