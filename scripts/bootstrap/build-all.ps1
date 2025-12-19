# Build all Scala applications

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Building Yield Curve Pipeline" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Build Ingestor
Write-Host "Building FRED Ingestor..." -ForegroundColor Yellow
Set-Location pipelines\yield-curve\ingestor
sbt clean compile assembly
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Ingestor build failed" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Ingestor built: target\scala-2.13\fred-ingestor-assembly-0.1.0.jar" -ForegroundColor Green
Write-Host ""

# Build Flink Job
Write-Host "Building Flink Job..." -ForegroundColor Yellow
Set-Location ..\flink-job
sbt clean compile assembly
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Flink Job build failed" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Flink Job built: target\scala-2.13\yield-curve-flink-assembly-0.1.0.jar" -ForegroundColor Green
Write-Host ""

Set-Location ..\..\..

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "✅ All applications built successfully!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next: Run the pipeline with .\scripts\test\run-pipeline.ps1" -ForegroundColor Yellow
Write-Host ""

