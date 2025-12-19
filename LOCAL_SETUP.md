# Local Development Setup

This guide explains how to run the entire yield curve pipeline **locally** on your machine without Fly.io.

---

## Prerequisites

### Required Software

1. **Docker Desktop** (for Windows/macOS)
   - Download: https://www.docker.com/products/docker-desktop
   - Ensure Docker is running before proceeding

2. **Java 17**
   ```bash
   sdk install java 17.0.10-tem
   ```

3. **Scala 2.13**
   ```bash
   sdk install scala 2.13.12
   ```

4. **sbt**
   ```bash
   sdk install sbt
   ```

5. **FRED API Key**
   - Get free key at: https://fred.stlouisfed.org
   - Create account → My Account → API Keys → Request API Key

---

## Step 1: Set Environment Variables

### Windows (PowerShell)
```powershell
$env:FRED_API_KEY = "your_api_key_here"
$env:KAFKA_BOOTSTRAP = "localhost:29092"
```

### macOS/Linux (Bash)
```bash
export FRED_API_KEY="your_api_key_here"
export KAFKA_BOOTSTRAP="localhost:29092"
```

**Note:** For permanent setup, add to your shell profile (`~/.bashrc`, `~/.zshrc`, or PowerShell profile).

---

## Step 2: Start Platform Services

From the project root directory:

```bash
docker-compose up -d
```

This starts:
- **Zookeeper** (port 2181)
- **Kafka** (ports 9092 internal, 29092 for localhost)
- **Flink JobManager** (port 8081 - Web UI)
- **Flink TaskManager**

### Verify Services

```bash
docker-compose ps
```

All services should show "Up" status.

**Access Flink Web UI:** http://localhost:8081

---

## Step 3: Build the Scala Applications

### Build Ingestor

```bash
cd pipelines/yield-curve/ingestor
sbt clean compile assembly
```

This creates: `target/scala-2.13/fred-ingestor-assembly-0.1.0.jar`

### Build Flink Job

```bash
cd ../flink-job
sbt clean compile assembly
```

This creates: `target/scala-2.12/yield-curve-flink-assembly-0.1.0.jar`

---

## Step 4: Run the Pipeline

### Option A: Manual Execution (Recommended for Testing)

#### 1. Run the Ingestor (Fetch Data from FRED)

From `pipelines/yield-curve/ingestor`:

```bash
sbt "run"
```

Or using the JAR:

```bash
java -jar target/scala-2.13/fred-ingestor-assembly-0.1.0.jar
```

**Expected Output:**
- Fetches last 10 days of DGS10 and DGS2 data
- Publishes to Kafka topic `norm.macro.rate`
- Exits when complete

#### 2. Verify Data in Kafka

```bash
docker exec -it yield-kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic norm.macro.rate \
  --from-beginning \
  --max-messages 10
```

You should see JSON events with Treasury rate data.

#### 3. Submit Flink Job

From `pipelines/yield-curve/flink-job`:

```bash
# Using Flink CLI (if installed locally)
flink run -c YieldCurveJob target/scala-2.12/yield-curve-flink-assembly-0.1.0.jar

# OR submit via Web UI
# 1. Go to http://localhost:8081
# 2. Click "Submit New Job"
# 3. Upload: target/scala-2.12/yield-curve-flink-assembly-0.1.0.jar
# 4. Entry Class: YieldCurveJob
# 5. Click "Submit"
```

#### 4. Verify Signal Output

```bash
docker exec -it yield-kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic signal.yield_curve \
  --from-beginning
```

You should see yield curve spread calculations and inversion signals.

---

## Step 5: Monitor and Debug

### View Flink Job Status
- Web UI: http://localhost:8081
- Check running jobs, task managers, logs

### View Kafka Topics

```bash
# List all topics
docker exec -it yield-kafka kafka-topics --list --bootstrap-server localhost:9092

# Describe a topic
docker exec -it yield-kafka kafka-topics --describe --topic norm.macro.rate --bootstrap-server localhost:9092
```

### View Docker Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f kafka
docker-compose logs -f flink-jobmanager
```

---

## Step 6: Stop Services

```bash
# Stop but keep data
docker-compose stop

# Stop and remove containers (keeps volumes)
docker-compose down

# Stop and remove everything including data
docker-compose down -v
```

---

## Troubleshooting

### Kafka Connection Issues

If ingestor/Flink can't connect to Kafka:
- Ensure `KAFKA_BOOTSTRAP=localhost:29092` is set
- Verify Kafka is healthy: `docker-compose ps`
- Check Kafka logs: `docker-compose logs kafka`

### "Not a valid command: assembly"

The sbt-assembly plugin is missing. This has been fixed - the plugin file is now included at:
- `pipelines/yield-curve/ingestor/project/plugins.sbt`
- `pipelines/yield-curve/flink-job/project/plugins.sbt`

If you still see this error, run the build command again (sbt needs to reload the plugin).

### "Error downloading org.apache.flink:flink-streaming-scala_2.13"

This has been fixed. The Flink job now uses Scala 2.12 (Flink 1.20.0 doesn't support Scala 2.13).
The ingestor still uses Scala 2.13. Run the build command again.

### Flink Job Fails

- Check Flink logs in Web UI (http://localhost:8081)
- Verify JAR was built with `assembly` (includes all dependencies)
- Ensure Kafka topic `norm.macro.rate` has data

### FRED API Issues

- Verify API key is set: `echo $FRED_API_KEY` (bash) or `echo $env:FRED_API_KEY` (PowerShell)
- Check API key is valid at https://fred.stlouisfed.org
- FRED may rate-limit; wait a few minutes between runs

---

## Running Tests

### Ingestor Tests
```bash
cd pipelines/yield-curve/ingestor
sbt test
```

### Flink Job Tests
```bash
cd pipelines/yield-curve/flink-job
sbt test
```

---

## Next Steps

Once local setup works:
1. Experiment with different date ranges in `FredIngestor.scala`
2. Modify spread calculation logic in `YieldCurveJob.scala`
3. Add more Treasury series (DGS5, DGS30, etc.)
4. Build a consumer to read signals and display them

---

## Architecture Diagram (Local)

```
FRED API (internet)
   ↓
FredIngestor (local JVM)
   ↓
Kafka (Docker: localhost:29092)
   ↓ topic: norm.macro.rate
Flink Job (Docker: Flink cluster)
   ↓ topic: signal.yield_curve
Kafka (Docker)
   ↓
[Future: Dashboard/Consumer]
```

