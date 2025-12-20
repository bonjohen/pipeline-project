# Quick Start Guide - Local Development

Get the financial signals pipelines running locally in **10 minutes**.

This guide covers all three implemented pipelines:
1. **Yield Curve Inversion** (10Y-2Y Treasury spread)
2. **Credit Spreads** (High Yield vs Treasuries)
3. **Repo Market Stress** (SOFR spikes)

## 🚀 Automated Setup (Recommended)

Use the automated script to start everything:

**Windows:**
```powershell
$env:FRED_API_KEY = "your_api_key_here"
.\scripts\start-all.ps1
```

**macOS/Linux:**
```bash
export FRED_API_KEY="your_api_key_here"
./scripts/start-all.sh
```

This script will:
1. **Automatically start Docker Desktop** if not running (Windows/macOS)
2. Build all pipelines
3. Start Docker Compose (Kafka, Flink, Zookeeper)
4. Run all ingestors
5. Submit all Flink jobs via REST API

**Skip options:**
- `--SkipBuild` (PowerShell) / `--skip-build` (bash) - Skip building JARs
- `--SkipDocker` (PowerShell) / `--skip-docker` (bash) - Skip Docker startup
- `--SkipIngestors` (PowerShell) / `--skip-ingestors` (bash) - Skip running ingestors

**To stop all services:**
```powershell
# Windows
.\scripts\stop-all.ps1

# macOS/Linux
./scripts/stop-all.sh
```

---

## 📋 Manual Setup (Step-by-Step)

If you prefer to run each step manually:

---

## Prerequisites

- **Docker Desktop** (running)
- **Java 17+**
- **sbt** (Scala Build Tool)
- **FRED API Key** (free from https://fred.stlouisfed.org)

**Windows Users:** See [WINDOWS_SETUP.md](WINDOWS_SETUP.md) for installation help.

---

## Step 1: Start Docker Services

```powershell
# Start Kafka, Zookeeper, and Flink
docker-compose up -d

# Verify services are running
docker-compose ps
```

Wait ~30 seconds for services to initialize.

---

## Step 2: Build Applications

You can build all pipelines or just one. Here's how to build all:

```powershell
# Build Yield Curve pipeline
cd pipelines\yield-curve\ingestor
sbt clean compile assembly
cd ..\flink-job
sbt clean compile assembly
cd ..\..\..

# Build Credit Spreads pipeline
cd pipelines\credit-spreads\ingestor
sbt clean compile assembly
cd ..\flink-job
sbt clean compile assembly
cd ..\..\..

# Build Repo Stress pipeline
cd pipelines\repo-stress\ingestor
sbt clean compile assembly
cd ..\flink-job
sbt clean compile assembly
cd ..\..\..
```

**Or use the automated script:**
```powershell
.\scripts\bootstrap\build-all.ps1
```

---

## Step 3: Run Ingestors

Set environment variables first:
```powershell
$env:FRED_API_KEY = "your_api_key_here"
$env:KAFKA_BOOTSTRAP = "localhost:29092"
```

Then run each ingestor (choose one or run all):

**Yield Curve:**
```powershell
cd pipelines\yield-curve\ingestor
sbt run
cd ..\..\..
```

**Credit Spreads:**
```powershell
cd pipelines\credit-spreads\ingestor
sbt run
cd ..\..\..
```

**Repo Stress:**
```powershell
cd pipelines\repo-stress\ingestor
sbt run
cd ..\..\..
```

**Market Breadth:**
```powershell
# Set your Nasdaq Data Link API key
$env:NASDAQ_DATA_LINK_API_KEY="your_api_key_here"

cd pipelines\market-breadth\ingestor
sbt run
cd ..\..\..
```

You should see: `✅ Data ingested to Kafka topic: norm.macro.rate` (for FRED pipelines)
or `✅ Successfully ingested N breadth records` (for Market Breadth)

---

## Step 4: Submit Flink Jobs

Open **http://localhost:8081** in your browser and submit each job:

### Yield Curve Job
1. Click **"Submit New Job"** → **"+ Add New"**
2. Upload: `pipelines\yield-curve\flink-job\target\scala-2.12\yield-curve-flink-assembly-0.1.0.jar`
3. Entry Class: `YieldCurveJob`
4. Click **"Submit"**

### Credit Spreads Job
1. Click **"Submit New Job"** → **"+ Add New"**
2. Upload: `pipelines\credit-spreads\flink-job\target\scala-2.12\credit-spreads-flink-assembly-0.1.0.jar`
3. Entry Class: `CreditSpreadsJob`
4. Click **"Submit"**

### Repo Stress Job
1. Click **"Submit New Job"** → **"+ Add New"**
2. Upload: `pipelines\repo-stress\flink-job\target\scala-2.12\repo-stress-flink-assembly-0.1.0.jar`
3. Entry Class: `RepoStressJob`
4. Click **"Submit"**

### Market Breadth Job
1. Click **"Submit New Job"** → **"+ Add New"**
2. Upload: `pipelines\market-breadth\flink-job\target\scala-2.12\breadth-flink-assembly-0.1.0.jar`
3. Entry Class: `BreadthSignalJob`
4. Click **"Submit"**

All jobs should appear in "Running Jobs".

---

## Step 5: View Results

View output from each pipeline:

**Yield Curve Signals:**
```powershell
docker exec yield-kafka kafka-console-consumer `
  --bootstrap-server localhost:9092 `
  --topic signal.yield_curve `
  --from-beginning
```

**Credit Spread Signals:**
```powershell
docker exec yield-kafka kafka-console-consumer `
  --bootstrap-server localhost:9092 `
  --topic signal.credit_spread `
  --from-beginning
```

**Repo Stress Signals:**
```powershell
docker exec yield-kafka kafka-console-consumer `
  --bootstrap-server localhost:9092 `
  --topic signal.repo_stress `
  --from-beginning
```

**Market Breadth Signals:**
```powershell
docker exec yield-kafka kafka-console-consumer `
  --bootstrap-server localhost:9092 `
  --topic signals.breadth.zweig `
  --from-beginning
```

**Market Breadth Raw Data:**
```powershell
docker exec yield-kafka kafka-console-consumer `
  --bootstrap-server localhost:9092 `
  --topic market.breadth.raw `
  --from-beginning
```

**Market Breadth Normalized Data:**
```powershell
docker exec yield-kafka kafka-console-consumer `
  --bootstrap-server localhost:9092 `
  --topic market.breadth.normalized `
  --from-beginning
```

---

## macOS/Linux Quick Commands

If you prefer a single script, use the build script:

```bash
# Build both applications
./scripts/bootstrap/build-all.sh

# Set environment and run ingestor
export FRED_API_KEY="your_api_key_here"
export KAFKA_BOOTSTRAP="localhost:29092"
cd pipelines/yield-curve/ingestor
sbt run
```

Then follow Steps 4-5 above to submit the Flink job and view results.

---

## What You'll See

### Example Output: Yield Curve Signal
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

### Example Output: Credit Spread Signal
```json
{
  "schema_version": 1,
  "signal_id": "CREDIT_SPREAD_HY_10Y",
  "event_date": "2025-12-18",
  "spread_bps": 358.0,
  "regime": "NORMAL",
  "stress_level": "LOW"
}
```

### Example Output: Repo Stress Signal
```json
{
  "schema_version": 1,
  "signal_id": "REPO_STRESS_SOFR",
  "event_date": "2025-12-18",
  "spread_bps": 7.0,
  "spike_detected": false,
  "stress_level": "NORMAL",
  "rolling_avg_30d_bps": 7.0
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

### "Not a valid command: assembly"
The sbt-assembly plugin is missing. This should already be configured in `project/plugins.sbt`.
Run `sbt reload` then try again.

### "Error downloading org.apache.flink:flink-streaming-scala_2.13"
This has been fixed. The Flink job uses Scala 2.12 (Flink 1.20.0 requirement).
Make sure you're building the latest code.

### "No resolvable bootstrap urls given in bootstrap.servers"
**For Ingestor:** Set `$env:KAFKA_BOOTSTRAP = "localhost:29092"` (runs on host machine)
**For Flink Job:** The code defaults to `kafka:9092` (runs inside Docker network)

### "Couldn't resolve server yield-kafka.internal"
The Flink job is using the old Fly.io address. Make sure you've rebuilt after the latest code changes.

### Kafka won't start
- Ensure Docker Desktop is running
- Check ports aren't in use: `netstat -an | findstr 9092` (Windows)

### Ingestor fails
- Verify FRED_API_KEY is set: `echo $env:FRED_API_KEY` (PowerShell)
- Check Kafka is running: `docker-compose ps`

### Flink job fails
- Check Flink logs in Web UI: http://localhost:8081
- Verify JAR was built with `assembly`
- Ensure job is connecting to `kafka:9092` (not `localhost:29092`)

### No data in output topic
```powershell
# Check input topic has data
docker exec yield-kafka kafka-console-consumer `
  --bootstrap-server localhost:9092 `
  --topic norm.macro.rate `
  --from-beginning `
  --max-messages 5
```

---

## Key Configuration Notes

### Kafka Bootstrap Addresses
- **Ingestor (runs on host):** `localhost:29092`
- **Flink Job (runs in Docker):** `kafka:9092`
- **Kafka console commands:** `localhost:9092` (inside container via `docker exec`)

### Scala Versions
- **Ingestor:** Scala 2.13.12 (latest)
- **Flink Job:** Scala 2.12.18 (required by Flink 1.20.0)

This is normal - they communicate via JSON over Kafka, not compiled code.

---

## Next Steps

- Modify date ranges in `FredIngestor.scala` to fetch more data
- Experiment with spread calculations in `YieldCurveJob.scala`
- Add more Treasury series (DGS5, DGS30)
- Build a consumer application to process signals

---

## Architecture

```
FRED API → Ingestor (sbt run) → Kafka → Flink (Docker) → Kafka → [Your Consumer]
            ↓                      ↓                        ↓
        localhost:29092      kafka:9092              localhost:9092
```

All services run locally. No cloud deployment needed for development!

