#!/usr/bin/env pwsh
<#
.SYNOPSIS
    View the latest signals from all pipelines
.DESCRIPTION
    Displays the latest 3 signals from Yield Curve, Credit Spreads, and Repo Stress pipelines
.PARAMETER Pipeline
    Which pipeline to view: YieldCurve, CreditSpreads, RepoStress, or All (default)
.PARAMETER Count
    Number of messages to display (default: 3)
.EXAMPLE
    .\scripts\view-latest.ps1
    View latest 3 signals from all pipelines
.EXAMPLE
    .\scripts\view-latest.ps1 -Pipeline YieldCurve -Count 5
    View latest 5 yield curve signals
#>

param(
    [ValidateSet("All", "YieldCurve", "CreditSpreads", "RepoStress")]
    [string]$Pipeline = "All",

    [int]$Count = 3
)

$ErrorActionPreference = "Stop"

# Topic mapping
$topics = @{
    "YieldCurve" = "signal.yield_curve"
    "CreditSpreads" = "signal.credit_spread"
    "RepoStress" = "signal.repo_stress"
}

function Show-Signals {
    param(
        [string]$Name,
        [string]$Topic,
        [int]$MessageCount
    )

    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  $Name Signals (Latest $MessageCount)" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    docker exec yield-kafka kafka-console-consumer `
        --bootstrap-server localhost:9092 `
        --topic $Topic `
        --from-beginning `
        --max-messages $MessageCount
}

# Main execution
Write-Host " Viewing Latest Pipeline Signals" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green

if ($Pipeline -eq "All") {
    foreach ($key in $topics.Keys | Sort-Object) {
        Show-Signals -Name $key -Topic $topics[$key] -MessageCount $Count
        Start-Sleep -Milliseconds 500
    }
}
else {
    Show-Signals -Name $Pipeline -Topic $topics[$Pipeline] -MessageCount $Count
}

Write-Host " Done" -ForegroundColor Green

