# ============================================================
# NULL-SAFETY SCANNER & AUTO-FIXER
# Finds all risky null patterns in Flutter Dart code
# ============================================================

param(
    [switch]$AutoFix = $false,
    [switch]$ExportReport = $true
)

Write-Host "🔍 NULL-SAFETY COMPREHENSIVE SCAN" -ForegroundColor Cyan
Write-Host "====================================`n" -ForegroundColor Cyan

$issues = @()
$fileCount = 0
$totalIssues = 0

# Pattern definitions
$patterns = @{
    'UnsafeToString' = @{
        Regex = '(?<!\?)\.toString\(\)'
        Severity = 'HIGH'
        Description = 'Calling .toString() without null-safety'
        Fix = 'Use ?.toString() or add ?? "default"'
    }
    'NullAssertion' = @{
        Regex = '(?<!=\s*\w+)!\s*[;\.\[]'
        Severity = 'CRITICAL'
        Description = 'Null assertion operator (!) that can crash'
        Fix = 'Replace ! with ?? or add null check'
    }
    'MapAccessToString' = @{
        Regex = '\[.+\]\.toString\(\)'
        Severity = 'CRITICAL'
        Description = 'Map/List access followed by .toString()'
        Fix = 'Use (map[key] ?? defaultValue).toString()'
    }
    'StringInterpolation' = @{
        Regex = 'Text\([''"].*\$\{?(\w+(?:\.\w+)?)'
        Severity = 'MEDIUM'
        Description = 'String interpolation in Text() that may be null'
        Fix = 'Use ${variable ?? "default"} or ${variable?.toString()}'
    }
    'PropertyChainToString' = @{
        Regex = '(?<!\?)\.\w+\.toString\(\)'
        Severity = 'HIGH'
        Description = 'Property chain ending in .toString() without null-safety'
        Fix = 'Use safe navigation: object?.property?.toString()'
    }
}

Write-Host "📂 Scanning lib/ directory...`n" -ForegroundColor Yellow

Get-ChildItem lib -Recurse -Filter "*.dart" | ForEach-Object {
    $file = $_
    $fileCount++
    $shortPath = $file.FullName -replace [regex]::Escape((Get-Location).Path + "\"), ""

    $lineNum = 0
    $lines = Get-Content $file.FullName

    foreach ($line in $lines) {
        $lineNum++

        # Skip comments and error handling
        if ($line -match '^\s*//' -or $line -match 'catch.*e\.toString' -or $line -match 'Exception.*toString') {
            continue
        }

        foreach ($patternName in $patterns.Keys) {
            $pattern = $patterns[$patternName]

            if ($line -match $pattern.Regex) {
                # Additional filtering for false positives
                $isFalsePositive = $false

                if ($patternName -eq 'UnsafeToString' -and $line -match '\?\?') {
                    $isFalsePositive = $true
                }

                if ($patternName -eq 'NullAssertion' -and ($line -match '!=' -or $line -match '!!')) {
                    $isFalsePositive = $true
                }

                if (-not $isFalsePositive) {
                    $totalIssues++

                    $issues += [PSCustomObject]@{
                        File = $shortPath
                        Line = $lineNum
                        Severity = $pattern.Severity
                        Pattern = $patternName
                        Code = $line.Trim()
                        Description = $pattern.Description
                        Fix = $pattern.Fix
                    }
                }
            }
        }
    }
}

Write-Host "✅ Scan Complete!" -ForegroundColor Green
Write-Host "   Files scanned: $fileCount" -ForegroundColor Cyan
Write-Host "   Issues found: $totalIssues`n" -ForegroundColor $(if ($totalIssues -gt 0) { 'Red' } else { 'Green' })

if ($totalIssues -eq 0) {
    Write-Host "🎉 No null-safety issues detected!" -ForegroundColor Green
    exit 0
}

# Group by severity
$critical = $issues | Where-Object { $_.Severity -eq 'CRITICAL' }
$high = $issues | Where-Object { $_.Severity -eq 'HIGH' }
$medium = $issues | Where-Object { $_.Severity -eq 'MEDIUM' }

Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "           ISSUE BREAKDOWN                 " -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🔴 CRITICAL: $($critical.Count) issues" -ForegroundColor Red
Write-Host "🟠 HIGH:     $($high.Count) issues" -ForegroundColor Yellow
Write-Host "🟡 MEDIUM:   $($medium.Count) issues" -ForegroundColor Yellow
Write-Host ""

# Show top 20 critical issues
if ($critical.Count -gt 0) {
    Write-Host "🔴 TOP CRITICAL ISSUES (showing first 20):" -ForegroundColor Red
    Write-Host ""

    $critical | Select-Object -First 20 | ForEach-Object {
        Write-Host "📄 $($_.File):$($_.Line)" -ForegroundColor Yellow
        Write-Host "   Pattern: $($_.Pattern)" -ForegroundColor Cyan
        Write-Host "   Code: $($_.Code)" -ForegroundColor White
        Write-Host "   Fix: $($_.Fix)" -ForegroundColor Green
        Write-Host ""
    }

    if ($critical.Count -gt 20) {
        Write-Host "   ... and $($critical.Count - 20) more critical issues`n" -ForegroundColor Gray
    }
}

# Export report
if ($ExportReport) {
    $reportPath = "null_safety_report.csv"
    $issues | Export-Csv -Path $reportPath -NoTypeInformation -Encoding UTF8
    Write-Host "📊 Full report exported to: $reportPath" -ForegroundColor Cyan
    Write-Host "   View with: code $reportPath`n" -ForegroundColor Gray
}

# Auto-fix option
if ($AutoFix) {
    Write-Host "⚠️  AUTO-FIX MODE NOT IMPLEMENTED YET" -ForegroundColor Yellow
    Write-Host "   Due to complexity, manual review recommended." -ForegroundColor Yellow
    Write-Host "   Open the CSV report and fix issues one by one.`n" -ForegroundColor Yellow
} else {
    Write-Host "💡 TIP: Run with -AutoFix flag for automatic fixes (use with caution)" -ForegroundColor Cyan
    Write-Host "   Example: .\null_safety_scanner.ps1 -AutoFix`n" -ForegroundColor Gray
}

Write-Host "═══════════════════════════════════════════`n" -ForegroundColor Cyan

# Summary recommendations
Write-Host "📋 RECOMMENDED ACTIONS:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Fix CRITICAL issues first (null assertions and map access)" -ForegroundColor White
Write-Host "2. Review HIGH severity items (unsafe .toString() calls)" -ForegroundColor White
Write-Host "3. Address MEDIUM issues in UI-heavy code" -ForegroundColor White
Write-Host "4. Test thoroughly after each batch of fixes" -ForegroundColor White
Write-Host ""
Write-Host "🔧 Common fixes:" -ForegroundColor Yellow
Write-Host "   • map[key].toString() → (map[key] ?? 0).toString()" -ForegroundColor Green
Write-Host "   • variable! → variable ?? defaultValue" -ForegroundColor Green
Write-Host "   • obj.prop.toString() → obj.prop?.toString() ?? 'default'" -ForegroundColor Green
Write-Host "   • Text('\$var') → Text('\${var ?? ''}')" -ForegroundColor Green
Write-Host ""
