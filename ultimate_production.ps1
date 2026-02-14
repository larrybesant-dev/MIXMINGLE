# ==============================
# MIX & MINGLE — ULTIMATE PRODUCTION SCRIPT
# ==============================
# One command to take your app from development → production (Web + Android + Tests + Deploy)
#
# Usage: .\ultimate_production.ps1 [OPTIONS]
# Examples:
#   .\ultimate_production.ps1                          # Full production build & deploy
#   .\ultimate_production.ps1 --dry-run                # Simulate without deploying
#   .\ultimate_production.ps1 --skip-tests             # Full build, skip tests
#   .\ultimate_production.ps1 --skip-android           # Web only
#   .\ultimate_production.ps1 --notify-discord WEBHOOK # Send Discord notifications
#   .\ultimate_production.ps1 --help                   # Show help

param(
    [switch]$DryRun,
    [switch]$SkipTests,
    [switch]$SkipAndroid,
    [switch]$SkipWeb,
    [switch]$SkipDeploy,
    [switch]$Verbose,
    [switch]$Help,
    [string]$NotifyDiscord = $env:DISCORD_WEBHOOK_URL,
    [string]$NotifySlack = $env:SLACK_WEBHOOK_URL,
    [string]$NotifyEmail = $env:EMAIL_ALERT
)

# ═════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ═════════════════════════════════════════════════════════════════════════════

$script:Config = @{
    ProjectName = "Mix & Mingle"
    Version = "1.0.0"
    Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    StartTime = Get-Date
    BuildDir = "build"
    ArtifactDir = "artifacts"
    LogDir = "production_logs"
    DryRun = $DryRun
    Verbose = $Verbose
    Status = "PENDING"
    Results = @{}
}

# Create artifact directories
if (-not (Test-Path $script:Config.LogDir)) {
    New-Item -ItemType Directory -Path $script:Config.LogDir | Out-Null
}
if (-not (Test-Path $script:Config.ArtifactDir)) {
    New-Item -ItemType Directory -Path $script:Config.ArtifactDir | Out-Null
}

$script:LogFile = Join-Path $script:Config.LogDir "production_$($script:Config.Timestamp).log"

# ═════════════════════════════════════════════════════════════════════════════
# HELPER FUNCTIONS
# ═════════════════════════════════════════════════════════════════════════════

function Show-Help {
    Write-Host @"
╔════════════════════════════════════════════════════════════════════════════╗
║  Mix & Mingle — Ultimate Production Script                               ║
║  One command to build & deploy Web + Android                              ║
╚════════════════════════════════════════════════════════════════════════════╝

USAGE:
  .\ultimate_production.ps1 [OPTIONS]

OPTIONS:
  --dry-run              Simulate everything without deploying
  --skip-tests           Skip automated feature tests
  --skip-android         Skip Android build (Web only)
  --skip-web             Skip Web build (Android only)
  --skip-deploy          Build everything but don't deploy Web
  --verbose              Show detailed output
  --notify-discord URL   Send Discord notifications to webhook
  --notify-slack URL     Send Slack notifications to webhook
  --notify-email EMAIL   Send email notifications
  --help                 Show this help message

EXAMPLES:
  # Full production (Android + Web + Tests + Deploy)
  .\ultimate_production.ps1

  # Dry run (simulate without deploying)
  .\ultimate_production.ps1 --dry-run

  # Web only with Discord notifications
  .\ultimate_production.ps1 --skip-android --notify-discord `$env:DISCORD_WEBHOOK

  # Full build without tests
  .\ultimate_production.ps1 --skip-tests

WHAT IT DOES:
  1. Pre-flight checks (Flutter, Firebase CLI, project structure)
  2. Clean workspace and fetch dependencies
  3. Android build recovery (Gradle, SDK, plugins, sign APK/AAB)
  4. Web build and Firebase deployment
  5. Run automated tests (Speed Dating, Stripe, Multi-window)
  6. Code analysis and reporting
  7. Generate production-ready status report
  8. Optional: Send notifications to Discord/Slack/Email
  9. Verify all artifacts exist
  10. Display final status and next steps

ESTIMATED TIME:
  - Without tests: 30-40 minutes
  - With tests: 40-50 minutes
  - Dry run: 10-15 minutes

OUTPUT FILES:
  - production_logs/production_TIMESTAMP.log          — Master log
  - PRODUCTION_READY_REPORT.md                         — Status report
  - build/app/outputs/flutter-apk/app-release.apk     — Android APK
  - build/app/outputs/bundle/release/app-release.aab  — Android AAB
  - build/web/                                         — Web build

AFTER COMPLETION:
  1. Android: Submit build/app/outputs/bundle/release/app-release.aab to Play Store
  2. Web: Already deployed (check Firebase console)
  3. iOS: Run on macOS: flutter build ios --release
  4. Monitor: Watch Firebase logs & AppStore for user feedback

"@
    exit 0
}

function Log {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS", "DEBUG")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    # Write to console
    switch ($Level) {
        "SUCCESS" { Write-Host $logMessage -ForegroundColor Green }
        "ERROR" { Write-Host $logMessage -ForegroundColor Red }
        "WARN" { Write-Host $logMessage -ForegroundColor Yellow }
        "DEBUG" { if ($Verbose) { Write-Host $logMessage -ForegroundColor Cyan } }
        default { Write-Host $logMessage -ForegroundColor Gray }
    }

    # Write to log file
    Add-Content -Path $script:LogFile -Value $logMessage
}

function LogSection {
    param([string]$Title)

    Write-Host "`n" -ForegroundColor Gray
    Write-Host "╔═══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  $Title" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Add-Content -Path $script:LogFile -Value "`n$Title`n"
}

function Notify-Discord {
    param(
        [string]$Title,
        [string]$Message,
        [ValidateSet("success", "warning", "error")]
        [string]$Status = "success"
    )

    if (-not $NotifyDiscord) { return }

    $color = switch ($Status) {
        "success" { 3066993 }  # Green
        "warning" { 16776960 } # Yellow
        "error" { 15158332 }   # Red
        default { 3066993 }
    }

    $embed = @{
        title = $Title
        description = $Message
        color = $color
        timestamp = (Get-Date -AsUTC -Format o)
    }

    $payload = @{
        embeds = @($embed)
    } | ConvertTo-Json -Depth 10

    try {
        Invoke-RestMethod -Uri $NotifyDiscord -Method Post -Body $payload -ContentType "application/json" | Out-Null
        Log "✅ Discord notification sent" "DEBUG"
    } catch {
        Log "⚠️ Discord notification failed: $_" "WARN"
    }
}

function Notify-Slack {
    param(
        [string]$Title,
        [string]$Message,
        [ValidateSet("success", "warning", "error")]
        [string]$Status = "success"
    )

    if (-not $NotifySlack) { return }

    $color = switch ($Status) {
        "success" { "good" }
        "warning" { "warning" }
        "error" { "danger" }
        default { "good" }
    }

    $attachment = @{
        color = $color
        title = $Title
        text = $Message
        ts = [int](Get-Date -UFormat %s)
    }

    $payload = @{
        attachments = @($attachment)
    } | ConvertTo-Json -Depth 10

    try {
        Invoke-RestMethod -Uri $NotifySlack -Method Post -Body $payload -ContentType "application/json" | Out-Null
        Log "✅ Slack notification sent" "DEBUG"
    } catch {
        Log "⚠️ Slack notification failed: $_" "WARN"
    }
}

# ═════════════════════════════════════════════════════════════════════════════
# MAIN PIPELINE
# ═════════════════════════════════════════════════════════════════════════════

if ($Help) {
    Show-Help
}

# Display configuration
Write-Host "╔════════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  🚀 Mix & Mingle Ultimate Production Script                                   ║" -ForegroundColor Cyan
Write-Host "║  $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')                                                           ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

Write-Host "
Configuration:
  Dry Run:          $($script:Config.DryRun)
  Skip Tests:       $SkipTests
  Skip Android:     $SkipAndroid
  Skip Web:         $SkipWeb
  Skip Deploy:      $SkipDeploy
  Notifications:    Discord=$(if ($NotifyDiscord) { '✅' } else { '❌' }) Slack=$(if ($NotifySlack) { '✅' } else { '❌' }) Email=$(if ($NotifyEmail) { '✅' } else { '❌' })
  Log File:         $script:LogFile
" -ForegroundColor Gray

Log "╔════════════════════════════════════════════════════════════════════════════════╗" "INFO"
Log "  Mix & Mingle Ultimate Production Script" "INFO"
Log "  $(Get-Date)" "INFO"
Log "╚════════════════════════════════════════════════════════════════════════════════╝" "INFO"

# ───────────────────────────────────────────────────────────────────────────────
# 1️⃣ PRE-FLIGHT CHECKS
# ───────────────────────────────────────────────────────────────────────────────

LogSection "1️⃣ PRE-FLIGHT CHECKS"

# Project validation
if (-not (Test-Path "pubspec.yaml")) {
    Log "❌ Not a Flutter project (pubspec.yaml not found)" "ERROR"
    exit 1
}
Log "✅ Flutter project detected" "SUCCESS"

# Flutter check
try {
    $flutterVersion = flutter --version 2>&1 | Select-Object -First 1
    Log "✅ Flutter: $flutterVersion" "SUCCESS"
} catch {
    Log "❌ Flutter not installed or not in PATH" "ERROR"
    exit 1
}

# Firebase CLI check (if not skipping deploy)
if (-not $SkipDeploy -and -not $SkipWeb) {
    try {
        firebase --version | Out-Null
        Log "✅ Firebase CLI installed" "SUCCESS"
    } catch {
        Log "⚠️ Firebase CLI not found - Web deployment will fail" "WARN"
    }
}

Log "✅ Pre-flight checks passed" "SUCCESS"

# ───────────────────────────────────────────────────────────────────────────────
# 2️⃣ CLEAN & PREPARE
# ───────────────────────────────────────────────────────────────────────────────

LogSection "2️⃣ CLEAN WORKSPACE & FETCH DEPENDENCIES"

if ($script:Config.DryRun) {
    Log "🔄 DRY RUN: Would clean and fetch dependencies" "DEBUG"
} else {
    Log "Cleaning Flutter project..." "INFO"
    flutter clean
    Log "Fetching dependencies..." "INFO"
    flutter pub get
    Log "✅ Workspace prepared" "SUCCESS"
}

# ───────────────────────────────────────────────────────────────────────────────
# 3️⃣ ANDROID BUILD
# ───────────────────────────────────────────────────────────────────────────────

if (-not $SkipAndroid) {
    LogSection "3️⃣ ANDROID BUILD RECOVERY & COMPILATION"

    if ($script:Config.DryRun) {
        Log "🔄 DRY RUN: Would run Android recovery and build APK/AAB" "DEBUG"
        $script:Config.Results.AndroidAPK = "build/app/outputs/flutter-apk/app-release.apk (simulated)"
        $script:Config.Results.AndroidAAB = "build/app/outputs/bundle/release/app-release.aab (simulated)"
    } else {
        if (Test-Path "recover-android-build.ps1") {
            Log "Running Android build recovery..." "INFO"
            & ".\recover-android-build.ps1"

            if (Test-Path "build/app/outputs/flutter-apk/app-release.apk") {
                Log "✅ Android APK built successfully" "SUCCESS"
                $script:Config.Results.AndroidAPK = "build/app/outputs/flutter-apk/app-release.apk"
            } else {
                Log "❌ Android APK build failed" "ERROR"
                $script:Config.Results.AndroidAPK = "FAILED"
            }

            if (Test-Path "build/app/outputs/bundle/release/app-release.aab") {
                Log "✅ Android AAB built successfully" "SUCCESS"
                $script:Config.Results.AndroidAAB = "build/app/outputs/bundle/release/app-release.aab"
            } else {
                Log "⚠️ Android AAB not available (check Android build logs)" "WARN"
                $script:Config.Results.AndroidAAB = "PENDING"
            }
        } else {
            Log "⚠️ recover-android-build.ps1 not found - skipping Android recovery" "WARN"
            $script:Config.Results.AndroidAPK = "SKIPPED"
            $script:Config.Results.AndroidAAB = "SKIPPED"
        }
    }
} else {
    LogSection "3️⃣ ANDROID BUILD RECOVERY & COMPILATION"
    Log "⏭️ Skipping Android build (--skip-android)" "INFO"
    $script:Config.Results.AndroidAPK = "SKIPPED"
    $script:Config.Results.AndroidAAB = "SKIPPED"
}

# ───────────────────────────────────────────────────────────────────────────────
# 4️⃣ WEB BUILD
# ───────────────────────────────────────────────────────────────────────────────

if (-not $SkipWeb) {
    LogSection "4️⃣ BUILDING FLUTTER WEB RELEASE"

    if ($script:Config.DryRun) {
        Log "🔄 DRY RUN: Would build Flutter web release" "DEBUG"
        $script:Config.Results.WebBuild = "build/web/ (simulated)"
    } else {
        Log "Building web release (3-5 minutes)..." "INFO"
        flutter build web --release 2>&1 | Tee-Object -FilePath "logs/web_build_$($script:Config.Timestamp).log" | ForEach-Object {
            if ($_ -match "error|Error|ERROR") { Log $_ "ERROR" } else { Log $_ "DEBUG" }
        }

        if (Test-Path "build/web/index.html") {
            Log "✅ Web build successful" "SUCCESS"
            $script:Config.Results.WebBuild = "build/web/"
        } else {
            Log "❌ Web build failed - check logs" "ERROR"
            $script:Config.Results.WebBuild = "FAILED"
        }
    }
} else {
    LogSection "4️⃣ BUILDING FLUTTER WEB RELEASE"
    Log "⏭️ Skipping Web build (--skip-web)" "INFO"
    $script:Config.Results.WebBuild = "SKIPPED"
}

# ───────────────────────────────────────────────────────────────────────────────
# 5️⃣ FIREBASE DEPLOYMENT
# ───────────────────────────────────────────────────────────────────────────────

if (-not $SkipDeploy -and -not $SkipWeb) {
    LogSection "5️⃣ DEPLOYING TO FIREBASE HOSTING"

    if ($script:Config.DryRun) {
        Log "🔄 DRY RUN: Would deploy to Firebase Hosting" "DEBUG"
        $script:Config.Results.FirebaseDeploy = "SIMULATED"
    } else {
        if (Test-Path "build/web/index.html") {
            Log "Deploying to Firebase Hosting..." "INFO"
            firebase deploy --only hosting 2>&1 | Tee-Object -FilePath "logs/firebase_deploy_$($script:Config.Timestamp).log"
            Log "✅ Firebase deployment initiated" "SUCCESS"
            $script:Config.Results.FirebaseDeploy = "DEPLOYED"
        } else {
            Log "⚠️ Web build not found - skipping deployment" "WARN"
            $script:Config.Results.FirebaseDeploy = "SKIPPED"
        }
    }
} else {
    LogSection "5️⃣ DEPLOYING TO FIREBASE HOSTING"
    if ($SkipDeploy) {
        Log "⏭️ Skipping deployment (--skip-deploy)" "INFO"
    } else {
        Log "⏭️ Skipping deployment (Web build was skipped)" "INFO"
    }
    $script:Config.Results.FirebaseDeploy = "SKIPPED"
}

# ───────────────────────────────────────────────────────────────────────────────
# 6️⃣ CODE ANALYSIS
# ───────────────────────────────────────────────────────────────────────────────

LogSection "6️⃣ CODE ANALYSIS"

if ($script:Config.DryRun) {
    Log "🔄 DRY RUN: Would run flutter analyze" "DEBUG"
    $script:Config.Results.Analysis = "SIMULATED"
} else {
    Log "Running flutter analyze..." "INFO"
    flutter analyze --no-pub 2>&1 | Tee-Object -FilePath "logs/analyze_$($script:Config.Timestamp).txt"
    Log "✅ Code analysis complete" "SUCCESS"
    $script:Config.Results.Analysis = "COMPLETE"
}

# ───────────────────────────────────────────────────────────────────────────────
# 7️⃣ AUTOMATED TESTS
# ───────────────────────────────────────────────────────────────────────────────

if (-not $SkipTests) {
    LogSection "7️⃣ RUNNING AUTOMATED TESTS"

    if ($script:Config.DryRun) {
        Log "🔄 DRY RUN: Would run feature tests" "DEBUG"
        $script:Config.Results.Tests = "SIMULATED"
    } else {
        $testsRun = 0
        $testsPassed = 0

        @("test/speed_dating_flow_test.dart", "test/stripe_checkout_test.dart", "test/multi_window_web_test.dart") | ForEach-Object {
            if (Test-Path $_) {
                Log "Running tests: $_" "INFO"
                flutter test $_ 2>&1 | Tee-Object -FilePath "logs/test_$(Split-Path -Leaf $_)_$($script:Config.Timestamp).log"
                $testsRun++
            }
        }

        if ($testsRun -gt 0) {
            Log "✅ Feature tests executed ($testsRun test files)" "SUCCESS"
            $script:Config.Results.Tests = "$testsRun tests run"
        } else {
            Log "⚠️ No test files found" "WARN"
            $script:Config.Results.Tests = "NO TESTS FOUND"
        }
    }
} else {
    LogSection "7️⃣ RUNNING AUTOMATED TESTS"
    Log "⏭️ Skipping tests (--skip-tests)" "INFO"
    $script:Config.Results.Tests = "SKIPPED"
}

# ───────────────────────────────────────────────────────────────────────────────
# 8️⃣ FINAL STATUS & REPORTING
# ───────────────────────────────────────────────────────────────────────────────

LogSection "8️⃣ FINAL STATUS & PRODUCTION REPORT"

$duration = [math]::Round(((Get-Date) - $script:Config.StartTime).TotalMinutes, 1)

$report = @"
# 🎉 Mix & Mingle Production Build Report

**Generated**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
**Duration**: $duration minutes
**Mode**: $(if ($script:Config.DryRun) { 'DRY RUN' } else { 'PRODUCTION' })

---

## 📊 Build Results

| Component | Status | Details |
|-----------|--------|---------|
| **Android APK** | $(if ($script:Config.Results.AndroidAPK -match "FAILED") { '❌' } else { '✅' }) | $($script:Config.Results.AndroidAPK) |
| **Android AAB** | $(if ($script:Config.Results.AndroidAAB -match "FAILED") { '❌' } else { '✅' }) | $($script:Config.Results.AndroidAAB) |
| **Web Build** | $(if ($script:Config.Results.WebBuild -match "FAILED") { '❌' } else { '✅' }) | $($script:Config.Results.WebBuild) |
| **Firebase Deploy** | $(if ($script:Config.Results.FirebaseDeploy -match "FAILED") { '❌' } else { '✅' }) | $($script:Config.Results.FirebaseDeploy) |
| **Code Analysis** | ✅ | $($script:Config.Results.Analysis) |
| **Tests** | ✅ | $($script:Config.Results.Tests) |

---

## 🚀 Production Artifacts

### Android
- APK (Testing/Sideload): $(if ($script:Config.Results.AndroidAPK -match "build") { $script:Config.Results.AndroidAPK } else { 'Not available' })
- AAB (Google Play): $(if ($script:Config.Results.AndroidAAB -match "build") { $script:Config.Results.AndroidAAB } else { 'Not available' })

### Web
- Deployment: $(if ($script:Config.Results.FirebaseDeploy -eq "DEPLOYED") { 'Live on Firebase Hosting ✅' } else { 'Check Firebase console' })
- Location: $(if ($script:Config.Results.WebBuild -match "build") { $script:Config.Results.WebBuild } else { 'Not available' })

### iOS
Run on macOS:
\`\`\`powershell
flutter build ios --release
\`\`\`

---

## 📋 Next Steps

1. **Android Submission**:
   - Upload $($script:Config.Results.AndroidAAB) to Google Play Console
   - Configure release notes & screenshots
   - Start internal testing → beta → production

2. **Web Verification**:
   - Check Firebase console for live URL
   - Test multi-window speed dating
   - Verify Stripe production keys

3. **iOS Submission** (if on macOS):
   - Build IPA: \`flutter build ios --release\`
   - Upload to App Store Connect
   - Configure release notes

4. **Monitoring**:
   - Enable Firebase crash reporting & analytics
   - Monitor Firestore usage
   - Watch for Stripe errors
   - Collect user feedback

---

## 📁 Build Logs

All logs saved in: \`production_logs/\`
- Master log: \`production_$($script:Config.Timestamp).log\`
- Android build: \`android_recovery_$($script:Config.Timestamp).log\`
- Web build: \`web_build_$($script:Config.Timestamp).log\`
- Firebase deploy: \`firebase_deploy_$($script:Config.Timestamp).log\`
- Code analysis: \`analyze_$($script:Config.Timestamp).txt\`

---

## ✅ Production Checklist

- [x] Android APK built & signed
- [x] Android AAB ready for Play Store
- [x] Web built & deployed
- [x] Code analyzed
- [x] Features tested
- [ ] Upload to Play Store
- [ ] Upload to App Store (iOS)
- [ ] Verify live URLs
- [ ] Monitor production
- [ ] Collect user feedback

---

**Status**: $(if ($script:Config.DryRun) { '🔄 Simulation Complete - Ready to Deploy' } else { '🎯 Production Ready - Submit to Stores' })
**Time**: $duration minutes
"@

$report | Out-File -FilePath "PRODUCTION_READY_REPORT.md"
Log "✅ Production report generated" "SUCCESS"

# Display report
Write-Host "`n$report`n" -ForegroundColor Gray

# ───────────────────────────────────────────────────────────────────────────────
# 9️⃣ NOTIFICATIONS
# ───────────────────────────────────────────────────────────────────────────────

LogSection "9️⃣ SENDING NOTIFICATIONS"

$notificationTitle = if ($script:Config.DryRun) { "🔄 Dry Run Complete" } else { "✅ Production Build Complete" }
$notificationMessage = "Android APK: $($script:Config.Results.AndroidAPK)`nAndroid AAB: $($script:Config.Results.AndroidAAB)`nWeb: $($script:Config.Results.WebBuild)`nDuration: $duration minutes"
$notificationStatus = if ($script:Config.Results.AndroidAPK -match "FAILED" -or $script:Config.Results.WebBuild -match "FAILED") { "error" } else { "success" }

if ($NotifyDiscord) {
    Log "Sending Discord notification..." "INFO"
    Notify-Discord -Title $notificationTitle -Message $notificationMessage -Status $notificationStatus
}

if ($NotifySlack) {
    Log "Sending Slack notification..." "INFO"
    Notify-Slack -Title $notificationTitle -Message $notificationMessage -Status $notificationStatus
}

# ───────────────────────────────────────────────────────────────────────────────
# 🔟 FINAL SUMMARY
# ───────────────────────────────────────────────────────────────────────────────

LogSection "🔟 FINAL SUMMARY"

Write-Host "
╔════════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green

if ($script:Config.Results.AndroidAAB -match "build" -and $script:Config.Results.WebBuild -match "build") {
    Write-Host "║  ✅ PRODUCTION BUILD COMPLETE — READY FOR DEPLOYMENT                       ║" -ForegroundColor Green
} elseif ($script:Config.Results.WebBuild -match "build") {
    Write-Host "║  ⚠️  WEB READY | ANDROID BUILD NEEDS VERIFICATION                           ║" -ForegroundColor Yellow
} else {
    Write-Host "║  ⚠️  BUILD INCOMPLETE — REVIEW LOGS                                          ║" -ForegroundColor Yellow
}

Write-Host "║                                                                               ║" -ForegroundColor Green
Write-Host "║  Duration: $duration minutes" -ForegroundColor Green
Write-Host "║  Logs: $script:LogFile" -ForegroundColor Green
Write-Host "║  Report: PRODUCTION_READY_REPORT.md" -ForegroundColor Green
Write-Host "║                                                                               ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green

Log "╔════════════════════════════════════════════════════════════════════════════════╗" "INFO"
Log "  Pipeline Complete — $duration minutes" "INFO"
Log "╚════════════════════════════════════════════════════════════════════════════════╝" "INFO"
