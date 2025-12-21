# 🎉 Fly.io Deployment Complete!

## ✅ All Services Deployed Successfully

### Platform Services (3/3)
- ✅ **pipeline-kafka** - Kafka + Zookeeper with 10GB persistent volume
- ✅ **pipeline-flink-jobmanager** - Flink JobManager with web UI
- ✅ **pipeline-flink-taskmanager** - Flink TaskManager (workers)

### Pipeline Services (10/10)
- ✅ **pipeline-yield-ingestor** - Yield Curve Ingestor (FRED_API_KEY configured)
- ✅ **pipeline-yield-flink** - Yield Curve Flink Job
- ✅ **pipeline-credit-ingestor** - Credit Spreads Ingestor (FRED_API_KEY configured)
- ✅ **pipeline-credit-flink** - Credit Spreads Flink Job
- ✅ **pipeline-repo-ingestor** - Repo Stress Ingestor (FRED_API_KEY configured)
- ✅ **pipeline-repo-flink** - Repo Stress Flink Job
- ✅ **pipeline-breadth-ingestor** - Market Breadth Ingestor (placeholder API key)
- ✅ **pipeline-breadth-flink** - Market Breadth Flink Job

**Total: 13 apps deployed (11 pipeline apps + 2 pending cleanup)**

## 🔑 API Keys Configured

- ✅ **FRED_API_KEY** - Set for yield-curve, credit-spreads, and repo-stress ingestors
- ⚠️  **NASDAQ_DATA_LINK_API_KEY** - Placeholder set for market-breadth ingestor
  - Current value: `PLACEHOLDER_KEY_GET_FROM_NASDAQ_DATA_LINK`
  - Get a real key at: https://data.nasdaq.com
  - Update with: `flyctl secrets set NASDAQ_DATA_LINK_API_KEY="your_real_key" --app pipeline-breadth-ingestor`

## 🚀 Quick Commands

### View All Apps
```bash
flyctl apps list
```

### Check App Status
```bash
flyctl status --app pipeline-kafka
flyctl status --app pipeline-flink-jobmanager
```

### View Logs
```bash
# Platform services
flyctl logs --app pipeline-kafka
flyctl logs --app pipeline-flink-jobmanager

# Pipeline services
flyctl logs --app pipeline-yield-ingestor
flyctl logs --app pipeline-credit-ingestor
flyctl logs --app pipeline-repo-ingestor
flyctl logs --app pipeline-breadth-ingestor
```

### Access Flink Web UI
```bash
flyctl open --app pipeline-flink-jobmanager
```
Or visit: https://pipeline-flink-jobmanager.fly.dev

### SSH into a Machine
```bash
flyctl ssh console --app pipeline-kafka
```

### Restart an App
```bash
flyctl apps restart pipeline-yield-ingestor
```

### Scale an App
```bash
# Increase memory
flyctl scale memory 1024 --app pipeline-yield-ingestor

# Add more machines
flyctl scale count 2 --app pipeline-flink-taskmanager
```

## 📊 Monitoring

### Check Machine Status
```bash
flyctl machine list --app pipeline-kafka
```

### View Metrics
```bash
flyctl dashboard
```

### Check Kafka Topics (from local)
```bash
# First, SSH into Kafka machine
flyctl ssh console --app pipeline-kafka

# Then list topics
kafka-topics --bootstrap-server localhost:9092 --list

# View messages
kafka-console-consumer --bootstrap-server localhost:9092 --topic signal.yield_curve --from-beginning
```

## 💰 Cost Management

### Current Setup
- **Platform**: 3 apps (Kafka + 2 Flink services)
- **Pipelines**: 8 apps (4 ingestors + 4 Flink jobs)
- **Estimated cost**: ~$35-50/month

### Stop Apps to Save Money
```bash
# Stop all pipeline services (keep platform running)
flyctl apps stop pipeline-yield-ingestor
flyctl apps stop pipeline-yield-flink
flyctl apps stop pipeline-credit-ingestor
flyctl apps stop pipeline-credit-flink
flyctl apps stop pipeline-repo-ingestor
flyctl apps stop pipeline-repo-flink
flyctl apps stop pipeline-breadth-ingestor
flyctl apps stop pipeline-breadth-flink

# Stop platform services
flyctl apps stop pipeline-kafka
flyctl apps stop pipeline-flink-jobmanager
flyctl apps stop pipeline-flink-taskmanager
```

### Start Apps Again
```bash
# Start platform first
flyctl machine start <machine_id> --app pipeline-kafka
flyctl machine start <machine_id> --app pipeline-flink-jobmanager
flyctl machine start <machine_id> --app pipeline-flink-taskmanager

# Then start pipelines
flyctl apps restart pipeline-yield-ingestor
# ... etc
```

## 🔧 Troubleshooting

### App is Crashing
```bash
# Check logs
flyctl logs --app <app-name>

# Check machine status
flyctl machine list --app <app-name>

# Restart the app
flyctl apps restart <app-name>
```

### Kafka Connection Issues
```bash
# Make sure Kafka is running
flyctl status --app pipeline-kafka

# If stopped, start it
flyctl machine start <machine_id> --app pipeline-kafka

# Check if it's accessible
flyctl ssh console --app pipeline-kafka
# Inside the machine:
netstat -tulpn | grep 9092
```

### Update API Keys
```bash
# Update FRED API key
flyctl secrets set FRED_API_KEY="new_key" --app pipeline-yield-ingestor

# Update NASDAQ key
flyctl secrets set NASDAQ_DATA_LINK_API_KEY="new_key" --app pipeline-breadth-ingestor
```

## 📝 Next Steps

1. **Get a real NASDAQ Data Link API key** and update the breadth ingestor
2. **Monitor the logs** to ensure data is flowing correctly
3. **Check the Flink dashboard** to see job status
4. **Set up alerts** in the Fly.io dashboard
5. **Consider adding health checks** to the fly.toml files

## 🎯 Architecture

```
Internet
   │
   ├─→ FRED API ────→ [Yield/Credit/Repo Ingestors] ──→ Kafka
   └─→ Nasdaq API ──→ [Breadth Ingestor] ─────────────→ Kafka
                                                          │
                                                          ↓
                                                    [Flink Jobs]
                                                          │
                                                          ↓
                                                    Kafka (Signals)
```

All services communicate via Fly.io's private `.internal` network for security and performance.

