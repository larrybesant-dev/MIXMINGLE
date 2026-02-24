#!/usr/bin/env pwsh
# Flutter Web Layout Diagnostics
# Scans for widgets causing infinite constraint issues

Write-Host "🔍 Flutter Web Layout Diagnostics" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

$issues = @()
$warnings = @()
$suspiciousFiles = @()

# Pattern 1: ListView/SingleChildScrollView in Column without Expanded/SizedBox
Write-Host "📜 Checking for unbounded scrollables in Column/Row..." -ForegroundColor Yellow

$dartFiles = Get-ChildItem -Path "lib" -Recurse -Filter "*.dart"

foreach ($file in $dartFiles) {
    $content = Get-Content $file.FullName -Raw
    $lines = Get-Content $file.FullName

    $relPath = $file.FullName.Replace("$PWD\", "")

    # Check for Column containing ListView without Expanded
    if ($content -match "Column\s*\(" -and
        ($content -match "ListView\(" -or $content -match "ListView\.builder\(" -or
         $content -match "SingleChildScrollView\(" -or $content -match "CustomScrollView\(")) {

        # Check if there's an Expanded/SizedBox wrapping it
        $hasExpanded = $content -match "Expanded\s*\(\s*child:\s*(ListView|SingleChildScrollView|CustomScrollView)"
        $hasSizedBox = $content -match "SizedBox\s*\([^)]*height:[^)]*child:\s*(ListView|SingleChildScrollView|CustomScrollView)"

        if (-not $hasExpanded -and -not $hasSizedBox) {
            $lineNum = 0
            for ($i = 0; $i -lt $lines.Count; $i++) {
                if ($lines[$i] -match "(ListView|SingleChildScrollView|CustomScrollView)") {
                    $lineNum = $i + 1
                    break
                }
            }

            $issues += "ERROR: $relPath (line ~$lineNum) - Scrollable in Column/Row without Expanded/SizedBox"
            $suspiciousFiles += $relPath
            Write-Host "  ❌ $relPath (line ~$lineNum)" -ForegroundColor Red
        }
    }

    # Check for Row containing horizontal ListView
    if ($content -match "Row\s*\(" -and
        ($content -match "ListView\s*\([^)]*scrollDirection:\s*Axis\.horizontal" -or
         $content -match "ListView\.builder\s*\([^)]*scrollDirection:\s*Axis\.horizontal")) {

        $hasExpanded = $content -match "Expanded\s*\(\s*child:\s*ListView"
        $hasSizedBox = $content -match "SizedBox\s*\([^)]*width:[^)]*child:\s*ListView"

        if (-not $hasExpanded -and -not $hasSizedBox) {
            $warnings += "WARNING: $relPath - Horizontal ListView in Row without width constraint"
            Write-Host "  ⚠️  $relPath" -ForegroundColor Yellow
        }
    }
}

Write-Host ""

# Pattern 2: Unbounded Container/SizedBox without dimensions
Write-Host "📦 Checking for unbounded containers..." -ForegroundColor Yellow

foreach ($file in $dartFiles) {
    $content = Get-Content $file.FullName -Raw
    $lines = Get-Content $file.FullName
    $relPath = $file.FullName.Replace("$PWD\", "")

    # Look for Container with no height/width in Column
    if ($content -match "Column\s*\(" -and $content -match "Container\s*\(") {
        # Check if Container has height or width
        $containerMatches = [regex]::Matches($content, "Container\s*\([^\}]+?\)")

        foreach ($match in $containerMatches) {
            $containerBlock = $match.Value
            if ($containerBlock -notmatch "height:" -and $containerBlock -notmatch "width:" -and
                $containerBlock -notmatch "constraints:" -and $containerBlock -match "child:") {

                $warnings += "WARNING: $relPath - Container without dimensions may cause issues"
                Write-Host "  ⚠️  $relPath - Unbounded Container" -ForegroundColor Yellow
                break
            }
        }
    }
}

Write-Host ""

# Pattern 3: Flexible/Expanded misuse
Write-Host "🔄 Checking for Flexible/Expanded misuse..." -ForegroundColor Yellow

foreach ($file in $dartFiles) {
    $content = Get-Content $file.FullName -Raw
    $relPath = $file.FullName.Replace("$PWD\", "")

    # Expanded outside Column/Row/Flex
    if ($content -match "Expanded\s*\(") {
        # This is a rough check - just warn about potential issues
        if ($content -notmatch "Column\s*\(" -and $content -notmatch "Row\s*\(" -and
            $content -notmatch "Flex\s*\(") {
            $warnings += "WARNING: $relPath - Expanded used outside Column/Row/Flex context"
        }
    }
}

Write-Host ""

# Pattern 4: IntrinsicHeight/IntrinsicWidth overuse (expensive on web)
Write-Host "⚡ Checking for expensive layout widgets..." -ForegroundColor Yellow

foreach ($file in $dartFiles) {
    $content = Get-Content $file.FullName -Raw
    $relPath = $file.FullName.Replace("$PWD\", "")

    if ($content -match "IntrinsicHeight|IntrinsicWidth") {
        $warnings += "WARNING: $relPath - IntrinsicHeight/Width is expensive (especially on web)"
        Write-Host "  ⚠️  $relPath - Uses Intrinsic widgets (performance impact)" -ForegroundColor Yellow
    }
}

Write-Host ""

# Pattern 5: Nested scrollables (can cause issues)
Write-Host "🔁 Checking for nested scrollables..." -ForegroundColor Yellow

foreach ($file in $dartFiles) {
    $content = Get-Content $file.FullName -Raw
    $relPath = $file.FullName.Replace("$PWD\", "")

    # Count scrollable widgets
    $scrollableCount = ([regex]::Matches($content, "ListView|SingleChildScrollView|CustomScrollView|GridView")).Count

    if ($scrollableCount -gt 2) {
        $warnings += "WARNING: $relPath - Multiple scrollables ($scrollableCount) - check for nesting"
        Write-Host "  ⚠️  $relPath - $scrollableCount scrollable widgets (may be nested)" -ForegroundColor Yellow
    }
}

Write-Host ""

# Pattern 6: MediaQuery.of(context).size usage without SafeArea
Write-Host "📱 Checking for viewport size usage..." -ForegroundColor Yellow

foreach ($file in $dartFiles) {
    $content = Get-Content $file.FullName -Raw
    $relPath = $file.FullName.Replace("$PWD\", "")

    if ($content -match "MediaQuery\.of\(context\)\.size" -and $content -notmatch "SafeArea") {
        # This is just informational
        # Write-Host "  ℹ️  $relPath: Uses MediaQuery.size (ensure proper constraints)" -ForegroundColor Gray
    }
}

Write-Host ""

# Summary
Write-Host "====================================" -ForegroundColor Cyan
Write-Host "📊 LAYOUT DIAGNOSTIC SUMMARY" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "🔴 CRITICAL ISSUES: $($issues.Count)" -ForegroundColor Red
Write-Host "⚠️  WARNINGS: $($warnings.Count)" -ForegroundColor Yellow
Write-Host ""

if ($issues.Count -gt 0) {
    Write-Host "Critical issues that need fixing:" -ForegroundColor Red
    $issues | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    Write-Host ""
}

if ($warnings.Count -gt 0 -and $warnings.Count -le 10) {
    Write-Host "Warnings to review:" -ForegroundColor Yellow
    $warnings | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
    Write-Host ""
} elseif ($warnings.Count -gt 10) {
    Write-Host "First 10 warnings:" -ForegroundColor Yellow
    $warnings | Select-Object -First 10 | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
    Write-Host "  ... and $($warnings.Count - 10) more" -ForegroundColor Gray
    Write-Host ""
}

if ($issues.Count -gt 0) {
    Write-Host "💡 RECOMMENDED FIXES:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "For scrollables in Column/Row:" -ForegroundColor White
    Write-Host "  ❌ BAD:" -ForegroundColor Red
    Write-Host "     Column(children: [ListView(...)])" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  ✅ GOOD:" -ForegroundColor Green
    Write-Host "     Column(children: [Expanded(child: ListView(...))])" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  OR:" -ForegroundColor Cyan
    Write-Host "     Column(children: [SizedBox(height: 500, child: ListView(...))])" -ForegroundColor Gray
    Write-Host ""
}

# Generate detailed report for suspicious files
if ($suspiciousFiles.Count -gt 0) {
    Write-Host "🔍 Top files to check:" -ForegroundColor Cyan
    $suspiciousFiles | Select-Object -Unique | Select-Object -First 5 | ForEach-Object {
        Write-Host "  - $_" -ForegroundColor White
    }
    Write-Host ""
}

# Export detailed report
$reportFile = "web_layout_diagnostic_report.md"
$report = @"
# Flutter Web Layout Diagnostic Report
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Summary
- **Critical Issues**: $($issues.Count)
- **Warnings**: $($warnings.Count)

## Critical Issues (Fix Required)
$(if ($issues.Count -gt 0) { $issues | ForEach-Object { "- $_`n" } } else { "None`n" })

## Warnings (Review Recommended)
$(if ($warnings.Count -gt 0) { $warnings | ForEach-Object { "- $_`n" } } else { "None`n" })

## Common Fixes

### 1. Scrollable in Column
**Problem**: ListView/SingleChildScrollView in Column without bounds

**Fix**:
``````dart
// Bad
Column(
  children: [
    ListView(...), // ❌ Infinite height
  ],
)

// Good - Option 1: Use Expanded
Column(
  children: [
    Expanded(
      child: ListView(...), // ✅ Takes remaining space
    ),
  ],
)

// Good - Option 2: Fixed height
Column(
  children: [
    SizedBox(
      height: 500,
      child: ListView(...), // ✅ Fixed height
    ),
  ],
)

// Good - Option 3: Use shrinkWrap
Column(
  children: [
    ListView(
      shrinkWrap: true, // ✅ Only takes needed space
      physics: NeverScrollableScrollPhysics(),
      children: [...],
    ),
  ],
)
``````

### 2. Horizontal ListView in Row
**Problem**: Horizontal ListView in Row without width constraint

**Fix**:
``````dart
// Bad
Row(
  children: [
    ListView(
      scrollDirection: Axis.horizontal, // ❌ Infinite width
      children: [...],
    ),
  ],
)

// Good
Row(
  children: [
    Expanded(
      child: ListView(
        scrollDirection: Axis.horizontal, // ✅ Constrained width
        children: [...],
      ),
    ),
  ],
)
``````

### 3. Nested Scrollables
**Problem**: Multiple scrollable widgets nested

**Fix**: Use `CustomScrollView` with slivers or disable inner scroll:
``````dart
CustomScrollView(
  slivers: [
    SliverList(...),
    SliverGrid(...),
  ],
)
``````

## Next Steps
1. Fix all ❌ critical issues listed above
2. Review ⚠️  warnings for potential problems
3. Test on web with: ``flutter run -d chrome``
4. Check browser console for remaining errors

"@

$report | Out-File -FilePath $reportFile -Encoding UTF8
Write-Host "📄 Full report saved to: $reportFile" -ForegroundColor Cyan
Write-Host ""

if ($issues.Count -eq 0) {
    Write-Host "✅ No critical layout issues found!" -ForegroundColor Green
    Write-Host "Your web app should render correctly." -ForegroundColor Green
} else {
    Write-Host "🔧 Fix the $($issues.Count) critical issue(s) above to resolve layout errors." -ForegroundColor Yellow
}
