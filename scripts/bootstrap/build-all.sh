#!/bin/bash
# Build all Scala applications

set -e

echo "========================================="
echo "Building Yield Curve Pipeline"
echo "========================================="
echo ""

# Build Ingestor
echo "Building FRED Ingestor..."
cd pipelines/yield-curve/ingestor
sbt clean compile assembly
echo "✅ Ingestor built: target/scala-2.13/fred-ingestor-assembly-0.1.0.jar"
echo ""

# Build Flink Job
echo "Building Flink Job..."
cd ../flink-job
sbt clean compile assembly
echo "✅ Flink Job built: target/scala-2.13/yield-curve-flink-assembly-0.1.0.jar"
echo ""

cd ../../..

echo "========================================="
echo "✅ All applications built successfully!"
echo "========================================="
echo ""
echo "Next: Run the pipeline with ./scripts/test/run-pipeline.sh"
echo ""

