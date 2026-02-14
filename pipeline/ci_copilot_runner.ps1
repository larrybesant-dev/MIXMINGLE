<#
.SYNOPSIS
CI/CD Runner with Copilot Auto-Fix for Flutter Web + Firebase
.DESCRIPTION
Runs full pipeline:
1. Version bump & backup
2. Clean & analyze
3. Tests with Copilot auto-fix retry
4. Coverage enforcement
5. Build (with optional WASM)
6. Deploy to Firebase
7. Health check & multi-channel alerts
8. Rollback on failure
#>

# ===== CONFIG =====
$maxRetries = 5
$coverageThreshold = 80
$useWasm = $env:USE_WASM -eq "true"
$artifactsDir = ".\artifacts\" + (Get-Date -Format "yyyyMMdd_HHmmss")
$rollbackDir = ".\pipeline\rollback_artifacts\"

# Ensure directories exist
New-Item -ItemType Directory -Force -Path $artifactsDir | Out-Null
New-Item -ItemType Directory -Force -Path $rollbackDir | Out-Null

# ===== FUNCTIONS =====
function Write-Log($message) {
    Write-Host "$(Get-Date -Format 'HH:mm:ss') | $message"
}

# Import modules
Import-Module .\pipeline\modules\versioning.ps1
Import-Module .\pipeline\modules\backup.ps1
Import-Module .\pipeline\modules\notifications.ps1
Import-Module .\pipeline\modules\rollback.ps1

function Run-FlutterTestWithCopilotRetry {
    $retry = 0
    $success = $false

    while (-not $success -and $retry -lt $maxRetries) {
        Write-Log "🔁 Running tests (Attempt $($retry+1)/$maxRetries)..."
        flutter test --coverage 2>&1 | Tee-Object flutter_test.log
        if ($LASTEXITCODE -eq 0) {
            Write-Log "✅ Tests passed!"
            $success = $true
        } else {
            Write-Log "⚠️ Tests failed. Generating Copilot prompt..."
            $errors = Get-Content flutter_test.log -Raw
            $copilotPrompt = "Fix all Flutter/Dart errors in the project so tests pass. Errors: $errors"
            
            # Save prompt to file for manual Copilot application
            $promptFile = "copilot_fix_prompt_$((Get-Date).ToString('yyyyMMdd_HHmmss')).txt"
            $copilotPrompt | Out-File -FilePath $promptFile -Encoding utf8
            Write-Log "💡 Copilot prompt saved to $promptFile. Open in VS Code and apply fixes manually."

            $retry++
            Start-Sleep -Seconds 5
        }
    }

    if (-not $success) {
        Write-Log "❌ Tests failed after $maxRetries attempts."
        Send-MultiAlert -FailedStep "Tests Auto-Fix"
        Rollback-Build "Tests Auto-Fix"
        exit 1
    }
}

function Check-Coverage {
    if (Test-Path ".\lcov.info") {
        $lcov = Get-Content .\lcov.info
        $total = ($lcov | Select-String "^DA:" | Measure-Object).Count
        $covered = ($lcov | Select-String "^DA:\d+,\d*[1-9]" | Measure-Object).Count
        $percent = [math]::Round(($covered / $total) * 100, 2)
        Write-Log "📊 Test coverage: $percent%"
        if ($percent -lt $coverageThreshold) {
            Write-Log "❌ Coverage below $coverageThreshold%. Failing pipeline."
            Send-MultiAlert -FailedStep "Coverage Enforcement"
            Rollback-Build "Coverage Enforcement"
            exit 1
        }
    } else {
        Write-Log "⚠️ lcov.info not found, skipping coverage check."
    }
}

function Build-FlutterWeb {
    $cmd = "flutter build web"
    if ($useWasm) { $cmd += " --wasm" }
    Write-Log "🏗️ Building Flutter Web ($($useWasm ? 'WASM enabled' : 'Standard'))..."
    Invoke-Expression $cmd
}

function Deploy-Firebase {
    Write-Log "📤 Deploying to Firebase Hosting..."
    firebase deploy --only hosting
    if ($LASTEXITCODE -ne 0) {
        Write-Log "❌ Firebase deploy failed."
        Send-MultiAlert -FailedStep "Firebase Deploy"
        Rollback-Build "Firebase Deploy"
        exit 1
    }
}

function Health-Check {
    Write-Log "🩺 Running health check..."
    $response = Invoke-WebRequest -Uri "https://mix-and-mingle-v2.web.app" -UseBasicParsing -ErrorAction SilentlyContinue
    if ($response.StatusCode -eq 200) {
        Write-Log "✅ Site is live and responsive."
        Send-MultiAlert -Message "Pipeline completed successfully!"
    } else {
        Write-Log "❌ Health check failed."
        Send-MultiAlert -FailedStep "Health Check"
        Rollback-Build "Health Check"
        exit 1
    }
}

function Send-MultiAlert {
    param(
        [string]$FailedStep = "",
        [string]$Message = ""
    )
    # Use the imported function
    Send-Alert $Message
}

function Rollback-Build {
    param([string]$Reason)
    Write-Log "↩️ Rolling back build due to $Reason..."
    Copy-Item -Path ".\build\web\*" -Destination "$rollbackDir\$((Get-Date).ToString('yyyyMMdd_HHmmss'))" -Recurse -Force
    # Call rollback function
    Rollback-Deploy
}

# ===== PIPELINE STEPS =====
Write-Log "🚀 Starting CI/CD pipeline..."

# 1. Version bump & backup
Bump-PatchVersion
Create-Backup -SourcePaths @("lib","pubspec.yaml","build")

# 2. Clean & analyze
flutter clean
flutter analyze

# 3. Run tests with Copilot auto-fix
Run-FlutterTestWithCopilotRetry

# 4. Check coverage
Check-Coverage

# 5. Build
Build-FlutterWeb

# 6. Deploy
Deploy-Firebase

# 7. Health check
Health-Check

Write-Log "🎉 Pipeline finished successfully!"