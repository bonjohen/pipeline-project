# Fixes Applied

This document tracks the fixes applied to resolve build issues.

---

## Issue 1: "Not a valid command: assembly"

**Problem:** The `sbt assembly` command failed because the sbt-assembly plugin was not configured.

**Fix Applied:**
- Created `pipelines/yield-curve/ingestor/project/plugins.sbt`
- Already existed: `pipelines/yield-curve/flink-job/project/plugins.sbt`
- Both files now contain: `addSbtPlugin("com.eed3si9n" % "sbt-assembly" % "2.2.0")`

**Resolution:** Run `sbt clean compile assembly` again. sbt will load the plugin and the command will work.

---

## Issue 2: "Error downloading org.apache.flink:flink-streaming-scala_2.13:1.20.0"

**Problem:** Apache Flink 1.20.0 does not provide Scala 2.13 artifacts. Only Scala 2.12 is supported.

**Fix Applied:**
- Updated `pipelines/yield-curve/flink-job/build.sbt`:
  - Changed `scalaVersion` from `2.13.12` to `2.12.18`
  - Added `% "provided"` to Flink dependencies (they're provided by the Flink runtime)
  - Added `flink-clients` dependency
  - Added assembly merge strategy to handle META-INF conflicts

**Note:** The ingestor still uses Scala 2.13 (it doesn't depend on Flink).

**Resolution:** Run `sbt clean compile assembly` again. Dependencies will now resolve correctly.

---

## Current Configuration

### Ingestor (pipelines/yield-curve/ingestor)
- **Scala Version:** 2.13.12
- **Dependencies:**
  - Kafka clients 3.8.0
  - requests 0.8.0
  - ujson 3.1.0
- **Output:** `target/scala-2.13/fred-ingestor-assembly-0.1.0.jar`

### Flink Job (pipelines/yield-curve/flink-job)
- **Scala Version:** 2.12.18 (required by Flink 1.20.0)
- **Dependencies:**
  - Flink streaming-scala 1.20.0 (provided)
  - Flink clients 1.20.0 (provided)
  - Flink connector-kafka 3.2.0-1.20
  - ujson 3.1.0
- **Output:** `target/scala-2.12/yield-curve-flink-assembly-0.1.0.jar`

---

## Next Steps

1. **Build the Ingestor:**
   ```bash
   cd pipelines/yield-curve/ingestor
   sbt clean compile assembly
   ```

2. **Build the Flink Job:**
   ```bash
   cd pipelines/yield-curve/flink-job
   sbt clean compile assembly
   ```

3. **Verify JARs were created:**
   ```bash
   # Ingestor
   ls pipelines/yield-curve/ingestor/target/scala-2.13/fred-ingestor-assembly-0.1.0.jar
   
   # Flink Job
   ls pipelines/yield-curve/flink-job/target/scala-2.12/yield-curve-flink-assembly-0.1.0.jar
   ```

4. **Continue with the pipeline setup** as described in WINDOWS_SETUP.md or LOCAL_SETUP.md

---

## Documentation Updated

The following files have been updated with troubleshooting information:
- ✅ WINDOWS_SETUP.md
- ✅ LOCAL_SETUP.md
- ✅ STEP_BY_STEP.md
- ✅ README.md

---

## Why Different Scala Versions?

**Ingestor (2.13):**
- Simple Kafka producer
- No Flink dependencies
- Can use latest Scala version for better language features

**Flink Job (2.12):**
- Runs on Flink runtime
- Must match Flink's supported Scala version
- Flink 1.20.0 only supports Scala 2.12
- This is a Flink limitation, not a project choice

This is a common pattern in Flink projects and doesn't cause any issues since the two applications don't share compiled code - they only communicate via Kafka messages (JSON).

---

**All fixes have been applied. You can now proceed with building the applications.**

