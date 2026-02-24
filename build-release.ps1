# -------------------------------
# MIX & MINGLE – Flutter Release Build Script
# -------------------------------

# Config
$keystorePath = "C:\Users\LARRY\keystore\mixmingle.jks"
$storePassword = "YOUR_STORE_PASSWORD"
$keyPassword = "YOUR_KEY_PASSWORD"
$keyAlias = "mixmingle"

Write-Host "✅ Starting Flutter release build..."

# Step 1: Clean project
Write-Host "Cleaning project..."
flutter clean
Remove-Item -Recurse -Force .dart_tool, build -ErrorAction SilentlyContinue
flutter pub get

# Step 2: Show outdated packages (optional info)
Write-Host "Checking outdated packages..."
flutter pub outdated

# Step 3: Set environment for signing
$env:KEYSTORE_PATH=$keystorePath
$env:STORE_PASSWORD=$storePassword
$env:KEY_PASSWORD=$keyPassword
$env:KEY_ALIAS=$keyAlias

# Step 4: Build release APK
Write-Host "Building release APK..."
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols

# Step 5: Build release App Bundle (for Play Store)
Write-Host "Building release App Bundle (AAB)..."
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols

# Step 6: Split APK per ABI (optional, smaller APKs)
Write-Host "Building ABI-specific APKs..."
flutter build apk --release --split-per-abi

# Step 7: Verify APK signing
Write-Host "Verifying APK signing..."
$apkPath = "build\app\outputs\flutter-apk\app-release.apk"
apksigner verify $apkPath
Write-Host "✅ APK signing verified"

# Step 8: Output locations
Write-Host "`nBuild complete!"
Write-Host "📦 APK: build\app\outputs\flutter-apk\app-release.apk"
Write-Host "📦 Split APKs: build\app\outputs\flutter-apk\*"
Write-Host "📦 App Bundle: build\app\outputs\bundle\release\app-release.aab"
