#!/bin/bash
# Stop all pipeline components

echo "========================================="
echo "Stopping All Pipeline Components"
echo "========================================="
echo ""

# Get list of running Flink jobs
echo "Cancelling Flink jobs..."
if curl -s http://localhost:8081/jobs >/dev/null 2>&1; then
    jobs=$(curl -s http://localhost:8081/jobs | grep -o '"id":"[^"]*"' | sed 's/"id":"\([^"]*\)"/\1/')
    if [ -n "$jobs" ]; then
        for job_id in $jobs; do
            echo "  Cancelling job: $job_id"
            curl -s -X GET "http://localhost:8081/jobs/$job_id?mode=cancel" >/dev/null 2>&1
        done
        echo "✅ Flink jobs cancelled"
    else
        echo "  No running jobs found"
    fi
else
    echo "  Flink not running or not accessible"
fi
echo ""

# Stop Docker Compose
echo "Stopping Docker Compose..."
docker-compose down
echo "✅ Docker Compose stopped"
echo ""

echo "========================================="
echo "✅ All services stopped"
echo "========================================="
echo ""

