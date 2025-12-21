#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Deploy missing pipeline services to Fly.io
.DESCRIPTION
    Deploys only the services that are still missing
#>

$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Deploying Missing Services" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Helper function to ensure app exists
function Ensure-FlyApp {
    param([string]$AppName)
    
    $appExists = flyctl apps list --json 2>$null | ConvertFrom-Json | Where-Object { $_.Name -eq $AppName }
    
    if (-not $appExists) {
        Write-Host "     Creating app $AppName..." -ForegroundColor Gray
        flyctl apps create $AppName --org personal 2>$null
        if ($LASTEXITCODE -ne 0) {
            flyctl apps create $AppName
            if ($LASTEXITCODE -ne 0) {
                Write-Host "❌ Failed to create app $AppName" -ForegroundColor Red
                return $false
            }
        }
    }
    return $true
}

# Helper function to deploy a service
function Deploy-Service {
    param(
        [string]$Name,
        [string]$AppName,
        [string]$Path
    )
    
    Write-Host "  Deploying $Name..." -ForegroundColor Cyan
    
    # Ensure app exists
    if (-not (Ensure-FlyApp $AppName)) {
        Write-Host "❌ $Name deployment failed (couldn't create app)" -ForegroundColor Red
        return $false
    }
    
    Set-Location $Path
    
    flyctl deploy --ha=false
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ $Name deployment failed" -ForegroundColor Red
        return $false
    }
    
    Write-Host "  ✅ $Name deployed" -ForegroundColor Green
    Write-Host ""
    return $true
}

# Start from project root
Set-Location C:\Projects\pipeline-project

# Deploy Repo Stress Flink Job
if (-not (Deploy-Service "Repo Stress Flink Job" "pipeline-repo-flink" "pipelines\repo-stress\flink-job")) {
    Write-Host "Continuing despite error..." -ForegroundColor Yellow
}
Set-Location C:\Projects\pipeline-project

# Deploy Market Breadth Pipeline
if (-not (Deploy-Service "Market Breadth Ingestor" "pipeline-breadth-ingestor" "pipelines\market-breadth\ingestor")) {
    Write-Host "Continuing despite error..." -ForegroundColor Yellow
}
Set-Location C:\Projects\pipeline-project

if (-not (Deploy-Service "Market Breadth Flink Job" "pipeline-breadth-flink" "pipelines\market-breadth\flink-job")) {
    Write-Host "Continuing despite error..." -ForegroundColor Yellow
}
Set-Location C:\Projects\pipeline-project

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "✅ Deployment Complete!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Check deployment status:" -ForegroundColor White
Write-Host "   flyctl apps list" -ForegroundColor Gray
Write-Host ""
Write-Host "2. View Flink dashboard:" -ForegroundColor White
Write-Host "   flyctl open --app pipeline-flink-jobmanager" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Check logs:" -ForegroundColor White
Write-Host "   flyctl logs --app pipeline-yield-ingestor" -ForegroundColor Gray
Write-Host ""

