# Fly.io Deployment Guide

This guide walks you through deploying the entire pipeline system to Fly.io.

## Prerequisites

1. Install Fly.io CLI:
   ```powershell
   powershell -Command "iwr https://fly.io/install.ps1 -useb | iex"
   ```

2. Login to Fly.io:
   ```bash
   flyctl auth login
   ```

3. Build all JARs locally:
   ```powershell
   .\scripts\bootstrap\build-all.ps1
   ```

## Architecture on Fly.io

The system is deployed as **11 separate Fly.io apps**:

### Platform Services (3 apps)
1. **pipeline-kafka** - Kafka + Zookeeper (with persistent volume)
2. **pipeline-flink-jobmanager** - Flink JobManager (web UI + coordinator)
3. **pipeline-flink-taskmanager** - Flink TaskManager (workers)

### Pipeline Services (8 apps - 4 pipelines × 2 services each)
4. **pipeline-yield-ingestor** - Fetches Treasury data from FRED API
5. **pipeline-yield-flink** - Processes yield curve signals
6. **pipeline-credit-ingestor** - Fetches credit spread data from FRED API
7. **pipeline-credit-flink** - Processes credit spread signals
8. **pipeline-repo-ingestor** - Fetches repo rate data from FRED API
9. **pipeline-repo-flink** - Processes repo stress signals
10. **pipeline-breadth-ingestor** - Fetches market breadth data from Nasdaq Data Link
11. **pipeline-breadth-flink** - Processes market breadth signals

## Deployment Order

**IMPORTANT**: Deploy in this exact order to ensure dependencies are met.

### Step 1: Deploy Platform Services

**Note**: The automated script (`fly-deploy-all.ps1`) handles app creation automatically. If deploying manually:

```powershell
# 1. Deploy Kafka (with persistent storage)
cd platform/kafka
flyctl deploy --ha=false
# The script will create the app and volume automatically

# 2. Deploy Flink JobManager
cd ../flink
flyctl deploy --config fly.jobmanager.toml --ha=false

# 3. Deploy Flink TaskManager
flyctl deploy --config fly.taskmanager.toml --ha=false
```

### Step 2: Set API Keys as Secrets

```powershell
# FRED API Key (required for yield-curve, credit-spreads, repo-stress)
flyctl secrets set FRED_API_KEY="your_fred_api_key" --app pipeline-yield-ingestor
flyctl secrets set FRED_API_KEY="your_fred_api_key" --app pipeline-credit-ingestor
flyctl secrets set FRED_API_KEY="your_fred_api_key" --app pipeline-repo-ingestor

# Nasdaq Data Link API Key (required for market-breadth)
flyctl secrets set NASDAQ_DATA_LINK_API_KEY="your_nasdaq_key" --app pipeline-breadth-ingestor
```

### Step 3: Deploy Pipeline Services

**Note**: The automated script handles app creation. If deploying manually, just run `flyctl deploy --ha=false` in each directory.

The script will deploy all 8 pipeline services (4 ingestors + 4 Flink jobs) automatically.

## Accessing Services

```bash
# View Flink Web UI
flyctl open --app pipeline-flink-jobmanager

# View logs
flyctl logs --app pipeline-kafka
flyctl logs --app pipeline-yield-ingestor
flyctl logs --app pipeline-yield-flink

# SSH into Kafka to view topics
flyctl ssh console --app pipeline-kafka
# Then run: kafka-console-consumer --bootstrap-server localhost:9092 --topic signal.yield_curve --from-beginning
```

## Networking

All apps communicate via Fly.io's private network (`.internal` DNS):
- Kafka: `pipeline-kafka.internal:9092`
- Flink JobManager: `pipeline-flink-jobmanager.internal:6123`

## Cost Estimation

- **Platform services**: ~$15-20/month (Kafka with volume, 2 Flink instances)
- **Pipeline services**: ~$20-30/month (8 small instances)
- **Total**: ~$35-50/month

You can reduce costs by:
- Using `auto_stop_machines` for ingestors (they run once and exit)
- Scaling down to 1 TaskManager
- Using smaller VM sizes

## Automated Deployment

Use the provided scripts for easier deployment:

```powershell
# 1. Build all JARs
.\scripts\bootstrap\build-all.ps1

# 2. Deploy all services to Fly.io
.\scripts\deploy\fly-deploy-all.ps1

# 3. Set API keys as secrets
$env:FRED_API_KEY = "your_fred_api_key"
$env:NASDAQ_DATA_LINK_API_KEY = "your_nasdaq_key"
.\scripts\deploy\fly-set-secrets.ps1
```

## Troubleshooting

### Issue: "Could not find a Dockerfile"

**Solution**: Make sure you're in the correct directory when running `flyctl deploy`. Each service has its own `fly.toml` and `Dockerfile`.

### Issue: Kafka fails to start

**Symptoms**: Logs show Zookeeper connection errors

**Solution**:
1. Check if the volume was created: `flyctl volumes list --app pipeline-kafka`
2. Restart the app: `flyctl apps restart pipeline-kafka`
3. Check logs: `flyctl logs --app pipeline-kafka`

### Issue: Flink jobs can't connect to Kafka

**Symptoms**: Flink job logs show "Connection refused" to Kafka

**Solution**:
1. Verify Kafka is running: `flyctl status --app pipeline-kafka`
2. Check internal DNS: `flyctl ssh console --app pipeline-flink-jobmanager` then `ping pipeline-kafka.internal`
3. Verify KAFKA_BOOTSTRAP env var is set correctly in fly.toml

### Issue: Ingestor fails with "API key not found"

**Solution**: Set the API key as a secret:
```bash
flyctl secrets set FRED_API_KEY="your_key" --app pipeline-yield-ingestor
```

### Issue: High costs

**Solution**:
1. Stop unused apps: `flyctl apps stop pipeline-breadth-ingestor`
2. Scale down: `flyctl scale count 0 --app pipeline-breadth-ingestor`
3. Use smaller VMs: Edit fly.toml and change `memory = '256mb'`

### Issue: Flink Web UI not accessible

**Solution**:
```bash
flyctl open --app pipeline-flink-jobmanager
```

This opens the Flink dashboard in your browser.

## Monitoring

### View all apps
```bash
flyctl apps list
```

### View app status
```bash
flyctl status --app pipeline-kafka
flyctl status --app pipeline-flink-jobmanager
```

### View logs
```bash
# Real-time logs
flyctl logs --app pipeline-kafka

# Specific number of lines
flyctl logs --app pipeline-yield-ingestor -n 100
```

### SSH into a container
```bash
flyctl ssh console --app pipeline-kafka

# Then inside the container:
kafka-console-consumer --bootstrap-server localhost:9092 --topic signal.yield_curve --from-beginning
```

## Scaling

### Scale ingestors (run on schedule)
```bash
# Stop ingestor (it runs once and exits)
flyctl scale count 0 --app pipeline-yield-ingestor

# Run manually when needed
flyctl scale count 1 --app pipeline-yield-ingestor
```

### Scale Flink TaskManagers
```bash
# Add more TaskManagers for parallel processing
flyctl scale count 2 --app pipeline-flink-taskmanager
```

## Cleanup

To remove all apps and volumes:

```powershell
# Delete all apps
flyctl apps destroy pipeline-kafka --yes
flyctl apps destroy pipeline-flink-jobmanager --yes
flyctl apps destroy pipeline-flink-taskmanager --yes
flyctl apps destroy pipeline-yield-ingestor --yes
flyctl apps destroy pipeline-yield-flink --yes
flyctl apps destroy pipeline-credit-ingestor --yes
flyctl apps destroy pipeline-credit-flink --yes
flyctl apps destroy pipeline-repo-ingestor --yes
flyctl apps destroy pipeline-repo-flink --yes
flyctl apps destroy pipeline-breadth-ingestor --yes
flyctl apps destroy pipeline-breadth-flink --yes

# Volumes are automatically deleted when the app is destroyed
```

## Important Notes

1. **Kafka Data Persistence**: The Kafka volume persists data even if the app restarts. To reset, destroy the volume and recreate it.

2. **Ingestor Behavior**: Ingestors run once and exit. They're designed to be triggered manually or via cron. Consider using Fly.io's scheduled machines feature.

3. **Flink Job Submission**: The Flink jobs are submitted automatically when the container starts. They connect to the JobManager via internal networking.

4. **Internal Networking**: All services communicate via Fly.io's private `.internal` network. No public internet traffic between services.

5. **Region Selection**: All services are deployed to `sjc` (San Jose) region. Change `primary_region` in fly.toml files if needed.

## Next Steps

After deployment:
1. Verify all services are running: `flyctl apps list`
2. Check Flink Web UI: `flyctl open --app pipeline-flink-jobmanager`
3. Run ingestors manually to populate data
4. View signals in Kafka topics via SSH

