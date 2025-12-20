# Stop all pipeline components

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Stopping All Pipeline Components" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Get list of running Flink jobs
Write-Host "Cancelling Flink jobs..." -ForegroundColor Yellow
try {
    $jobs = Invoke-RestMethod -Uri "http://localhost:8081/jobs" -ErrorAction SilentlyContinue
    if ($jobs.jobs) {
        foreach ($job in $jobs.jobs) {
            if ($job.status -eq "RUNNING") {
                Write-Host "  Cancelling job: $($job.id)" -ForegroundColor Gray
                Invoke-RestMethod -Uri "http://localhost:8081/jobs/$($job.id)?mode=cancel" -Method Get -ErrorAction SilentlyContinue | Out-Null
            }
        }
        Write-Host "✅ Flink jobs cancelled" -ForegroundColor Green
    } else {
        Write-Host "  No running jobs found" -ForegroundColor Gray
    }
} catch {
    Write-Host "  Flink not running or not accessible" -ForegroundColor Gray
}
Write-Host ""

# Stop Docker Compose
Write-Host "Stopping Docker Compose..." -ForegroundColor Yellow
docker-compose down
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Docker Compose stopped" -ForegroundColor Green
} else {
    Write-Host "⚠️  Docker Compose may not have stopped cleanly" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "✅ All services stopped" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

