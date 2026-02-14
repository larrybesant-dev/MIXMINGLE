# ==========================
# MIX & MINGLE – ENTERPRISE CI/CD
# ==========================

$ErrorActionPreference = "Continue"
Import-Module .\pipeline\versioning.ps1
Import-Module .\pipeline\backup.ps1
Import-Module .\pipeline\recovery.ps1
Import-Module .\pipeline\rollback.ps1
Import-Module .\pipeline\notifications.ps1
Import-Module .\pipeline\coverage.ps1

# ==========================
# STEP 1: Version Bump
# ==========================
Write-Log "⚡ Step 1: Bumping version..."
Bump-PatchVersion -Pubspec "pubspec.yaml"

# ==========================
# STEP 2: Backup
# ==========================
Write-Log "💾 Step 2: Creating backup..."
Create-Backup -SourcePaths @("lib","pubspec.yaml","build")

# ==========================
# STEP 3: Clean Workspace
# ==========================
Write-Log "🧹 Step 3: Cleaning workspace..."
try {
    flutter clean
} catch {
    Write-Log "⚠️ Clean failed, attempting recovery..."
    Recover-Step -Step "clean"
}

# ==========================
# STEP 3.1: Flutter Analyze
# ==========================
Write-Log "🔍 Step 3.1: Running flutter analyze..."
try {
    flutter analyze
} catch {
    Recover-Step -Step "analyze"
}

# ==========================
# STEP 3.2: Tests with Retry
# ==========================
Write-Log "🧪 Step 3.2: Running tests..."
$maxRetries = 3
$attempt = 1
do {
    flutter test --coverage
    $result = $LASTEXITCODE
    if ($result -eq 0) { break }
    Write-Log "⚠️ Test failed on attempt $attempt, retrying..."
    Start-Sleep -Seconds 5
    $attempt++
} while ($attempt -le $maxRetries)

if ($result -ne 0) {
    Send-MultiAlert -Message "❌ Tests failed after $maxRetries attempts." -Critical
    & .\pipeline\rollback.ps1 -Reason "Tests failed" -FailedStep "tests"
    exit 1
} else {
    Write-Log "✅ All tests passed!"
}

# ==========================
# STEP 3.3: Enforce Coverage Threshold
# ==========================
$coverageFile = "coverage/lcov.info"
if (Test-Path $coverageFile) {
    $coveragePercent = Get-CoveragePercent -LcovFile $coverageFile
    if ($coveragePercent -lt 80) {
        Write-Log "❌ Coverage below 80% ($coveragePercent%)"
        Send-MultiAlert -Message "❌ Coverage below threshold: $coveragePercent%"
        exit 1
    } else {
        Write-Log "✅ Coverage: $coveragePercent%"
    }
} else {
    Write-Log "⚠️ Coverage file not found!"
}

# ==========================
# STEP 3.4: Artifact Backup & Retention
# ==========================
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$artifactPath = "artifacts/$timestamp"
Write-Log "💾 Backing up build artifacts to $artifactPath"
Copy-Item build/web -Destination $artifactPath -Recurse

# Keep only last 5 backups
$keep = 5
$backups = Get-ChildItem artifacts | Sort-Object LastWriteTime -Descending
if ($backups.Count -gt $keep) {
    $backups[$keep..($backups.Count-1)] | Remove-Item -Recurse -Force
    Write-Log "🗑️ Removed old backups, keeping last $keep versions."
}

# ==========================
# STEP 4: Build Flutter Web
# ==========================
Write-Log "🏗️ Step 4: Building Flutter Web..."
$buildArgs = @("build", "web", "--release")
if ($env:USE_WASM -eq "true") {
    $buildArgs += "--wasm"
    Write-Log "Using WebAssembly build (--wasm)"
}
try {
    & flutter $buildArgs
} catch {
    Recover-Step -Step "build"
}

# ==========================
# STEP 5: Deploy to Firebase
# ==========================
Write-Log "📤 Step 5: Deploying to Firebase..."
try {
    firebase deploy --only hosting
} catch {
    Write-Log "❌ Deployment failed!"
    & .\pipeline\rollback.ps1 -Reason "Firebase deploy failed" -FailedStep "deploy"
    Send-MultiAlert -Message "❌ Deployment failed!" -Critical
    exit 1
}

# ==========================
# STEP 6: Health Check
# ==========================
Write-Log "🩺 Step 6: Running health check..."
$siteUrl = "https://mix-and-mingle-v2.web.app"
try {
    $response = Invoke-WebRequest -Uri $siteUrl -UseBasicParsing -TimeoutSec 15
    if ($response.StatusCode -eq 200) {
        Write-Log "✅ Site is live: $siteUrl"
        Send-MultiAlert -Message "🎉 Pipeline completed successfully! Site is live: $siteUrl"
    } else {
        throw "Health check failed"
    }
} catch {
    Write-Log "❌ Health check failed!"
    Send-MultiAlert -Message "❌ Pipeline completed but health check failed."
}

Write-Log "🎉 PIPELINE FINISHED"