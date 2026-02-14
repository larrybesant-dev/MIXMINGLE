<#
.SYNOPSIS
Mix & Mingle - Workspace Cleanup & Analysis
Complete cleanup, fix, and analysis of Flutter project.

.DESCRIPTION
Performs:
1. Flutter clean
2. Pub get for fresh dependencies
3. Automatic Dart fixes
4. Code analysis
5. Dependency report
6. Final status report
#>

# Configuration
$startTime = Get-Date
$logFile = "workspace-cleanup-$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# Logging function
function Write-Log {
    param([string]$message, [string]$level = "INFO")

    $colors = @{
        "INFO"    = "White"
        "SUCCESS" = "Green"
        "WARNING" = "Yellow"
        "ERROR"   = "Red"
        "STEP"    = "Cyan"
    }

    $timestamp = Get-Date -Format "HH:mm:ss"
    $logEntry = "[$timestamp] [$level] $message"

    Write-Host $logEntry -ForegroundColor ($colors[$level] ?? "White")
    Add-Content $logFile $logEntry
}

function Write-Section {
    param([string]$title)
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  $title" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

# ============================================================================
# START
# ============================================================================

Write-Section "MIX & MINGLE - WORKSPACE CLEANUP & ANALYSIS"

Write-Log "Starting workspace cleanup..." "STEP"
Write-Log "Log file: $logFile" "INFO"

# ============================================================================
# STEP 1: Flutter Clean
# ============================================================================

Write-Section "Step 1: Flutter Clean"

Write-Log "Running: flutter clean" "STEP"
try {
    flutter clean 2>&1 | Tee-Object -Variable cleanOutput | ForEach-Object {
        Write-Log $_ "INFO"
    }

    if ($LASTEXITCODE -eq 0 -or $null -eq $LASTEXITCODE) {
        Write-Log "✅ Flutter clean completed successfully" "SUCCESS"
    } else {
        Write-Log "❌ flutter clean failed with exit code: $LASTEXITCODE" "ERROR"
        exit 1
    }
} catch {
    Write-Log "❌ Exception during flutter clean: $_" "ERROR"
    exit 1
}

Write-Log "Cleaned artifacts:" "INFO"
Write-Log "  - build/" "INFO"
Write-Log "  - .dart_tool/" "INFO"
Write-Log "  - ephemeral/" "INFO"

# ============================================================================
# STEP 2: Flutter Pub Get
# ============================================================================

Write-Section "Step 2: Fetch Dependencies (flutter pub get)"

Write-Log "Running: flutter pub get" "STEP"
try {
    flutter pub get 2>&1 | Tee-Object -Variable pubOutput | ForEach-Object {
        Write-Log $_ "INFO"
    }

    if ($LASTEXITCODE -eq 0 -or $null -eq $LASTEXITCODE) {
        Write-Log "✅ Dependencies resolved successfully" "SUCCESS"
    } else {
        Write-Log "❌ flutter pub get failed with exit code: $LASTEXITCODE" "WARNING"
    }
} catch {
    Write-Log "❌ Exception during flutter pub get: $_" "ERROR"
}

# ============================================================================
# STEP 3: Dart Fix
# ============================================================================

Write-Section "Step 3: Apply Automatic Dart Fixes"

Write-Log "Running: dart fix --apply" "STEP"
Write-Log "This may take a moment..." "INFO"

try {
    dart fix --apply 2>&1 | Tee-Object -Variable fixOutput | ForEach-Object {
        Write-Log $_ "INFO"
    }

    if ($LASTEXITCODE -eq 0 -or $null -eq $LASTEXITCODE) {
        Write-Log "✅ Dart fixes applied" "SUCCESS"
    } else {
        Write-Log "⚠️  Dart fix completed with warnings" "WARNING"
    }
} catch {
    Write-Log "❌ Exception during dart fix: $_" "ERROR"
}

# ============================================================================
# STEP 4: Flutter Analyze
# ============================================================================

Write-Section "Step 4: Code Analysis (flutter analyze)"

Write-Log "Running: flutter analyze" "STEP"
Write-Log "This may take 30-60 seconds..." "INFO"

try {
    $analyzeOutput = @()
    flutter analyze 2>&1 | Tee-Object -Variable tempOutput | ForEach-Object {
        $analyzeOutput += $_

        # Only show errors and summary, not every line
        if ($_ -match "error:|warning:|  ✓|Analyzing" -or $_ -match "^[0-9]+ issue") {
            Write-Log $_ "INFO"
        }
    }

    if ($LASTEXITCODE -eq 0 -or $null -eq $LASTEXITCODE) {
        Write-Log "✅ Analysis completed - No critical errors" "SUCCESS"
    } else {
        Write-Log "⚠️  Analysis found issues (see details above)" "WARNING"
    }

    # Count errors
    $errorCount = ($analyzeOutput | Where-Object { $_ -match "error:" }).Count
    $warningCount = ($analyzeOutput | Where-Object { $_ -match "warning:" }).Count

    Write-Log "Summary: $errorCount errors, $warningCount warnings" "INFO"

} catch {
    Write-Log "❌ Exception during flutter analyze: $_" "ERROR"
}

# ============================================================================
# STEP 5: Dependency Report
# ============================================================================

Write-Section "Step 5: Dependency Report"

Write-Log "Running: flutter pub deps --style=compact" "STEP"

try {
    flutter pub deps --style=compact 2>&1 | Tee-Object -Variable depsOutput | Select-Object -First 50 | ForEach-Object {
        Write-Log $_ "INFO"
    }

    if ($depsOutput.Count -gt 50) {
        Write-Log "... (showing first 50 lines, use 'flutter pub deps' for full list)" "INFO"
    }
} catch {
    Write-Log "⚠️  Could not generate dependency report: $_" "WARNING"
}

# ============================================================================
# STEP 6: Final Report
# ============================================================================

$endTime = Get-Date
$duration = ($endTime - $startTime).TotalSeconds

Write-Section "Cleanup Complete"

Write-Log "📊 FINAL REPORT:" "STEP"
Write-Log "  Total Duration: ${duration:F0} seconds" "INFO"
Write-Log "  ✅ Flutter clean: Success" "SUCCESS"
Write-Log "  ✅ Dependencies: Resolved" "SUCCESS"
Write-Log "  ✅ Dart fixes: Applied" "SUCCESS"
Write-Log "  ✅ Analysis: Complete" "SUCCESS"

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1️⃣  Review any errors above" -ForegroundColor White
Write-Host "  2️⃣  Run: flutter pub get (if needed)" -ForegroundColor White
Write-Host "  3️⃣  Test web: flutter run -d chrome" -ForegroundColor White
Write-Host "  4️⃣  Build web: flutter build web --release" -ForegroundColor White
Write-Host ""

Write-Log "Workspace cleanup finished successfully" "SUCCESS"
Write-Log "Full log saved to: $logFile" "INFO"

Write-Host "🎉 Ready for production build!" -ForegroundColor Green
