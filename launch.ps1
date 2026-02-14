<#
.SYNOPSIS
🚀 Quick-Start Launcher - Mix & Mingle Production
Choose your automation mode with simple menu.

.DESCRIPTION
Interactive launcher for production deployment scripts:
- Full Automation: Fix + Build + Verify everything
- Android Only: Just fix and build Android
- Verify Only: Just check if everything is ready
- Custom: Choose specific components

.EXAMPLE
.\launch.ps1
#>

# ============================================================================
# INTERACTIVE LAUNCHER MENU
# ============================================================================

function Show-Menu {
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  🚀 MIX & MINGLE - PRODUCTION LAUNCHER                ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Choose your automation mode:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [1] 🟢 FULL AUTOMATION (Recommended)" -ForegroundColor Green
    Write-Host "      • Fixes Android configuration" -ForegroundColor White
    Write-Host "      • Builds APK + AAB" -ForegroundColor White
    Write-Host "      • Verifies Web + Android" -ForegroundColor White
    Write-Host "      • Generates master report" -ForegroundColor White
    Write-Host ""
    Write-Host "  [2] 🟠 ANDROID BUILD ONLY" -ForegroundColor Yellow
    Write-Host "      • Fixes Gradle/Kotlin/SDK issues" -ForegroundColor White
    Write-Host "      • Builds APK + AAB" -ForegroundColor White
    Write-Host "      • No verification" -ForegroundColor White
    Write-Host ""
    Write-Host "  [3] 🔵 VERIFY ONLY" -ForegroundColor Blue
    Write-Host "      • Check Web app status" -ForegroundColor White
    Write-Host "      • Check APK/AAB status" -ForegroundColor White
    Write-Host "      • Code quality review" -ForegroundColor White
    Write-Host ""
    Write-Host "  [4] ⚙️  CUSTOM MODE" -ForegroundColor Magenta
    Write-Host "      • Choose individual components" -ForegroundColor White
    Write-Host ""
    Write-Host "  [5] 📋 VIEW QUICK GUIDE" -ForegroundColor Cyan
    Write-Host "      • Show step-by-step instructions" -ForegroundColor White
    Write-Host ""
    Write-Host "  [Q] Quit" -ForegroundColor Gray
    Write-Host ""
}

function Show-QuickGuide {
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  📋 QUICK GUIDE - PRODUCTION DEPLOYMENT               ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "CURRENT STATUS:" -ForegroundColor Yellow
    Write-Host "  ✅ Web App: LIVE at https://mix-and-mingle-v2.web.app" -ForegroundColor Green
    Write-Host "  ⚠️  Android: Needs build (APK/AAB production artifacts)" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "RECOMMENDED WORKFLOW:" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "Step 1: Full Automation (1-2 hours)" -ForegroundColor Cyan
    Write-Host "  Run: .\master-production-automation.ps1" -ForegroundColor White
    Write-Host "  • Fixes all Android issues" -ForegroundColor Gray
    Write-Host "  • Builds APK and AAB" -ForegroundColor Gray
    Write-Host "  • Verifies everything works" -ForegroundColor Gray
    Write-Host ""

    Write-Host "Step 2: Test APK (15-30 minutes)" -ForegroundColor Cyan
    Write-Host "  Run: adb install -r build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor White
    Write-Host "  • Install on device or emulator" -ForegroundColor Gray
    Write-Host "  • Test all features (login, video, Stripe, etc.)" -ForegroundColor Gray
    Write-Host "  • Check Firebase Console for crashes" -ForegroundColor Gray
    Write-Host ""

    Write-Host "Step 3: Test Web (5 minutes)" -ForegroundColor Cyan
    Write-Host "  Visit: https://mix-and-mingle-v2.web.app" -ForegroundColor White
    Write-Host "  • Test same features as Android" -ForegroundColor Gray
    Write-Host "  • Check browser console (F12) for errors" -ForegroundColor Gray
    Write-Host ""

    Write-Host "Step 4: Submit to Play Store (30 minutes)" -ForegroundColor Cyan
    Write-Host "  1. Go to: https://play.google.com/console" -ForegroundColor White
    Write-Host "  2. Upload: build/app/outputs/bundle/release/app-release.aab" -ForegroundColor White
    Write-Host "  3. Add release notes and screenshots" -ForegroundColor White
    Write-Host "  4. Submit for review" -ForegroundColor White
    Write-Host ""

    Write-Host "Step 5: Monitor (Ongoing)" -ForegroundColor Cyan
    Write-Host "  • Watch Firebase Console for issues" -ForegroundColor White
    Write-Host "  • Check Play Store reviews" -ForegroundColor White
    Write-Host "  • Monitor user analytics" -ForegroundColor White
    Write-Host ""

    Write-Host "TOTAL TIME TO LAUNCH: 3-72 hours" -ForegroundColor Green
    Write-Host "  • Build: 1-2 hours" -ForegroundColor White
    Write-Host "  • Testing: 15-30 minutes" -ForegroundColor White
    Write-Host "  • Submission: 30 minutes" -ForegroundColor White
    Write-Host "  • Play Store review: 2-48 hours" -ForegroundColor White
    Write-Host ""
}

function Show-CustomOptions {
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║  ⚙️  CUSTOM MODE - SELECT COMPONENTS                  ║" -ForegroundColor Magenta
    Write-Host "╚═══════════════════════════════════════════════════════╝" -ForegroundColor Magenta
    Write-Host ""

    Write-Host "Select what to run:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [A] Build APK only" -ForegroundColor Yellow
    Write-Host "  [B] Build AAB only" -ForegroundColor Yellow
    Write-Host "  [AB] Build APK + AAB (recommended)" -ForegroundColor Green
    Write-Host "  [V] Verify Web + Android status" -ForegroundColor Blue
    Write-Host "  [ALL] Everything (same as Full Automation)" -ForegroundColor Green
    Write-Host ""

    $choice = Read-Host "Enter choice"

    switch ($choice.ToUpper()) {
        "A" {
            Write-Host ""
            Write-Host "Starting APK build only..." -ForegroundColor Yellow
            & .\android-production-ready.ps1 -NoAAB
        }
        "B" {
            Write-Host ""
            Write-Host "Starting AAB build only..." -ForegroundColor Yellow
            & .\android-production-ready.ps1 -NoAPK
        }
        "AB" {
            Write-Host ""
            Write-Host "Starting APK + AAB build..." -ForegroundColor Yellow
            & .\android-production-ready.ps1
        }
        "V" {
            Write-Host ""
            Write-Host "Starting verification..." -ForegroundColor Yellow
            & .\verify-production-ready.ps1
        }
        "ALL" {
            Write-Host ""
            Write-Host "Starting full automation..." -ForegroundColor Yellow
            & .\master-production-automation.ps1
        }
        default {
            Write-Host "Invalid choice" -ForegroundColor Red
        }
    }
}

# ============================================================================
# MAIN LOOP
# ============================================================================

do {
    Show-Menu
    $choice = Read-Host "Enter choice (1-5 or Q)"

    switch ($choice.ToUpper()) {
        "1" {
            Write-Host ""
            Write-Host "🟢 Launching FULL AUTOMATION..." -ForegroundColor Green
            Write-Host "This will:" -ForegroundColor White
            Write-Host "  1. Fix Android configuration (Gradle, Kotlin, SDK)" -ForegroundColor Gray
            Write-Host "  2. Build APK + AAB" -ForegroundColor Gray
            Write-Host "  3. Verify Web + Android" -ForegroundColor Gray
            Write-Host "  4. Generate master report" -ForegroundColor Gray
            Write-Host ""
            Write-Host -NoNewLine "Press ENTER to start (or Ctrl+C to cancel): " -ForegroundColor Yellow
            Read-Host | Out-Null

            & .\master-production-automation.ps1

            Write-Host ""
            Write-Host "✅ Full automation complete!" -ForegroundColor Green
            Write-Host "   Check the generated MASTER_PRODUCTION_REPORT_*.md file" -ForegroundColor White
        }

        "2" {
            Write-Host ""
            Write-Host "🟠 Launching ANDROID BUILD ONLY..." -ForegroundColor Yellow
            Write-Host "This will:" -ForegroundColor White
            Write-Host "  1. Fix Android configuration" -ForegroundColor Gray
            Write-Host "  2. Build APK + AAB" -ForegroundColor Gray
            Write-Host ""
            Write-Host -NoNewLine "Press ENTER to start (or Ctrl+C to cancel): " -ForegroundColor Yellow
            Read-Host | Out-Null

            & .\android-production-ready.ps1

            Write-Host ""
            Write-Host "✅ Android build complete!" -ForegroundColor Green
            Write-Host "   APK: build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor White
            Write-Host "   AAB: build\app\outputs\bundle\release\app-release.aab" -ForegroundColor White
        }

        "3" {
            Write-Host ""
            Write-Host "🔵 Launching VERIFY ONLY..." -ForegroundColor Blue
            Write-Host ""

            & .\verify-production-ready.ps1 -QuickTest

            Write-Host ""
            Write-Host "✅ Verification complete!" -ForegroundColor Green
        }

        "4" {
            Show-CustomOptions
        }

        "5" {
            Show-QuickGuide
            Write-Host -NoNewLine "Press ENTER to continue..." -ForegroundColor Gray
            Read-Host | Out-Null
        }

        "Q" {
            Write-Host "Goodbye!" -ForegroundColor Green
            exit 0
        }

        default {
            Write-Host "Invalid choice. Please enter 1-5 or Q." -ForegroundColor Red
        }
    }
} while ($true)
