#!/bin/bash
# Run the complete yield curve pipeline locally

set -e

echo "========================================="
echo "Running Yield Curve Pipeline"
echo "========================================="
echo ""

# Check environment
if [ -z "$FRED_API_KEY" ]; then
    echo "❌ FRED_API_KEY not set. Please run:"
    echo "   export FRED_API_KEY='your_key_here'"
    exit 1
fi

# Set Kafka bootstrap for local
export KAFKA_BOOTSTRAP="localhost:29092"

echo "Step 1: Running FRED Ingestor..."
echo "Fetching Treasury data from FRED API..."
cd pipelines/yield-curve/ingestor
sbt "run"
echo "✅ Data ingested to Kafka topic: norm.macro.rate"
echo ""

echo "Step 2: Verifying data in Kafka..."
echo "Showing first 5 messages:"
docker exec yield-kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic norm.macro.rate \
  --from-beginning \
  --max-messages 5 \
  --timeout-ms 5000 || true
echo ""

echo "Step 3: Submitting Flink Job..."
cd ../flink-job

# Check if Flink CLI is available
if command -v flink &> /dev/null; then
    echo "Using Flink CLI..."
    flink run -c YieldCurveJob target/scala-2.13/yield-curve-flink-assembly-0.1.0.jar
else
    echo "Flink CLI not found. Please submit job manually:"
    echo "1. Go to http://localhost:8081"
    echo "2. Click 'Submit New Job'"
    echo "3. Upload: pipelines/yield-curve/flink-job/target/scala-2.13/yield-curve-flink-assembly-0.1.0.jar"
    echo "4. Entry Class: YieldCurveJob"
    echo "5. Click 'Submit'"
fi

cd ../../..

echo ""
echo "========================================="
echo "✅ Pipeline Running!"
echo "========================================="
echo ""
echo "Monitor:"
echo "- Flink Web UI: http://localhost:8081"
echo ""
echo "View signals:"
echo "  docker exec yield-kafka kafka-console-consumer \\"
echo "    --bootstrap-server localhost:9092 \\"
echo "    --topic signal.yield_curve \\"
echo "    --from-beginning"
echo ""

