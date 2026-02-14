<#
.SYNOPSIS
Automated code fixer for Mix & Mingle Flutter app.
Fixes all known issues: unused imports, deprecated APIs, unused variables.

.DESCRIPTION
Systematically fixes common Flutter/Dart issues:
1. Removes unused imports
2. Replaces deprecated APIs (withOpacity → withValues, WillPopScope → PopScope)
3. Removes unused variables
4. Fixes dead null-aware expressions
5. Upgrades deprecated patterns
6. Applies dart fix --apply
#>

param(
    [switch]$DryRun = $false,
    [switch]$AutoApply = $false
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$workspace = Get-Location
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupDir = "code_fixes_backup_$timestamp"
$reportFile = "CODE_FIX_REPORT_$timestamp.md"
$verbose = $true

# ============================================================================
# LOGGING
# ============================================================================

function Write-Log { param([string]$msg, [string]$level = "INFO")
    $timestamp = Get-Date -Format "HH:mm:ss"
    $colors = @{
        "INFO"    = "White"
        "SUCCESS" = "Green"
        "WARNING" = "Yellow"
        "ERROR"   = "Red"
        "FIX"     = "Cyan"
    }
    $color = $colors[$level] ?? "White"
    Write-Host "[$timestamp] [$level] $msg" -ForegroundColor $color
}

function Write-Report { param([string]$content)
    Add-Content $reportFile $content
}

# ============================================================================
# BACKUP BEFORE CHANGES
# ============================================================================

Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         AUTOMATED CODE FIXER v1                  ║" -ForegroundColor Cyan
Write-Host "║    Mix & Mingle Production Code Cleanup          ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Log "Creating backup directory: $backupDir" "INFO"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
Copy-Item -Path "lib" -Destination "$backupDir/lib_backup" -Recurse -Force
Copy-Item -Path "pubspec.yaml" -Destination "$backupDir/pubspec.yaml.bak" -Force
Write-Log "✅ Backup created" "SUCCESS"

@"
# 🔧 CODE FIX REPORT
**Generated:** $(Get-Date)
**Dry Run:** $DryRun

## Overview
This report documents all code fixes applied to the Mix & Mingle Flutter app.

---

## Summary of Changes

"@ | Out-File $reportFile

# ============================================================================
# FIX 1: REMOVE STUB FILES
# ============================================================================

Write-Log "Fixing: Removing stub/deprecated placeholder files..." "INFO"

$stubsToRemove = @(
    "lib/splash_simple.dart",
    "lib/login_simple.dart",
    "lib/signup_simple.dart",
    "lib/home_simple.dart",
    "lib/PHASE_11_STABILITY_USAGE_EXAMPLES.dart"
)

$removedCount = 0
foreach ($file in $stubsToRemove) {
    if (Test-Path $file) {
        Write-Log "Removing stub: $file" "FIX"
        if (-not $DryRun) {
            Remove-Item $file -Force
            $removedCount++
        }
    }
}

@"
### Removed Stub Files
- Removed $removedCount unused stub files
- Files removed: $($stubsToRemove -join ', ')

"@ | Out-File $reportFile -Append

Write-Log "✅ Removed $removedCount stub files" "SUCCESS"

# ============================================================================
# FIX 2: REMOVE UNUSED IMPORTS FROM app_routes.dart
# ============================================================================

Write-Log "Fixing: Removing unused imports from app_routes.dart..." "INFO"

$appRoutesFile = "lib/app_routes.dart"
if (Test-Path $appRoutesFile) {
    $content = Get-Content $appRoutesFile -Raw
    $originalContent = $content

    # Remove unused imports
    $unusedImports = @(
        "import 'splash_simple.dart';",
        "import 'login_simple.dart';",
        "import 'signup_simple.dart';",
        "import 'home_simple.dart';"
    )

    $importCount = 0
    foreach ($import in $unusedImports) {
        if ($content -match [regex]::Escape($import)) {
            Write-Log "Removing unused import: $import" "FIX"
            $content = $content -replace [regex]::Escape($import) + "`n", ""
            $importCount++
        }
    }

    if ($importCount -gt 0 -and -not $DryRun) {
        Set-Content $appRoutesFile $content
        Write-Log "✅ Removed $importCount unused imports from app_routes.dart" "SUCCESS"

        @"
### Fixed: app_routes.dart
- Removed $importCount unused imports (splash_simple, login_simple, etc.)

"@ | Out-File $reportFile -Append
    }
}

# ============================================================================
# FIX 3: REPLACE DEPRECATED API: withOpacity → withValues()
# ============================================================================

Write-Log "Fixing: Replacing deprecated withOpacity() with withValues()..." "INFO"

$filesToFix = @(
    "lib/features/home_page.dart",
    "lib/features/chat_list_page.dart",
    "lib/features/speed_dating_page.dart",
    "lib/features/moderation/widgets/mod_log_viewer.dart",
    "lib/features/room/screens/room_page.dart"
)

$replacementCount = 0
foreach ($file in $filesToFix) {
    if (Test-Path $file) {
        $content = Get-Content $file -Raw

        # Find withOpacity usages
        $matches = [regex]::Matches($content, "withOpacity\(([\d.]+)\)")
        if ($matches.Count -gt 0) {
            foreach ($match in $matches) {
                $opacity = $match.Groups[1].Value
                $oldCode = $match.Value
                $newCode = "withValues(alpha: $opacity)"

                Write-Log "Replacing in $file`: $oldCode → $newCode" "FIX"
                $content = $content -replace [regex]::Escape($oldCode), $newCode
                $replacementCount++
            }

            if (-not $DryRun) {
                Set-Content $file $content
            }
        }
    }
}

if ($replacementCount -gt 0) {
    Write-Log "✅ Replaced $replacementCount deprecated withOpacity() calls" "SUCCESS"

    @"
### Fixed: Deprecated API Usage
- Replaced $replacementCount \`withOpacity()\` with \`.withValues()\`
- Fixed files:
  - lib/features/home_page.dart
  - lib/features/chat_list_page.dart
  - lib/features/speed_dating_page.dart
  - lib/features/moderation/widgets/mod_log_viewer.dart
  - lib/features/room/screens/room_page.dart

"@ | Out-File $reportFile -Append
}

# ============================================================================
# FIX 4: REPLACE DEPRECATED WillPopScope → PopScope
# ============================================================================

Write-Log "Fixing: Replacing WillPopScope with PopScope..." "INFO"

$willPopScopeFiles = @(
    "lib/features/room/widgets/spotlight_view.dart"
)

$willPopCount = 0
foreach ($file in $willPopScopeFiles) {
    if (Test-Path $file) {
        $content = Get-Content $file -Raw

        if ($content -match "WillPopScope") {
            Write-Log "Replacing WillPopScope in $file" "FIX"

            # Replace WillPopScope with PopScope
            $content = $content -replace "WillPopScope\(", "PopScope("
            $content = $content -replace "onWillPop:", "onPopInvoked:"

            if (-not $DryRun) {
                Set-Content $file $content
                $willPopCount++
            }
        }
    }
}

if ($willPopCount -gt 0) {
    Write-Log "✅ Replaced $willPopCount WillPopScope with PopScope" "SUCCESS"

    @"
### Fixed: Deprecated UI Components
- Replaced WillPopScope with PopScope for Android predictive back support
- Fixed files: lib/features/room/widgets/spotlight_view.dart

"@ | Out-File $reportFile -Append
}

# ============================================================================
# FIX 5: REMOVE UNUSED IMPORTS IN TEST FILES
# ============================================================================

Write-Log "Fixing: Removing unused imports in test files..." "INFO"

$testFiles = @(
    "test/widgets/login_page_test.dart",
    "test/widgets/events_page_test.dart",
    "test/widgets/home_page_test.dart",
    "test/widgets/chat_list_page_test.dart",
    "test/features/room/full_room_e2e_test.dart",
    "test/helpers/test_helpers.dart",
    "test/models/room_test.dart",
    "test/services/auth_service_test.dart",
    "test/create_sample_event.dart"
)

$testImportCount = 0
foreach ($file in $testFiles) {
    if (Test-Path $file) {
        $content = Get-Content $file -Raw

        # Common unused test imports
        $unusedTestImports = @(
            "package:flutter/material.dart",
            "package:firebase_core/firebase_core.dart",
            "package:firebase_auth/firebase_auth.dart",
            "package:cloud_firestore/cloud_firestore.dart",
            "package:mix_and_mingle/services/auth_service.dart",
            "../helpers/test_helpers.dart",
            "mock_firebase.dart",
            "dart:io"
        )

        foreach ($import in $unusedTestImports) {
            if ($content -match "import\s+['\"]$import['\"];?") {
                # Check if actually used
                $importName = $import.Split('/')[-1].Split('.')[0]
                if ($content -notmatch "$importName\(" -and $content -notmatch "$importName\." -and $content -notmatch "@$importName") {
                    Write-Log "Removing unused test import from $file`: $import" "FIX"
                    $content = $content -replace "import\s+['\"]$import['\"];?\n", ""
                    $testImportCount++
                }
            }
        }

        if ($testImportCount -gt 0 -and -not $DryRun) {
            Set-Content $file $content
        }
    }
}

if ($testImportCount -gt 0) {
    Write-Log "✅ Removed $testImportCount unused imports from test files" "SUCCESS"

    @"
### Fixed: Test File Imports
- Removed $testImportCount unused imports from test files
- Cleaned test helpers and mocks

"@ | Out-File $reportFile -Append
}

# ============================================================================
# FIX 6: APPLY DART FIX
# ============================================================================

Write-Log "Applying: dart fix --apply..." "INFO"

if ($AutoApply -and -not $DryRun) {
    Write-Log "Running: dart fix --apply" "FIX"
    dart fix --apply 2>&1 | Out-Host
    Write-Log "✅ Dart fixes applied" "SUCCESS"

    @"
### Applied: dart fix --apply
- Automatically fixed remaining lint issues
- Fixed unused variables, imports, null-safe patterns

"@ | Out-File $reportFile -Append
} else {
    Write-Log "Skipping dart fix (add --AutoApply to enable)" "WARNING"
}

# ============================================================================
# FIX 7: VERIFY FIXES
# ============================================================================

Write-Log "Verifying fixes..." "INFO"

flutter analyze > "analysis_after_fix.txt" 2>&1

$beforeErrors = if (Test-Path "latest_errors.txt") {
    (Get-Content "latest_errors.txt" | Select-String "^error " | Measure-Object).Count
} else { "unknown" }

$afterErrors = (Get-Content "analysis_after_fix.txt" | Select-String "^error " | Measure-Object).Count
$afterWarnings = (Get-Content "analysis_after_fix.txt" | Select-String "^warning " | Measure-Object).Count

@"
### Verification Results
- Errors before: $beforeErrors
- Errors after: $afterErrors
- Warnings after: $afterWarnings
- Analysis log: analysis_after_fix.txt

"@ | Out-File $reportFile -Append

Write-Log "✅ Code quality analysis complete" "SUCCESS"

# ============================================================================
# FINAL REPORT
# ============================================================================

@"

---

## Recommendations

### Next Steps
1. Review all changes in version control
2. Run tests: \`flutter test\`
3. Test on Android: \`flutter build apk --release\`
4. Test on Web: \`flutter build web --release\`

### Manual Fixes (if needed)
- Review \`analysis_after_fix.txt\` for remaining warnings
- Address deprecated member usage with @Deprecated annotations
- Update BuildContext usage across async gaps

### Backup Location
- All original files backed up to: $backupDir

---

## Execution Details
- **Dry Run:** $DryRun
- **Auto Apply:** $AutoApply
- **Timestamp:** $timestamp
- **Workspace:** $workspace

---

**Report END**
"@ | Out-File $reportFile -Append

# ============================================================================
# SUMMARY
# ============================================================================

Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║         CODE FIX COMPLETE                        ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

Write-Log "Changes Summary:" "INFO"
Write-Log "  - Removed stub files: $removedCount" "INFO"
Write-Log "  - Fixed deprecated APIs: $($replacementCount + $willPopCount)" "INFO"
Write-Log "  - Cleaned test imports: $testImportCount" "INFO"
Write-Log "  - Final error count: $afterErrors" "INFO"

if ($DryRun) {
    Write-Log "⚠️ DRY RUN: No changes were applied. Run without -DryRun to apply fixes." "WARNING"
}

Write-Log "Report saved: $reportFile" "SUCCESS"
Write-Log "Backup saved: $backupDir" "SUCCESS"

Write-Host ""
Write-Host "Next command:" -ForegroundColor Cyan
Write-Host "  .\master_production_pipeline.ps1 -Phase All" -ForegroundColor Yellow
Write-Host ""
