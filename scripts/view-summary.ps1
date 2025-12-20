#!/usr/bin/env pwsh
<#
.SYNOPSIS
    View a summary of processed signals
.DESCRIPTION
    Shows sample signals from each pipeline
#>

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "           PIPELINE SIGNAL SUMMARY" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan

Write-Host "[YIELD CURVE SIGNALS] - Latest 3" -ForegroundColor Yellow
Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
docker exec yield-kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic signal.yield_curve --from-beginning --max-messages 3 2>$null
Write-Host ""

Write-Host "[CREDIT SPREAD SIGNALS] - Latest 3" -ForegroundColor Yellow
Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
docker exec yield-kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic signal.credit_spread --from-beginning --max-messages 3 2>$null
Write-Host ""

Write-Host "[REPO STRESS SIGNALS] - Latest 3" -ForegroundColor Yellow
Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
docker exec yield-kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic signal.repo_stress --from-beginning --max-messages 3 2>$null
Write-Host ""

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "To view all signals from a specific pipeline:" -ForegroundColor White
Write-Host "  docker exec yield-kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic signal.yield_curve --from-beginning" -ForegroundColor Gray
Write-Host "  docker exec yield-kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic signal.credit_spread --from-beginning" -ForegroundColor Gray
Write-Host "  docker exec yield-kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic signal.repo_stress --from-beginning" -ForegroundColor Gray
Write-Host "================================================================" -ForegroundColor Cyan

