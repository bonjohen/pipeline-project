#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Deploy all services to Fly.io
.DESCRIPTION
    Deploys the entire pipeline system to Fly.io in the correct order
.PARAMETER SkipPlatform
    Skip deploying platform services (Kafka, Flink)
.PARAMETER SkipPipelines
    Skip deploying pipeline services
.EXAMPLE
    .\scripts\deploy\fly-deploy-all.ps1
    Deploy everything
.EXAMPLE
    .\scripts\deploy\fly-deploy-all.ps1 -SkipPlatform
    Deploy only pipeline services
#>

param(
    [switch]$SkipPlatform,
    [switch]$SkipPipelines
)

$ErrorActionPreference = "Stop"

# Helper function to ensure app exists
function Ensure-FlyApp {
    param(
        [string]$AppName
    )

    $appExists = flyctl apps list --json 2>$null | ConvertFrom-Json | Where-Object { $_.Name -eq $AppName }

    if (-not $appExists) {
        Write-Host "     Creating app $AppName..." -ForegroundColor Gray
        flyctl apps create $AppName --org personal 2>$null
        if ($LASTEXITCODE -ne 0) {
            # Try without --org flag
            flyctl apps create $AppName
            if ($LASTEXITCODE -ne 0) {
                Write-Host "❌ Failed to create app $AppName" -ForegroundColor Red
                return $false
            }
        }
    }
    return $true
}

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Fly.io Deployment Script" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Check if flyctl is installed
try {
    $null = flyctl version
} catch {
    Write-Host "❌ flyctl is not installed. Please install it first:" -ForegroundColor Red
    Write-Host "   powershell -Command `"iwr https://fly.io/install.ps1 -useb | iex`"" -ForegroundColor Yellow
    exit 1
}

# Check if logged in
try {
    $null = flyctl auth whoami
} catch {
    Write-Host "❌ Not logged in to Fly.io. Please run: flyctl auth login" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Fly.io CLI ready" -ForegroundColor Green
Write-Host ""

# Deploy Platform Services
if (-not $SkipPlatform) {
    Write-Host "Step 1: Deploying Platform Services..." -ForegroundColor Yellow
    Write-Host ""

    # Deploy Kafka
    Write-Host "  1a. Deploying Kafka + Zookeeper..." -ForegroundColor Cyan
    Set-Location platform/kafka

    # Ensure app exists
    if (-not (Ensure-FlyApp "pipeline-kafka")) {
        exit 1
    }

    # Create volume if it doesn't exist
    Write-Host "     Creating volume for Kafka data..." -ForegroundColor Gray
    $volumeExists = flyctl volumes list --app pipeline-kafka --json 2>$null | ConvertFrom-Json | Where-Object { $_.Name -eq "kafka_data" }

    if (-not $volumeExists) {
        flyctl volumes create kafka_data --size 10 --region sjc --app pipeline-kafka --yes
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ Volume creation failed" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "     Volume already exists, skipping..." -ForegroundColor Gray
    }

    Write-Host "     Deploying Kafka app..." -ForegroundColor Gray
    flyctl deploy --ha=false
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Kafka deployment failed" -ForegroundColor Red
        exit 1
    }
    Set-Location ../..
    Write-Host "  ✅ Kafka deployed" -ForegroundColor Green
    Write-Host ""

    # Deploy Flink JobManager
    Write-Host "  1b. Deploying Flink JobManager..." -ForegroundColor Cyan
    Set-Location platform/flink

    if (-not (Ensure-FlyApp "pipeline-flink-jobmanager")) {
        exit 1
    }

    flyctl deploy --config fly.jobmanager.toml --ha=false
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Flink JobManager deployment failed" -ForegroundColor Red
        exit 1
    }
    Set-Location ../..
    Write-Host "  ✅ Flink JobManager deployed" -ForegroundColor Green
    Write-Host ""

    # Deploy Flink TaskManager
    Write-Host "  1c. Deploying Flink TaskManager..." -ForegroundColor Cyan
    Set-Location platform/flink

    if (-not (Ensure-FlyApp "pipeline-flink-taskmanager")) {
        exit 1
    }

    flyctl deploy --config fly.taskmanager.toml --ha=false
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Flink TaskManager deployment failed" -ForegroundColor Red
        exit 1
    }
    Set-Location ../..
    Write-Host "  ✅ Flink TaskManager deployed" -ForegroundColor Green
    Write-Host ""

    Write-Host "Platform services deployed successfully!" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host "Step 1: Skipping platform services (--SkipPlatform)" -ForegroundColor Gray
    Write-Host ""
}

# Deploy Pipeline Services
if (-not $SkipPipelines) {
    Write-Host "Step 2: Deploying Pipeline Services..." -ForegroundColor Yellow
    Write-Host ""

    # Yield Curve
    Write-Host "  2a. Deploying Yield Curve Pipeline..." -ForegroundColor Cyan
    Set-Location pipelines/yield-curve/ingestor
    if (-not (Ensure-FlyApp "pipeline-yield-ingestor")) { exit 1 }
    flyctl deploy --ha=false
    Set-Location ../flink-job
    if (-not (Ensure-FlyApp "pipeline-yield-flink")) { exit 1 }
    flyctl deploy --ha=false
    Set-Location ../../..
    Write-Host "  ✅ Yield Curve deployed" -ForegroundColor Green
    Write-Host ""

    # Credit Spreads
    Write-Host "  2b. Deploying Credit Spreads Pipeline..." -ForegroundColor Cyan
    Set-Location pipelines/credit-spreads/ingestor
    if (-not (Ensure-FlyApp "pipeline-credit-ingestor")) { exit 1 }
    flyctl deploy --ha=false
    Set-Location ../flink-job
    if (-not (Ensure-FlyApp "pipeline-credit-flink")) { exit 1 }
    flyctl deploy --ha=false
    Set-Location ../../..
    Write-Host "  ✅ Credit Spreads deployed" -ForegroundColor Green
    Write-Host ""

    # Repo Stress
    Write-Host "  2c. Deploying Repo Stress Pipeline..." -ForegroundColor Cyan
    Set-Location pipelines/repo-stress/ingestor
    if (-not (Ensure-FlyApp "pipeline-repo-ingestor")) { exit 1 }
    flyctl deploy --ha=false
    Set-Location ../flink-job
    if (-not (Ensure-FlyApp "pipeline-repo-flink")) { exit 1 }
    flyctl deploy --ha=false
    Set-Location ../../..
    Write-Host "  ✅ Repo Stress deployed" -ForegroundColor Green
    Write-Host ""

    # Market Breadth
    Write-Host "  2d. Deploying Market Breadth Pipeline..." -ForegroundColor Cyan
    Set-Location pipelines/market-breadth/ingestor
    if (-not (Ensure-FlyApp "pipeline-breadth-ingestor")) { exit 1 }
    flyctl deploy --ha=false
    Set-Location ../flink-job
    if (-not (Ensure-FlyApp "pipeline-breadth-flink")) { exit 1 }
    flyctl deploy --ha=false
    Set-Location ../../..
    Write-Host "  ✅ Market Breadth deployed" -ForegroundColor Green
    Write-Host ""

    Write-Host "Pipeline services deployed successfully!" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host "Step 2: Skipping pipeline services (--SkipPipelines)" -ForegroundColor Gray
    Write-Host ""
}

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "✅ Deployment Complete!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Set API keys as secrets:" -ForegroundColor White
Write-Host "   flyctl secrets set FRED_API_KEY=your_key --app pipeline-yield-ingestor" -ForegroundColor Gray
Write-Host "   flyctl secrets set FRED_API_KEY=your_key --app pipeline-credit-ingestor" -ForegroundColor Gray
Write-Host "   flyctl secrets set FRED_API_KEY=your_key --app pipeline-repo-ingestor" -ForegroundColor Gray
Write-Host "   flyctl secrets set NASDAQ_DATA_LINK_API_KEY=your_key --app pipeline-breadth-ingestor" -ForegroundColor Gray
Write-Host ""
Write-Host "2. View Flink Web UI:" -ForegroundColor White
Write-Host "   flyctl open --app pipeline-flink-jobmanager" -ForegroundColor Gray
Write-Host ""
Write-Host "3. View logs:" -ForegroundColor White
Write-Host "   flyctl logs --app pipeline-kafka" -ForegroundColor Gray
Write-Host "   flyctl logs --app pipeline-yield-ingestor" -ForegroundColor Gray
Write-Host ""

