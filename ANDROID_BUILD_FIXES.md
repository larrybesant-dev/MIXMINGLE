# Android Build Fix - Quick Reference

## 🔴 Gradle Errors - Quick Fixes

### Error: "Gradle 7.x not compatible"
**Solution:**
```powershell
# Edit android/gradle/wrapper/gradle-wrapper.properties
gradle-7.x-all.zip  →  gradle-8.2-all.zip
```

### Error: "Android Gradle plugin version X incompatible"
**Solution:**
```gradle
// android/build.gradle
classpath 'com.android.tools.build:gradle:8.2.0'  // Update to 8.2.0
```

### Error: "compileSdkVersion too old"
**Solution:**
```gradle
// android/app/build.gradle
compileSdkVersion 34  // Must be 34 or higher
minSdkVersion 21      // Min 21 for modern Flutter
targetSdkVersion 34   // Match compileSdk
```

---

## 🔴 Plugin Errors - Quick Fixes

### Error: "Agora plugin not found / Build failure"
```powershell
# Update pubspec.yaml
flutter pub upgrade agora_rtc_engine agora_uikit

# Or specific version
flutter pub add agora_rtc_engine:^6.2.0
flutter pub add agora_uikit:^1.3.0

flutter pub get
flutter clean
flutter build apk --release
```

### Error: "Stripe integration broken"
```powershell
# Update Stripe
flutter pub upgrade flutter_stripe

# Or specific version
flutter pub add flutter_stripe:^10.0.0

flutter pub get
flutter clean
flutter build apk --release
```

### Error: "Firebase plugins mismatch"
```powershell
# Upgrade all Firebase plugins together
flutter pub upgrade firebase_core firebase_auth cloud_firestore firebase_functions

flutter pub get
flutter clean
flutter build apk --release
```

---

## 🔴 Signing / Key Errors - Quick Fixes

### Error: "key.properties not found"
**Solution:**
1. Create `android/key.properties`:
```properties
storeFile=../keystore.jks
storePassword=your_password
keyAlias=your_alias
keyPassword=your_password
```

2. Update `android/app/build.gradle`:
```gradle
signingConfigs {
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
    release {
        signingConfig signingConfigs.release
        minifyEnabled false
    }
}
```

### Error: "Invalid keystore / password incorrect"
```powershell
# Recreate keystore
keytool -genkey -v -keystore ../keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias release
```

---

## 🔴 ProGuard / Minification Errors - Quick Fixes

### Error: "ProGuard configuration error"
**Solution:**
Create/update `android/app/proguard-rules.pro`:
```proguard
# Agora
-keep class io.agora.** { *; }
-dontwarn io.agora.**

# Stripe
-keep class com.stripe.** { *; }
-dontwarn com.stripe.**

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Flutter & plugins
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**
```

**In `android/app/build.gradle`:**
```gradle
buildTypes {
    release {
        minifyEnabled true  // or false if having ProGuard issues
        shrinkResources true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        signingConfig signingConfigs.release
    }
}
```

---

## 🔴 Kotlin / Java Compile Errors - Quick Fixes

### Error: "Java version incompatible"
```gradle
// android/app/build.gradle
compileOptions {
    sourceCompatibility JavaVersion.VERSION_11
    targetCompatibility JavaVersion.VERSION_11
}

kotlinOptions {
    jvmTarget = "11"
}
```

### Error: "Kotlin version X not compatible"
```gradle
// android/build.gradle
ext.kotlin_version = '1.9.0'
```

---

## 🔴 Memory / NDK Errors - Quick Fixes

### Error: "Out of memory during build"
```powershell
# Windows: Increase heap size
# Set environment variable:
[Environment]::SetEnvironmentVariable('GRADLE_OPTS', '-Xmx4096m', 'User')

# Then restart PowerShell and rebuild
flutter clean
flutter pub get
flutter build apk --release
```

### Error: "NDK version mismatch"
```gradle
// android/app/build.gradle
android {
    ndkVersion "25.1.8937393"  // Specify explicit NDK version
}
```

---

## ✅ Verification Steps

After applying fixes:

```powershell
# 1. Clean everything
flutter clean
Remove-Item -Recurse -Force "build", ".dart_tool", "android/.gradle" -ErrorAction SilentlyContinue

# 2. Fresh dependencies
flutter pub get

# 3. Check health
flutter doctor

# 4. Test APK build first
flutter build apk --release

# 5. If APK works, test AAB
flutter build appbundle --release

# 6. Verify artifacts exist
Test-Path "build/app/outputs/flutter-apk/app-release.apk"
Test-Path "build/app/outputs/bundle/release/app-release.aab"
```

---

## 🎯 If All Fails

```powershell
# Nuclear reset
flutter clean
Remove-Item -Recurse -Force "build", ".dart_tool", "android/.gradle", "android/app/build" -ErrorAction SilentlyContinue

# Full refresh
flutter pub get
flutter pub upgrade

# Try APK with maximum verbosity
flutter build apk --release -v 2>&1 | Tee-Object -FilePath "full_debug.log"

# Search log for "ERROR" or "FAILED"
Select-String -Path "full_debug.log" -Pattern "ERROR|FAILED|error" | Head -20
```

---

**Use this when:**
1. Running `diagnose-android-build.ps1` identifies specific error
2. Need quick fix for known issue
3. Gradle/plugin/SDK version mismatch

**Reference:** See `ANDROID_BUILD_TROUBLESHOOTING.md` for detailed explanations
