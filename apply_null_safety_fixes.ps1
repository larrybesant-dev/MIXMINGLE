# ============================================================
# TARGETED NULL-SAFETY AUTO-FIXER
# Fixes the most dangerous patterns first
# ============================================================

Write-Host "🔧 APPLYING TARGETED NULL-SAFETY FIXES" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$fixCount = 0
$filesFixed = @()

# Priority 1: Fix MapAccessToString pattern (most likely culprit)
Write-Host "🎯 Priority 1: Fixing map[key].toString() patterns...`n" -ForegroundColor Yellow

$report = Import-Csv null_safety_report.csv
$mapIssues = $report | Where-Object { $_.Pattern -eq 'MapAccessToString' }

Write-Host "Found $($mapIssues.Count) map access issues`n" -ForegroundColor Cyan

foreach ($issue in $mapIssues) {
    Write-Host "📄 Fixing: $($issue.File):$($issue.Line)" -ForegroundColor Yellow
    Write-Host "   Before: $($issue.Code)" -ForegroundColor Red

    # Read file
    $filePath = Join-Path (Get-Location) $issue.File
    $content = Get-Content $filePath -Raw

    # Pattern: something[key].toString() → (something[key] ?? defaultValue).toString()
    # We need to be smart about the default value based on context

    $oldLine = $issue.Code
    $newLine = $oldLine

    # Detect the pattern and wrap with null-coalescing
    if ($oldLine -match '(\w+)\[([^\]]+)\]\.toString\(\)') {
        $mapName = $Matches[1]
        $key = $Matches[2]

        # Determine default value based on context
        $defaultValue = '0'
        if ($oldLine -match 'count|Count|total|Total') {
            $defaultValue = '0'
        } elseif ($oldLine -match 'name|Name|text|Text|message|Message') {
            $defaultValue = "''"
        }

        $newLine = $oldLine -replace "$mapName\[$key\]\.toString\(\)", "($mapName[$key] ?? $defaultValue).toString()"

        Write-Host "   After:  $newLine" -ForegroundColor Green

        # Apply fix
        if ($content -match [regex]::Escape($oldLine)) {
            $content = $content -replace [regex]::Escape($oldLine), $newLine
            Set-Content -Path $filePath -Value $content -NoNewline
            $fixCount++

            if ($filesFixed -notcontains $issue.File) {
                $filesFixed += $issue.File
            }
        }
    }

    Write-Host ""
}

Write-Host "`n✅ Fixed $fixCount map access issues in $($filesFixed.Count) files`n" -ForegroundColor Green

# Priority 2: Fix critical null assertions in hot-path files
Write-Host "🎯 Priority 2: Fixing critical null assertions in auth/home files...`n" -ForegroundColor Yellow

$criticalFiles = @(
    'lib\auth_gate.dart',
    'lib\home_simple.dart',
    'lib\features\home_page.dart',
    'lib\features\chat_list_page.dart'
)

$hotPathIssues = $report | Where-Object {
    $_.Pattern -eq 'NullAssertion' -and
    $criticalFiles -contains $_.File
}

Write-Host "Found $($hotPathIssues.Count) null assertions in hot-path files`n" -ForegroundColor Cyan

foreach ($issue in $hotPathIssues) {
    Write-Host "📄 $($issue.File):$($issue.Line)" -ForegroundColor Yellow
    Write-Host "   Code: $($issue.Code)" -ForegroundColor White
    Write-Host "   Note: Requires manual review - null assertions are context-dependent" -ForegroundColor Gray
    Write-Host ""
}

Write-Host "`n═══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "           FIX SUMMARY                      " -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "✅ Auto-fixed: $fixCount issues" -ForegroundColor Green
Write-Host "📂 Files modified: $($filesFixed.Count)" -ForegroundColor Cyan
Write-Host ""
Write-Host "⚠️  Remaining null assertions require manual review" -ForegroundColor Yellow
Write-Host "   These are context-dependent and need careful analysis" -ForegroundColor Yellow
Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Review the changes in the modified files" -ForegroundColor White
Write-Host "2. Run: flutter run -d chrome --web-port=5000 --release" -ForegroundColor White
Write-Host "3. Check Chrome DevTools console for remaining errors" -ForegroundColor White
Write-Host ""
