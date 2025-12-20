# Viewing Processed Pipeline Data

This guide shows you how to view the processed signals from all three pipelines.

## Quick Summary

**View sample signals from all pipelines:**
```powershell
.\scripts\view-summary.ps1
```

## Viewing Individual Pipeline Signals

### 1. Yield Curve Signals (10Y-2Y Spread)

**View latest 5 signals:**
```powershell
docker exec yield-kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic signal.yield_curve --from-beginning --max-messages 5
```

**View all signals:**
```powershell
docker exec yield-kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic signal.yield_curve --from-beginning
```

**Follow new signals in real-time:**
```powershell
docker exec yield-kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic signal.yield_curve
```

**Sample Output:**
```json
{
  "schema_version": 1,
  "signal_id": "UST_10Y_2Y",
  "event_date": "2025-12-09",
  "spread_bps": 51.0,
  "is_inverted": false,
  "regime": "NORMAL"
}
```

**Fields:**
- `spread_bps` - Spread between 10Y and 2Y yields in basis points
- `is_inverted` - `true` if yield curve is inverted (recession signal)
- `regime` - `INVERTED` or `NORMAL`

---

### 2. Credit Spread Signals (High Yield vs Treasury)

**View latest 5 signals:**
```powershell
docker exec yield-kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic signal.credit_spread --from-beginning --max-messages 5
```

**View all signals:**
```powershell
docker exec yield-kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic signal.credit_spread --from-beginning
```

**Sample Output:**
```json
{
  "schema_version": 1,
  "signal_id": "CREDIT_SPREAD_HY_10Y",
  "event_date": "2025-11-19",
  "spread_bps": 275,
  "regime": "COMPRESSED",
  "stress_level": "LOW"
}
```

**Fields:**
- `spread_bps` - Spread between High Yield and 10Y Treasury in basis points
- `regime` - `COMPRESSED` (<300 bps), `NORMAL` (300-500), `ELEVATED` (500-700), `DISTRESSED` (>700)
- `stress_level` - `LOW` (<400), `MODERATE` (400-600), `HIGH` (600-800), `EXTREME` (>800)

---

### 3. Repo Market Stress Signals (SOFR Spread)

**View latest 5 signals:**
```powershell
docker exec yield-kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic signal.repo_stress --from-beginning --max-messages 5
```

**View all signals:**
```powershell
docker exec yield-kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic signal.repo_stress --from-beginning
```

**Sample Output:**
```json
{
  "schema_version": 1,
  "signal_id": "REPO_STRESS_SOFR",
  "event_date": "2025-10-20",
  "spread_bps": -84.0,
  "spike_detected": true,
  "stress_level": "SEVERE_STRESS",
  "rolling_avg_30d_bps": -84.0
}
```

**Fields:**
- `spread_bps` - Spread between SOFR and Fed Funds target in basis points
- `spike_detected` - `true` if spread exceeds ±25 bps
- `stress_level` - `NORMAL` (<10 bps), `ELEVATED` (10-25), `STRESS` (25-50), `SEVERE_STRESS` (>50)
- `rolling_avg_30d_bps` - 30-day rolling average (currently same as spread_bps)

---

## Viewing Raw Input Data

**View raw rate data (input to all pipelines):**
```powershell
docker exec yield-kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic norm.macro.rate --from-beginning --max-messages 10
```

**Sample Output:**
```json
{
  "schema_version": 1,
  "event_id": "uuid",
  "source": "fred",
  "series_id": "DGS10",
  "event_date": "2025-12-09",
  "value_pct": 4.42,
  "ingest_ts_utc": "2025-12-19T23:27:30.123Z"
}
```

---

## Monitoring Flink Jobs

**View job status:**
```powershell
curl.exe -s http://localhost:8081/jobs/overview | ConvertFrom-Json | Select-Object -ExpandProperty jobs | Format-Table jid, name, state
```

**Open Flink Web UI:**
```
http://localhost:8081
```

---

## Tips

1. **Press Ctrl+C** to stop following a topic
2. **Use `--max-messages N`** to limit output
3. **Use `--from-beginning`** to see all historical data
4. **Omit `--from-beginning`** to see only new messages
5. **Use `| ConvertFrom-Json`** in PowerShell to parse JSON for further processing

---

## Example: Count Total Signals

```powershell
# Count yield curve signals
$count = docker exec yield-kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic signal.yield_curve --from-beginning --timeout-ms 5000 2>$null | Measure-Object -Line
Write-Host "Total Yield Curve Signals: $($count.Lines)"
```

