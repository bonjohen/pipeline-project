# Deployment Scripts

This directory contains scripts for deploying the pipeline system to various platforms.

## Fly.io Deployment

### Quick Start

See [FLY_QUICK_START.md](FLY_QUICK_START.md) for a quick reference guide.

### Full Documentation

See [../../FLY_DEPLOYMENT.md](../../FLY_DEPLOYMENT.md) for comprehensive deployment instructions.

### Scripts

- **`fly-deploy-all.ps1`** - Automated deployment of all services to Fly.io
- **`fly-set-secrets.ps1`** - Set API keys as secrets in Fly.io apps

### Usage

```powershell
# 1. Build all JARs first
cd ../..
.\scripts\bootstrap\build-all.ps1

# 2. Set your API keys
$env:FRED_API_KEY = "your_fred_api_key"
$env:NASDAQ_DATA_LINK_API_KEY = "your_nasdaq_key"

# 3. Deploy everything
.\scripts\deploy\fly-deploy-all.ps1

# 4. Set secrets
.\scripts\deploy\fly-set-secrets.ps1
```

## Architecture on Fly.io

The system is deployed as 11 separate Fly.io apps:

### Platform Services (3 apps)
- `pipeline-kafka` - Kafka + Zookeeper with persistent storage
- `pipeline-flink-jobmanager` - Flink coordinator with web UI
- `pipeline-flink-taskmanager` - Flink workers

### Pipeline Services (8 apps)
- `pipeline-yield-ingestor` + `pipeline-yield-flink`
- `pipeline-credit-ingestor` + `pipeline-credit-flink`
- `pipeline-repo-ingestor` + `pipeline-repo-flink`
- `pipeline-breadth-ingestor` + `pipeline-breadth-flink`

## Networking

All services communicate via Fly.io's private `.internal` network:
- Kafka: `pipeline-kafka.internal:9092`
- Flink JobManager: `pipeline-flink-jobmanager.internal:6123`

## Cost Optimization

- Ingestors run once and exit - scale them to 0 when not needed
- Use smaller VM sizes for development
- Stop unused pipelines

## Other Platforms

For other deployment platforms (AWS, GCP, Azure, Railway, Render), see the main [FLY_DEPLOYMENT.md](../../FLY_DEPLOYMENT.md) for alternatives.

