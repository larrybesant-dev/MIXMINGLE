# master-fix-scan-all.ps1
# Larry's Ultimate Flutter Scan + Fix + Build

$ErrorActionPreference = "Stop"
Write-Host "`n🎯 Starting full scan + fix + build..."

# ----------------------------
# 1️⃣ Detect OS
# ----------------------------
$OS = $PSVersionTable.OS
Write-Host "Detected OS: $OS"

# ----------------------------
# 2️⃣ Create logs folder
# ----------------------------
$logDir = ".\logs"
if (!(Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir }

# ----------------------------
# 3️⃣ Backup critical folders
# ----------------------------
$foldersToBackup = @(".\lib\helpers", ".\android", ".\ios", ".\windows\flutter\ephemeral")
foreach ($folder in $foldersToBackup) {
    if (Test-Path $folder) {
        $backupPath = "$folder-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Copy-Item -Path $folder -Destination $backupPath -Recurse
        Write-Host "✅ Backed up $folder to $backupPath"
    }
}

# ----------------------------
# 4️⃣ Upgrade Flutter & clean project
# ----------------------------
Write-Host "`n🔄 Upgrading Flutter SDK and cleaning project..."
flutter upgrade | Tee-Object -FilePath "$logDir\flutter_upgrade.log"
flutter clean | Tee-Object -FilePath "$logDir\flutter_clean.log"
flutter pub get | Tee-Object -FilePath "$logDir\pub_get.log"

# ----------------------------
# 5️⃣ Patch web-0.5.1 if installed
# ----------------------------
$webPackagePath = "$env:APPDATA\Pub\Cache\hosted\pub.dev\web-0.5.1\lib"
if (Test-Path $webPackagePath) {
    Write-Host "`n🛠️  Patching web-0.5.1..."
    Get-ChildItem $webPackagePath -Filter "*.dart" -Recurse | ForEach-Object {
        (Get-Content $_.FullName) |
            ForEach-Object { $_ -replace '\.jsify\(', 'js_util.jsify(' } |
            Set-Content $_.FullName
    }
    Write-Host "✅ web-0.5.1 patched"
}

# ----------------------------
# 6️⃣ Patch Android Gradle & Kotlin
# ----------------------------
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

# ----------------------------
# 7️⃣ Patch flutter_local_notifications_windows
# ----------------------------
$windowsPluginPath = ".\windows\flutter\ephemeral\.plugin_symlinks\flutter_local_notifications_windows\src"
if (Test-Path $windowsPluginPath) {
    Write-Host "`n🖥️  Patching flutter_local_notifications_windows..."
    $pluginCpp = Join-Path $windowsPluginPath "plugin.cpp"
    if (Test-Path $pluginCpp) {
        (Get-Content $pluginCpp) |
            ForEach-Object {
                if ($_ -match "#include <atlbase.h>") {
                    "#include <windows.h>`n#using <atlbase.h>"
                } else { $_ }
            } | Set-Content $pluginCpp
        Write-Host "✅ flutter_local_notifications_windows patched"
    }
}

# ----------------------------
# 8️⃣ Full Dart analysis
# ----------------------------
Write-Host "`n🔍 Running Flutter analysis on all Dart files..."
flutter analyze | Tee-Object -FilePath "$logDir\flutter_analyze.log"

# ----------------------------
# 9️⃣ Optional: Quick build tests
# ----------------------------
Write-Host "`n⚡ Performing quick build tests..."

Write-Host "`n🚀 Building Android APK..."
flutter build apk | Tee-Object -FilePath "$logDir\build_android.log"

Write-Host "`n🌐 Building Web..."
flutter build web | Tee-Object -FilePath "$logDir\build_web.log"

if ($OS -match "Windows") {
    Write-Host "`n🖥️  Building Windows..."
    flutter build windows | Tee-Object -FilePath "$logDir\build_windows.log"
} else {
    Write-Host "`nℹ️ Windows build skipped (not Windows)"
}

if ($OS -match "Darwin") {
    Write-Host "`n🍏 Building iOS..."
    flutter build ios --release | Tee-Object -FilePath "$logDir\build_ios.log"
} else {
    Write-Host "`nℹ️ iOS build skipped (not macOS)"
}

Write-Host "`n🎯 Master scan + fix complete! All logs saved to $logDir"
