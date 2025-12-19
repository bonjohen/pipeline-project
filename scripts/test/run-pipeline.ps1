# Run the complete yield curve pipeline locally

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Running Yield Curve Pipeline" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Check environment
if (-not $env:FRED_API_KEY) {
    Write-Host "❌ FRED_API_KEY not set. Please run:" -ForegroundColor Red
    Write-Host "   `$env:FRED_API_KEY = 'your_key_here'" -ForegroundColor Yellow
    exit 1
}

# Set Kafka bootstrap for local
$env:KAFKA_BOOTSTRAP = "localhost:29092"

Write-Host "Step 1: Running FRED Ingestor..." -ForegroundColor Yellow
Write-Host "Fetching Treasury data from FRED API..." -ForegroundColor White
Set-Location pipelines\yield-curve\ingestor
sbt "run"
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Ingestor failed" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Data ingested to Kafka topic: norm.macro.rate" -ForegroundColor Green
Write-Host ""

Write-Host "Step 2: Verifying data in Kafka..." -ForegroundColor Yellow
Write-Host "Showing first 5 messages:" -ForegroundColor White
docker exec yield-kafka kafka-console-consumer `
  --bootstrap-server localhost:9092 `
  --topic norm.macro.rate `
  --from-beginning `
  --max-messages 5 `
  --timeout-ms 5000
Write-Host ""

Write-Host "Step 3: Submitting Flink Job..." -ForegroundColor Yellow
Set-Location ..\flink-job

Write-Host "Please submit job manually:" -ForegroundColor Yellow
Write-Host "1. Go to http://localhost:8081" -ForegroundColor White
Write-Host "2. Click 'Submit New Job'" -ForegroundColor White
Write-Host "3. Upload: pipelines\yield-curve\flink-job\target\scala-2.12\yield-curve-flink-assembly-0.1.0.jar" -ForegroundColor White
Write-Host "4. Entry Class: YieldCurveJob" -ForegroundColor White
Write-Host "5. Click 'Submit'" -ForegroundColor White

Set-Location ..\..\..

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "✅ Ingestor Complete!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Monitor:" -ForegroundColor Yellow
Write-Host "- Flink Web UI: http://localhost:8081" -ForegroundColor Cyan
Write-Host ""
Write-Host "View signals:" -ForegroundColor Yellow
Write-Host "  docker exec yield-kafka kafka-console-consumer ``" -ForegroundColor Gray
Write-Host "    --bootstrap-server localhost:9092 ``" -ForegroundColor Gray
Write-Host "    --topic signal.yield_curve ``" -ForegroundColor Gray
Write-Host "    --from-beginning" -ForegroundColor Gray
Write-Host ""

