#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Set API keys as secrets in Fly.io apps
.DESCRIPTION
    Sets FRED_API_KEY and NASDAQ_DATA_LINK_API_KEY as secrets for the ingestor apps
.EXAMPLE
    .\scripts\deploy\fly-set-secrets.ps1
#>

$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Setting Fly.io Secrets" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Check for FRED API Key
if (-not $env:FRED_API_KEY) {
    Write-Host "❌ FRED_API_KEY environment variable not set" -ForegroundColor Red
    Write-Host "   Please set it first: `$env:FRED_API_KEY = 'your_key_here'" -ForegroundColor Yellow
    Write-Host "   Get a free key at: https://fred.stlouisfed.org/docs/api/api_key.html" -ForegroundColor Yellow
    exit 1
}

# Check for Nasdaq Data Link API Key
if (-not $env:NASDAQ_DATA_LINK_API_KEY) {
    Write-Host "⚠️  NASDAQ_DATA_LINK_API_KEY environment variable not set" -ForegroundColor Yellow
    Write-Host "   This is optional for market-breadth pipeline" -ForegroundColor Yellow
    Write-Host "   Get a free key at: https://data.nasdaq.com" -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "Setting FRED_API_KEY for ingestor apps..." -ForegroundColor Yellow
Write-Host ""

# Set FRED API Key for yield-curve ingestor
Write-Host "  Setting secret for pipeline-yield-ingestor..." -ForegroundColor Cyan
flyctl secrets set FRED_API_KEY="$env:FRED_API_KEY" --app pipeline-yield-ingestor
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to set secret for pipeline-yield-ingestor" -ForegroundColor Red
    exit 1
}
Write-Host "  ✅ Secret set for pipeline-yield-ingestor" -ForegroundColor Green

# Set FRED API Key for credit-spreads ingestor
Write-Host "  Setting secret for pipeline-credit-ingestor..." -ForegroundColor Cyan
flyctl secrets set FRED_API_KEY="$env:FRED_API_KEY" --app pipeline-credit-ingestor
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to set secret for pipeline-credit-ingestor" -ForegroundColor Red
    exit 1
}
Write-Host "  ✅ Secret set for pipeline-credit-ingestor" -ForegroundColor Green

# Set FRED API Key for repo-stress ingestor
Write-Host "  Setting secret for pipeline-repo-ingestor..." -ForegroundColor Cyan
flyctl secrets set FRED_API_KEY="$env:FRED_API_KEY" --app pipeline-repo-ingestor
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to set secret for pipeline-repo-ingestor" -ForegroundColor Red
    exit 1
}
Write-Host "  ✅ Secret set for pipeline-repo-ingestor" -ForegroundColor Green

Write-Host ""

# Set Nasdaq Data Link API Key if available
if ($env:NASDAQ_DATA_LINK_API_KEY) {
    Write-Host "Setting NASDAQ_DATA_LINK_API_KEY for market-breadth ingestor..." -ForegroundColor Yellow
    Write-Host "  Setting secret for pipeline-breadth-ingestor..." -ForegroundColor Cyan
    flyctl secrets set NASDAQ_DATA_LINK_API_KEY="$env:NASDAQ_DATA_LINK_API_KEY" --app pipeline-breadth-ingestor
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to set secret for pipeline-breadth-ingestor" -ForegroundColor Red
        exit 1
    }
    Write-Host "  ✅ Secret set for pipeline-breadth-ingestor" -ForegroundColor Green
} else {
    Write-Host "Skipping NASDAQ_DATA_LINK_API_KEY (not set)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "✅ Secrets Set Successfully!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

