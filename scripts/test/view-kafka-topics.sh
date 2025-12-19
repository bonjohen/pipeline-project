#!/bin/bash
# View Kafka topics and messages

echo "========================================="
echo "Kafka Topics Viewer"
echo "========================================="
echo ""

echo "Available topics:"
docker exec yield-kafka kafka-topics --list --bootstrap-server localhost:9092
echo ""

echo "========================================="
echo "Topic: norm.macro.rate (Input)"
echo "========================================="
echo "Last 10 messages:"
docker exec yield-kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic norm.macro.rate \
  --from-beginning \
  --max-messages 10 \
  --timeout-ms 5000 2>/dev/null || echo "No messages found"

echo ""
echo "========================================="
echo "Topic: signal.yield_curve (Output)"
echo "========================================="
echo "Last 10 messages:"
docker exec yield-kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic signal.yield_curve \
  --from-beginning \
  --max-messages 10 \
  --timeout-ms 5000 2>/dev/null || echo "No messages found"

echo ""
echo "========================================="
echo "To stream messages in real-time:"
echo "========================================="
echo "Input:  docker exec yield-kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic norm.macro.rate"
echo "Output: docker exec yield-kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic signal.yield_curve"
echo ""

