# Quick Start Guide - Local Development

Get the yield curve pipeline running locally in **5 minutes**.

---

## Prerequisites

- Docker Desktop (running)
- Java 17+
- sbt
- FRED API Key (free from https://fred.stlouisfed.org)

**Windows Users:** See [WINDOWS_SETUP.md](WINDOWS_SETUP.md) for detailed installation instructions.

**Note:** SDKMAN (`sdk` command) only works in bash/zsh, not PowerShell. Windows users should install Java and sbt using Chocolatey or manual installers.

---

## Quick Setup (Windows PowerShell)

```powershell
# 1. Set your FRED API key
$env:FRED_API_KEY = "your_api_key_here"
$env:KAFKA_BOOTSTRAP = "localhost:29092"

# 2. Start platform services
docker-compose up -d

# 3. Build applications
.\scripts\bootstrap\build-all.ps1

# 4. Run ingestor
cd pipelines\yield-curve\ingestor
sbt run
cd ..\..\..

# 5. Open Flink UI and submit job
# http://localhost:8081
# Upload: pipelines\yield-curve\flink-job\target\scala-2.12\yield-curve-flink-assembly-0.1.0.jar
# Entry Class: YieldCurveJob

# 6. View results
docker exec yield-kafka kafka-console-consumer `
  --bootstrap-server localhost:9092 `
  --topic signal.yield_curve `
  --from-beginning
```

---

## Quick Setup (macOS/Linux/Git Bash)

```bash
# 1. Set your FRED API key
export FRED_API_KEY="your_api_key_here"
export KAFKA_BOOTSTRAP="localhost:29092"

# 2. Start platform services
docker-compose up -d

# 3. Build applications
./scripts/bootstrap/build-all.sh

# 4. Run ingestor
cd pipelines/yield-curve/ingestor
sbt run
cd ../../..

# 5. Open Flink UI and submit job
# http://localhost:8081
# Upload: pipelines/yield-curve/flink-job/target/scala-2.12/yield-curve-flink-assembly-0.1.0.jar
# Entry Class: YieldCurveJob

# 6. View results
docker exec yield-kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic signal.yield_curve \
  --from-beginning
```

---

## What You'll See

### Ingestor Output
```
Fetching DGS10 and DGS2 data from FRED...
Publishing to Kafka topic: norm.macro.rate
Done!
```

### Kafka Input Topic (norm.macro.rate)
```json
{
  "schema_version": 1,
  "event_id": "uuid-here",
  "source": "fred",
  "series_id": "DGS10",
  "event_date": "2025-12-18",
  "value_pct": 4.52,
  "ingest_ts_utc": "2025-12-19T10:30:00Z"
}
```

### Kafka Output Topic (signal.yield_curve)
```json
{
  "schema_version": 1,
  "signal_id": "UST_10Y_2Y",
  "event_date": "2025-12-18",
  "spread_bps": 45.2,
  "is_inverted": false,
  "regime": "NORMAL"
}
```

---

## Useful Commands

### Check Services
```bash
docker-compose ps
```

### View Logs
```bash
docker-compose logs -f kafka
docker-compose logs -f flink-jobmanager
```

### List Kafka Topics
```bash
docker exec yield-kafka kafka-topics --list --bootstrap-server localhost:9092
```

### Stop Everything
```bash
docker-compose down
```

### Clean Restart
```bash
docker-compose down -v  # Removes all data
docker-compose up -d
```

---

## Troubleshooting

**Kafka won't start:**
- Ensure Docker Desktop is running
- Check port 9092 isn't in use: `netstat -an | findstr 9092` (Windows) or `lsof -i :9092` (macOS/Linux)

**Ingestor fails:**
- Verify FRED_API_KEY is set: `echo $env:FRED_API_KEY` (PowerShell) or `echo $FRED_API_KEY` (bash)
- Check Kafka is running: `docker-compose ps`

**Flink job fails:**
- Ensure JAR was built with `assembly` (includes dependencies)
- Check Flink logs in Web UI: http://localhost:8081

**No data in signal topic:**
- Verify input topic has data: `docker exec yield-kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic norm.macro.rate --from-beginning --max-messages 5`
- Check Flink job is running in Web UI

---

## Next Steps

- Read [LOCAL_SETUP.md](LOCAL_SETUP.md) for detailed documentation
- Modify date ranges in `FredIngestor.scala` to fetch more data
- Experiment with spread calculations in `YieldCurveJob.scala`
- Add more Treasury series (DGS5, DGS30)

---

## Architecture

```
FRED API → Ingestor (sbt run) → Kafka → Flink (Docker) → Kafka → [Your Consumer]
```

All services run locally. No cloud deployment needed for development!

