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
   - Step-by-step instructions
   - Troubleshooting
   - Configuration notes

3. **[WINDOWS_SETUP.md](../WINDOWS_SETUP.md)**
   - Windows-specific installation instructions
   - Chocolatey and manual installation options
   - PowerShell-specific commands

## 🚀 Getting Started

**New to the project?**
1. Read [README.md](../README.md) for overview
2. Follow [QUICKSTART.md](../QUICKSTART.md) to run locally
3. Windows users: See [WINDOWS_SETUP.md](../WINDOWS_SETUP.md) for installation help

## 🔧 Key Configuration

### Kafka Bootstrap Addresses
- **Ingestor (runs on host):** `localhost:29092`
- **Flink Job (runs in Docker):** `kafka:9092`
- **Console commands (via docker exec):** `localhost:9092`

### Scala Versions
- **Ingestor:** Scala 2.13.12
- **Flink Job:** Scala 2.12.18 (required by Flink 1.20.0)

### Build Outputs
- **Ingestor JAR:** `pipelines/yield-curve/ingestor/target/scala-2.13/fred-ingestor-assembly-0.1.0.jar`
- **Flink Job JAR:** `pipelines/yield-curve/flink-job/target/scala-2.12/yield-curve-flink-assembly-0.1.0.jar`

## 🐛 Common Issues

All common issues and their solutions are documented in the **Troubleshooting** section of [QUICKSTART.md](../QUICKSTART.md).

## 📝 Documentation Maintenance

When updating documentation:
- Keep README.md focused on project overview
- Put setup instructions in QUICKSTART.md
- Put Windows-specific details in WINDOWS_SETUP.md
- Avoid creating redundant documentation files

