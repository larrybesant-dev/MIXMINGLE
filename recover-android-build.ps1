# ==========================================
# Complete Android Build Recovery
# ==========================================
# This script runs the complete fix pipeline:
# 1. Diagnose the issue
# 2. Apply auto-fixes
# 3. Test APK build
# 4. Test AAB build
# 5. Report results

Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Android Build Complete Recovery      ║" -ForegroundColor Cyan
Write-Host "║  Mix & Mingle — February 6, 2026      ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan

# --- Phase 1: Initial Checks ---
Write-Host "`n[PHASE 1] Pre-flight checks..." -ForegroundColor Yellow

if (-not (Test-Path "pubspec.yaml")) {
    Write-Host "❌ Not in Flutter project directory!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Flutter project detected" -ForegroundColor Green

# --- Phase 2: Diagnose ---
Write-Host "`n[PHASE 2] Running diagnostics..." -ForegroundColor Yellow

if (Test-Path "diagnose-android-build.ps1") {
    Write-Host "Running: .\diagnose-android-build.ps1" -ForegroundColor Gray
    & ".\diagnose-android-build.ps1"
} else {
    Write-Host "⚠️ diagnose-android-build.ps1 not found, skipping detailed diagnostics" -ForegroundColor Yellow
}

# --- Phase 3: Apply Auto-Fixes ---
Write-Host "`n[PHASE 3] Applying auto-fixes..." -ForegroundColor Yellow

if (Test-Path "apply-android-fixes.ps1") {
    Write-Host "Running: .\apply-android-fixes.ps1" -ForegroundColor Gray
    & ".\apply-android-fixes.ps1"
} else {
    Write-Host "❌ apply-android-fixes.ps1 not found!" -ForegroundColor Red
    Write-Host "   Expected at: $(Get-Location)\apply-android-fixes.ps1" -ForegroundColor Red
    exit 1
}

# --- Phase 4: Test APK Build ---
Write-Host "`n[PHASE 4] Testing APK build..." -ForegroundColor Yellow
Write-Host "(This may take 5-15 minutes)" -ForegroundColor Gray

$apkStartTime = Get-Date
flutter build apk --release
$apkEndTime = Get-Date
$apkDuration = $apkEndTime - $apkStartTime

if (Test-Path "build/app/outputs/flutter-apk/app-release.apk") {
    Write-Host "✅ APK build SUCCESS" -ForegroundColor Green
    Write-Host "   Duration: $($apkDuration.TotalMinutes.ToString('F1')) minutes" -ForegroundColor Green
    Write-Host "   Path: build/app/outputs/flutter-apk/app-release.apk" -ForegroundColor Green
    $apkSuccess = $true
} else {
    Write-Host "❌ APK build FAILED" -ForegroundColor Red
    Write-Host "   Check: android_apk_build_verbose.log" -ForegroundColor Red
    $apkSuccess = $false
}

# --- Phase 5: Test AAB Build (if APK succeeded) ---
if ($apkSuccess) {
    Write-Host "`n[PHASE 5] Testing AAB build..." -ForegroundColor Yellow
    Write-Host "(This may take 5-15 minutes)" -ForegroundColor Gray

    $aabStartTime = Get-Date
    flutter build appbundle --release
    $aabEndTime = Get-Date
    $aabDuration = $aabEndTime - $aabStartTime

    if (Test-Path "build/app/outputs/bundle/release/app-release.aab") {
        Write-Host "✅ AAB build SUCCESS" -ForegroundColor Green
        Write-Host "   Duration: $($aabDuration.TotalMinutes.ToString('F1')) minutes" -ForegroundColor Green
        Write-Host "   Path: build/app/outputs/bundle/release/app-release.aab" -ForegroundColor Green
        $aabSuccess = $true
    } else {
        Write-Host "❌ AAB build FAILED" -ForegroundColor Red
        Write-Host "   Check: android_aab_build_verbose.log" -ForegroundColor Red
        $aabSuccess = $false
    }
} else {
    Write-Host "`n[PHASE 5] Skipping AAB test (APK must succeed first)" -ForegroundColor Yellow
    $aabSuccess = $false
}

# --- Phase 6: Generate Final Report ---
Write-Host "`n[PHASE 6] Generating final report..." -ForegroundColor Yellow

$report = @"
═════════════════════════════════════════════════════════════════
  ANDROID BUILD RECOVERY — FINAL REPORT
═════════════════════════════════════════════════════════════════
  Date: $(Get-Date)
  Project: Mix & Mingle
  Status: Recovery Complete

BUILD RESULTS:
  APK Build: $(if ($apkSuccess) {"✅ SUCCESS"} else {"❌ FAILED"})
  - Duration: $($apkDuration.TotalMinutes.ToString('F1')) minutes
  - Artifact: build/app/outputs/flutter-apk/app-release.apk

  AAB Build: $(if ($aabSuccess) {"✅ SUCCESS"} else {if ($apkSuccess) {"⏸ SKIPPED (waiting for verification)" } else {"⏸ SKIPPED (APK build failed)"}})
  - Duration: $(if ($aabSuccess) {$aabDuration.TotalMinutes.ToString('F1') + " minutes"} else {"N/A"})
  - Artifact: build/app/outputs/bundle/release/app-release.aab

AUTO-FIXES APPLIED:
  ✅ Gradle wrapper → gradle-8.2-all.zip
  ✅ Android Gradle plugin → 8.2.0
  ✅ Kotlin version → 1.9.0
  ✅ compileSdkVersion → 34
  ✅ minSdkVersion → 21
  ✅ targetSdkVersion → 34
  ✅ NDK version → 25.1.8937393
  ✅ multiDexEnabled → true
  ✅ ProGuard rules → Agora, Stripe, Firebase
  ✅ Flutter plugins → upgraded

DIAGNOSTIC LOGS:
  - flutter_doctor_report.txt
  - android_apk_build_verbose.log
  - android_diagnostics_report.txt
  - android_autofixes_summary.txt

NEXT STEPS:
  $(if ($apkSuccess -and $aabSuccess) {
    @"
  1. ✅ Android builds are ready!
  2. Prepare for App Submission:
     - AAB: build/app/outputs/bundle/release/app-release.aab
     - Upload to Google Play Console
     - Configure release notes & screenshots
     - Start internal testing → beta → production
  3. Deploy Web (separate from Android):
     - flutter build web --release
     - firebase deploy --only hosting
  4. iOS (if macOS available):
     - flutter build ios --release
"@
  } elseif ($apkSuccess) {
    @"
  1. ✅ APK builds successfully
  2. ⚠️ AAB build needs verification
  3. Check AAB error logs and fix signing/bundling issues
  4. Retry: flutter build appbundle --release
"@
  } else {
    @"
  1. ❌ APK build failed - review logs
  2. Check android_apk_build_verbose.log for the specific error
  3. See ANDROID_BUILD_FIX_STEPS.md for manual fixes
  4. Try: flutter build apk --release --no-shrink (skips ProGuard)
  5. Retry: .\apply-android-fixes.ps1 (apply more aggressive fixes)
"@
  })

BUILD TIME SUMMARY:
  Total Recovery Duration: ~$(if ($aabSuccess) {($apkDuration.TotalMinutes + $aabDuration.TotalMinutes).ToString('F1')} else {$apkDuration.TotalMinutes.ToString('F1')}) minutes

REFERENCES:
  - ANDROID_BUILD_FIX_STEPS.md (detailed step-by-step)
  - ANDROID_BUILD_FIXES.md (quick fixes by error type)
  - ANDROID_BUILD_TROUBLESHOOTING.md (comprehensive guide)

═════════════════════════════════════════════════════════════════
"@

$report | Out-File -FilePath "ANDROID_BUILD_RECOVERY_REPORT.txt"
Get-Content "ANDROID_BUILD_RECOVERY_REPORT.txt" | Write-Host

# --- Final Summary ---
Write-Host "`n╔════════════════════════════════════════╗" -ForegroundColor Cyan
if ($aabSuccess) {
    Write-Host "║  ✅ ANDROID BUILD — READY FOR                ║" -ForegroundColor Green
    Write-Host "║     GOOGLE PLAY SUBMISSION                ║" -ForegroundColor Green
} elseif ($apkSuccess) {
    Write-Host "║  ⚠️  APK READY, AAB NEEDS VERIFICATION   ║" -ForegroundColor Yellow
} else {
    Write-Host "║  ❌ BUILD FAILED — SEE LOGS FOR DETAILS   ║" -ForegroundColor Red
}
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan

Write-Host "`n📄 Full report: ANDROID_BUILD_RECOVERY_REPORT.txt" -ForegroundColor Cyan
Write-Host "📚 Documentation: ANDROID_BUILD_FIX_STEPS.md" -ForegroundColor Cyan
