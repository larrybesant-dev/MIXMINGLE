#!/usr/bin/env pwsh
# pre_commit_check.ps1 - Run before every commit to catch regressions.
# Usage: .\scripts\pre_commit_check.ps1
# Or install as a git hook: see scripts/install_hooks.ps1

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host "`n[1/3] Running flutter pub get..." -ForegroundColor Cyan
flutter pub get --offline 2>&1 | Select-Object -Last 3

Write-Host "`n[2/3] Running flutter analyze..." -ForegroundColor Cyan
$analyzeOut = flutter analyze --no-fatal-infos 2>&1
$analyzeOut | Select-Object -Last 5

# Extract issue count and fail if any ERRORS are present
$errorLines = $analyzeOut | Select-String -Pattern "^\s+error "
if ($errorLines.Count -gt 0) {
    Write-Host "`n❌ COMMIT BLOCKED — $($errorLines.Count) error(s) found:" -ForegroundColor Red
    $errorLines | ForEach-Object { Write-Host "   $_" -ForegroundColor Red }
    exit 1
}

$summary = $analyzeOut | Select-String -Pattern "\d+ issues? found|No issues found"
Write-Host "✅ Analyzer: $($summary.Line.Trim())" -ForegroundColor Green

Write-Host "`n[3/3] Running flutter test (fast unit tests only)..." -ForegroundColor Cyan
flutter test test/unit/ --reporter compact 2>&1 | Select-Object -Last 5
if ($LASTEXITCODE -ne 0) {
    Write-Host "`n❌ COMMIT BLOCKED — Unit tests failed." -ForegroundColor Red
    exit 1
}

Write-Host "`n✅ All pre-commit checks passed. Safe to push." -ForegroundColor Green
exit 0
