# Pipeline Processing

**Fly.io–hosted (soon), Scala + Kafka + Flink streaming pipeline**

---

## Overview

This repository implements a **production-style streaming analytics platform** that detects economic signals, such as **U.S. Treasury yield curve inversions (10Y–2Y)**, using Federal Reserve Economic Data.

The project is designed as a **teaching-quality reference system** that demonstrates:

* Multi-service streaming architectures
* State-aware stream processing with Apache Flink
* Event-driven pipelines using Apache Kafka
* Cloud-native deployment using Fly.io (soon)

The first release implements **three pipelines**:
1. Yield Curve Inversion (10Y-2Y Treasury spread)
2. Credit Spreads (High Yield vs Treasuries)
3. Repo Market Stress (SOFR spikes)

The structure is intentionally designed to support **many pipelines**, **many Flink jobs**, and **future dashboards** without refactoring.

---

## Quick Links

* **[Quick Start Guide](QUICKSTART.md)** – Get running locally in 10 minutes (automated script available!)
* **[Pipeline Reference](PIPELINES.md)** – Detailed documentation for all implemented pipelines
* **[Windows Setup](WINDOWS_SETUP.md)** – Windows-specific installation help
* **[Signals Reference](SIGNALS.md)** – All planned signals and their logic

## 🚀 Quick Start

```powershell
# Windows - Automatically starts Docker Desktop if needed
$env:FRED_API_KEY = "your_api_key_here"
.\scripts\start-all.ps1
```

```bash
# macOS/Linux - Automatically starts Docker if needed
export FRED_API_KEY="your_api_key_here"
./scripts/start-all.sh
```

This automated script starts Docker (if needed), builds all pipelines, starts Docker services, runs ingestors, and submits Flink jobs.

See [QUICKSTART.md](QUICKSTART.md) for detailed instructions.

---

## Key Goals

* Use **real, free economic data** (FRED)
* Avoid local infrastructure complexity
* Support **Windows and macOS** development
* Enable **manual testing now**, automation later
* Scale to **10+ analytical pipelines**
* Prepare for **customer-facing dashboards** in later releases
* Be suitable for **videos, slides, and public education**

---

## Development & Validation Strategy

Development follows a progressive validation model:

1. **Local development** using Docker Compose
   * Kafka, Zookeeper, and Flink run in Docker
   * Scala applications built with sbt
   * Manual testing and validation

2. **Cross-platform validation**
   * Windows 11 (PowerShell)
   * macOS (bash/zsh)
   * Linux (bash)

3. **Cloud deployment** (future)
   * Deploy to Fly.io using the same artifacts
   * Remote monitoring and validation

---

## High-Level Architecture

```
FRED API
   ↓
Scala Ingestor (Fly.io job)
   ↓
Kafka (event log)
   ↓
Apache Flink (stateful stream processing)
   ↓
Kafka (signal events)
   ↓
Future dashboards & APIs
```

---

## Repository Structure

```
yield-curve-pipeline/
├── platform/                 # Shared platform services
│   ├── kafka/                # Kafka + ZooKeeper Fly app
│   └── flink/                # Flink runtime Fly app
│
├── pipelines/                # Independent analytical pipelines
│   ├── yield-curve/          # Pipeline 01: Yield Curve Inversion
│   │   ├── schemas/          # Event contracts
│   │   ├── ingestor/         # Scala ingestion job
│   │   └── flink-job/        # Flink streaming job
│   ├── credit-spreads/       # Pipeline 02: Credit Spreads (HY vs Treasuries)
│   │   ├── schemas/
│   │   ├── ingestor/
│   │   └── flink-job/
│   └── repo-stress/          # Pipeline 03: Repo Market Stress / SOFR Spikes
│       ├── schemas/
│       ├── ingestor/
│       └── flink-job/
│
├── tests/                    # Cross-pipeline and platform tests (future)
│
├── docs/                     # Slides, screenshots, scripts (future)
│   ├── slides/
│   ├── screenshots/
│   └── narration/
│
├── site/                     # Customer-facing dashboard (future)
│
└── scripts/                  # Deployment and validation scripts
```

This structure supports:

* Many pipelines
* Many Flink jobs per pipeline
* Shared platform services
* Future APIs and dashboards
* Educational assets (slides, videos)

---

## Technologies Used

* **Scala 2.13** (Ingestor) / **Scala 2.12** (Flink Job - required by Flink 1.20.0)
* **sbt**
* **Apache Kafka**
* **Apache Flink 1.20.0**
* **Fly.io**
* **FRED API**
* **GitHub** (user: `bonjohen`)

---

## Required Accounts

| Service | Purpose                  | Cost      |
| ------- | ------------------------ | --------- |
| Fly.io  | Hosting runtime services | Free tier |
| FRED    | Economic data API        | Free      |
| GitHub  | Source control           | Free      |

---

## Local Tooling Requirements

### Required (Windows & macOS)

* Git
* Fly.io CLI (`flyctl`)
* Java 17
* Scala 2.13
* sbt

### Windows Notes

* **Git Bash** is recommended for Bash scripts
* CMD syntax is shown where environment variables differ

---

## Installation Summary

### Fly.io CLI

**Bash (Git Bash (Win) / macOS):**

```bash
curl -L https://fly.io/install.sh | sh
```

Authenticate:

```bash
fly auth login
```

---

### Scala Toolchain (SDKMAN)

```bash
curl -s "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"

sdk install java 17.0.10-tem
sdk install scala 2.13.12
sdk install sbt
```

---

## FRED API Key

Create a free API key at:
[https://fred.stlouisfed.org](https://fred.stlouisfed.org)

**Windows (CMD):**

```cmd
setx FRED_API_KEY "YOUR_KEY_HERE"
```

**Bash:**

```bash
export FRED_API_KEY="YOUR_KEY_HERE"
```

---

## Getting Started

### Local Development (Recommended)

For local development and testing:

**📖 See [QUICKSTART.md](QUICKSTART.md)** for complete setup instructions.

**Requirements:**
- Docker Desktop
- Java 17+
- sbt
- FRED API Key (free from https://fred.stlouisfed.org)

**Windows Users:** See [WINDOWS_SETUP.md](WINDOWS_SETUP.md) for installation help.

---

## Platform Services (Fly.io)

### Kafka

* Runs as a **private Fly.io app**
* Not exposed publicly
* Used by all pipelines

### Flink

* JobManager + TaskManager
* Web UI exposed via Fly.io routing
* Hosts multiple streaming jobs

---

## Implemented Pipelines

### 1. Yield Curve Inversion

**Data Inputs:**
* **DGS10** – 10-year Treasury yield
* **DGS2** – 2-year Treasury yield

**Output Signal:**
* `spread_bps = (10Y − 2Y) × 100`
* `is_inverted = spread_bps < 0`
* `regime = INVERTED | NORMAL`

**Kafka Topics:**
* Input: `norm.macro.rate`
* Output: `signal.yield_curve`

---

### 2. Credit Spreads (High Yield vs Treasuries)

**Data Inputs:**
* **BAMLH0A0HYM2EY** – ICE BofA US High Yield Index Effective Yield
* **DGS10** – 10-year Treasury yield

**Output Signal:**
* `spread_bps = (HY Yield − Treasury Yield) × 100`
* `regime = COMPRESSED | NORMAL | ELEVATED | DISTRESSED`
* `stress_level = LOW | MODERATE | HIGH | EXTREME`

**Kafka Topics:**
* Input: `norm.macro.rate`
* Output: `signal.credit_spread`

**Interpretation:**
* Spreads < 300 bps: Compressed (low risk premium)
* Spreads 300-500 bps: Normal market conditions
* Spreads 500-700 bps: Elevated risk
* Spreads > 700 bps: Distressed conditions

---

### 3. Repo Market Stress / SOFR Spikes

**Data Inputs:**
* **SOFR** – Secured Overnight Financing Rate
* **DFEDTARU** – Federal Funds Target Range - Upper Limit
* **DFEDTARL** – Federal Funds Target Range - Lower Limit

**Output Signal:**
* `spread_bps = (SOFR − Fed Funds Target Midpoint) × 100`
* `spike_detected = |spread_bps| > 25`
* `stress_level = NORMAL | ELEVATED | STRESS | SEVERE_STRESS`

**Kafka Topics:**
* Input: `norm.macro.rate`
* Output: `signal.repo_stress`

**Interpretation:**
* Spread < 10 bps: Normal funding conditions
* Spread 10-25 bps: Elevated but manageable
* Spread 25-50 bps: Funding stress
* Spread > 50 bps: Severe stress (liquidity crisis)

---

## Testing Strategy (Release 1)

* **Unit tests** for every Scala file
* **Manual pipeline validation**
* **Log inspection**
* **Flink UI verification**

Automation is introduced in **Release 3**.

---

## Roadmap

### Release 1 ✅ (Complete)

* Platform foundation (Kafka, Flink, Docker Compose)
* Three pipelines implemented:
  1. Yield Curve Inversion
  2. Credit Spreads (High Yield vs Treasuries)
  3. Repo Market Stress / SOFR Spikes
* Unit tests for all pipelines
* Local development environment
* Manual testing and validation

### Release 2 (Next)

* Additional signals (VIX, TED Spread, etc.)
* Enhanced Flink jobs with windowing and state
* Integration tests

### Release 3

* Automated tests
* CI/CD
* Test coverage metrics

### Release 4

* Customer-facing dashboard
* Public read-only views

### Release 5

* Remaining pipelines
* Full analytics suite

---

## Educational Use

This project is designed to support:

* Blog posts (johnboen.com)
* YouTube walkthroughs
* Slide decks
* Architecture discussions
* Live and recorded demos

All artifacts (slides, screenshots, narration scripts) will be versioned in this repository.

---

## License

This project is provided for **educational and experimental purposes**.
Licensing details will be finalized prior to public release.


