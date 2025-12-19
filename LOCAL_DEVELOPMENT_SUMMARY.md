# Local Development - Complete Summary

This document provides a complete overview of running the yield curve pipeline locally.

---

## 📁 New Files Created

### Configuration
- **docker-compose.yml** - Local Kafka, Zookeeper, and Flink services
- **.env.example** - Environment variable template

### Documentation
- **LOCAL_SETUP.md** - Detailed local setup guide
- **QUICKSTART.md** - 5-minute quick start guide
- **LOCAL_DEVELOPMENT_SUMMARY.md** - This file

### Scripts (Bash - macOS/Linux/Git Bash)
- **scripts/bootstrap/setup-local.sh** - Initialize local environment
- **scripts/bootstrap/build-all.sh** - Build all Scala applications
- **scripts/test/run-pipeline.sh** - Run complete pipeline
- **scripts/test/view-kafka-topics.sh** - View Kafka messages

### Scripts (PowerShell - Windows)
- **scripts/bootstrap/setup-local.ps1** - Initialize local environment
- **scripts/bootstrap/build-all.ps1** - Build all Scala applications
- **scripts/test/run-pipeline.ps1** - Run complete pipeline
- **scripts/test/view-kafka-topics.ps1** - View Kafka messages

---

## 🚀 Quick Start (Choose Your Platform)

### Windows (PowerShell)

```powershell
# 1. Set environment variables
$env:FRED_API_KEY = "your_api_key_here"
$env:KAFKA_BOOTSTRAP = "localhost:29092"

# 2. Run automated setup
.\scripts\bootstrap\setup-local.ps1

# 3. Build applications
.\scripts\bootstrap\build-all.ps1

# 4. Run pipeline
.\scripts\test\run-pipeline.ps1

# 5. View results
.\scripts\test\view-kafka-topics.ps1
```

### macOS/Linux/Git Bash

```bash
# 1. Set environment variables
export FRED_API_KEY="your_api_key_here"
export KAFKA_BOOTSTRAP="localhost:29092"

# 2. Run automated setup
./scripts/bootstrap/setup-local.sh

# 3. Build applications
./scripts/bootstrap/build-all.sh

# 4. Run pipeline
./scripts/test/run-pipeline.sh

# 5. View results
./scripts/test/view-kafka-topics.sh
```

---

## 📊 Architecture (Local)

```
┌─────────────┐
│  FRED API   │ (Internet)
└──────┬──────┘
       │
       ▼
┌─────────────────────┐
│  FredIngestor       │ (Local JVM - sbt run)
│  (Scala)            │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│  Kafka              │ (Docker - localhost:29092)
│  Topic:             │
│  norm.macro.rate    │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│  Flink Job          │ (Docker - Flink cluster)
│  YieldCurveJob      │
│  (Scala)            │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│  Kafka              │ (Docker - localhost:29092)
│  Topic:             │
│  signal.yield_curve │
└──────┬──────────────┘
       │
       ▼
   [Your Consumer]
```

---

## 🔧 Services Running

| Service | Container | Port | Purpose |
|---------|-----------|------|---------|
| Zookeeper | yield-zookeeper | 2181 | Kafka coordination |
| Kafka | yield-kafka | 9092 (internal)<br>29092 (localhost) | Message broker |
| Flink JobManager | yield-flink-jobmanager | 8081 | Flink Web UI & coordination |
| Flink TaskManager | yield-flink-taskmanager | - | Flink job execution |

---

## 📝 Key Topics

| Topic | Purpose | Schema |
|-------|---------|--------|
| norm.macro.rate | Treasury rate data from FRED | schemas/norm_macro_rate.schema.json |
| signal.yield_curve | Yield curve spread signals | schemas/signal_yield_curve.schema.json |

---

## 🛠️ Common Commands

### Service Management
```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose stop

# View service status
docker-compose ps

# View logs
docker-compose logs -f [service-name]

# Restart services
docker-compose restart

# Clean restart (removes all data)
docker-compose down -v
docker-compose up -d
```

### Kafka Operations
```bash
# List topics
docker exec yield-kafka kafka-topics --list --bootstrap-server localhost:9092

# View messages (input)
docker exec yield-kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic norm.macro.rate \
  --from-beginning

# View messages (output)
docker exec yield-kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic signal.yield_curve \
  --from-beginning

# Delete topic (for testing)
docker exec yield-kafka kafka-topics \
  --delete \
  --topic norm.macro.rate \
  --bootstrap-server localhost:9092
```

### Build & Run
```bash
# Build ingestor
cd pipelines/yield-curve/ingestor
sbt clean compile assembly

# Run ingestor
sbt run

# Build Flink job
cd pipelines/yield-curve/flink-job
sbt clean compile assembly

# Run tests
sbt test
```

---

## 🌐 Web Interfaces

- **Flink Dashboard**: http://localhost:8081
  - View running jobs
  - Monitor task managers
  - Check job logs
  - Submit new jobs

---

## 🐛 Troubleshooting

### Docker Issues
```bash
# Check Docker is running
docker info

# Check container status
docker-compose ps

# View container logs
docker-compose logs kafka
docker-compose logs flink-jobmanager
```

### Kafka Connection Issues
- Ensure `KAFKA_BOOTSTRAP=localhost:29092` for local development
- Check Kafka is healthy: `docker-compose ps`
- Verify port 29092 is not in use

### Build Issues
- Ensure Java 17+ is installed: `java -version`
- Clear sbt cache: `sbt clean`
- Check sbt version: `sbt --version`

### FRED API Issues
- Verify API key: `echo $FRED_API_KEY` (bash) or `echo $env:FRED_API_KEY` (PowerShell)
- Check rate limits (FRED allows many requests per day)
- Verify internet connectivity

---

## 📚 Next Steps

1. **Experiment with the code**
   - Modify date ranges in `FredIngestor.scala`
   - Change spread calculation in `YieldCurveJob.scala`
   - Add more Treasury series (DGS5, DGS30)

2. **Build a consumer**
   - Read from `signal.yield_curve` topic
   - Display signals in real-time
   - Store signals in a database

3. **Add more pipelines**
   - Follow the structure in `pipelines/yield-curve`
   - Create new schemas
   - Build new Flink jobs

4. **Deploy to Fly.io** (when ready)
   - Follow original README instructions
   - Use same JARs built locally
   - Configure environment variables in Fly.io

---

## 📖 Documentation Index

- **QUICKSTART.md** - Get running in 5 minutes
- **LOCAL_SETUP.md** - Detailed setup instructions
- **README.md** - Project overview and architecture
- **This file** - Complete local development reference

---

## ✅ Checklist

Before running the pipeline, ensure:

- [ ] Docker Desktop is installed and running
- [ ] Java 17+ is installed
- [ ] sbt is installed
- [ ] FRED API key is obtained and set
- [ ] `docker-compose up -d` completes successfully
- [ ] All services show "Up" in `docker-compose ps`
- [ ] Flink Web UI is accessible at http://localhost:8081
- [ ] Applications are built with `sbt assembly`
- [ ] Environment variables are set correctly

---

**You're all set for local development! 🎉**

