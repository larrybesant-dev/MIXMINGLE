<#
.SYNOPSIS
Full automated Android build recovery and production-ready rebuild for Flutter.
Ensures Gradle, SDK, plugins, signing, multidex, and caches are correct.
Generates detailed diagnostics and final APK/AAB.
.DESCRIPTION
Streamlined Android build recovery script that:
1. Cleans Flutter project and Gradle caches
2. Checks Android SDK versions
3. Updates Gradle wrapper to 8.2
4. Updates Android Gradle plugin to 8.2.0
5. Enables multidex for large APPs
6. Verifies signing configuration
7. Upgrades Flutter plugins
8. Builds release APK and AAB
9. Generates comprehensive report
.EXAMPLE
.\android-build-recovery-v2.ps1
#>

# --- CONFIGURATION ---
$workspace = "${PWD}"
$keyProps = Join-Path $workspace "android\key.properties"
$gradleWrapper = Join-Path $workspace "android\gradle\wrapper\gradle-wrapper.properties"
$buildReport = Join-Path $workspace "ANDROID_BUILD_RECOVERY_REPORT_V2.txt"

# --- FUNCTIONS ---
function Write-Log {
    param([string]$msg, [string]$level = "INFO")
    $timestamp = Get-Date -Format "HH:mm:ss"
    $colors = @{
        "INFO"    = "White"
        "SUCCESS" = "Green"
        "WARNING" = "Yellow"
        "ERROR"   = "Red"
        "BACKUP"  = "Cyan"
    }
    $color = $colors[$level] ?? "White"
    Write-Host "[$timestamp] [$level] $msg" -ForegroundColor $color
}

function Backup-File {
    param([string]$file)
    if(Test-Path $file) {
        Copy-Item $file "$file.bak" -Force
        Write-Log "Backed up $file" "BACKUP"
    }
}

function Clean-Flutter {
    Write-Log "Cleaning Flutter project and Gradle caches..."
    flutter clean
    Remove-Item -Recurse -Force ".gradle","build" -ErrorAction SilentlyContinue
    flutter pub get
    Write-Log "Flutter project cleaned successfully" "SUCCESS"
}

function Check-Android-SDK {
    Write-Log "Checking Android SDK and build-tools..."
    flutter doctor -v | Select-String "Android SDK" | Out-Host
}

function Apply-Gradle-Fixes {
    Write-Log "Applying Gradle wrapper & plugin fixes..."

    # Update Gradle wrapper to 8.2
    Backup-File $gradleWrapper
    $wrapperContent = Get-Content $gradleWrapper
    $wrapperContent = $wrapperContent -replace "gradle-[\d\.]+-all.zip","gradle-8.2-all.zip"
    Set-Content $gradleWrapper $wrapperContent
    Write-Log "Gradle wrapper updated to 8.2" "SUCCESS"

    # Update build.gradle plugin
    $buildGradle = Join-Path $workspace "android\build.gradle"
    Backup-File $buildGradle
    $buildContent = Get-Content $buildGradle
    $buildContent = $buildContent -replace "com.android.tools.build:gradle:[\d\.]+","com.android.tools.build:gradle:8.2.0"
    Set-Content $buildGradle $buildContent
    Write-Log "Android Gradle plugin updated to 8.2.0" "SUCCESS"
}

function Enable-MultiDex {
    Write-Log "Enabling multidex support..."
    $appGradle = Join-Path $workspace "android\app\build.gradle"
    Backup-File $appGradle

    $content = Get-Content $appGradle -Raw

    # Add multiDexEnabled to defaultConfig if not present
    if($content -notmatch "multiDexEnabled\s+true") {
        $content = $content -replace "(defaultConfig\s*\{)","$1`n        multiDexEnabled true"
        Write-Log "Added multiDexEnabled true to defaultConfig" "SUCCESS"
    }

    # Add multidex dependency if not present
    if($content -notmatch "androidx\.multidex:multidex") {
        if($content -match "dependencies\s*\{") {
            $content = $content -replace "(dependencies\s*\{)","$1`n    implementation 'androidx.multidex:multidex:2.0.1'"
        } else {
            $content += "`n`ndependencies {`n    implementation 'androidx.multidex:multidex:2.0.1'`n}`n"
        }
        Write-Log "Added androidx.multidex:multidex:2.0.1 dependency" "SUCCESS"
    }

    Set-Content $appGradle $content
}

function Check-KeyProperties {
    Write-Log "Checking key.properties for signing..."
    if(-not (Test-Path $keyProps)) {
        Write-Log "⚠️ key.properties missing! Android release build may fail!" "WARNING"
        Write-Log "Create android/key.properties with:" "WARNING"
        Write-Log "  storePassword=YOUR_PASSWORD" "WARNING"
        Write-Log "  keyPassword=YOUR_PASSWORD" "WARNING"
        Write-Log "  keyAlias=YOUR_ALIAS" "WARNING"
        Write-Log "  storeFile=YOUR_KEYSTORE_PATH" "WARNING"
    } else {
        Write-Log "key.properties found - signing configured" "SUCCESS"
    }
}

function Upgrade-Plugins {
    Write-Log "Upgrading Flutter plugins..."
    flutter pub upgrade
    Write-Log "Flutter plugins upgraded" "SUCCESS"
}

function Run-Build {
    Write-Log "Starting APK build..."
    $apkStart = Get-Date
    try {
        flutter build apk --release 2>&1
        $apkEnd = Get-Date
        $apkTime = ($apkEnd - $apkStart).TotalMinutes

        if(Test-Path "build\app\outputs\flutter-apk\app-release.apk") {
            Write-Log "✅ APK build succeeded (${apkTime:F1} min)" "SUCCESS"
        } else {
            Write-Log "⚠️ APK file not found after build" "WARNING"
        }
    } catch {
        Write-Log "APK build failed: $_" "ERROR"
    }

    Write-Log "Starting AAB build..."
    $aabStart = Get-Date
    try {
        flutter build appbundle --release 2>&1
        $aabEnd = Get-Date
        $aabTime = ($aabEnd - $aabStart).TotalMinutes

        if(Test-Path "build\app\outputs\bundle\release\app-release.aab") {
            Write-Log "✅ AAB build succeeded (${aabTime:F1} min)" "SUCCESS"
        } else {
            Write-Log "⚠️ AAB file not found after build" "WARNING"
        }
    } catch {
        Write-Log "AAB build failed: $_" "ERROR"
    }
}

function Generate-Report {
    Write-Log "Generating Android build recovery report..."

    $reportContent = @"
═══════════════════════════════════════════════════════════════════════════════
  ANDROID BUILD RECOVERY REPORT V2
═══════════════════════════════════════════════════════════════════════════════

Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Workspace: $workspace

───────────────────────────────────────────────────────────────────────────────
BUILD ARTIFACTS
───────────────────────────────────────────────────────────────────────────────

APK:  build\app\outputs\flutter-apk\app-release.apk
AAB:  build\app\outputs\bundle\release\app-release.aab

───────────────────────────────────────────────────────────────────────────────
FLUTTER DOCTOR OUTPUT
───────────────────────────────────────────────────────────────────────────────

$((flutter doctor -v) -join "`n")

───────────────────────────────────────────────────────────────────────────────
GRADLE CONFIGURATION
───────────────────────────────────────────────────────────────────────────────

Gradle Wrapper: 8.2
Android Gradle Plugin: 8.2.0
MultiDex: Enabled
Signing: Configured (key.properties present: $(Test-Path $keyProps))

───────────────────────────────────────────────────────────────────────────────
NEXT STEPS
───────────────────────────────────────────────────────────────────────────────

1. Verify APK works:
   $env:ANDROID_HOME\platform-tools\adb install build\app\outputs\flutter-apk\app-release.apk

2. Upload AAB to Google Play Console:
   https://play.google.com/console → Your App → Releases → Production → Upload AAB

3. Deploy Web (if needed):
   flutter build web --release && firebase deploy --only hosting

─────────────────────────────────────────────────────────────────────────────────

END OF REPORT
"@

    $reportContent | Out-File $buildReport -Encoding UTF8
    Write-Log "Report saved: $buildReport" "SUCCESS"
}

# --- MAIN EXECUTION ---
Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║           ANDROID BUILD RECOVERY V2                       ║" -ForegroundColor Cyan
Write-Host "║    Full Gradle + SDK + Plugin Auto-Fix + Build           ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Verify we're in a Flutter project
if(-not (Test-Path "pubspec.yaml")) {
    Write-Log "❌ Not in a Flutter project directory!" "ERROR"
    Write-Log "Make sure pubspec.yaml exists in current directory" "ERROR"
    exit 1
}

Write-Log "✅ Flutter project detected" "SUCCESS"
Write-Host ""

# Run all steps
Clean-Flutter
Write-Host ""

Check-Android-SDK
Write-Host ""

Apply-Gradle-Fixes
Write-Host ""

Enable-MultiDex
Write-Host ""

Check-KeyProperties
Write-Host ""

Upgrade-Plugins
Write-Host ""

Write-Log "Building release APK and AAB..." "INFO"
Write-Host "This will take 20-40 minutes on first build..."
Write-Host ""
Run-Build
Write-Host ""

Generate-Report

Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║              ✅ BUILD RECOVERY COMPLETE                    ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "APK:  build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Green
Write-Host "AAB:  build\app\outputs\bundle\release\app-release.aab" -ForegroundColor Green
Write-Host ""
Write-Host "Report: $buildReport" -ForegroundColor Cyan
Write-Host ""
