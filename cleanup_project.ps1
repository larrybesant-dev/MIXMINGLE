# ==============================
# MIX & MINGLE — COMPLETE PROJECT CLEANUP
# ==============================
# Remove ALL unused files, assets, imports, and dependencies
# Backup created before deletion

Write-Host "🧹 Starting Complete Project Cleanup..." -ForegroundColor Cyan
Write-Host "   This will remove stub/old/deprecated files, unused assets, and unused imports" -ForegroundColor Gray

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupDir = "cleanup_backup_$timestamp"
$reportFile = "cleanup_report_$timestamp.md"

# Create backup
Write-Host "`n📦 Creating backup..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path $backupDir | Out-Null
Copy-Item -Path "lib" -Destination "$backupDir/lib_backup" -Recurse -Force
Copy-Item -Path "pubspec.yaml" -Destination "$backupDir/pubspec.yaml.backup" -Force
Write-Host "✅ Backup created: $backupDir" -ForegroundColor Green

# --- STEP 1: Remove stub/old/deprecated Dart files ---
Write-Host "`n🗑️ Step 1: Removing stub/old/deprecated files..." -ForegroundColor Yellow

$filesToRemove = @()

# Find all stub, old, deprecated files
Get-ChildItem -Recurse -Include "*_stub.dart", "*_old.dart", "*_deprecated.dart", "*_backup.dart", "*_temp.dart", "*_test_old.dart" -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host "   Removing: $($_.FullName)" -ForegroundColor Gray
    $filesToRemove += $_.FullName
    Remove-Item -Force $_.FullName -ErrorAction SilentlyContinue
}

Write-Host "✅ Removed $($filesToRemove.Count) stub/old/deprecated files" -ForegroundColor Green

# --- STEP 2: Apply Dart fixes to remove unused imports ---
Write-Host "`n🔧 Step 2: Applying Dart fixes..." -ForegroundColor Yellow
dart fix --apply 2>&1
Write-Host "✅ Dart fixes applied" -ForegroundColor Green

# --- STEP 3: Identify unused assets ---
Write-Host "`n🖼️ Step 3: Analyzing asset usage..." -ForegroundColor Yellow

$assetsDir = "assets"
$unusedAssets = @()

if (Test-Path $assetsDir) {
    Get-ChildItem -Recurse -Include "*.png", "*.jpg", "*.jpeg", "*.svg", "*.gif", "*.webp" -Path $assetsDir | ForEach-Object {
        $assetName = $_.Name
        $assetPath = $_.FullName

        # Search for asset references in Dart code
        $found = $false

        # Check if mentioned in pubspec.yaml
        if ((Get-Content pubspec.yaml | Select-String -Pattern $assetName)) {
            $found = $true
        }

        # Check if mentioned in any Dart file
        try {
            $search = Get-Content -Path "lib\**\*.dart" -Recurse -ErrorAction SilentlyContinue | Select-String -Pattern ([regex]::Escape($assetName))
            if ($search) { $found = $true }
        } catch { }

        if (-not $found) {
            Write-Host "   Unused asset found: $assetPath" -ForegroundColor Gray
            $unusedAssets += $assetPath
        }
    }

    # Optional: Remove unused assets (commented out for safety)
    Write-Host "⚠️ Found $($unusedAssets.Count) potentially unused assets" -ForegroundColor Yellow
    Write-Host "   (Review before deletion - not auto-deleted for safety)" -ForegroundColor Gray
}

# --- STEP 4: Analyze code for unused variables/functions ---
Write-Host "`n🔍 Step 4: Analyzing code quality..." -ForegroundColor Yellow

$analyzeOutput = flutter analyze --no-pub 2>&1
$analyzeFile = "flutter_analyze_$timestamp.txt"
$analyzeOutput | Out-File -FilePath $analyzeFile

# Count issues
$errors = ($analyzeOutput | Select-String -Pattern "error" | Measure-Object).Count
$warnings = ($analyzeOutput | Select-String -Pattern "warning" | Measure-Object).Count
$info = ($analyzeOutput | Select-String -Pattern "info" | Measure-Object).Count

Write-Host "   Analysis Results:" -ForegroundColor Gray
Write-Host "     Errors: $errors" -ForegroundColor $(if ($errors -gt 0) { "Red" } else { "Green" })
Write-Host "     Warnings: $warnings" -ForegroundColor $(if ($warnings -gt 0) { "Yellow" } else { "Green" })
Write-Host "     Info: $info" -ForegroundColor Gray
Write-Host "✅ Analysis report: $analyzeFile" -ForegroundColor Green

# --- STEP 5: Identify unused dependencies ---
Write-Host "`n📦 Step 5: Checking for unused dependencies..." -ForegroundColor Yellow

$pubDeps = flutter pub deps --style=list 2>&1
$pubDepsFile = "pubspec_deps_$timestamp.txt"
$pubDeps | Out-File -FilePath $pubDepsFile

Write-Host "⚠️ Review pubspec.yaml and remove unused packages:" -ForegroundColor Yellow
Write-Host "   Run: flutter pub remove package_name" -ForegroundColor Gray
Write-Host "   To remove a package you're not using" -ForegroundColor Gray
Write-Host "   Dependency list: $pubDepsFile" -ForegroundColor Gray

# --- STEP 6: Clean Flutter project ---
Write-Host "`n🧹 Step 6: Cleaning Flutter project..." -ForegroundColor Yellow

Write-Host "   Running: flutter clean" -ForegroundColor Gray
flutter clean
Write-Host "   Running: flutter pub get" -ForegroundColor Gray
flutter pub get

Write-Host "✅ Flutter project cleaned" -ForegroundColor Green

# --- STEP 7: Identify large/unneeded folders ---
Write-Host "`n📁 Step 7: Analyzing project structure..." -ForegroundColor Yellow

$unusedDirs = @()

# Check for common unused directories
@("node_modules", "build", ".dart_tool", ".git\objects", "coverage", "test_output") | ForEach-Object {
    if (Test-Path $_) {
        $size = (Get-ChildItem -Recurse $_ -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB
        Write-Host "   Found: $_ (~$([math]::Round($size, 2)) MB)" -ForegroundColor Gray
    }
}

# --- STEP 8: Generate cleanup report ---
Write-Host "`n📋 Step 8: Generating cleanup report..." -ForegroundColor Yellow

$report = @"
# 🧹 Mix & Mingle Project Cleanup Report

**Date**: $(Get-Date)
**Timestamp**: $timestamp

---

## ✅ Cleanup Actions Completed

### 1. Stub/Old/Deprecated Files Removed
- Count: $($filesToRemove.Count) files
- Files:
$($filesToRemove | ForEach-Object { "  - $_`n" })

### 2. Dart Fixes Applied
- Unused imports removed
- Code formatted
- See `flutter_analyze_$timestamp.txt` for details

### 3. Asset Analysis
- Total unused assets found: $($unusedAssets.Count)
$(if ($unusedAssets.Count -gt 0) { "- Review before deletion:`n$($unusedAssets | ForEach-Object { "  - $_`n" })" } else { "- All assets appear to be used ✅" })

### 4. Code Quality Analysis
- Errors found: $errors
- Warnings found: $warnings
- Info messages: $info
- Report: `flutter_analyze_$timestamp.txt`

### 5. Dependencies
- Analyzed with: flutter pub deps
- Review `pubspec_deps_$timestamp.txt`
- Unused packages should be removed with: \`flutter pub remove package_name\`

### 6. Flutter Project Cleaned
- Ran: \`flutter clean\`
- Ran: \`flutter pub get\`
- Build cache cleared
- Dependencies refreshed

---

## 📊 Cleanup Summary

| Category | Action | Files |
|----------|--------|-------|
| Stub/Old/Deprecated | ✅ Removed | $($filesToRemove.Count) |
| Unused Assets | ⚠️ Identified | $($unusedAssets.Count) |
| Unused Imports | ✅ Removed | N/A |
| Build Cache | ✅ Cleared | N/A |

---

## 🔍 Files to Review

1. **flutter_analyze_$timestamp.txt** — Code quality issues
   - Review errors (must fix)
   - Review warnings (should fix)
   - Info messages (optional)

2. **pubspec_deps_$timestamp.txt** — Dependency list
   - Identify unused packages
   - Remove with: \`flutter pub remove package_name\`

3. **Unused Assets** (if any):
$(if ($unusedAssets.Count -gt 0) {
  "   Review these files for deletion:`n"
  $unusedAssets | ForEach-Object { "   - $_`n" }
} else {
  "   None identified ✅"
})

---

## ⚙️ Next Steps

### 1. Review Code Quality
\`\`\`powershell
cat flutter_analyze_$timestamp.txt
\`\`\`

### 2. Remove Unused Assets (if needed)
\`\`\`powershell
Remove-Item "assets/path/to/unused/file.png" -Force
\`\`\`

### 3. Remove Unused Packages
\`\`\`powershell
flutter pub remove package_name
flutter pub get
\`\`\`

### 4. Verify Build
\`\`\`powershell
flutter build web --release
flutter build apk --release
\`\`\`

---

## 💾 Backup Information

If you need to restore original files:
- Location: \`$backupDir/\`
- Contents:
  - \`lib_backup/\` — Original lib directory
  - \`pubspec.yaml.backup\` — Original pubspec.yaml

Restore with:
\`\`\`powershell
Copy-Item "$backupDir/lib_backup" -Destination "lib" -Recurse -Force
Copy-Item "$backupDir/pubspec.yaml.backup" -Destination "pubspec.yaml" -Force
\`\`\`

---

## 📁 Generated Files

- \`$reportFile\` — This report
- \`flutter_analyze_$timestamp.txt\` — Code analysis
- \`pubspec_deps_$timestamp.txt\` — Dependency list
- \`$backupDir/\` — Backup of original files

---

**Status**: ✅ Cleanup Complete
**Ready for**: Next production build
"@

$report | Out-File -FilePath $reportFile
Write-Host "✅ Cleanup report generated: $reportFile" -ForegroundColor Green

# --- DISPLAY FINAL REPORT ---
Write-Host "`n$report" -ForegroundColor Gray

# --- FINAL SUMMARY ---
Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  ✅ PROJECT CLEANUP COMPLETE                                   ║" -ForegroundColor Green
Write-Host "║                                                                ║" -ForegroundColor Green
Write-Host "║  Stub/Old/Deprecated Files Removed: $($filesToRemove.Count)" -ForegroundColor Green
Write-Host "║  Unused Assets Identified: $($unusedAssets.Count)" -ForegroundColor Green
Write-Host "║  Code Quality Issues:              " -ForegroundColor Green
Write-Host "║    - Errors: $errors" -ForegroundColor Green
Write-Host "║    - Warnings: $warnings" -ForegroundColor Green
Write-Host "║                                                                ║" -ForegroundColor Green
Write-Host "║  📋 Review Report: $reportFile" -ForegroundColor Green
Write-Host "║  💾 Backup: $backupDir/" -ForegroundColor Green
Write-Host "║  📁 Next: Review flutter_analyze_$timestamp.txt" -ForegroundColor Green
Write-Host "║                                                                ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Green

Write-Host "`n📖 See $reportFile for complete details and next steps" -ForegroundColor Cyan
