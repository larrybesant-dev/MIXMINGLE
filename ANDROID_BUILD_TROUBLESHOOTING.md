# Android Build Troubleshooting Guide

## Problem
```
Execution failed for task ':app:compileFlutterBuildRelease'.
> Process 'command 'C:\Users\LARRY\flutter\bin\flutter.bat'' finished with non-zero exit value 1
```

This is a **generic Flutter/Gradle failure** indicating something in the Flutter build is breaking for release mode (not Web-specific).

---

## 1️⃣ Get Full Build Logs

Run with verbose flag to identify the actual error:

```powershell
flutter build appbundle --release -v
```

**Look for:**
- Missing dependencies
- Version conflicts
- Kotlin/Java compile errors
- Flutter plugin issues (Agora, Stripe)
- ProGuard/R8 obfuscation problems

---

## 2️⃣ Common Fixes for Gradle Release Build

### Step 1: Clean & Fetch

```powershell
flutter clean
flutter pub get
```

### Step 2: Update Gradle Wrapper

**File**: `android/gradle/wrapper/gradle-wrapper.properties`

Ensure **Gradle 8.2+** (Flutter 3.38+ requires 8.x):

```properties
distributionUrl=https\://services.gradle.org/distributions/gradle-8.2-all.zip
```

### Step 3: Update Android Gradle Plugin

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
```

### Step 4: Update Compile & Min SDK

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
        applicationId "com.example.mixmingle"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
    }
}
```

### Step 5: Add ProGuard Rules (if minifyEnabled)

**File**: `android/app/proguard-rules.pro`

```proguard
# Agora SDK
-keep class io.agora.** { *; }
-dontwarn io.agora.**

# Stripe
-keep class com.stripe.** { *; }
-dontwarn com.stripe.**

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**
```

**In `android/app/build.gradle`**:

```gradle
buildTypes {
    release {
        minifyEnabled true
        shrinkResources true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        signingConfig signingConfigs.release
    }
}
```

### Step 6: Verify Release Signing Config

**File**: `android/key.properties`

Make sure it exists and has correct values:

```properties
storeFile=/path/to/your/keystore.jks
storePassword=your_store_password
keyAlias=your_key_alias
keyPassword=your_key_password
```

**File**: `android/app/build.gradle`

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
        minifyEnabled false
        shrinkResources false
    }
}
```

---

## 3️⃣ Test APK First (Isolate Issue)

APK builds are simpler than AAB. If APK succeeds but AAB fails, the issue is specific to bundling:

```powershell
flutter build apk --release -v
```

---

## 4️⃣ Update Flutter & Plugins

```powershell
flutter pub outdated
flutter pub upgrade
flutter pub get
```

Then rebuild:

```powershell
flutter clean
flutter pub get
flutter build appbundle --release -v
```

---

## 5️⃣ Common Plugin Issues

### Agora SDK
- Ensure `agora_uikit` or `agora_rtc_engine` is latest
- Check version in `pubspec.yaml`

```yaml
dependencies:
  agora_rtc_engine: ^6.2.0  # or latest
  agora_uikit: ^1.3.0       # or latest
```

### Stripe
- Ensure `flutter_stripe` is latest
- Android SDK 21+

```yaml
dependencies:
  flutter_stripe: ^10.0.0  # or latest
```

### Firebase
- Ensure all Firebase plugins match versions
- Recent versions require Gradle 8.2+

```yaml
dependencies:
  firebase_core: ^2.24.0
  firebase_auth: ^4.15.0
  cloud_firestore: ^4.14.0
  firebase_functions: ^4.5.0
```

---

## 6️⃣ Full Recovery Steps

If all else fails, do a **complete reset**:

```powershell
# Full clean
flutter clean
Remove-Item -Recurse -Force "build", ".dart_tool", "android/.gradle"

# Fresh pub get
flutter pub get

# Rebuild Android directory
flutter pub get
flutter doctor

# Try APK first
flutter build apk --release -v

# If APK works, try AAB
flutter build appbundle --release -v
```

---

## Diagnosis Checklist

- [ ] Run verbose build log `-v` to identify actual error
- [ ] Gradle wrapper: 8.2+
- [ ] Gradle plugin: 8.2.0+
- [ ] Kotlin: 1.9.0+
- [ ] compileSdkVersion: 34
- [ ] minSdkVersion: 21
- [ ] targetSdkVersion: 34
- [ ] ProGuard rules added for Agora, Stripe
- [ ] `key.properties` exists and has correct signing config
- [ ] Flutter plugins up to date (`flutter pub upgrade`)
- [ ] APK builds successfully
- [ ] AAB builds successfully

---

## Next Steps

1. **Run verbose build**:
   ```powershell
   flutter build appbundle --release -v 2>&1 | Tee-Object -FilePath android_build_verbose.log
   ```

2. **Check log for specific error** in `android_build_verbose.log`

3. **Apply relevant fix** from sections above

4. **Test APK**:
   ```powershell
   flutter build apk --release
   ```

5. **Test AAB**:
   ```powershell
   flutter build appbundle --release
   ```

---

**Date**: February 6, 2026
**Status**: Troubleshooting Guide
