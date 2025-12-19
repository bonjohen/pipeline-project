#!/bin/bash
# Local development environment setup script
# Works on macOS, Linux, and Git Bash on Windows

set -e

echo "========================================="
echo "Yield Curve Pipeline - Local Setup"
echo "========================================="
echo ""

# Check Docker
echo "Checking Docker..."
if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found. Please install Docker Desktop."
    exit 1
fi

if ! docker info &> /dev/null; then
    echo "❌ Docker is not running. Please start Docker Desktop."
    exit 1
fi
echo "✅ Docker is running"
echo ""

# Check Java
echo "Checking Java..."
if ! command -v java &> /dev/null; then
    echo "❌ Java not found. Please install Java 17."
    exit 1
fi
java_version=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2 | cut -d'.' -f1)
if [ "$java_version" -lt 17 ]; then
    echo "❌ Java 17 or higher required. Found version: $java_version"
    exit 1
fi
echo "✅ Java $java_version found"
echo ""

# Check sbt
echo "Checking sbt..."
if ! command -v sbt &> /dev/null; then
    echo "❌ sbt not found. Please install sbt."
    exit 1
fi
echo "✅ sbt found"
echo ""

# Check FRED API key
echo "Checking FRED_API_KEY..."
if [ -z "$FRED_API_KEY" ]; then
    echo "⚠️  FRED_API_KEY not set."
    echo "   Get a free key at: https://fred.stlouisfed.org"
    echo "   Then run: export FRED_API_KEY='your_key_here'"
    echo ""
else
    echo "✅ FRED_API_KEY is set"
    echo ""
fi

# Start Docker services
echo "Starting platform services (Kafka, Flink)..."
docker-compose up -d

echo ""
echo "Waiting for services to be ready..."
sleep 10

# Check service health
echo ""
echo "Checking service health..."
docker-compose ps

echo ""
echo "========================================="
echo "✅ Platform services are running!"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Set FRED_API_KEY if not already set:"
echo "   export FRED_API_KEY='your_key_here'"
echo ""
echo "2. Build the applications:"
echo "   ./scripts/bootstrap/build-all.sh"
echo ""
echo "3. Run the pipeline:"
echo "   ./scripts/test/run-pipeline.sh"
echo ""
echo "Flink Web UI: http://localhost:8081"
echo ""

