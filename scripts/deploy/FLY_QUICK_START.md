# Fly.io Quick Start Guide

## Prerequisites

1. **Install Fly.io CLI**:
   ```powershell
   powershell -Command "iwr https://fly.io/install.ps1 -useb | iex"
   ```

2. **Login**:
   ```bash
   flyctl auth login
   ```

3. **Set API Keys**:
   ```powershell
   $env:FRED_API_KEY = "your_fred_api_key_here"
   $env:NASDAQ_DATA_LINK_API_KEY = "your_nasdaq_key_here"
   ```

## Deploy Everything (3 Commands)

```powershell
# 1. Build all JARs
.\scripts\bootstrap\build-all.ps1

# 2. Deploy all services
.\scripts\deploy\fly-deploy-all.ps1

# 3. Set secrets
.\scripts\deploy\fly-set-secrets.ps1
```

## Verify Deployment

```bash
# Check all apps are running
flyctl apps list

# Open Flink Web UI
flyctl open --app pipeline-flink-jobmanager

# View Kafka logs
flyctl logs --app pipeline-kafka
```

## Run Ingestors

Ingestors run once and exit. Trigger them manually:

```bash
# Restart an ingestor to fetch fresh data
flyctl apps restart pipeline-yield-ingestor
flyctl apps restart pipeline-credit-ingestor
flyctl apps restart pipeline-repo-ingestor
flyctl apps restart pipeline-breadth-ingestor
```

## View Data

SSH into Kafka and view topics:

```bash
flyctl ssh console --app pipeline-kafka

# Inside the container:
kafka-console-consumer --bootstrap-server localhost:9092 --topic signal.yield_curve --from-beginning --max-messages 10
kafka-console-consumer --bootstrap-server localhost:9092 --topic signal.credit_spread --from-beginning --max-messages 10
kafka-console-consumer --bootstrap-server localhost:9092 --topic signal.repo_stress --from-beginning --max-messages 10
```

## Common Commands

```bash
# View app status
flyctl status --app pipeline-kafka

# View logs (real-time)
flyctl logs --app pipeline-yield-ingestor

# Restart an app
flyctl apps restart pipeline-kafka

# Stop an app (to save costs)
flyctl apps stop pipeline-breadth-ingestor

# Scale down to 0 instances
flyctl scale count 0 --app pipeline-breadth-ingestor
```

## Estimated Costs

- **Platform (Kafka + Flink)**: ~$15-20/month
- **Pipelines (8 services)**: ~$20-30/month
- **Total**: ~$35-50/month

Reduce costs by stopping unused ingestors and scaling down.

## Cleanup

To remove everything:

```bash
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
```

## Troubleshooting

See [FLY_DEPLOYMENT.md](../../FLY_DEPLOYMENT.md) for detailed troubleshooting.

Quick fixes:
- **Kafka won't start**: Check volume exists with `flyctl volumes list --app pipeline-kafka`
- **Flink jobs can't connect**: Verify Kafka is running with `flyctl status --app pipeline-kafka`
- **API key errors**: Set secrets with `flyctl secrets set FRED_API_KEY=your_key --app pipeline-yield-ingestor`

