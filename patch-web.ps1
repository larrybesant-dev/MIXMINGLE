# ============================================
# PowerShell Script: Patch web-0.5.1 for Flutter
# Replaces .toJS and .jsify with dart:js_util equivalents
# ============================================

$packagePath = "$env:USERPROFILE\AppData\Local\Pub\Cache\hosted\pub.dev\web-0.5.1\lib\src\helpers"
$backupPath = "$packagePath-backup"

# Backup
if (-not (Test-Path $backupPath)) {
    Copy-Item $packagePath $backupPath -Recurse
    Write-Host "✅ Backup created at $backupPath"
} else {
    Write-Host "⚠ Backup already exists at $backupPath"
}

# Add dart:js_util import
Get-ChildItem $packagePath -Recurse -Filter *.dart | ForEach-Object {
    $file = $_.FullName
    $content = Get-Content $file -Raw
    if ($content -notmatch "import 'dart:js_util' as js_util;") {
        $content = "import 'dart:js_util' as js_util;`n" + $content
        Set-Content $file $content
        Write-Host "➕ Added js_util import in $file"
    }
}

# Replace .toJS
Get-ChildItem $packagePath -Recurse -Filter *.dart | ForEach-Object {
    $file = $_.FullName
    (Get-Content $file) |
        ForEach-Object { $_ -replace "\.toJS\b", "" } |
        Set-Content $file
    Write-Host "♻ Patched .toJS in $file"
}

# Replace .jsify() with js_util.jsify()
Get-ChildItem $packagePath -Recurse -Filter *.dart | ForEach-Object {
    $file = $_.FullName
    (Get-Content $file) |
        ForEach-Object { $_ -replace "\.jsify\(\)", "js_util.jsify($&)" } |
        Set-Content $file
    Write-Host "♻ Patched .jsify() in $file"
}

Write-Host "✅ web-0.5.1 patch complete. Run 'flutter clean' and rebuild your project."
