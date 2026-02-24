# master-fix-full.ps1
# Larry's Ultimate Flutter Master Build Fix

$ErrorActionPreference = "Stop"
Write-Host "`n🎯 Starting ultimate master fix script..."

# Detect OS
$OS = $PSVersionTable.OS
Write-Host "Detected OS: $OS"

# Backup helpers folder
if (Test-Path ".\lib\helpers") {
    $backupPath = ".\lib\helpers-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item -Path ".\lib\helpers" -Destination $backupPath -Recurse
    Write-Host "✅ helpers folder backed up to $backupPath"
}

# Upgrade Flutter
Write-Host "`n🔄 Upgrading Flutter SDK..."
flutter upgrade

# Clean project
Write-Host "`n🧹 Cleaning project..."
flutter clean

# Get dependencies
Write-Host "`n📦 Getting pub dependencies..."
flutter pub get

# Patch web-0.5.1 if installed
$webPackagePath = "$env:APPDATA\Pub\Cache\hosted\pub.dev\web-0.5.1\lib"
if (Test-Path $webPackagePath) {
    Write-Host "`n🛠️  Patching web-0.5.1..."
    # Fix jsify / dot-shorthand errors
    Get-ChildItem $webPackagePath -Filter "*.dart" -Recurse | ForEach-Object {
        (Get-Content $_.FullName) |
            ForEach-Object { $_ -replace '\.jsify\(', 'js_util.jsify(' } |
            Set-Content $_.FullName
    }
    Write-Host "✅ web-0.5.1 patched"
}

# Fix Android Gradle/Kotlin
$androidBuildFile = ".\android\build.gradle"
if (Test-Path $androidBuildFile) {
    Write-Host "`n📱 Patching Android Gradle & Kotlin..."
    (Get-Content $androidBuildFile) |
        ForEach-Object {
            $_ -replace 'classpath "com.android.tools.build:gradle:.*"', 'classpath "com.android.tools.build:gradle:8.2.0"' `
               -replace 'classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:.*"', 'classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.10"'
        } | Set-Content $androidBuildFile
    Write-Host "✅ Android Gradle & Kotlin patched"
}

# Patch flutter_local_notifications_windows to fix atlbase.h error
$windowsPluginPath = ".\windows\flutter\ephemeral\.plugin_symlinks\flutter_local_notifications_windows\src"
if (Test-Path $windowsPluginPath) {
    Write-Host "`n🖥️  Patching flutter_local_notifications_windows..."
    $pluginCpp = Join-Path $windowsPluginPath "plugin.cpp"
    if (Test-Path $pluginCpp) {
        (Get-Content $pluginCpp) |
            ForEach-Object {
                if ($_ -match "#include <atlbase.h>") {
                    "#include <windows.h>`n#using <atlbase.h>" # replace with safe include
                } else { $_ }
            } | Set-Content $pluginCpp
        Write-Host "✅ flutter_local_notifications_windows patched"
    }
}

# Build Android APK
Write-Host "`n🚀 Building Android APK..."
flutter build apk

# Build Web
Write-Host "`n🌐 Building Web..."
flutter build web

# Build Windows if running on Windows
if ($OS -match "Windows") {
    Write-Host "`n🖥️  Building Windows..."
    flutter build windows
} else {
    Write-Host "`nℹ️  Windows build skipped (not Windows)"
}

# Build iOS if running on macOS
if ($OS -match "Darwin") {
    Write-Host "`n🍏 Building iOS..."
    flutter build ios --release
} else {
    Write-Host "`nℹ️  iOS build skipped (not macOS)"
}

Write-Host "`n🎯 Ultimate master fix complete! Review logs for errors."
