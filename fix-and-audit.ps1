# ==========================
# 🔹 Mix & Mingle Auto-Fix & Audit
# ==========================

Write-Host "`n🎯 Starting Mix & Mingle Fix & Audit..." -ForegroundColor Cyan

# -----------------------------
# 1️⃣ Upgrade web package (Dart 3 compatible)
# -----------------------------
Write-Host "`n🔹 Upgrading 'web' package..."
$pubFile = "pubspec.yaml"
(Get-Content $pubFile) -replace "(web:\s*)1\.1\.1", '${1}^1.2.0' | Set-Content $pubFile

Write-Host "✅ Updated web package version to ^1.2.0"

# -----------------------------
# 2️⃣ Run Flutter pub upgrade & get
# -----------------------------
Write-Host "`n🔹 Running flutter pub upgrade & get..."
flutter pub upgrade
flutter pub get
Write-Host "✅ Flutter dependencies updated"

# -----------------------------
# 3️⃣ Fix missing imports in lib
# -----------------------------
Write-Host "`n🔹 Checking for missing imports in lib..."
$dartFiles = Get-ChildItem -Path "lib" -Recurse -Filter *.dart

foreach ($file in $dartFiles) {
    $content = Get-Content $file.FullName
    if ($content -match "import .+;") { continue }
    else {
        Write-Host "⚠️ Adding 'import flutter/material.dart' to $($file.FullName)" -ForegroundColor Yellow
        Set-Content $file.FullName ("import 'package:flutter/material.dart';`n" + (Get-Content $file.FullName))
    }
}
Write-Host "✅ Imports checked and fixed"

# -----------------------------
# 4️⃣ Check Firebase config
# -----------------------------
$androidFirebase = "android/app/google-services.json"
$iosFirebase = "ios/Runner/GoogleService-Info.plist"

if (Test-Path $androidFirebase) {
    Write-Host "✅ Android Firebase config exists" -ForegroundColor Green
} else {
    Write-Host "❌ Android Firebase config missing" -ForegroundColor Red
}

if (Test-Path $iosFirebase) {
    Write-Host "✅ iOS Firebase config exists" -ForegroundColor Green
} else {
    Write-Host "❌ iOS Firebase config missing" -ForegroundColor Red
}

# -----------------------------
# 5️⃣ Flutter analyze & fix issues
# -----------------------------
Write-Host "`n🔹 Running flutter analyze..."
flutter analyze

# -----------------------------
# 6️⃣ Run tests
# -----------------------------
Write-Host "`n🔹 Running flutter test..."
flutter test

# -----------------------------
# 7️⃣ Optional: Keep window open
# -----------------------------
Write-Host "`n🛑 Auto-Fix & Audit Complete! Review warnings above."
Write-Host "Press any key to close this window..."
$x = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
