#!/bin/bash
# Build all Scala applications

set -e

echo "========================================="
echo "Building All Pipelines"
echo "========================================="
echo ""

# Build Yield Curve Pipeline
echo "1. Building Yield Curve Pipeline..."
cd pipelines/yield-curve/ingestor
sbt clean compile assembly
cd ../flink-job
sbt clean compile assembly
echo "✅ Yield Curve Pipeline built"
echo ""

# Build Credit Spreads Pipeline
echo "2. Building Credit Spreads Pipeline..."
cd ../../credit-spreads/ingestor
sbt clean compile assembly
cd ../flink-job
sbt clean compile assembly
echo "✅ Credit Spreads Pipeline built"
echo ""

# Build Repo Stress Pipeline
echo "3. Building Repo Stress Pipeline..."
cd ../../repo-stress/ingestor
sbt clean compile assembly
cd ../flink-job
sbt clean compile assembly
echo "✅ Repo Stress Pipeline built"
echo ""

cd ../../..

echo "========================================="
echo "✅ All 3 pipelines built successfully!"
echo "========================================="
echo ""
echo "Built JARs:"
echo "  - pipelines/yield-curve/ingestor/target/scala-2.13/fred-ingestor-assembly-0.1.0.jar"
echo "  - pipelines/yield-curve/flink-job/target/scala-2.12/yield-curve-flink-assembly-0.1.0.jar"
echo "  - pipelines/credit-spreads/ingestor/target/scala-2.13/credit-spreads-ingestor-assembly-0.1.0.jar"
echo "  - pipelines/credit-spreads/flink-job/target/scala-2.12/credit-spreads-flink-assembly-0.1.0.jar"
echo "  - pipelines/repo-stress/ingestor/target/scala-2.13/repo-stress-ingestor-assembly-0.1.0.jar"
echo "  - pipelines/repo-stress/flink-job/target/scala-2.12/repo-stress-flink-assembly-0.1.0.jar"
echo ""
echo "Next: Run ingestors and submit Flink jobs via http://localhost:8081"
echo ""

