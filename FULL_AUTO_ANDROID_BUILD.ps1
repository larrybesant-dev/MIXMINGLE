# ==========================================
# MIX & MINGLE — FULL AUTO ANDROID BUILD
# ==========================================

$root = "C:\Users\LARRY\MIXMINGLE"
$android = "$root\android"
$keystoreDir = "$android\keystore"
$keystorePath = "$keystoreDir\release.keystore"
$keyAlias = "mixmingle"
$keyPass = "mixmingle123"
$storePass = "mixmingle123"

Set-Location $root
Write-Host "🚀 MIX&MINGLE FULL AUTO BUILD STARTING..."

# ------------------------------------------
# OPEN IMPORTANT FILES FOR EDITING
# ------------------------------------------
Invoke-Item "$android\build.gradle"
Invoke-Item "$android\app\build.gradle"
Invoke-Item "$android\gradle\wrapper\gradle-wrapper.properties"
Invoke-Item "$root\pubspec.yaml"

# ------------------------------------------
# ENSURE KEYSTORE EXISTS
# ------------------------------------------
if (!(Test-Path $keystoreDir)) {
    New-Item -ItemType Directory -Path $keystoreDir | Out-Null
}

if (!(Test-Path $keystorePath)) {
    Write-Host "🔐 Creating release keystore..."
    keytool -genkeypair `
      -v `
      -keystore $keystorePath `
      -alias $keyAlias `
      -keyalg RSA `
      -keysize 2048 `
      -validity 10000 `
      -storepass $storePass `
      -keypass $keyPass `
      -dname "CN=MixMingle, OU=Dev, O=MixMingle, L=USA, S=TX, C=US"
} else {
    Write-Host "🔐 Keystore already exists."
}

# ------------------------------------------
# WRITE key.properties
# ------------------------------------------
$keyProps = @"
storePassword=$storePass
keyPassword=$keyPass
keyAlias=$keyAlias
storeFile=keystore/release.keystore
"@

$keyProps | Set-Content "$android\key.properties"

# ------------------------------------------
# FIX GRADLE WRAPPER
# ------------------------------------------
Set-Location $android
.\gradlew wrapper --gradle-version 8.13 --distribution-type all

# ------------------------------------------
# FORCE KOTLIN VERSION
# ------------------------------------------
$gradleFile = "$android\build.gradle"
(Get-Content $gradleFile) `
-replace "ext.kotlin_version\s*=\s*'.*?'", "ext.kotlin_version = '1.9.10'" `
| Set-Content $gradleFile

# ------------------------------------------
# FORCE ANDROID SIGNING CONFIG
# ------------------------------------------
$appGradle = "$android\app\build.gradle"
$appGradleContent = Get-Content $appGradle -Raw

if ($appGradleContent -notmatch "signingConfigs") {
$appGradleContent += @"

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
"@
$appGradleContent | Set-Content $appGradle
}

# ------------------------------------------
# CLEAN & GET PACKAGES
# ------------------------------------------
Set-Location $root
flutter clean
flutter pub get

# ------------------------------------------
# BUILD APK + AAB (VERBOSE)
# ------------------------------------------
Write-Host "📦 Building APK..."
flutter build apk --release --verbose

Write-Host "📦 Building App Bundle..."
flutter build appbundle --release --verbose

# ------------------------------------------
# OPEN OUTPUTS
# ------------------------------------------
Invoke-Item "$root\build\app\outputs\flutter-apk"
Invoke-Item "$root\build\app\outputs\bundle\release"

Write-Host "✅ BUILD COMPLETE — APK & AAB READY"
