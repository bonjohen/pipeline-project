# Pipeline Reference

This document provides detailed information about all implemented signal pipelines.

---

## 1. Yield Curve Inversion

**Status:** ✅ Implemented

### Overview
Monitors the spread between 10-year and 2-year US Treasury yields. An inverted yield curve (negative spread) has historically been a reliable predictor of economic recessions.

### Data Sources
- **DGS10** – 10-Year Treasury Constant Maturity Rate
- **DGS2** – 2-Year Treasury Constant Maturity Rate
- **Source:** Federal Reserve Economic Data (FRED)

### Signal Logic
```
spread_bps = (DGS10 - DGS2) × 100
is_inverted = spread_bps < 0
regime = INVERTED if spread_bps < 0 else NORMAL
```

### Kafka Topics
- **Input:** `norm.macro.rate`
- **Output:** `signal.yield_curve`

### Output Schema
```json
{
  "schema_version": 1,
  "signal_id": "UST_10Y_2Y",
  "event_date": "2025-12-18",
  "ten_year_pct": 4.52,
  "two_year_pct": 4.07,
  "spread_bps": 45.0,
  "is_inverted": false,
  "regime": "NORMAL"
}
```

### Build & Run
```bash
# Build
cd pipelines/yield-curve/ingestor && sbt clean compile assembly
cd ../flink-job && sbt clean compile assembly

# Run ingestor
export FRED_API_KEY="your_key"
export KAFKA_BOOTSTRAP="localhost:29092"
cd pipelines/yield-curve/ingestor && sbt run

# Submit Flink job via http://localhost:8081
# Upload: pipelines/yield-curve/flink-job/target/scala-2.12/yield-curve-flink-assembly-0.1.0.jar
# Entry Class: YieldCurveJob
```

---

## 2. Credit Spreads (High Yield vs Treasuries)

**Status:** ✅ Implemented

### Overview
Monitors the spread between high-yield corporate bonds and US Treasuries. Widening spreads indicate increasing credit risk and potential economic stress.

### Data Sources
- **BAMLH0A0HYM2EY** – ICE BofA US High Yield Index Effective Yield
- **DGS10** – 10-Year Treasury Constant Maturity Rate
- **Source:** Federal Reserve Economic Data (FRED)

### Signal Logic
```
spread_bps = (BAMLH0A0HYM2EY - DGS10) × 100

regime:
  < 300 bps  → COMPRESSED (low risk premium)
  300-500    → NORMAL
  500-700    → ELEVATED
  > 700      → DISTRESSED

stress_level:
  < 400 bps  → LOW
  400-600    → MODERATE
  600-800    → HIGH
  > 800      → EXTREME
```

### Kafka Topics
- **Input:** `norm.macro.rate`
- **Output:** `signal.credit_spread`

### Output Schema
```json
{
  "schema_version": 1,
  "signal_id": "CREDIT_SPREAD_HY_10Y",
  "event_date": "2025-12-18",
  "hy_yield_pct": 7.85,
  "treasury_10y_pct": 4.52,
  "spread_bps": 333.0,
  "regime": "NORMAL",
  "stress_level": "LOW"
}
```

### Build & Run
```bash
# Build
cd pipelines/credit-spreads/ingestor && sbt clean compile assembly
cd ../flink-job && sbt clean compile assembly

# Run ingestor
export FRED_API_KEY="your_key"
export KAFKA_BOOTSTRAP="localhost:29092"
cd pipelines/credit-spreads/ingestor && sbt run

# Submit Flink job via http://localhost:8081
# Upload: pipelines/credit-spreads/flink-job/target/scala-2.12/credit-spreads-flink-assembly-0.1.0.jar
# Entry Class: CreditSpreadsJob
```

---

## 3. Repo Market Stress / SOFR Spikes

**Status:** ✅ Implemented

### Overview
Monitors the Secured Overnight Financing Rate (SOFR) relative to the Federal Funds target range. Spikes in SOFR indicate funding stress in the overnight lending market.

### Data Sources
- **SOFR** – Secured Overnight Financing Rate
- **DFEDTARU** – Federal Funds Target Range - Upper Limit
- **DFEDTARL** – Federal Funds Target Range - Lower Limit
- **Source:** Federal Reserve Economic Data (FRED)

### Signal Logic
```
fed_target = (DFEDTARU + DFEDTARL) / 2
spread_bps = (SOFR - fed_target) × 100
spike_detected = |spread_bps| > 25

stress_level:
  < 10 bps   → NORMAL
  10-25      → ELEVATED
  25-50      → STRESS
  > 50       → SEVERE_STRESS
```

### Kafka Topics
- **Input:** `norm.macro.rate`
- **Output:** `signal.repo_stress`

### Output Schema
```json
{
  "schema_version": 1,
  "signal_id": "REPO_STRESS_SOFR",
  "event_date": "2025-12-18",
  "sofr_pct": 4.57,
  "fed_funds_target_pct": 4.625,
  "spread_bps": -5.5,
  "spike_detected": false,
  "stress_level": "NORMAL",
  "rolling_avg_30d_bps": -5.5
}
```

### Build & Run
```bash
# Build
cd pipelines/repo-stress/ingestor && sbt clean compile assembly
cd ../flink-job && sbt clean compile assembly

# Run ingestor
export FRED_API_KEY="your_key"
export KAFKA_BOOTSTRAP="localhost:29092"
cd pipelines/repo-stress/ingestor && sbt run

# Submit Flink job via http://localhost:8081
# Upload: pipelines/repo-stress/flink-job/target/scala-2.12/repo-stress-flink-assembly-0.1.0.jar
# Entry Class: RepoStressJob
```

---

## 4. Market Breadth Thrust (Zweig Indicator)

**Status:** ✅ Implemented

### Overview
Detects the Zweig Breadth Thrust, a rare and powerful bullish signal that occurs when market breadth rapidly expands from oversold to strong levels. This indicates aggressive institutional buying and broad market participation, historically associated with the start of durable bull markets.

### Data Sources
- **NYSE Advance/Decline Data** – Daily counts of advancing, declining, and unchanged issues
- **Source:** Nasdaq Data Link (formerly Quandl)
- **Dataset:** NYSE breadth statistics (e.g., FINRA/FNSQ_NYSE or similar)

### Signal Logic
```
breadth_ratio = advancing / (advancing + declining)

Zweig Thrust Condition:
  1. Ratio rises from below 0.40 to above 0.615
  2. Occurs within a 10-day window

confidence:
  > 0.65  → HIGH
  > 0.615 → MODERATE
```

### Kafka Topics
- **Input (Raw):** `market.breadth.raw`
- **Input (Normalized):** `market.breadth.normalized`
- **Output:** `signals.breadth.zweig`

### Output Schema
```json
{
  "schema_version": 1,
  "signal_id": "ZWEIG_BREADTH_THRUST",
  "exchange": "NYSE",
  "trigger_date": "2025-03-14",
  "window_days": 10,
  "from_ratio": 0.37,
  "to_ratio": 0.651,
  "threshold_low": 0.40,
  "threshold_high": 0.615,
  "thrust_detected": true,
  "confidence": "HIGH"
}
```

### Build & Run
```bash
# Build
cd pipelines/market-breadth/ingestor && sbt clean compile assembly
cd ../flink-job && sbt clean compile assembly

# Run ingestor
export NASDAQ_DATA_LINK_API_KEY="your_key"
export KAFKA_BOOTSTRAP="localhost:29092"
cd pipelines/market-breadth/ingestor && sbt run

# Submit Flink job via http://localhost:8081
# Upload: pipelines/market-breadth/flink-job/target/scala-2.12/breadth-flink-assembly-0.1.0.jar
# Entry Class: BreadthSignalJob
```

### Data Flow
1. **Ingestor** pulls NYSE breadth data from Nasdaq Data Link API
2. Publishes raw data to `market.breadth.raw` (immutable audit log)
3. Calculates breadth ratio and publishes to `market.breadth.normalized`
4. **Flink Job** maintains a sliding 10-day window per exchange
5. Detects Zweig Thrust pattern and emits signals to `signals.breadth.zweig`

### Notes
- The ingestor fetches the last 30 days of data by default
- Update the `DatasetCode` in `BreadthIngestor.scala` with your actual Nasdaq Data Link dataset
- Breadth data is typically updated once per trading day after market close
- The Zweig Thrust is a rare signal (historically occurs only a few times per decade)

