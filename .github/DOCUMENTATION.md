# Documentation Guide

This project has streamlined documentation for local development and deployment.

## 📚 Documentation Files

### Main Documentation

1. **[README.md](../README.md)**
   - Project overview and architecture
   - Technology stack
   - Repository structure
   - Roadmap

2. **[QUICKSTART.md](../QUICKSTART.md)**
   - Complete local setup guide (10 minutes)
   - Step-by-step instructions for all pipelines
   - Troubleshooting
   - Configuration notes

3. **[PIPELINES.md](../PIPELINES.md)**
   - Detailed reference for all implemented pipelines
   - Data sources and signal logic
   - Build and run instructions
   - Output schemas

4. **[WINDOWS_SETUP.md](../WINDOWS_SETUP.md)**
   - Windows-specific installation instructions
   - Chocolatey and manual installation options
   - PowerShell-specific commands

5. **[SIGNALS.md](../SIGNALS.md)**
   - All planned signals and their logic
   - Future pipeline roadmap

## 🚀 Getting Started

**New to the project?**
1. Read [README.md](../README.md) for overview
2. Follow [QUICKSTART.md](../QUICKSTART.md) to run locally
3. See [PIPELINES.md](../PIPELINES.md) for detailed pipeline documentation
4. Windows users: See [WINDOWS_SETUP.md](../WINDOWS_SETUP.md) for installation help

**Quick start (automated):**
```powershell
# Windows
$env:FRED_API_KEY = "your_key"
.\scripts\start-all.ps1

# macOS/Linux
export FRED_API_KEY="your_key"
./scripts/start-all.sh
```

## 🔧 Key Configuration

### Kafka Bootstrap Addresses
- **Ingestor (runs on host):** `localhost:29092`
- **Flink Job (runs in Docker):** `kafka:9092`
- **Console commands (via docker exec):** `localhost:9092`

### Scala Versions
- **Ingestor:** Scala 2.13.12
- **Flink Job:** Scala 2.12.18 (required by Flink 1.20.0)

### Build Outputs
All pipelines follow the same pattern:
- **Ingestor JARs:** `pipelines/{pipeline}/ingestor/target/scala-2.13/*-assembly-0.1.0.jar`
- **Flink Job JARs:** `pipelines/{pipeline}/flink-job/target/scala-2.12/*-assembly-0.1.0.jar`

Implemented pipelines: `yield-curve`, `credit-spreads`, `repo-stress`

## 🐛 Common Issues

All common issues and their solutions are documented in the **Troubleshooting** section of [QUICKSTART.md](../QUICKSTART.md).

## 📝 Documentation Maintenance

When updating documentation:
- Keep README.md focused on project overview
- Put setup instructions in QUICKSTART.md
- Put pipeline details in PIPELINES.md
- Put Windows-specific details in WINDOWS_SETUP.md
- Avoid creating redundant documentation files

When adding a new pipeline:
1. Create the pipeline directory structure under `pipelines/`
2. Add pipeline details to PIPELINES.md
3. Update QUICKSTART.md with build/run examples
4. Update README.md repository structure section
5. Update build scripts (build-all.ps1 and build-all.sh)

