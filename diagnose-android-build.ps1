# ==========================================
# Android Build Troubleshooting Script
# ==========================================

Write-Host "🔍 Diagnosing Android Build Issue..." -ForegroundColor Cyan

# --- Step 1: Check Flutter & Gradle Status ---
Write-Host "`n📋 Flutter & Gradle Status:" -ForegroundColor Yellow
flutter doctor -v | Out-File -FilePath flutter_doctor_report.txt
Get-Content flutter_doctor_report.txt

# --- Step 2: Clean & Fresh Setup ---
Write-Host "`n🧹 Cleaning project..." -ForegroundColor Yellow
flutter clean
Remove-Item -Recurse -Force "build", ".dart_tool" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "android/.gradle" -ErrorAction SilentlyContinue
Write-Host "✅ Project cleaned"

Write-Host "`n📦 Fetching dependencies..." -ForegroundColor Yellow
flutter pub get

# --- Step 3: Check Android Config ---
Write-Host "`n🔧 Checking Android Configuration..." -ForegroundColor Yellow

# Check gradle wrapper
$gradleWrapper = Get-Content "android/gradle/wrapper/gradle-wrapper.properties" -ErrorAction SilentlyContinue
if ($gradleWrapper -match "gradle-8") {
    Write-Host "✅ Gradle 8.x detected" -ForegroundColor Green
} else {
    Write-Host "⚠️ Gradle may be outdated - should use 8.2+" -ForegroundColor Yellow
}

# Check build.gradle
$buildGradle = Get-Content "android/build.gradle" -ErrorAction SilentlyContinue
if ($buildGradle -match "com.android.tools.build:gradle:8") {
    Write-Host "✅ Android Gradle plugin 8.x detected" -ForegroundColor Green
} else {
    Write-Host "⚠️ Android Gradle plugin may be outdated" -ForegroundColor Yellow
}

# Check app/build.gradle
$appGradle = Get-Content "android/app/build.gradle" -ErrorAction SilentlyContinue
if ($appGradle -match "compileSdkVersion 3[4-9]") {
    Write-Host "✅ compileSdkVersion 34+ detected" -ForegroundColor Green
} else {
    Write-Host "⚠️ compileSdkVersion may be outdated (need 34+)" -ForegroundColor Yellow
}

# Check signing config
if (Test-Path "android/key.properties") {
    Write-Host "✅ key.properties exists" -ForegroundColor Green
} else {
    Write-Host "⚠️ key.properties not found - release signing may fail" -ForegroundColor Yellow
}

# --- Step 4: Run Verbose Build ---
Write-Host "`n🔍 Running verbose APK build..." -ForegroundColor Yellow
Write-Host "   (This will take several minutes - captures detailed error log)" -ForegroundColor Gray

flutter build apk --release -v 2>&1 | Tee-Object -FilePath "android_apk_build_verbose.log"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ APK build successful!" -ForegroundColor Green
    Write-Host "   Artifact: build/app/outputs/flutter-apk/app-release.apk" -ForegroundColor Green

    Write-Host "`n🔍 Now attempting AAB build..." -ForegroundColor Yellow
    flutter build appbundle --release -v 2>&1 | Tee-Object -FilePath "android_aab_build_verbose.log"

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ AAB build successful!" -ForegroundColor Green
        Write-Host "   Artifact: build/app/outputs/bundle/release/app-release.aab" -ForegroundColor Green
    } else {
        Write-Host "❌ AAB build failed (see android_aab_build_verbose.log)" -ForegroundColor Red
    }
} else {
    Write-Host "❌ APK build failed (see android_apk_build_verbose.log)" -ForegroundColor Red
}

# --- Step 5: Generate Diagnostics Report ---
Write-Host "`n📋 Generating diagnostics report..." -ForegroundColor Yellow

$report = @"
Android Build Diagnostics Report
=================================
Date: $(Get-Date)

Build Logs:
  - flutter_doctor_report.txt
  - android_apk_build_verbose.log
  - android_aab_build_verbose.log

Next Steps:
  1. Review android_apk_build_verbose.log for specific error
  2. Look for lines with "ERROR", "FAILED", "error:"
  3. Check ANDROID_BUILD_TROUBLESHOOTING.md for fixes
  4. Common issues:
     - Gradle version mismatch (need 8.2+)
     - SDK version mismatch (need compileSdk 34+)
     - Missing key.properties for signing
     - Plugin version conflicts
     - ProGuard/minify issues

Common Fixes:
  1. Update Gradle:
     android/gradle/wrapper/gradle-wrapper.properties → gradle-8.2-all.zip

  2. Update Gradle Plugin:
     android/build.gradle → com.android.tools.build:gradle:8.2.0

  3. Update SDK versions:
     android/app/build.gradle → compileSdkVersion 34, minSdkVersion 21

  4. Update Flutter plugins:
     flutter pub upgrade
     flutter clean && flutter pub get

  5. If ProGuard error, check android/app/proguard-rules.pro

"@

$report | Out-File -FilePath "android_diagnostics_report.txt"
Get-Content "android_diagnostics_report.txt" | Write-Host

Write-Host "`n🎯 Diagnostics complete!" -ForegroundColor Green
Write-Host "   Reports saved to:" -ForegroundColor Gray
Write-Host "   - flutter_doctor_report.txt" -ForegroundColor Gray
Write-Host "   - android_apk_build_verbose.log" -ForegroundColor Gray
Write-Host "   - android_aab_build_verbose.log" -ForegroundColor Gray
Write-Host "   - android_diagnostics_report.txt" -ForegroundColor Gray

Write-Host "`n📖 See ANDROID_BUILD_TROUBLESHOOTING.md for detailed solutions" -ForegroundColor Cyan
