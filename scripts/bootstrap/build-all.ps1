# Build all Scala applications

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Building All Pipelines" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Build Yield Curve Pipeline
Write-Host "1. Building Yield Curve Pipeline..." -ForegroundColor Yellow
Set-Location pipelines\yield-curve\ingestor
sbt clean compile assembly
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Yield Curve Ingestor build failed" -ForegroundColor Red
    exit 1
}
Set-Location ..\flink-job
sbt clean compile assembly
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Yield Curve Flink Job build failed" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Yield Curve Pipeline built" -ForegroundColor Green
Write-Host ""

# Build Credit Spreads Pipeline
Write-Host "2. Building Credit Spreads Pipeline..." -ForegroundColor Yellow
Set-Location ..\..\credit-spreads\ingestor
sbt clean compile assembly
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Credit Spreads Ingestor build failed" -ForegroundColor Red
    exit 1
}
Set-Location ..\flink-job
sbt clean compile assembly
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Credit Spreads Flink Job build failed" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Credit Spreads Pipeline built" -ForegroundColor Green
Write-Host ""

# Build Repo Stress Pipeline
Write-Host "3. Building Repo Stress Pipeline..." -ForegroundColor Yellow
Set-Location ..\..\repo-stress\ingestor
sbt clean compile assembly
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Repo Stress Ingestor build failed" -ForegroundColor Red
    exit 1
}
Set-Location ..\flink-job
sbt clean compile assembly
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Repo Stress Flink Job build failed" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Repo Stress Pipeline built" -ForegroundColor Green
Write-Host ""

# Build Market Breadth Pipeline
Write-Host "4. Building Market Breadth Pipeline..." -ForegroundColor Yellow
Set-Location ..\..\market-breadth\ingestor
sbt clean compile assembly
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Market Breadth Ingestor build failed" -ForegroundColor Red
    exit 1
}
Set-Location ..\flink-job
sbt clean compile assembly
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Market Breadth Flink Job build failed" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Market Breadth Pipeline built" -ForegroundColor Green
Write-Host ""

Set-Location ..\..\..

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "✅ All 4 pipelines built successfully!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Built JARs:" -ForegroundColor Yellow
Write-Host "  - pipelines\yield-curve\ingestor\target\scala-2.13\fred-ingestor-assembly-0.1.0.jar" -ForegroundColor Gray
Write-Host "  - pipelines\yield-curve\flink-job\target\scala-2.12\yield-curve-flink-assembly-0.1.0.jar" -ForegroundColor Gray
Write-Host "  - pipelines\credit-spreads\ingestor\target\scala-2.13\credit-spreads-ingestor-assembly-0.1.0.jar" -ForegroundColor Gray
Write-Host "  - pipelines\credit-spreads\flink-job\target\scala-2.12\credit-spreads-flink-assembly-0.1.0.jar" -ForegroundColor Gray
Write-Host "  - pipelines\repo-stress\ingestor\target\scala-2.13\repo-stress-ingestor-assembly-0.1.0.jar" -ForegroundColor Gray
Write-Host "  - pipelines\repo-stress\flink-job\target\scala-2.12\repo-stress-flink-assembly-0.1.0.jar" -ForegroundColor Gray
Write-Host "  - pipelines\market-breadth\ingestor\target\scala-2.13\breadth-ingestor-assembly-0.1.0.jar" -ForegroundColor Gray
Write-Host "  - pipelines\market-breadth\flink-job\target\scala-2.12\breadth-flink-assembly-0.1.0.jar" -ForegroundColor Gray
Write-Host ""
Write-Host "Next: Run ingestors and submit Flink jobs via http://localhost:8081" -ForegroundColor Yellow
Write-Host ""

