#!/usr/bin/env pwsh
# PowerShell Flutter Web Audit Script
# Run from project root
$libPath = ".\lib"

Write-Host "🔎 Starting Flutter Web audit..." -ForegroundColor Cyan

# 1️⃣ Find all Dart files
Write-Host "`nDiscovering Dart files..." -ForegroundColor Yellow
$dartFiles = Get-ChildItem -Path $libPath -Recurse -Include *.dart
Write-Host "Found $($dartFiles.Count) Dart files" -ForegroundColor Green

# 2️⃣ Scan for missing imports
Write-Host "`n📄 Checking for missing imports..." -ForegroundColor Yellow
$missingImports = @()
foreach ($file in $dartFiles) {
    $lines = Get-Content $file.FullName
    foreach ($line in $lines) {
        if ($line -match "import\s+['""](.+)['""];") {
            $importPath = $matches[1]
            if ($importPath.StartsWith("package:")) { continue } # skip pub packages
            if ($importPath.StartsWith("dart:")) { continue } # skip dart: imports

            # Resolve relative path
            $baseDir = $file.DirectoryName
            $fullPath = Join-Path $baseDir $importPath
            $fullPath = $fullPath -replace '/', '\'

            # Normalize path
            if (Test-Path $fullPath) {
                $fullPath = Resolve-Path $fullPath
            }

            if (-not (Test-Path $fullPath)) {
                $relPath = $file.FullName.Replace("$PWD\", "")
                $missingImports += "❌ Missing: $importPath in $relPath"
                Write-Host "  ❌ Missing: $importPath in $relPath" -ForegroundColor Red
            }
        }
    }
}

if ($missingImports.Count -eq 0) {
    Write-Host "  ✅ No missing imports found" -ForegroundColor Green
}

# 3️⃣ Detect duplicate 'child:' in constructors
Write-Host "`n⚠️  Checking for duplicate 'child:' arguments..." -ForegroundColor Yellow
$duplicateChildFiles = @()
foreach ($file in $dartFiles) {
    $content = Get-Content $file.FullName -Raw

    # Look for widget constructors with multiple child: parameters
    $widgetPattern = '\b\w+\s*\([^)]*\bchild\s*:[^)]*\bchild\s*:'
    if ($content -match $widgetPattern) {
        $relPath = $file.FullName.Replace("$PWD\", "")
        $duplicateChildFiles += $relPath
        Write-Host "  ⚠️  Duplicate 'child:' in $relPath" -ForegroundColor Yellow
    }
}

if ($duplicateChildFiles.Count -eq 0) {
    Write-Host "  ✅ No duplicate 'child:' parameters found" -ForegroundColor Green
}

# 4️⃣ Find undefined classes/providers (based on lib folder)
Write-Host "`n❓ Scanning for possible undefined classes / providers..." -ForegroundColor Yellow
Write-Host "  (This may take a moment...)" -ForegroundColor Gray

# Gather all classes defined in lib
$allClasses = @{}
$knownDartTypes = @(
    'String', 'int', 'double', 'bool', 'List', 'Map', 'Set', 'Object', 'dynamic',
    'Widget', 'State', 'StatelessWidget', 'StatefulWidget', 'BuildContext',
    'Future', 'Stream', 'Duration', 'DateTime', 'Icon', 'Text', 'Container',
    'Column', 'Row', 'Stack', 'Positioned', 'Scaffold', 'AppBar', 'Center',
    'Padding', 'Material', 'InkWell', 'GestureDetector', 'Navigator', 'Route',
    'MaterialPageRoute', 'Colors', 'Color', 'ThemeData', 'TextStyle', 'EdgeInsets',
    'BoxDecoration', 'BorderRadius', 'BoxConstraints', 'Size', 'Offset',
    'Alignment', 'MainAxisAlignment', 'CrossAxisAlignment', 'Axis',
    'FlutterError', 'Exception', 'Error', 'Key', 'ValueKey', 'GlobalKey',
    'MaterialApp', 'CupertinoApp', 'WidgetsApp', 'Expanded', 'Flexible',
    'SizedBox', 'ListView', 'GridView', 'SingleChildScrollView', 'CustomScrollView',
    'TextField', 'TextEditingController', 'FocusNode', 'InputDecoration',
    'FirebaseOptions', 'DocumentSnapshot', 'QuerySnapshot', 'CollectionReference',
    'AsyncValue', 'ProviderScope', 'ConsumerWidget', 'Provider', 'MultiProvider',
    'ChangeNotifier', 'ValueNotifier', 'StreamBuilder', 'FutureBuilder'
)

foreach ($file in $dartFiles) {
    $classMatches = Select-String -Path $file.FullName -Pattern '\bclass\s+(\w+)' -AllMatches
    foreach ($match in $classMatches) {
        $className = $match.Matches[0].Groups[1].Value
        if (-not $allClasses.ContainsKey($className)) {
            $allClasses[$className] = $file.FullName
        }
    }

    # Also gather enums
    $enumMatches = Select-String -Path $file.FullName -Pattern '\benum\s+(\w+)' -AllMatches
    foreach ($match in $enumMatches) {
        $enumName = $match.Matches[0].Groups[1].Value
        if (-not $allClasses.ContainsKey($enumName)) {
            $allClasses[$enumName] = $file.FullName
        }
    }

    # Also gather typedefs
    $typedefMatches = Select-String -Path $file.FullName -Pattern '\btypedef\s+(\w+)' -AllMatches
    foreach ($match in $typedefMatches) {
        $typedefName = $match.Matches[0].Groups[1].Value
        if (-not $allClasses.ContainsKey($typedefName)) {
            $allClasses[$typedefName] = $file.FullName
        }
    }
}

Write-Host "  Found $($allClasses.Count) defined classes/enums/typedefs" -ForegroundColor Green

# Simple undefined class check (this will have false positives, so we'll limit output)
$possiblyUndefined = @()
$checkedTypes = @{}
$sampleSize = [Math]::Min(50, $dartFiles.Count)

# Only check a sample to avoid overwhelming output
foreach ($file in ($dartFiles | Select-Object -First $sampleSize)) {
    $content = Get-Content $file.FullName -Raw

    # Look for type annotations and class instantiations
    $typePattern = '\b([A-Z][a-zA-Z0-9_]*)\s*[(<]'
    $matches = [regex]::Matches($content, $typePattern)

    foreach ($match in $matches) {
        $typeName = $match.Groups[1].Value

        # Skip if already checked or is known
        if ($checkedTypes.ContainsKey($typeName)) { continue }
        if ($knownDartTypes -contains $typeName) { continue }
        if ($allClasses.ContainsKey($typeName)) { continue }

        # Skip generic type parameters (usually single letter)
        if ($typeName.Length -eq 1) { continue }

        # Skip if it ends with common suffixes that are likely from packages
        if ($typeName -match '(Provider|Service|Controller|Repository|Model|Widget|Screen|Page)$') {
            # These are likely defined but check anyway
            if (-not $allClasses.ContainsKey($typeName)) {
                $checkedTypes[$typeName] = $true
                $possiblyUndefined += $typeName
            }
        }
    }
}

if ($possiblyUndefined.Count -gt 0) {
    Write-Host "  ⚠️  Found $($possiblyUndefined.Count) possibly undefined types (may include false positives):" -ForegroundColor Yellow
    $possiblyUndefined | Select-Object -Unique -First 10 | ForEach-Object {
        Write-Host "    - $_" -ForegroundColor Yellow
    }
    if ($possiblyUndefined.Count -gt 10) {
        Write-Host "    ... and $($possiblyUndefined.Count - 10) more" -ForegroundColor Gray
    }
    Write-Host "  ℹ️  Note: These may be from external packages or imported with prefixes" -ForegroundColor Cyan
} else {
    Write-Host "  ✅ No obviously undefined types found in sample" -ForegroundColor Green
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "📊 AUDIT SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total Dart files scanned: $($dartFiles.Count)" -ForegroundColor White
Write-Host "Missing imports: $($missingImports.Count)" -ForegroundColor $(if ($missingImports.Count -gt 0) { 'Red' } else { 'Green' })
Write-Host "Duplicate 'child:' issues: $($duplicateChildFiles.Count)" -ForegroundColor $(if ($duplicateChildFiles.Count -gt 0) { 'Yellow' } else { 'Green' })
Write-Host "Possibly undefined types: $($possiblyUndefined.Count)" -ForegroundColor $(if ($possiblyUndefined.Count -gt 0) { 'Yellow' } else { 'Green' })
Write-Host ""

if ($missingImports.Count -eq 0 -and $duplicateChildFiles.Count -eq 0) {
    Write-Host "✅ Audit complete - No critical issues found!" -ForegroundColor Green
} else {
    Write-Host "⚠️  Audit complete - Review issues above" -ForegroundColor Yellow
}

# Export report
$reportFile = "flutter_web_audit_report.txt"
$report = @"
Flutter Web Audit Report
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

SUMMARY
=======
Total Dart files: $($dartFiles.Count)
Defined classes/enums: $($allClasses.Count)

MISSING IMPORTS ($($missingImports.Count))
===============
$(if ($missingImports.Count -gt 0) { $missingImports -join "`n" } else { "None" })

DUPLICATE CHILD PARAMETERS ($($duplicateChildFiles.Count))
==========================
$(if ($duplicateChildFiles.Count -gt 0) { $duplicateChildFiles -join "`n" } else { "None" })

POSSIBLY UNDEFINED TYPES ($($possiblyUndefined.Count))
========================
$(if ($possiblyUndefined.Count -gt 0) { ($possiblyUndefined | Select-Object -Unique) -join "`n" } else { "None" })

Note: Undefined types may include false positives for types from external packages
or types imported with library prefixes (e.g., 'package:name/file.dart' as prefix).
"@

$report | Out-File -FilePath $reportFile -Encoding UTF8
Write-Host "📄 Full report exported to: $reportFile" -ForegroundColor Cyan
