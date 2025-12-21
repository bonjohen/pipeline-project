# How to Access the Flink Dashboard

The Flink JobManager web UI is running on port 8081, but it's not publicly exposed for security reasons.

## Option 1: SSH into the Machine (Easiest)

```powershell
# Get the machine ID
flyctl machine list --app pipeline-flink-jobmanager

# SSH into the machine
flyctl ssh console --app pipeline-flink-jobmanager

# Inside the machine, check if Flink is running
curl http://localhost:8081
```

## Option 2: Use Fly.io Proxy (Recommended for Web Access)

This creates a secure tunnel from your local machine to the Flink JobManager:

```powershell
# Make sure you're NOT in the platform/flink directory
cd C:\Projects\pipeline-project

# Start the proxy (this will keep running)
flyctl proxy 8081 --app pipeline-flink-jobmanager
```

Then open your browser to: **http://localhost:8081**

Press `Ctrl+C` to stop the proxy when you're done.

## Option 2: SSH Port Forwarding

```powershell
# SSH into the machine with port forwarding
flyctl ssh console --app pipeline-flink-jobmanager -L 8081:localhost:8081
```

Then open your browser to: **http://localhost:8081**

## Option 3: Make it Publicly Accessible (Not Recommended)

If you really want to make it publicly accessible, you would need to:

1. Update the fly.toml to properly configure the HTTP service
2. Redeploy the app
3. Access it at https://pipeline-flink-jobmanager.fly.dev

However, this exposes your Flink dashboard to the internet, which is a security risk.

## What You'll See in the Dashboard

- **Overview**: Cluster status, available task slots, running jobs
- **Jobs**: List of all Flink jobs (running, finished, failed)
- **Task Managers**: Connected TaskManager instances
- **Job Manager**: JobManager configuration and metrics
- **Submit New Job**: Upload and submit new Flink JAR files

## Troubleshooting

### Proxy command fails
```powershell
# Re-authenticate first
flyctl auth logout
flyctl auth login

# Then try the proxy again
flyctl proxy 8081:8081 --app pipeline-flink-jobmanager
```

### Dashboard shows no jobs
This is normal if the Flink jobs haven't been submitted yet. The ingestors run independently and publish to Kafka. The Flink jobs need to be submitted to process the data.

### Can't connect to localhost:8081
Make sure the proxy command is still running in another terminal window.

