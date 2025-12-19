# View Kafka topics and messages

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Kafka Topics Viewer" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Available topics:" -ForegroundColor Yellow
docker exec yield-kafka kafka-topics --list --bootstrap-server localhost:9092
Write-Host ""

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Topic: norm.macro.rate (Input)" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Last 10 messages:" -ForegroundColor Yellow
docker exec yield-kafka kafka-console-consumer `
  --bootstrap-server localhost:9092 `
  --topic norm.macro.rate `
  --from-beginning `
  --max-messages 10 `
  --timeout-ms 5000 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "No messages found" -ForegroundColor Gray
}

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Topic: signal.yield_curve (Output)" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Last 10 messages:" -ForegroundColor Yellow
docker exec yield-kafka kafka-console-consumer `
  --bootstrap-server localhost:9092 `
  --topic signal.yield_curve `
  --from-beginning `
  --max-messages 10 `
  --timeout-ms 5000 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "No messages found" -ForegroundColor Gray
}

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "To stream messages in real-time:" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Input:  docker exec yield-kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic norm.macro.rate" -ForegroundColor Gray
Write-Host "Output: docker exec yield-kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic signal.yield_curve" -ForegroundColor Gray
Write-Host ""

