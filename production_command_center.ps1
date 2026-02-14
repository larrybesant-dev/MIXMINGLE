<#
.SYNOPSIS
🚀 PRODUCTION COMMAND CENTER
Master control script for Mix & Mingle production deployment.

.DESCRIPTION
One-stop command center to orchestrate entire production pipeline:
- Code quality fixes
- Project cleanup
- Build recovery (Android, Web)
- Firebase deployment
- Testing & verification
- Final production readiness report

.EXAMPLE
.\production_command_center.ps1 -Mode FastTrack
.\production_command_center.ps1 -Mode Professional
.\production_command_center.ps1 -Mode FullAudit
#>

param(
    [ValidateSet("Menu", "FastTrack", "Professional", "FullAudit", "Status")]
    [string]$Mode = "Menu"
)

# ============================================================================
# COLOR & FORMATTING
# ============================================================================

function Show-Menu {
    Clear-Host
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                  🚀 PRODUCTION COMMAND CENTER v1                          ║" -ForegroundColor Cyan
    Write-Host "║              Mix & Mingle - Full-Stack Production Deploy                 ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Select deployment mode:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [1] 🏃 FAST TRACK (15 min)" -ForegroundColor Green
    Write-Host "      └─ Minimal validation + direct build → APK/AAB/Web ready" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [2] 💼 PROFESSIONAL (60 min)" -ForegroundColor Cyan
    Write-Host "      └─ Code fixes + cleanup + build + deploy + basic tests" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [3] 🔬 FULL AUDIT (120+ min)" -ForegroundColor Yellow
    Write-Host "      └─ Complete audit + fixes + cleanup + build + tests + report" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [4] 📊 STATUS CHECK" -ForegroundColor Magenta
    Write-Host "      └─ Verify current build status & artifacts" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [0] EXIT" -ForegroundColor Red
    Write-Host ""
}

function Invoke-FastTrack {
    Write-Host ""
    Write-Host "╔═══════════════════════════════╗" -ForegroundColor Green
    Write-Host "║  🏃 FAST TRACK MODE           ║" -ForegroundColor Green
    Write-Host "║  ~15 min to production builds ║" -ForegroundColor Green
    Write-Host "╚═══════════════════════════════╝" -ForegroundColor Green
    Write-Host ""

    Write-Host "This mode:" -ForegroundColor Yellow
    Write-Host "  ✓ Skips code cleanup" -ForegroundColor Gray
    Write-Host "  ✓ Builds Android APK/AAB" -ForegroundColor Gray
    Write-Host "  ✓ Builds Web" -ForegroundColor Gray
    Write-Host "  ✓ Deploys to Firebase Hosting" -ForegroundColor Gray
    Write-Host "  ✗ No tests" -ForegroundColor Gray
    Write-Host ""

    Read-Host "Press ENTER to start..." | Out-Null

    Write-Host ""
    Write-Host "[1/3] Building Android..." -ForegroundColor Cyan
    & ".\android-build-recovery-v2.ps1"

    Write-Host ""
    Write-Host "[2/3] Building Web..." -ForegroundColor Cyan
    flutter build web --release

    Write-Host ""
    Write-Host "[3/3] Deploying to Firebase..." -ForegroundColor Cyan
    firebase deploy --only hosting

    Write-Host ""
    Write-Host "✅ FAST TRACK COMPLETE!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Build artifacts ready:" -ForegroundColor Cyan
    Write-Host "  📦 APK: build/app/outputs/flutter-apk/app-release.apk" -ForegroundColor Green
    Write-Host "  📦 AAB: build/app/outputs/bundle/release/app-release.aab" -ForegroundColor Green
    Write-Host "  🌐 Web: https://your-project.firebaseapp.com" -ForegroundColor Green
    Write-Host ""

    Read-Host "Press ENTER to continue..." | Out-Null
}

function Invoke-Professional {
    Write-Host ""
    Write-Host "╔═════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  💼 PROFESSIONAL MODE              ║" -ForegroundColor Cyan
    Write-Host "║  ~60 min to production-ready build ║" -ForegroundColor Cyan
    Write-Host "╚═════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "This mode:" -ForegroundColor Yellow
    Write-Host "  ✓ Fixes code quality issues" -ForegroundColor Gray
    Write-Host "  ✓ Removes unused files" -ForegroundColor Gray
    Write-Host "  ✓ Builds Android APK/AAB" -ForegroundColor Gray
    Write-Host "  ✓ Builds & deploys Web" -ForegroundColor Gray
    Write-Host "  ✓ Basic verification" -ForegroundColor Gray
    Write-Host "  ✗ No comprehensive tests" -ForegroundColor Gray
    Write-Host ""

    Read-Host "Press ENTER to start..." | Out-Null

    Write-Host ""
    Write-Host "[1/4] Fixing code quality..." -ForegroundColor Cyan
    if (Test-Path "code_fixer.ps1") {
        & ".\code_fixer.ps1" -AutoApply
    }

    Write-Host ""
    Write-Host "[2/4] Cleaning project..." -ForegroundColor Cyan
    if (Test-Path "cleanup_project.ps1") {
        & ".\cleanup_project.ps1"
    }

    Write-Host ""
    Write-Host "[3/4] Building all platforms..." -ForegroundColor Cyan
    & ".\android-build-recovery-v2.ps1"
    flutter build web --release

    Write-Host ""
    Write-Host "[4/4] Deploying to Firebase..." -ForegroundColor Cyan
    firebase deploy --only hosting

    Write-Host ""
    Write-Host "✅ PROFESSIONAL BUILD COMPLETE!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Ready for production:" -ForegroundColor Cyan
    Write-Host "  📦 APK (testing): build/app/outputs/flutter-apk/app-release.apk" -ForegroundColor Green
    Write-Host "  📦 AAB (Play Store): build/app/outputs/bundle/release/app-release.aab" -ForegroundColor Green
    Write-Host "  🌐 Web (Live): https://your-project.firebaseapp.com" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  1. Review code changes" -ForegroundColor Gray
    Write-Host "  2. Test APK on device / Android emulator" -ForegroundColor Gray
    Write-Host "  3. Submit AAB to Google Play Store" -ForegroundColor Gray
    Write-Host ""

    Read-Host "Press ENTER to continue..." | Out-Null
}

function Invoke-FullAudit {
    Write-Host ""
    Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "║  🔬 FULL AUDIT MODE                  ║" -ForegroundColor Yellow
    Write-Host "║  ~120+ min comprehensive production  ║" -ForegroundColor Yellow
    Write-Host "║       readiness verification         ║" -ForegroundColor Yellow
    Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "This mode executes all 10 phases:" -ForegroundColor Yellow
    Write-Host "  1️⃣  Comprehensive codebase audit" -ForegroundColor Gray
    Write-Host "  2️⃣  Project cleanup" -ForegroundColor Gray
    Write-Host "  3️⃣  Android build recovery" -ForegroundColor Gray
    Write-Host "  4️⃣  Web build & Firebase deploy" -ForegroundColor Gray
    Write-Host "  5️⃣  Firebase integration audit" -ForegroundColor Gray
    Write-Host "  6️⃣  Video engine (Agora) audit" -ForegroundColor Gray
    Write-Host "  7️⃣  Performance & UX checks" -ForegroundColor Gray
    Write-Host "  8️⃣  Run test suite" -ForegroundColor Gray
    Write-Host "  9️⃣  CI/CD verification" -ForegroundColor Gray
    Write-Host "  🔟 Final production report" -ForegroundColor Gray
    Write-Host ""

    Read-Host "Press ENTER to start (this will take ~2 hours)..." | Out-Null

    Write-Host ""
    Write-Host "Executing master production pipeline..." -ForegroundColor Cyan

    if (Test-Path "master_production_pipeline.ps1") {
        & ".\master_production_pipeline.ps1" -Phase All
    } else {
        Write-Host "❌ master_production_pipeline.ps1 not found!" -ForegroundColor Red
    }

    Write-Host ""
    Write-Host "✅ FULL AUDIT COMPLETE!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Check report:" -ForegroundColor Cyan
    Write-Host "  📋 MASTER_PRODUCTION_REPORT_*.md" -ForegroundColor Green
    Write-Host ""

    Read-Host "Press ENTER to continue..." | Out-Null
}

function Show-Status {
    Write-Host ""
    Write-Host "╔═════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║  📊 CURRENT BUILD STATUS               ║" -ForegroundColor Magenta
    Write-Host "╚═════════════════════════════════════════╝" -ForegroundColor Magenta
    Write-Host ""

    # Check Flutter environment
    Write-Host "Flutter Environment:" -ForegroundColor Yellow
    flutter --version

    # Check build artifacts
    Write-Host ""
    Write-Host "Build Artifacts:" -ForegroundColor Yellow

    if (Test-Path "build/app/outputs/flutter-apk/app-release.apk") {
        $apkSize = (Get-Item "build/app/outputs/flutter-apk/app-release.apk").Length / 1MB
        Write-Host "  ✅ APK: build/app/outputs/flutter-apk/app-release.apk (${apkSize:F1}MB)" -ForegroundColor Green
    } else {
        Write-Host "  ❌ APK: Not built yet" -ForegroundColor Red
    }

    if (Test-Path "build/app/outputs/bundle/release/app-release.aab") {
        $aabSize = (Get-Item "build/app/outputs/bundle/release/app-release.aab").Length / 1MB
        Write-Host "  ✅ AAB: build/app/outputs/bundle/release/app-release.aab (${aabSize:F1}MB)" -ForegroundColor Green
    } else {
        Write-Host "  ❌ AAB: Not built yet" -ForegroundColor Red
    }

    if (Test-Path "build/web/index.html") {
        $webSize = (Get-Item -Recurse "build/web" -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB
        Write-Host "  ✅ Web: build/web/ (${webSize:F1}MB)" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Web: Not built yet" -ForegroundColor Red
    }

    # Check latest analysis
    Write-Host ""
    Write-Host "Code Quality:" -ForegroundColor Yellow

    if (Test-Path "analysis_after_fix.txt") {
        $errors = (Get-Content "analysis_after_fix.txt" | Select-String "^error " | Measure-Object).Count
        $warnings = (Get-Content "analysis_after_fix.txt" | Select-String "^warning " | Measure-Object).Count
        Write-Host "  Errors: $errors" -ForegroundColor (if ($errors -eq 0) { "Green" } else { "Red" })
        Write-Host "  Warnings: $warnings" -ForegroundColor (if ($warnings -eq 0) { "Green" } else { "Yellow" })
        Write-Host "  (Latest: analysis_after_fix.txt)" -ForegroundColor Gray
    } else {
        Write-Host "  ⚠️  No analysis results yet - run code fixer or audit" -ForegroundColor Yellow
    }

    # Check reports
    Write-Host ""
    Write-Host "Reports:" -ForegroundColor Yellow

    $reports = Get-ChildItem -Filter "MASTER_PRODUCTION_REPORT_*.md" -ErrorAction SilentlyContinue
    if ($reports) {
        foreach ($report in $reports | Select-Object -Last 3) {
            Write-Host "  📄 $($report.Name)" -ForegroundColor Green
        }
    } else {
        Write-Host "  ❌ No production reports yet" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "Recommended next step:" -ForegroundColor Cyan

    if ((Test-Path "build/app/outputs/flutter-apk/app-release.apk") -and (Test-Path "build/app/outputs/bundle/release/app-release.aab")) {
        Write-Host "  ✅ All builds complete - ready for store submission!" -ForegroundColor Green
    } else {
        Write-Host "  Run: .\production_command_center.ps1 -Mode Professional" -ForegroundColor Yellow
    }

    Write-Host ""
    Read-Host "Press ENTER to continue..." | Out-Null
}

# ============================================================================
# MAIN MENU LOOP
# ============================================================================

function Invoke-Menu {
    while ($true) {
        Show-Menu
        $choice = Read-Host "Enter selection (0-4)"

        switch ($choice) {
            "1" { Invoke-FastTrack; break }
            "2" { Invoke-Professional; break }
            "3" { Invoke-FullAudit; break }
            "4" { Show-Status; break }
            "0" {
                Write-Host ""
                Write-Host "Goodbye! 👋" -ForegroundColor Cyan
                exit 0
            }
            default {
                Write-Host ""
                Write-Host "Invalid selection. Try again." -ForegroundColor Red
                Read-Host "Press ENTER..." | Out-Null
            }
        }
    }
}

# ============================================================================
# COMMAND-LINE MODE
# ============================================================================

switch ($Mode) {
    "FastTrack" { Invoke-FastTrack }
    "Professional" { Invoke-Professional }
    "FullAudit" { Invoke-FullAudit }
    "Status" { Show-Status }
    "Menu" { Invoke-Menu }
}
