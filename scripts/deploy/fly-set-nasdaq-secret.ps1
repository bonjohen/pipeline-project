#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Set NASDAQ_DATA_LINK_API_KEY secret for market-breadth ingestor
.DESCRIPTION
    Sets the NASDAQ_DATA_LINK_API_KEY as a secret for the pipeline-breadth-ingestor app
.EXAMPLE
    $env:NASDAQ_DATA_LINK_API_KEY = "your_key_here"
    .\scripts\deploy\fly-set-nasdaq-secret.ps1
#>

$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Setting NASDAQ API Key Secret" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Check for Nasdaq Data Link API Key
if (-not $env:NASDAQ_DATA_LINK_API_KEY) {
    Write-Host "❌ NASDAQ_DATA_LINK_API_KEY environment variable not set" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please set it first:" -ForegroundColor Yellow
    Write-Host "  `$env:NASDAQ_DATA_LINK_API_KEY = 'your_key_here'" -ForegroundColor White
    Write-Host ""
    Write-Host "Get a free key at: https://data.nasdaq.com" -ForegroundColor Cyan
    Write-Host ""
    exit 1
}

Write-Host "Setting NASDAQ_DATA_LINK_API_KEY for pipeline-breadth-ingestor..." -ForegroundColor Yellow
Write-Host ""

flyctl secrets set NASDAQ_DATA_LINK_API_KEY="$env:NASDAQ_DATA_LINK_API_KEY" --app pipeline-breadth-ingestor
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to set secret for pipeline-breadth-ingestor" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✅ Secret set successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "The app will automatically restart with the new secret." -ForegroundColor Cyan
Write-Host ""

