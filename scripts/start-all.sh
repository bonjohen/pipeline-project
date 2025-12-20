#!/bin/bash
# Start all pipeline components and submit Flink jobs
# This script:
# 1. Starts Docker Compose (Kafka, Flink, Zookeeper)
# 2. Waits for services to be ready
# 3. Runs all ingestors
# 4. Submits all Flink jobs via REST API

set -e

SKIP_BUILD=false
SKIP_DOCKER=false
SKIP_INGESTORS=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        --skip-docker)
            SKIP_DOCKER=true
            shift
            ;;
        --skip-ingestors)
            SKIP_INGESTORS=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--skip-build] [--skip-docker] [--skip-ingestors]"
            exit 1
            ;;
    esac
done

echo "========================================="
echo "Starting All Pipeline Components"
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

# Step 1: Build (optional)
if [ "$SKIP_BUILD" = false ]; then
    echo "Step 1: Building all pipelines..."
    ./scripts/bootstrap/build-all.sh
    echo ""
else
    echo "Step 1: Skipping build (--skip-build)"
    echo ""
fi

# Step 2: Start Docker
if [ "$SKIP_DOCKER" = false ]; then
    echo "Step 2: Starting Docker..."

    # Check if Docker is running
    docker_running=false
    if docker ps >/dev/null 2>&1; then
        docker_running=true
        echo "✅ Docker is already running"
    fi

    # Start Docker if not running
    if [ "$docker_running" = false ]; then
        echo "Docker is not running. Starting Docker..."

        # Detect OS and start Docker accordingly
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            if [ -e "/Applications/Docker.app" ]; then
                open -a Docker
                echo "Waiting for Docker to start..."
            else
                echo "❌ ERROR: Docker Desktop not found. Please install Docker Desktop or start it manually."
                exit 1
            fi
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Linux - try to start docker service
            if command -v systemctl >/dev/null 2>&1; then
                sudo systemctl start docker
                echo "Docker service started"
            else
                echo "❌ ERROR: Cannot start Docker automatically. Please start Docker manually."
                exit 1
            fi
        else
            echo "❌ ERROR: Unsupported OS. Please start Docker manually."
            exit 1
        fi

        # Wait for Docker to be ready (max 2 minutes)
        max_attempts=60
        attempt=0
        while [ $attempt -lt $max_attempts ]; do
            attempt=$((attempt + 1))
            if docker ps >/dev/null 2>&1; then
                echo "✅ Docker is ready"
                docker_running=true
                break
            fi
            if [ $attempt -eq $max_attempts ]; then
                echo "❌ ERROR: Docker failed to start after $((max_attempts * 2)) seconds"
                exit 1
            fi
            echo "  Attempt $attempt/$max_attempts..."
            sleep 2
        done
    fi
    echo ""

    # Start Docker Compose
    echo "Starting Docker Compose services..."
    docker-compose up -d
    echo "✅ Docker Compose started"
    echo ""

    # Wait for Kafka
    echo "Waiting for Kafka to be ready..."
    max_attempts=30
    attempt=0
    while [ $attempt -lt $max_attempts ]; do
        attempt=$((attempt + 1))
        if docker exec yield-kafka kafka-broker-api-versions --bootstrap-server localhost:9092 >/dev/null 2>&1; then
            echo "✅ Kafka is ready"
            break
        fi
        if [ $attempt -eq $max_attempts ]; then
            echo "❌ Kafka failed to start after $max_attempts attempts"
            exit 1
        fi
        echo "  Attempt $attempt/$max_attempts..."
        sleep 2
    done
    echo ""

    # Wait for Flink
    echo "Waiting for Flink to be ready..."
    attempt=0
    while [ $attempt -lt $max_attempts ]; do
        attempt=$((attempt + 1))
        if curl -s http://localhost:8081/overview >/dev/null 2>&1; then
            echo "✅ Flink is ready"
            break
        fi
        if [ $attempt -eq $max_attempts ]; then
            echo "❌ Flink failed to start after $max_attempts attempts"
            exit 1
        fi
        echo "  Attempt $attempt/$max_attempts..."
        sleep 2
    done
    echo ""
else
    echo "Step 2: Skipping Docker startup (--skip-docker)"
    echo ""
fi

# Step 3: Run Ingestors
if [ "$SKIP_INGESTORS" = false ]; then
    echo "Step 3: Running all ingestors..."
    echo ""

    echo "  3a. Running Yield Curve Ingestor..."
    cd pipelines/yield-curve/ingestor
    sbt -error "run"
    cd ../../..
    echo "  ✅ Yield Curve data ingested"
    echo ""

    echo "  3b. Running Credit Spreads Ingestor..."
    cd pipelines/credit-spreads/ingestor
    sbt -error "run"
    cd ../../..
    echo "  ✅ Credit Spreads data ingested"
    echo ""

    echo "  3c. Running Repo Stress Ingestor..."
    cd pipelines/repo-stress/ingestor
    sbt -error "run"
    cd ../../..
    echo "  ✅ Repo Stress data ingested"
    echo ""
else
    echo "Step 3: Skipping ingestors (--skip-ingestors)"
    echo ""
fi

# Step 4: Submit Flink Jobs via REST API
echo "Step 4: Submitting Flink jobs via REST API..."
echo ""

FLINK_URL="http://localhost:8081"

# Function to upload JAR and submit job
submit_flink_job() {
    local jar_path=$1
    local entry_class=$2
    local job_name=$3

    echo "  Submitting $job_name..."

    # Check if JAR exists
    if [ ! -f "$jar_path" ]; then
        echo "  ❌ JAR not found: $jar_path"
        return 1
    fi

    # Upload JAR
    upload_response=$(curl -s -X POST -F "jarfile=@$jar_path" "$FLINK_URL/jars/upload")

    # Extract JAR ID from response
    jar_id=$(echo "$upload_response" | grep -o '"filename":"[^"]*"' | sed 's/"filename":".*\/\([^"]*\)"/\1/')

    if [ -z "$jar_id" ]; then
        echo "  ❌ Failed to upload JAR"
        return 1
    fi

    echo "  ✓ JAR uploaded: $jar_id"

    # Submit job
    run_response=$(curl -s -X POST -H "Content-Type: application/json" \
        -d "{\"entryClass\":\"$entry_class\"}" \
        "$FLINK_URL/jars/$jar_id/run")

    # Extract job ID from response
    job_id=$(echo "$run_response" | grep -o '"jobid":"[^"]*"' | sed 's/"jobid":"\([^"]*\)"/\1/')

    if [ -n "$job_id" ]; then
        echo "  ✅ $job_name submitted (Job ID: $job_id)"
        return 0
    else
        echo "  ❌ Failed to submit job"
        return 1
    fi
}

# Submit all jobs
submit_flink_job "pipelines/yield-curve/flink-job/target/scala-2.12/yield-curve-flink-assembly-0.1.0.jar" "YieldCurveJob" "Yield Curve Job"
echo ""

submit_flink_job "pipelines/credit-spreads/flink-job/target/scala-2.12/credit-spreads-flink-assembly-0.1.0.jar" "CreditSpreadsJob" "Credit Spreads Job"
echo ""

submit_flink_job "pipelines/repo-stress/flink-job/target/scala-2.12/repo-stress-flink-assembly-0.1.0.jar" "RepoStressJob" "Repo Stress Job"
echo ""

# Summary
echo "========================================="
echo "✅ Pipeline Startup Complete!"
echo "========================================="
echo ""

echo "Services:"
echo "  - Flink Web UI:  http://localhost:8081"
echo "  - Kafka:         localhost:29092"
echo ""

echo "View signals:"
echo "  Yield Curve:    docker exec yield-kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic signal.yield_curve --from-beginning"
echo "  Credit Spreads: docker exec yield-kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic signal.credit_spread --from-beginning"
echo "  Repo Stress:    docker exec yield-kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic signal.repo_stress --from-beginning"
echo ""

echo "To stop all services:"
echo "  docker-compose down"
echo ""

