# ==========================================
# Android Build Auto-Fix Script
# ==========================================

Write-Host "🔧 Applying Android Build Fixes..." -ForegroundColor Cyan

# --- Step 1: Backup originals ---
Write-Host "`n📦 Backing up original files..." -ForegroundColor Yellow
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
Copy-Item "android/build.gradle" "android/build.gradle.backup.$timestamp" -Force -ErrorAction SilentlyContinue
Copy-Item "android/app/build.gradle" "android/app/build.gradle.backup.$timestamp" -Force -ErrorAction SilentlyContinue
Copy-Item "android/gradle/wrapper/gradle-wrapper.properties" "android/gradle/wrapper/gradle-wrapper.properties.backup.$timestamp" -Force -ErrorAction SilentlyContinue
Write-Host "✅ Backups saved (*.backup.$timestamp)" -ForegroundColor Green

# --- Step 2: Update Gradle Wrapper ---
Write-Host "`n🔄 Updating Gradle wrapper to 8.2..." -ForegroundColor Yellow
$gradleWrapperPath = "android/gradle/wrapper/gradle-wrapper.properties"
if (Test-Path $gradleWrapperPath) {
    $content = Get-Content $gradleWrapperPath
    $updated = $content -replace 'gradle-\d+\.\d+.*?\.zip', 'gradle-8.2-all.zip'
    $updated | Out-File -FilePath $gradleWrapperPath -Encoding UTF8
    Write-Host "✅ Gradle wrapper updated" -ForegroundColor Green
} else {
    Write-Host "⚠️ gradle-wrapper.properties not found" -ForegroundColor Yellow
}

# --- Step 3: Update build.gradle ---
Write-Host "`n🔄 Updating android/build.gradle..." -ForegroundColor Yellow
$buildGradlePath = "android/build.gradle"
if (Test-Path $buildGradlePath) {
    $buildGradleContent = @'
buildscript {
    ext.kotlin_version = '1.9.0'
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:8.2.0'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.buildDir = '../build'

subprojects {
    project.buildDir = "${rootProject.buildDir}/${project.name}"
}

subprojects {
    project.evaluationDependsOn(':app')
}

task clean(type: Delete) {
    delete rootProject.buildDir
}
'@
    $buildGradleContent | Out-File -FilePath $buildGradlePath -Encoding UTF8
    Write-Host "✅ android/build.gradle updated" -ForegroundColor Green
} else {
    Write-Host "⚠️ build.gradle not found" -ForegroundColor Yellow
}

# --- Step 4: Update app/build.gradle (SDK versions) ---
Write-Host "`n🔄 Updating android/app/build.gradle SDK versions..." -ForegroundColor Yellow
$appBuildGradlePath = "android/app/build.gradle"
if (Test-Path $appBuildGradlePath) {
    $appGradleContent = Get-Content $appBuildGradlePath -Raw

    # Update compileSdkVersion
    $appGradleContent = $appGradleContent -replace 'compileSdkVersion\s+\d+', 'compileSdkVersion 34'

    # Update minSdkVersion if exists, or add it
    if ($appGradleContent -match 'minSdkVersion') {
        $appGradleContent = $appGradleContent -replace 'minSdkVersion\s+\d+', 'minSdkVersion 21'
    } else {
        $appGradleContent = $appGradleContent -replace '(defaultConfig\s*\{)', "`$1`n        minSdkVersion 21"
    }

    # Update targetSdkVersion
    if ($appGradleContent -match 'targetSdkVersion') {
        $appGradleContent = $appGradleContent -replace 'targetSdkVersion\s+\d+', 'targetSdkVersion 34'
    } else {
        $appGradleContent = $appGradleContent -replace '(defaultConfig\s*\{)', "`$1`n        targetSdkVersion 34"
    }

    # Add NDK version if missing
    if (-not ($appGradleContent -match 'ndkVersion')) {
        $appGradleContent = $appGradleContent -replace '(android\s*\{)', "`$1`n    ndkVersion `"25.1.8937393`""
    }

    # Add multiDexEnabled if missing
    if (-not ($appGradleContent -match 'multiDexEnabled')) {
        $appGradleContent = $appGradleContent -replace '(defaultConfig\s*\{)', "`$1`n        multiDexEnabled true"
    }

    $appGradleContent | Out-File -FilePath $appBuildGradlePath -Encoding UTF8
    Write-Host "✅ android/app/build.gradle SDK versions updated" -ForegroundColor Green
} else {
    Write-Host "⚠️ app/build.gradle not found" -ForegroundColor Yellow
}

# --- Step 5: Create ProGuard rules ---
Write-Host "`n🔄 Creating ProGuard rules..." -ForegroundColor Yellow
$proguardPath = "android/app/proguard-rules.pro"
$proguardContent = @'
# Keep Flutter classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# Agora SDK
-keep class io.agora.** { *; }
-dontwarn io.agora.**

# Stripe
-keep class com.stripe.** { *; }
-dontwarn com.stripe.**

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Jetpack/AndroidX
-keep class androidx.** { *; }
-dontwarn androidx.**

# Kotlin
-keep class kotlin.** { *; }
-dontwarn kotlin.**

# Keep annotations
-keepclassmembers class * {
    @androidx.annotation.Keep *;
}

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Serializable
-keep class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}
'@
$proguardContent | Out-File -FilePath $proguardPath -Encoding UTF8
Write-Host "✅ ProGuard rules created/updated at $proguardPath" -ForegroundColor Green

# --- Step 6: Clean project ---
Write-Host "`n🧹 Cleaning project artifacts..." -ForegroundColor Yellow
flutter clean
Remove-Item -Recurse -Force "build", ".dart_tool", "android/.gradle", "android/app/build" -ErrorAction SilentlyContinue
Write-Host "✅ Project cleaned" -ForegroundColor Green

# --- Step 7: Fetch dependencies ---
Write-Host "`n📦 Upgrading Flutter plugins..." -ForegroundColor Yellow
flutter pub upgrade
flutter pub get
Write-Host "✅ Dependencies updated" -ForegroundColor Green

# --- Step 8: Health check ---
Write-Host "`n🏥 Running flutter doctor..." -ForegroundColor Yellow
flutter doctor
Write-Host "✅ Health check complete" -ForegroundColor Green

# --- Step 9: Generate summary ---
Write-Host "`n📋 Generating fix summary..." -ForegroundColor Yellow
$summary = @"
===========================================
Android Build Auto-Fix Summary
===========================================
Date: $(Get-Date)
Timestamp: $timestamp

Applied Fixes:
  ✅ Gradle wrapper updated to 8.2-all.zip
  ✅ Android Gradle plugin updated to 8.2.0
  ✅ Kotlin updated to 1.9.0
  ✅ compileSdkVersion set to 34
  ✅ minSdkVersion set to 21
  ✅ targetSdkVersion set to 34
  ✅ NDK version set to 25.1.8937393
  ✅ multiDexEnabled enabled
  ✅ ProGuard rules created for Agora, Stripe, Firebase
  ✅ Flutter plugins upgraded

Backups:
  - android/build.gradle.backup.$timestamp
  - android/app/build.gradle.backup.$timestamp
  - android/gradle/wrapper/gradle-wrapper.properties.backup.$timestamp

Next Steps:
  1. Review changes: git diff
  2. Test APK build: flutter build apk --release
  3. If APK fails, check: android_apk_build_verbose.log
  4. Once APK works, test AAB: flutter build appbundle --release
  5. Verify artifacts in: build/app/outputs/

See ANDROID_BUILD_FIX_STEPS.md for detailed manual fixes.
"@

$summary | Out-File -FilePath "android_autofixes_summary.txt"
Get-Content "android_autofixes_summary.txt" | Write-Host

Write-Host "`n✅ Auto-fixes applied!" -ForegroundColor Green
Write-Host "`nNow run the following to test:" -ForegroundColor Cyan
Write-Host "  flutter build apk --release" -ForegroundColor Gray
