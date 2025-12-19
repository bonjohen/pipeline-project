# Step-by-Step Local Setup Guide

Follow these exact steps to get the yield curve pipeline running locally.

---

## Prerequisites Check

Before starting, verify you have:

1. **Docker Desktop** - Download from https://www.docker.com/products/docker-desktop
   - Install and start Docker Desktop
   - Verify: Open terminal and run `docker --version`

2. **Java 17+** - Use SDKMAN (recommended)
   ```bash
   curl -s "https://get.sdkman.io" | bash
   sdk install java 17.0.10-tem
   ```
   - Verify: `java -version` (should show 17 or higher)

3. **sbt** - Scala build tool
   ```bash
   sdk install sbt
   ```
   - Verify: `sbt --version`

4. **FRED API Key** - Free from https://fred.stlouisfed.org
   - Create account
   - Go to "My Account" → "API Keys"
   - Click "Request API Key"
   - Copy your key

---

## Step 1: Set Environment Variables

### Windows PowerShell
```powershell
# Set for current session
$env:FRED_API_KEY = "paste_your_key_here"
$env:KAFKA_BOOTSTRAP = "localhost:29092"

# Verify
echo $env:FRED_API_KEY
echo $env:KAFKA_BOOTSTRAP
```

### macOS/Linux/Git Bash
```bash
# Set for current session
export FRED_API_KEY="paste_your_key_here"
export KAFKA_BOOTSTRAP="localhost:29092"

# Verify
echo $FRED_API_KEY
echo $KAFKA_BOOTSTRAP
```

**Note:** These are temporary. For permanent setup, add to your shell profile.

---

## Step 2: Start Docker Services

```bash
# From project root directory
docker-compose up -d
```

**Expected output:**
```
Creating network "pipeline-project_yield-network" with driver "bridge"
Creating yield-zookeeper ... done
Creating yield-kafka ... done
Creating yield-flink-jobmanager ... done
Creating yield-flink-taskmanager ... done
```

**Verify services are running:**
```bash
docker-compose ps
```

All services should show "Up" status.

**Test Flink Web UI:**
Open browser: http://localhost:8081

You should see the Flink Dashboard.

---

## Step 3: Build the Ingestor

```bash
cd pipelines/yield-curve/ingestor
sbt clean compile assembly
```

**What this does:**
- Downloads dependencies (first time only - may take a few minutes)
- Compiles Scala code
- Creates fat JAR with all dependencies

**Expected output (last line):**
```
[success] Total time: XX s
```

**Verify JAR was created:**
```bash
ls target/scala-2.13/fred-ingestor-assembly-0.1.0.jar
```

---

## Step 4: Build the Flink Job

```bash
cd ../flink-job
sbt clean compile assembly
```

**Expected output (last line):**
```
[success] Total time: XX s
```

**Verify JAR was created:**
```bash
ls target/scala-2.12/yield-curve-flink-assembly-0.1.0.jar
```

---

## Step 5: Run the Ingestor

```bash
cd ../ingestor
sbt run
```

**What this does:**
- Fetches last 10 days of DGS10 and DGS2 data from FRED
- Publishes JSON events to Kafka topic `norm.macro.rate`
- Exits when complete

**Expected output:**
```
[info] running FredIngestor
[success] Total time: X s
```

**Verify data in Kafka:**
```bash
docker exec yield-kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic norm.macro.rate \
  --from-beginning \
  --max-messages 5
```

You should see JSON like:
```json
{"schema_version":1,"event_id":"...","source":"fred","series_id":"DGS10","event_date":"2025-12-18","value_pct":4.52,"ingest_ts_utc":"..."}
```

Press Ctrl+C to stop.

---

## Step 6: Submit Flink Job

### Option A: Using Flink Web UI (Recommended)

1. Open http://localhost:8081
2. Click "Submit New Job" in left sidebar
3. Click "Add New" button
4. Upload: `pipelines/yield-curve/flink-job/target/scala-2.12/yield-curve-flink-assembly-0.1.0.jar`
5. Wait for upload to complete
6. In "Entry Class" field, type: `YieldCurveJob`
7. Click "Submit"

You should see the job appear in "Running Jobs".

### Option B: Using Flink CLI (if installed)

```bash
cd ../flink-job
flink run -c YieldCurveJob target/scala-2.12/yield-curve-flink-assembly-0.1.0.jar
```

---

## Step 7: View Results

```bash
docker exec yield-kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic signal.yield_curve \
  --from-beginning
```

**Expected output:**
You should see yield curve spread calculations (may take a few seconds to appear).

Press Ctrl+C to stop.

---

## Step 8: Monitor in Flink UI

1. Go to http://localhost:8081
2. Click on your running job
3. View:
   - Task Managers
   - Job Graph
   - Logs (click on tasks)

---

## Success! 🎉

You now have a complete streaming pipeline running locally:
- ✅ FRED data ingestion
- ✅ Kafka message broker
- ✅ Flink stream processing
- ✅ Yield curve signal generation

---

## Next Steps

### Run Again with Fresh Data

```bash
# Stop Flink job (in Web UI or Ctrl+C)
# Run ingestor again
cd pipelines/yield-curve/ingestor
sbt run
# Submit Flink job again
```

### Clean Restart

```bash
# Stop and remove all data
docker-compose down -v

# Start fresh
docker-compose up -d

# Rebuild and run
```

### Experiment

- Modify `FredIngestor.scala` to fetch more days of data
- Change spread calculation in `YieldCurveJob.scala`
- Add more Treasury series (DGS5, DGS30)

---

## Troubleshooting

### "Cannot connect to Kafka"
- Check Docker is running: `docker-compose ps`
- Verify KAFKA_BOOTSTRAP: `echo $KAFKA_BOOTSTRAP` (should be `localhost:29092`)
- Restart Kafka: `docker-compose restart kafka`

### "FRED_API_KEY not found"
- Verify it's set: `echo $FRED_API_KEY`
- Re-export the variable
- Check for typos

### "Port already in use"
- Check what's using the port: `netstat -an | findstr 9092` (Windows) or `lsof -i :9092` (macOS/Linux)
- Stop conflicting service or change port in docker-compose.yml

### "Not a valid command: assembly"
- The sbt-assembly plugin file has been created
- Run the build command again (sbt needs to reload the plugin)

### "Error downloading org.apache.flink:flink-streaming-scala_2.13"
- This has been fixed - Flink job now uses Scala 2.12
- Run the build command again

### Flink job fails
- Check logs in Flink Web UI
- Verify input topic has data
- Ensure JAR was built with `assembly`

---

## Stopping Everything

```bash
# Stop services (keeps data)
docker-compose stop

# Stop and remove containers (keeps data)
docker-compose down

# Stop and remove everything including data
docker-compose down -v
```

---

## Quick Reference

| Command | Purpose |
|---------|---------|
| `docker-compose up -d` | Start services |
| `docker-compose ps` | Check status |
| `docker-compose logs -f kafka` | View Kafka logs |
| `sbt clean compile assembly` | Build JAR |
| `sbt run` | Run application |
| `sbt test` | Run tests |

---

**Need help?** Check LOCAL_SETUP.md for detailed documentation.

