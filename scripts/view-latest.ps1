#!/usr/bin/env pwsh
<#
.SYNOPSIS
    View the latest signal from each pipeline
.DESCRIPTION
    Shows a quick summary of the most recent signal from each pipeline
#>

$ErrorActionPreference = "Stop"

Write-Host "`n================================================================" -ForegroundColor Cyan
Write-Host "           LATEST SIGNALS FROM ALL PIPELINES                   " -ForegroundColor Cyan
Write-Host "================================================================`n" -ForegroundColor Cyan

# Yield Curve
Write-Host "[YIELD CURVE] 10Y-2Y Spread" -ForegroundColor Yellow
try {
    $allYield = docker exec yield-kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic signal.yield_curve --from-beginning --max-messages 100 2>&1
    $yieldData = $allYield | Where-Object { $_ -match '^\{' } | Select-Object -Last 1
    if ($yieldData) {
        $yield = $yieldData | ConvertFrom-Json
        $status = if ($yield.is_inverted) { "[INVERTED]" } else { "[NORMAL]" }
        $spreadColor = if ($yield.is_inverted) { "Red" } else { "Green" }
        Write-Host "  Date:   $($yield.event_date)" -ForegroundColor White
        Write-Host "  Spread: $([math]::Round($yield.spread_bps, 1)) bps" -ForegroundColor $spreadColor
        Write-Host "  Status: $status" -ForegroundColor $spreadColor
    } else {
        Write-Host "  No data available" -ForegroundColor Gray
    }
} catch {
    Write-Host "  Error reading data" -ForegroundColor Gray
}

Write-Host ""

# Credit Spreads
Write-Host "[CREDIT SPREADS] High Yield vs 10Y Treasury" -ForegroundColor Yellow
try {
    $allCredit = docker exec yield-kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic signal.credit_spread --from-beginning --max-messages 100 2>&1
    $creditData = $allCredit | Where-Object { $_ -match '^\{' } | Select-Object -Last 1
    if ($creditData) {
        $credit = $creditData | ConvertFrom-Json
        $color = switch ($credit.stress_level) {
            "LOW" { "Green" }
            "MODERATE" { "Yellow" }
            "HIGH" { "Red" }
            "EXTREME" { "Magenta" }
            default { "White" }
        }
        Write-Host "  Date:         $($credit.event_date)" -ForegroundColor White
        Write-Host "  Spread:       $([math]::Round($credit.spread_bps, 1)) bps" -ForegroundColor $color
        Write-Host "  Regime:       $($credit.regime)" -ForegroundColor $color
        Write-Host "  Stress Level: $($credit.stress_level)" -ForegroundColor $color
    } else {
        Write-Host "  No data available" -ForegroundColor Gray
    }
} catch {
    Write-Host "  Error reading data" -ForegroundColor Gray
}

Write-Host ""

# Repo Stress
Write-Host "[REPO MARKET STRESS] SOFR Spread" -ForegroundColor Yellow
try {
    $allRepo = docker exec yield-kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic signal.repo_stress --from-beginning --max-messages 100 2>&1
    $repoData = $allRepo | Where-Object { $_ -match '^\{' } | Select-Object -Last 1
    if ($repoData) {
        $repo = $repoData | ConvertFrom-Json
        $color = switch ($repo.stress_level) {
            "NORMAL" { "Green" }
            "ELEVATED" { "Yellow" }
            "STRESS" { "Red" }
            "SEVERE_STRESS" { "Magenta" }
            default { "White" }
        }
        $spike = if ($repo.spike_detected) { "YES" } else { "NO" }
        $spikeColor = if ($repo.spike_detected) { "Red" } else { "Green" }
        Write-Host "  Date:         $($repo.event_date)" -ForegroundColor White
        Write-Host "  Spread:       $([math]::Round($repo.spread_bps, 1)) bps" -ForegroundColor $color
        Write-Host "  Spike:        $spike" -ForegroundColor $spikeColor
        Write-Host "  Stress Level: $($repo.stress_level)" -ForegroundColor $color
    } else {
        Write-Host "  No data available" -ForegroundColor Gray
    }
} catch {
    Write-Host "  Error reading data" -ForegroundColor Gray
}

Write-Host "`n================================================================" -ForegroundColor Cyan
Write-Host ""

