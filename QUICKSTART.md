# Quick Start Guide - Local Development

Get the yield curve pipeline running locally in **10 minutes**.

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

```powershell
# Build both the ingestor and Flink job
cd pipelines\yield-curve\ingestor
sbt clean compile assembly

cd ..\flink-job
sbt clean compile assembly

cd ..\..\..
```

**Expected output:**
- `pipelines/yield-curve/ingestor/target/scala-2.13/fred-ingestor-assembly-0.1.0.jar`
- `pipelines/yield-curve/flink-job/target/scala-2.12/yield-curve-flink-assembly-0.1.0.jar`

---

## Step 3: Run the Ingestor

```powershell
# Set environment variables
$env:FRED_API_KEY = "your_api_key_here"
$env:KAFKA_BOOTSTRAP = "localhost:29092"

# Run the ingestor
cd pipelines\yield-curve\ingestor
sbt run
```

You should see: `Publishing to Kafka topic: norm.macro.rate`

Press Ctrl+C when done, then return to project root:
```powershell
cd ..\..\..
```

---

## Step 4: Submit Flink Job

1. Open **http://localhost:8081** in your browser
2. Click **"Submit New Job"** in the left sidebar
3. Click **"+ Add New"** button
4. Upload: `pipelines\yield-curve\flink-job\target\scala-2.12\yield-curve-flink-assembly-0.1.0.jar`
5. Set **Entry Class:** `YieldCurveJob`
6. Click **"Submit"**

The job should appear in "Running Jobs".

---

## Step 5: View Results

```powershell
# View the output signals
docker exec yield-kafka kafka-console-consumer `
  --bootstrap-server localhost:9092 `
  --topic signal.yield_curve `
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

