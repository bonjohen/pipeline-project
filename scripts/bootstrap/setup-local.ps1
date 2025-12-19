# Local development environment setup script for Windows PowerShell

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Yield Curve Pipeline - Local Setup" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Check Docker
Write-Host "Checking Docker..." -ForegroundColor Yellow
try {
    $dockerVersion = docker --version
    docker info | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Docker not running"
    }
    Write-Host "✅ Docker is running" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker is not running. Please start Docker Desktop." -ForegroundColor Red
    exit 1
}
Write-Host ""

# Check Java
Write-Host "Checking Java..." -ForegroundColor Yellow
try {
    $javaVersion = java -version 2>&1 | Select-String "version" | ForEach-Object { $_ -replace '.*"(\d+).*', '$1' }
    if ([int]$javaVersion -lt 17) {
        Write-Host "❌ Java 17 or higher required. Found version: $javaVersion" -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ Java $javaVersion found" -ForegroundColor Green
} catch {
    Write-Host "❌ Java not found. Please install Java 17." -ForegroundColor Red
    exit 1
}
Write-Host ""

# Check sbt
Write-Host "Checking sbt..." -ForegroundColor Yellow
try {
    sbt --version | Out-Null
    Write-Host "✅ sbt found" -ForegroundColor Green
} catch {
    Write-Host "❌ sbt not found. Please install sbt." -ForegroundColor Red
    exit 1
}
Write-Host ""

# Check FRED API key
Write-Host "Checking FRED_API_KEY..." -ForegroundColor Yellow
if (-not $env:FRED_API_KEY) {
    Write-Host "⚠️  FRED_API_KEY not set." -ForegroundColor Yellow
    Write-Host "   Get a free key at: https://fred.stlouisfed.org" -ForegroundColor Yellow
    Write-Host "   Then run: `$env:FRED_API_KEY = 'your_key_here'" -ForegroundColor Yellow
    Write-Host ""
} else {
    Write-Host "✅ FRED_API_KEY is set" -ForegroundColor Green
    Write-Host ""
}

# Start Docker services
Write-Host "Starting platform services (Kafka, Flink)..." -ForegroundColor Yellow
docker-compose up -d

Write-Host ""
Write-Host "Waiting for services to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Check service health
Write-Host ""
Write-Host "Checking service health..." -ForegroundColor Yellow
docker-compose ps

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "✅ Platform services are running!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Set FRED_API_KEY if not already set:" -ForegroundColor White
Write-Host "   `$env:FRED_API_KEY = 'your_key_here'" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Build the applications:" -ForegroundColor White
Write-Host "   .\scripts\bootstrap\build-all.ps1" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Run the pipeline:" -ForegroundColor White
Write-Host "   .\scripts\test\run-pipeline.ps1" -ForegroundColor Gray
Write-Host ""
Write-Host "Flink Web UI: http://localhost:8081" -ForegroundColor Cyan
Write-Host ""

