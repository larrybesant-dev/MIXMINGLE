# Android Build Fix — Step-by-Step Guide

## Current Status

✅ Diagnostic script has been run
✅ Logs generated:

- `android_apk_build_verbose.log` — APK build details
- `android_diagnostics_report.txt` — Summary
- `flutter_doctor_report.txt` — System health

Now we need to **identify the exact error** and apply the fix.

---

## Step 1️⃣: Find the Exact Error

Open the verbose log and search for the error:

```powershell
notepad android_apk_build_verbose.log
```

**Search for** (Ctrl+F):

- `ERROR:`
- `FAILED`
- `error:`
- `Failed to resolve`
- `Duplicate class`
- `cannot find symbol`

**Copy the error message** and reference it in Step 2 below.

---

## Step 2️⃣: Apply Common Fixes

### Fix A: Gradle & Kotlin Versions

**File**: `android/gradle/wrapper/gradle-wrapper.properties`

```properties
distributionUrl=https\://services.gradle.org/distributions/gradle-8.2-all.zip
```

**File**: `android/build.gradle`

```gradle
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
```

---

### Fix B: SDK Versions

**File**: `android/app/build.gradle`

```gradle
android {
    compileSdkVersion 34
    ndkVersion "25.1.8937393"

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_11
        targetCompatibility JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId "com.yourcompany.mixmingle"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
        multiDexEnabled true  // Important for large apps
    }
}
```

---

### Fix C: ProGuard Rules (if minifying)

**File**: `android/app/proguard-rules.pro`

```proguard
# Keep Flutter classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

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
-keepclassmembers class * {
    @androidx.annotation.Keep *;
}
```

**File**: `android/app/build.gradle` (inside `android {}` block)

```gradle
buildTypes {
    debug {
        debuggable true
        minifyEnabled false
    }
    release {
        signingConfig signingConfigs.release
        minifyEnabled true        // Enable minification for release
        shrinkResources true      // Remove unused resources
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
}
```

---

### Fix D: Signing Configuration

**File**: `android/key.properties` (create if missing)

```properties
storeFile=../keystore.jks
storePassword=your_store_password
keyAlias=your_key_alias
keyPassword=your_key_password
```

**File**: `android/app/build.gradle` (update signing config)

```gradle
signingConfigs {
    debug {
        keyAlias 'androiddebugkey'
        keyPassword 'android'
        storeFile file('debug.keystore')
        storePassword 'android'
    }
    release {
        final keystoreProperties = new Properties()
        final keystorePropertiesFile = rootProject.file('key.properties')
        if (keystorePropertiesFile.exists()) {
            keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
        }
        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
        storePassword keystoreProperties['storePassword']
    }
}

buildTypes {
    debug {
        signingConfig signingConfigs.debug
    }
    release {
        signingConfig signingConfigs.release
        minifyEnabled true
        shrinkResources true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
}
```

---

### Fix E: Plugin Versions

**File**: `pubspec.yaml` — Update to latest compatible versions:

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Video
  agora_rtc_engine: ^6.2.0
  agora_uikit: ^1.3.0

  # Payments
  flutter_stripe: ^10.0.0

  # Firebase
  firebase_core: ^2.24.0
  firebase_auth: ^4.15.0
  cloud_firestore: ^4.14.0
  firebase_functions: ^4.5.0
  firebase_storage: ^11.6.0

  # Other
  http: ^1.1.0
  provider: ^6.0.0
```

Then:

```powershell
flutter pub upgrade
flutter clean
flutter pub get
```

---

### Fix F: Temporary Debug Build (if urgent)

If you need to deploy **quickly** while investigating:

```powershell
flutter build apk --release --no-shrink
```

This:

- ✅ Skips ProGuard/R8 minification
- ✅ Faster build
- ✅ Larger APK size
- ✅ Helps isolate minification issues

---

## Step 3️⃣: Clean & Rebuild

```powershell
# Full clean
flutter clean
Remove-Item -Recurse -Force "build", ".dart_tool" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "android/.gradle", "android/app/build" -ErrorAction SilentlyContinue

# Update dependencies
flutter pub upgrade
flutter pub get

# Verify health
flutter doctor
```

---

## Step 4️⃣: Test APK Build

```powershell
flutter build apk --release
```

**If APK succeeds:**

- ✅ Your Gradle/plugin config is correct
- ✅ Signing works
- ✅ Next: Test AAB

**If APK fails:**

- ❌ Check error again
- ❌ Review Step 2 fixes
- ❌ Try `--no-shrink` to isolate minification issue

---

## Step 5️⃣: Test AAB Build (if APK works)

```powershell
flutter build appbundle --release
```

**If AAB succeeds:**

- ✅ Ready to upload to Play Store

**If AAB fails:**

- ❌ Usually signing/bundling issue
- ❌ Review Fix D (signing config)

---

## Step 6️⃣: Verify Artifacts

```powershell
# Check APK
Test-Path "build/app/outputs/flutter-apk/app-release.apk"

# Check AAB
Test-Path "build/app/outputs/bundle/release/app-release.aab"
```

Both should return `True`.

---

## Step 7️⃣: Deploy Web (independent of Android)

While Android finishes building, deploy Web:

```powershell
flutter clean
flutter pub get
flutter build web --release
firebase deploy --only hosting
```

This works independently and Web should already be live.

---

## Reference: Common Error Messages

| Error                                          | Cause                     | Fix                                    |
| ---------------------------------------------- | ------------------------- | -------------------------------------- |
| `Gradle 7.x not compatible`                    | Gradle version too old    | Update to `gradle-8.2-all.zip`         |
| `Android Gradle plugin version X incompatible` | Plugin version too old    | Update to `gradle:8.2.0`               |
| `compileSdkVersion too low`                    | SDK version too old       | Update to `compileSdkVersion 34`       |
| `Failed to resolve io.agora`                   | Agora plugin issue        | `flutter pub upgrade agora_rtc_engine` |
| `Failed to resolve com.stripe`                 | Stripe plugin issue       | `flutter pub upgrade flutter_stripe`   |
| `Duplicate class com.google.android.gms`       | Plugin conflict           | Usually fixed by updating Firebase     |
| `cannot find symbol`                           | Java/Kotlin compile error | Check ProGuard rules                   |
| `Keystore not found`                           | Signing config issue      | Create `key.properties` & verify path  |

---

## Troubleshooting Checklist

- [ ] Read the exact error from `android_apk_build_verbose.log`
- [ ] Updated Gradle version to 8.2+
- [ ] Updated Android Gradle plugin to 8.2.0
- [ ] Updated SDK versions (34+)
- [ ] Updated Kotlin to 1.9.0+
- [ ] Updated Flutter plugins (`flutter pub upgrade`)
- [ ] Added ProGuard rules for Agora, Stripe, Firebase
- [ ] Created/verified `key.properties`
- [ ] Verified signing config in `build.gradle`
- [ ] Ran `flutter clean` and `flutter pub get`
- [ ] APK builds successfully
- [ ] AAB builds successfully

---

## When Ready for Production

```powershell
# Web deployment (if not already done)
flutter build web --release
firebase deploy --only hosting

# Android submission
# APK: build/app/outputs/flutter-apk/app-release.apk
# AAB: build/app/outputs/bundle/release/app-release.aab
# Upload AAB to Google Play Console

# iOS (if macOS available)
flutter build ios --release
```

---

**Need detailed reference?** Check:

- [ANDROID_BUILD_TROUBLESHOOTING.md](ANDROID_BUILD_TROUBLESHOOTING.md) — Comprehensive guide
- [ANDROID_BUILD_FIXES.md](ANDROID_BUILD_FIXES.md) — Quick reference

**Date**: February 6, 2026
**Status**: Ready to fix
