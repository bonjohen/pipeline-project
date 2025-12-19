# Windows Setup Guide

Complete setup guide for Windows users (PowerShell).

---

## Prerequisites Installation

### 1. Install Java 17

**Option A: Using Chocolatey (Recommended)**

If you have Chocolatey installed:
```powershell
choco install temurin17
```

**Option B: Manual Installation**

1. Download Eclipse Temurin 17 (OpenJDK):
   - Go to: https://adoptium.net/temurin/releases/
   - Select: Version 17 (LTS), Windows, x64
   - Download the `.msi` installer
2. Run the installer
3. Check "Set JAVA_HOME variable" during installation
4. Restart PowerShell

**Verify Installation:**
```powershell
java -version
```

Should show: `openjdk version "17.x.x"`

---

### 2. Install sbt (Scala Build Tool)

**Option A: Using Chocolatey**
```powershell
choco install sbt
```

**Option B: Manual Installation**

1. Download sbt from: https://www.scala-sbt.org/download.html
2. Download the Windows (msi) installer
3. Run the installer
4. Restart PowerShell

**Verify Installation:**
```powershell
sbt --version
```

---

### 3. Install Docker Desktop

1. Download from: https://www.docker.com/products/docker-desktop
2. Install Docker Desktop for Windows
3. Start Docker Desktop
4. Wait for it to fully start (whale icon in system tray should be steady)

**Verify Installation:**
```powershell
docker --version
docker-compose --version
```

---

### 4. Get FRED API Key

1. Go to: https://fred.stlouisfed.org
2. Create a free account
3. Navigate to: My Account → API Keys
4. Click "Request API Key"
5. Copy your API key

---

## Quick Start (After Prerequisites)

### Step 1: Set Environment Variables

```powershell
# Set for current PowerShell session
$env:FRED_API_KEY = "paste_your_api_key_here"
$env:KAFKA_BOOTSTRAP = "localhost:29092"

# Verify
echo $env:FRED_API_KEY
echo $env:KAFKA_BOOTSTRAP
```

**To make permanent (optional):**
```powershell
# Set permanently for your user account
[System.Environment]::SetEnvironmentVariable('FRED_API_KEY', 'your_key_here', 'User')
[System.Environment]::SetEnvironmentVariable('KAFKA_BOOTSTRAP', 'localhost:29092', 'User')

# Restart PowerShell after this
```

---

### Step 2: Start Docker Services

```powershell
# Navigate to project root
cd C:\Projects\pipeline-project

# Start services
docker-compose up -d

# Wait 10 seconds for services to start
Start-Sleep -Seconds 10

# Check status
docker-compose ps
```

All services should show "Up".

**Open Flink Web UI:** http://localhost:8081

---

### Step 3: Build Applications

```powershell
# Build Ingestor
cd pipelines\yield-curve\ingestor
sbt clean compile assembly

# Build Flink Job
cd ..\flink-job
sbt clean compile assembly

# Return to project root
cd ..\..\..
```

**Note:** First build will download dependencies (may take 5-10 minutes).

**If you get "Not a valid command: assembly" error:**
The sbt-assembly plugin file has been created. Just run the command again:
```powershell
sbt clean compile assembly
```

**If you get "Error downloading org.apache.flink:flink-streaming-scala_2.13" error:**
This has been fixed. The Flink job now uses Scala 2.12 (Flink 1.20.0 doesn't support Scala 2.13).
Run the build command again:
```powershell
sbt clean compile assembly
```

---

### Step 4: Run the Ingestor

```powershell
cd pipelines\yield-curve\ingestor
sbt run
```

**Expected output:**
```
[info] running FredIngestor
[success] Total time: X s
```

---

### Step 5: Verify Data in Kafka

```powershell
docker exec yield-kafka kafka-console-consumer `
  --bootstrap-server localhost:9092 `
  --topic norm.macro.rate `
  --from-beginning `
  --max-messages 5
```

You should see JSON events. Press Ctrl+C to stop.

---

### Step 6: Submit Flink Job

1. Open browser: http://localhost:8081
2. Click "Submit New Job" (left sidebar)
3. Click "Add New" button
4. Click "Select File" and navigate to:
   ```
   C:\Projects\pipeline-project\pipelines\yield-curve\flink-job\target\scala-2.12\yield-curve-flink-assembly-0.1.0.jar
   ```
5. Upload the file
6. In "Entry Class" field, type: `YieldCurveJob`
7. Click "Submit"

---

### Step 7: View Results

```powershell
docker exec yield-kafka kafka-console-consumer `
  --bootstrap-server localhost:9092 `
  --topic signal.yield_curve `
  --from-beginning
```

You should see yield curve signals. Press Ctrl+C to stop.

---

## Automated Scripts

Once prerequisites are installed, you can use the automated scripts:

```powershell
# Setup (checks prerequisites and starts Docker)
.\scripts\bootstrap\setup-local.ps1

# Build all applications
.\scripts\bootstrap\build-all.ps1

# Run pipeline
.\scripts\test\run-pipeline.ps1

# View Kafka topics
.\scripts\test\view-kafka-topics.ps1
```

---

## Troubleshooting

### "sbt: command not found"
- Restart PowerShell after installing sbt
- Verify installation: `sbt --version`
- Check PATH includes sbt: `$env:PATH`

### "java: command not found"
- Restart PowerShell after installing Java
- Verify installation: `java -version`
- Manually set JAVA_HOME if needed:
  ```powershell
  $env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-17.x.x"
  ```

### Docker issues
- Ensure Docker Desktop is running (check system tray)
- Try: `docker info` to verify Docker is accessible
- Restart Docker Desktop if needed

### Port conflicts
- Check if ports are in use:
  ```powershell
  netstat -an | findstr "9092"
  netstat -an | findstr "8081"
  ```
- Stop conflicting applications

---

## Alternative: Using Git Bash on Windows

If you prefer bash-style commands on Windows:

1. Install Git for Windows: https://git-scm.com/download/win
2. Open "Git Bash" instead of PowerShell
3. Use the bash scripts (`.sh` files) instead of PowerShell scripts (`.ps1`)
4. Follow the Linux/macOS instructions in QUICKSTART.md

---

## Quick Reference

| Task | Command |
|------|---------|
| Start services | `docker-compose up -d` |
| Stop services | `docker-compose down` |
| Check status | `docker-compose ps` |
| View logs | `docker-compose logs -f kafka` |
| Build app | `sbt clean compile assembly` |
| Run app | `sbt run` |
| Run tests | `sbt test` |

---

## Next Steps

After successful setup:
- Read **STEP_BY_STEP.md** for detailed walkthrough
- Check **LOCAL_SETUP.md** for advanced topics
- Experiment with the code!

---

**Need Help?**
- Check Docker Desktop is running
- Verify environment variables are set
- Ensure all prerequisites are installed
- Try restarting PowerShell

