# Start all pipeline components and submit Flink jobs
param(
    [switch]$SkipBuild,
    [switch]$SkipDocker,
    [switch]$SkipIngestors
)

$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Starting All Pipeline Components" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Check environment
if (-not $env:FRED_API_KEY) {
    Write-Host "ERROR: FRED_API_KEY not set. Please run:" -ForegroundColor Red
    Write-Host "   `$env:FRED_API_KEY = 'your_key_here'" -ForegroundColor Yellow
    exit 1
}

# Set Kafka bootstrap for local
$env:KAFKA_BOOTSTRAP = "localhost:29092"

# Step 1: Build (optional)
if (-not $SkipBuild) {
    Write-Host "Step 1: Building all pipelines..." -ForegroundColor Yellow
    .\scripts\bootstrap\build-all.ps1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Build failed" -ForegroundColor Red
        exit 1
    }
    Write-Host ""
} else {
    Write-Host "Step 1: Skipping build (--SkipBuild)" -ForegroundColor Gray
    Write-Host ""
}

# Step 2: Start Docker
if (-not $SkipDocker) {
    Write-Host "Step 2: Starting Docker..." -ForegroundColor Yellow

    # Check if Docker is running
    $dockerRunning = $false
    try {
        docker ps 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            $dockerRunning = $true
            Write-Host "Docker is already running" -ForegroundColor Green
        }
    } catch {
        # Docker not running
    }

    # Start Docker Desktop if not running
    if (-not $dockerRunning) {
        Write-Host "Docker is not running. Starting Docker Desktop..." -ForegroundColor Yellow

        # Try to find Docker Desktop executable
        $dockerPaths = @(
            "C:\Program Files\Docker\Docker\Docker Desktop.exe",
            "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe",
            "${env:ProgramFiles(x86)}\Docker\Docker\Docker Desktop.exe"
        )

        $dockerExe = $null
        foreach ($path in $dockerPaths) {
            if (Test-Path $path) {
                $dockerExe = $path
                break
            }
        }

        if (-not $dockerExe) {
            Write-Host "ERROR: Docker Desktop not found. Please install Docker Desktop or start it manually." -ForegroundColor Red
            exit 1
        }

        Start-Process $dockerExe
        Write-Host "Waiting for Docker to start (this may take 1-2 minutes)..." -ForegroundColor Yellow
        Write-Host "  Check Docker Desktop UI for progress..." -ForegroundColor Gray

        # Wait for Docker to be ready (max 3 minutes)
        $maxAttempts = 90
        $attempt = 0
        while ($attempt -lt $maxAttempts) {
            $attempt++
            try {
                docker ps 2>&1 | Out-Null
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "Docker is ready!" -ForegroundColor Green
                    $dockerRunning = $true
                    break
                }
            } catch {
                # Still waiting
            }
            if ($attempt -eq $maxAttempts) {
                Write-Host "ERROR: Docker failed to start after $($maxAttempts * 2) seconds" -ForegroundColor Red
                Write-Host "Please check Docker Desktop for errors and try again." -ForegroundColor Yellow
                exit 1
            }
            # Show progress every 10 seconds
            if ($attempt % 5 -eq 0) {
                $elapsed = $attempt * 2
                Write-Host "  Still waiting... ($elapsed seconds elapsed)" -ForegroundColor Gray
            }
            Start-Sleep -Seconds 2
        }
    }
    Write-Host ""

    # Start Docker Compose
    Write-Host "Starting Docker Compose services..." -ForegroundColor Yellow
    docker-compose up -d
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Docker Compose failed to start" -ForegroundColor Red
        exit 1
    }
    Write-Host "Docker Compose started" -ForegroundColor Green
    Write-Host ""

    # Wait for Kafka
    Write-Host "Waiting for Kafka to be ready..." -ForegroundColor Yellow
    $maxAttempts = 30
    $attempt = 0
    while ($attempt -lt $maxAttempts) {
        $attempt++
        try {
            docker exec yield-kafka kafka-broker-api-versions --bootstrap-server localhost:9092 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Kafka is ready" -ForegroundColor Green
                break
            }
        } catch {
            # Ignore errors
        }
        if ($attempt -eq $maxAttempts) {
            Write-Host "ERROR: Kafka failed to start after $maxAttempts attempts" -ForegroundColor Red
            exit 1
        }
        Write-Host "  Attempt $attempt/$maxAttempts..." -ForegroundColor Gray
        Start-Sleep -Seconds 2
    }
    Write-Host ""

    # Wait for Flink
    Write-Host "Waiting for Flink to be ready..." -ForegroundColor Yellow
    $attempt = 0
    while ($attempt -lt $maxAttempts) {
        $attempt++
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:8081/overview" -UseBasicParsing -TimeoutSec 2 -ErrorAction SilentlyContinue
            if ($response.StatusCode -eq 200) {
                Write-Host "Flink is ready" -ForegroundColor Green
                break
            }
        } catch {
            # Ignore errors
        }
        if ($attempt -eq $maxAttempts) {
            Write-Host "ERROR: Flink failed to start after $maxAttempts attempts" -ForegroundColor Red
            exit 1
        }
        Write-Host "  Attempt $attempt/$maxAttempts..." -ForegroundColor Gray
        Start-Sleep -Seconds 2
    }
    Write-Host ""
} else {
    Write-Host "Step 2: Skipping Docker startup (--SkipDocker)" -ForegroundColor Gray
    Write-Host ""
}

# Step 3: Run Ingestors
if (-not $SkipIngestors) {
    Write-Host "Step 3: Running all ingestors..." -ForegroundColor Yellow
    Write-Host ""

    Write-Host "  3a. Running Yield Curve Ingestor..." -ForegroundColor Cyan
    Set-Location pipelines\yield-curve\ingestor
    sbt -error "run"
    Set-Location ..\..\..
    Write-Host "  Yield Curve data ingested" -ForegroundColor Green
    Write-Host ""

    Write-Host "  3b. Running Credit Spreads Ingestor..." -ForegroundColor Cyan
    Set-Location pipelines\credit-spreads\ingestor
    sbt -error "run"
    Set-Location ..\..\..
    Write-Host "  Credit Spreads data ingested" -ForegroundColor Green
    Write-Host ""

    Write-Host "  3c. Running Repo Stress Ingestor..." -ForegroundColor Cyan
    Set-Location pipelines\repo-stress\ingestor
    sbt -error "run"
    Set-Location ..\..\..
    Write-Host "  Repo Stress data ingested" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host "Step 3: Skipping ingestors (--SkipIngestors)" -ForegroundColor Gray
    Write-Host ""
}

# Step 4: Submit Flink Jobs via REST API
Write-Host "Step 4: Submitting Flink jobs via REST API..." -ForegroundColor Yellow
Write-Host ""

$flinkUrl = "http://localhost:8081"

# Function to upload JAR and submit job using curl
function Submit-FlinkJob {
    param(
        [string]$JarPath,
        [string]$EntryClass,
        [string]$JobName
    )

    Write-Host "  Submitting $JobName..." -ForegroundColor Cyan

    # Check if JAR exists
    if (-not (Test-Path $JarPath)) {
        Write-Host "  ERROR: JAR not found: $JarPath" -ForegroundColor Red
        return $false
    }

    # Upload JAR using curl
    try {
        $uploadUrl = "$flinkUrl/jars/upload"

        # Use curl.exe for reliable multipart upload
        $uploadOutput = curl.exe -s -X POST -F "jarfile=@$JarPath" $uploadUrl | ConvertFrom-Json

        if (-not $uploadOutput.filename) {
            Write-Host "  ERROR: Failed to upload JAR" -ForegroundColor Red
            return $false
        }

        $jarId = $uploadOutput.filename -replace '^.*/([^/]+)$', '$1'
        Write-Host "  JAR uploaded: $jarId" -ForegroundColor Gray

        # Submit job
        $runUrl = "$flinkUrl/jars/$jarId/run"

        # Create temp JSON file
        $tempJson = [System.IO.Path]::GetTempFileName()
        @{entryClass=$EntryClass} | ConvertTo-Json -Compress | Out-File -FilePath $tempJson -Encoding utf8 -NoNewline

        $runResponse = curl.exe -s -X POST -H "Content-Type: application/json" --data-binary "@$tempJson" $runUrl
        Remove-Item $tempJson -ErrorAction SilentlyContinue

        $runOutput = $runResponse | ConvertFrom-Json

        if ($runOutput.jobid) {
            Write-Host "  $JobName submitted (Job ID: $($runOutput.jobid))" -ForegroundColor Green
            return $true
        } else {
            Write-Host "  ERROR: Failed to submit job" -ForegroundColor Red
            Write-Host "  Response: $runResponse" -ForegroundColor Gray
            return $false
        }

    } catch {
        Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Get script directory and project root
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir

# Submit all jobs
Submit-FlinkJob -JarPath "$projectRoot\pipelines\yield-curve\flink-job\target\scala-2.12\yield-curve-flink-assembly-0.1.0.jar" -EntryClass "YieldCurveJob" -JobName "Yield Curve Job" | Out-Null
Write-Host ""

Submit-FlinkJob -JarPath "$projectRoot\pipelines\credit-spreads\flink-job\target\scala-2.12\credit-spreads-flink-assembly-0.1.0.jar" -EntryClass "CreditSpreadsJob" -JobName "Credit Spreads Job" | Out-Null
Write-Host ""

Submit-FlinkJob -JarPath "$projectRoot\pipelines\repo-stress\flink-job\target\scala-2.12\repo-stress-flink-assembly-0.1.0.jar" -EntryClass "RepoStressJob" -JobName "Repo Stress Job" | Out-Null
Write-Host ""

# Summary
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Pipeline Startup Complete!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Services:" -ForegroundColor Yellow
Write-Host "  - Flink Web UI:  http://localhost:8081" -ForegroundColor Cyan
Write-Host "  - Kafka:         localhost:29092" -ForegroundColor Cyan
Write-Host ""

Write-Host "View signals:" -ForegroundColor Yellow
Write-Host "  Yield Curve:    docker exec yield-kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic signal.yield_curve --from-beginning" -ForegroundColor Gray
Write-Host "  Credit Spreads: docker exec yield-kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic signal.credit_spread --from-beginning" -ForegroundColor Gray
Write-Host "  Repo Stress:    docker exec yield-kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic signal.repo_stress --from-beginning" -ForegroundColor Gray
Write-Host ""

Write-Host "To stop all services:" -ForegroundColor Yellow
Write-Host "  .\scripts\stop-all.ps1" -ForegroundColor Gray
Write-Host ""

