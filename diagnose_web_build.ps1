#!/usr/bin/env pwsh
# Flutter Web Build Diagnostic Script
# Scans for web-incompatible code and missing dependencies

Write-Host "🔍 Flutter Web Build Diagnostics" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

$errors = @()
$warnings = @()

# Check 1: dart:io imports (not supported on web)
Write-Host "📦 Checking for dart:io imports (web-incompatible)..." -ForegroundColor Yellow
$dartIoFiles = Get-ChildItem -Path "lib" -Recurse -Filter "*.dart" |
    Select-String -Pattern "^import\s+['\`"]dart:io['\`"]" |
    Select-Object -ExpandProperty Path -Unique

if ($dartIoFiles) {
    foreach ($file in $dartIoFiles) {
        $relPath = $file.Replace("$PWD\", "")
        $errors += "❌ $relPath uses dart:io (not supported on web)"
        Write-Host "  ❌ $relPath" -ForegroundColor Red
    }
} else {
    Write-Host "  ✅ No dart:io imports found" -ForegroundColor Green
}

# Check 2: Missing package imports
Write-Host ""
Write-Host "📦 Checking for missing package dependencies..." -ForegroundColor Yellow

# Read pubspec.yaml
$pubspecContent = Get-Content "pubspec.yaml" -Raw
$dependencies = @()

if ($pubspecContent -match "(?s)dependencies:(.*?)dev_dependencies:") {
    $depSection = $Matches[1]
    $depSection -split "`n" | ForEach-Object {
        if ($_ -match "^\s+([a-z_]+):") {
            $dependencies += $Matches[1]
        }
    }
}

# Check for provider package usage
$providerImports = Get-ChildItem -Path "lib" -Recurse -Filter "*.dart" |
    Select-String -Pattern "package:provider/provider\.dart"

if ($providerImports -and "provider" -notin $dependencies) {
    $errors += "❌ Code imports 'provider' but it's not in pubspec.yaml"
    Write-Host "  ❌ 'provider' package imported but not in dependencies" -ForegroundColor Red
    $providerImports | ForEach-Object {
        $relPath = $_.Path.Replace("$PWD\", "")
        Write-Host "     - $relPath (line $($_.LineNumber))" -ForegroundColor Red
    }
}

# Check for firebase_performance usage
$perfImports = Get-ChildItem -Path "lib" -Recurse -Filter "*.dart" |
    Select-String -Pattern "package:firebase_performance"

if ($perfImports -and "firebase_performance" -notin $dependencies) {
    $errors += "❌ Code imports 'firebase_performance' but it's not in pubspec.yaml"
    Write-Host "  ❌ 'firebase_performance' package imported but not in dependencies" -ForegroundColor Red
    $perfImports | ForEach-Object {
        $relPath = $_.Path.Replace("$PWD\", "")
        Write-Host "     - $relPath (line $($_.LineNumber))" -ForegroundColor Red
    }
}

# Check 3: Platform-specific code without kIsWeb guards
Write-Host ""
Write-Host "📱 Checking for platform-specific code without kIsWeb guards..." -ForegroundColor Yellow

$platformFiles = Get-ChildItem -Path "lib" -Recurse -Filter "*.dart" |
    Select-String -Pattern "Platform\.(isAndroid|isIOS|isWindows|isMacOS|isLinux)" |
    Select-Object Path, LineNumber, Line -Unique

if ($platformFiles) {
    foreach ($match in $platformFiles) {
        $relPath = $match.Path.Replace("$PWD\", "")
        $fileContent = Get-Content $match.Path -Raw

        # Check if file has kIsWeb check
        if ($fileContent -notmatch "kIsWeb") {
            $warnings += "⚠️  $relPath uses Platform without kIsWeb guard"
            Write-Host "  ⚠️  $relPath (line $($match.LineNumber))" -ForegroundColor Yellow
            Write-Host "     $($match.Line.Trim())" -ForegroundColor Gray
        }
    }

    if ($warnings.Count -eq 0) {
        Write-Host "  ✅ All Platform usage has kIsWeb guards" -ForegroundColor Green
    }
} else {
    Write-Host "  ✅ No Platform-specific code found" -ForegroundColor Green
}

# Check 4: Missing methods in services
Write-Host ""
Write-Host "🔧 Checking for compilation errors in recent build..." -ForegroundColor Yellow

if (Test-Path "build_log_errors.txt") {
    $buildErrors = Get-Content "build_log_errors.txt" | Select-String -Pattern "Error: The method '(\w+)' isn't defined"

    if ($buildErrors) {
        $buildErrors | ForEach-Object {
            if ($_ -match "Error: The method '(\w+)' isn't defined for the type '(\w+)'") {
                $method = $Matches[1]
                $class = $Matches[2]
                $errors += "❌ Missing method: $class.$method()"
                Write-Host "  ❌ $class is missing method: $method()" -ForegroundColor Red
            }
        }
    }
}

# Check 5: Web-specific package support
Write-Host ""
Write-Host "🌐 Checking package web support..." -ForegroundColor Yellow

$packagesNeedingWebSetup = @{
    "agora_rtc_engine" = "Requires separate web SDK initialization"
    "image_picker" = "Uses web-specific plugin"
    "image_cropper" = "Limited web support"
    "file_picker" = "Uses web-specific implementation"
    "permission_handler" = "Limited/no web support"
    "path_provider" = "Limited web support"
    "firebase_messaging" = "Requires web-specific setup"
    "flutter_local_notifications" = "Not supported on web"
}

foreach ($pkg in $packagesNeedingWebSetup.Keys) {
    if ($pkg -in $dependencies) {
        $warnings += "⚠️  $pkg - $($packagesNeedingWebSetup[$pkg])"
        Write-Host "  ⚠️  $pkg" -ForegroundColor Yellow
        Write-Host "     $($packagesNeedingWebSetup[$pkg])" -ForegroundColor Gray
    }
}

# Summary
Write-Host ""
Write-Host "=================================" -ForegroundColor Cyan
Write-Host "📊 DIAGNOSTIC SUMMARY" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

if ($errors.Count -eq 0 -and $warnings.Count -eq 0) {
    Write-Host "✅ No issues found! Your project should build for web." -ForegroundColor Green
} else {
    Write-Host "🔴 BLOCKING ERRORS: $($errors.Count)" -ForegroundColor Red
    Write-Host "⚠️  WARNINGS: $($warnings.Count)" -ForegroundColor Yellow
    Write-Host ""

    if ($errors.Count -gt 0) {
        Write-Host "Critical issues that must be fixed:" -ForegroundColor Red
        $errors | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    }

    Write-Host ""
    Write-Host "💡 RECOMMENDED FIXES:" -ForegroundColor Cyan
    Write-Host ""

    if ($errors -match "provider") {
        Write-Host "1️⃣  Add 'provider' package to pubspec.yaml:" -ForegroundColor White
        Write-Host "   dependencies:" -ForegroundColor Gray
        Write-Host "     provider: ^6.1.0" -ForegroundColor Gray
        Write-Host "   OR convert to flutter_riverpod (already in your deps)" -ForegroundColor Gray
        Write-Host ""
    }

    if ($errors -match "firebase_performance") {
        Write-Host "2️⃣  Add 'firebase_performance' to pubspec.yaml:" -ForegroundColor White
        Write-Host "   dependencies:" -ForegroundColor Gray
        Write-Host "     firebase_performance: ^1.0.0" -ForegroundColor Gray
        Write-Host "   OR stub out PerformanceService for web using kIsWeb" -ForegroundColor Gray
        Write-Host ""
    }

    if ($errors -match "dart:io") {
        Write-Host "3️⃣  Wrap dart:io usage with conditional imports:" -ForegroundColor White
        Write-Host "   import 'package:flutter/foundation.dart' show kIsWeb;" -ForegroundColor Gray
        Write-Host "   if (!kIsWeb) { /* dart:io code */ }" -ForegroundColor Gray
        Write-Host ""
    }

    if ($errors -match "Missing method") {
        Write-Host "4️⃣  Implement missing methods in services or remove calls" -ForegroundColor White
        Write-Host ""
    }
}

Write-Host ""
Write-Host "🚀 Next steps:" -ForegroundColor Cyan
Write-Host "1. Fix all ❌ BLOCKING ERRORS above" -ForegroundColor White
Write-Host "2. Run: flutter pub get" -ForegroundColor White
Write-Host "3. Run: flutter build web -v" -ForegroundColor White
Write-Host "4. Check warnings for runtime issues" -ForegroundColor White
Write-Host ""

# Export detailed report
$reportFile = "web_build_diagnostic_report.md"
$report = @"
# Flutter Web Build Diagnostic Report
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Summary
- **Blocking Errors**: $($errors.Count)
- **Warnings**: $($warnings.Count)

## Errors
$(if ($errors.Count -gt 0) { $errors | ForEach-Object { "- $_`n" } } else { "None`n" })

## Warnings
$(if ($warnings.Count -gt 0) { $warnings | ForEach-Object { "- $_`n" } } else { "None`n" })

## Dependencies in pubspec.yaml
$($dependencies -join ", ")
"@

$report | Out-File -FilePath $reportFile -Encoding UTF8
Write-Host "📄 Full report saved to: $reportFile" -ForegroundColor Cyan
