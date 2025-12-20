#!/usr/bin/env pwsh
<#
.SYNOPSIS
    View processed signals from all pipelines
.DESCRIPTION
    Displays the latest signals from Yield Curve, Credit Spreads, and Repo Stress pipelines
.PARAMETER Pipeline
    Which pipeline to view: YieldCurve, CreditSpreads, RepoStress, or All (default)
.PARAMETER Count
    Number of messages to display (default: 10)
.PARAMETER Follow
    Follow mode - continuously display new messages as they arrive
.EXAMPLE
    .\scripts\view-signals.ps1
    View latest 10 signals from all pipelines
.EXAMPLE
    .\scripts\view-signals.ps1 -Pipeline YieldCurve -Count 20
    View latest 20 yield curve signals
.EXAMPLE
    .\scripts\view-signals.ps1 -Pipeline RepoStress -Follow
    Follow repo stress signals in real-time
#>

param(
    [ValidateSet("All", "YieldCurve", "CreditSpreads", "RepoStress")]
    [string]$Pipeline = "All",
    
    [int]$Count = 10,
    
    [switch]$Follow
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
        [int]$MessageCount,
        [bool]$FollowMode
    )
    
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  $Name Signals" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    
    if ($FollowMode) {
        Write-Host "Following new messages (Ctrl+C to stop)..." -ForegroundColor Yellow
        docker exec yield-kafka kafka-console-consumer `
            --bootstrap-server localhost:9092 `
            --topic $Topic `
            --from-beginning
    } else {
        docker exec yield-kafka kafka-console-consumer `
            --bootstrap-server localhost:9092 `
            --topic $Topic `
            --from-beginning `
            --max-messages $MessageCount
    }
}

function Format-Signal {
    param([string]$Json)
    
    try {
        $obj = $Json | ConvertFrom-Json
        
        # Format based on signal type
        if ($obj.signal_id -eq "UST_10Y_2Y") {
            $status = if ($obj.is_inverted) { " INVERTED" } else { " NORMAL" }
            Write-Host "$($obj.event_date) | Spread: $([math]::Round($obj.spread_bps, 1)) bps | $status" -ForegroundColor $(if ($obj.is_inverted) { "Red" } else { "Green" })
        }
        elseif ($obj.signal_id -eq "CREDIT_SPREAD_HY_10Y") {
            $color = switch ($obj.stress_level) {
                "LOW" { "Green" }
                "MODERATE" { "Yellow" }
                "HIGH" { "Red" }
                "EXTREME" { "Magenta" }
                default { "White" }
            }
            Write-Host "$($obj.event_date) | Spread: $([math]::Round($obj.spread_bps, 1)) bps | $($obj.regime) | Stress: $($obj.stress_level)" -ForegroundColor $color
        }
        elseif ($obj.signal_id -eq "REPO_STRESS_SOFR") {
            $color = switch ($obj.stress_level) {
                "NORMAL" { "Green" }
                "ELEVATED" { "Yellow" }
                "STRESS" { "Red" }
                "SEVERE_STRESS" { "Magenta" }
                default { "White" }
            }
            $spike = if ($obj.spike_detected) { " SPIKE" } else { " CHECK" }
            Write-Host "$($obj.event_date) | Spread: $([math]::Round($obj.spread_bps, 1)) bps | $spike | $($obj.stress_level)" -ForegroundColor $color
        }
    }
    catch {
        Write-Host $Json -ForegroundColor Gray
    }
}

# Main execution
Write-Host " Viewing Pipeline Signals" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green

if ($Pipeline -eq "All") {
    foreach ($key in $topics.Keys | Sort-Object) {
        Show-Signals -Name $key -Topic $topics[$key] -MessageCount $Count -FollowMode $false
        Start-Sleep -Milliseconds 500
    }
}
else {
    Show-Signals -Name $Pipeline -Topic $topics[$Pipeline] -MessageCount $Count -FollowMode $Follow
}

Write-Host " Done" -ForegroundColor Green

