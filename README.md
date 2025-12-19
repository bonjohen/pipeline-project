# Yield Curve Inversion Signal

**Fly.io–hosted, Scala + Kafka + Flink streaming pipeline**

---

## Overview

This repository implements a **production-style streaming analytics platform** that detects **U.S. Treasury yield curve inversions (10Y–2Y)** using real economic data from the Federal Reserve.

The project is designed as a **teaching-quality reference system** that demonstrates:

* Multi-service streaming architectures
* State-aware stream processing with Apache Flink
* Event-driven pipelines using Apache Kafka
* Cloud-native deployment using Fly.io
* Clean separation between **platform**, **pipelines**, and **future customer-facing systems**

The first release implements **one pipeline** (Yield Curve Inversion).
The structure is intentionally designed to support **many pipelines**, **many Flink jobs**, and **future dashboards** without refactoring.

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

1. **Local development** on
   **Windows 11 Home Edition Desktop (RTX 4070)**
   using Git, Scala, sbt, and Fly.io CLI

2. **Manual local validation**

   * Tests run via sbt
   * Scripts used where possible to enable future automation

3. **Cross-machine projectvalidation**

   * Windows 11 Home Edition Laptop
   * macOS (Apple Silicon)

4. **Cloud validation on Fly.io**

   * Same artifacts
   * Same tests
   * Same expectations

5. **Remote validation**

   * Inspect logs and UIs directly on Fly.io

No local Docker runtime is required.
All containers are built and executed remotely by Fly.io.

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
│   └── yield_curve/          # Pipeline 01: Yield Curve Inversion
│       ├── schemas/          # Event contracts
│       ├── ingestor/         # Scala ingestion job
│       └── flink-job/        # Flink streaming job
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

**Windows (CMD):**

```cmd
iwr https://fly.io/install.ps1 -useb | iex
```

**Bash (Git Bash / macOS):**

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

For local development without Fly.io:

**Quick Start:**
```bash
# See QUICKSTART.md for 5-minute setup
docker-compose up -d
./scripts/bootstrap/build-all.sh
./scripts/test/run-pipeline.sh
```

**Detailed Guide:** See [LOCAL_SETUP.md](LOCAL_SETUP.md)

**Requirements:**
- Docker Desktop
- Java 17+
- sbt
- FRED API Key

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

## Yield Curve Pipeline

### Data Inputs

* **DGS10** – 10-year Treasury yield
* **DGS2** – 2-year Treasury yield

### Output Signal

* `spread_bps = (10Y − 2Y) × 100`
* `is_inverted = spread_bps < 0`
* `regime = INVERTED | NORMAL`

---

## Testing Strategy (Release 1)

* **Unit tests** for every Scala file
* **Manual pipeline validation**
* **Log inspection**
* **Flink UI verification**

Automation is introduced in **Release 3**.

---

## Roadmap

### Release 1 (Current)

* One pipeline (Yield Curve)
* Manual testing
* Platform foundation

### Release 2

* 2–3 new signals
* Expanded schemas
* Manual validation

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

---

If you want next steps, I can:

* Add `docs/` with slide + narration templates
* Add pipeline scaffolding for the next 9 signals
* Add Fly.io deployment scripts
* Add CI/CD stubs
* Add dashboard architecture skeleton
