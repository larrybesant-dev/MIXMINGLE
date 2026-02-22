#!/usr/bin/env pwsh
# scripts/apply_analysis_rollback.ps1
#
# Removes temporary analysis_options.yaml exclusions that were added during
# the staged lint re-enable.  Run this once Stage 3 is complete and all
# platform-specific issues in the formerly-excluded files are resolved.
#
# Usage:
#   .\scripts\apply_analysis_rollback.ps1 [-DryRun]
#
# What it does:
#   1. Removes "test/**" and "integration_test/**" from analyzer.exclude.
#   2. Re-enables prefer_const_constructors, prefer_const_declarations,
#      prefer_final_fields, and prefer_final_locals.
#   3. Runs "flutter analyze" and reports the result.
#
# Prerequisites: Run AFTER completing lint Stage 1 and Stage 2 PRs.

param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$file    = Join-Path $PSScriptRoot '..' 'analysis_options.yaml'
$file    = [System.IO.Path]::GetFullPath($file)
$content = Get-Content $file -Raw

# ── 1. Remove temporary test excludes ────────────────────────────────────────
$testExcludesPattern = @'
    # Test files – many stubs extend sealed classes and use raw variables intentionally
    - test/**
    - integration_test/**

'@

if ($content -notmatch [regex]::Escape('- test/**')) {
    Write-Host "ℹ️  test/** exclude not found — may already be removed." -ForegroundColor Yellow
} else {
    $content = $content -replace [regex]::Escape($testExcludesPattern), ''
    Write-Host "✅ Removed test/** and integration_test/** from analyzer.exclude" -ForegroundColor Green
}

# ── 2. Re-enable lint rules ───────────────────────────────────────────────────
$replacements = @(
    @{ Old = '    prefer_const_constructors: false # Too strict for current codebase'; New = '    prefer_const_constructors: true' },
    @{ Old = '    prefer_const_declarations: false # Too strict';                      New = '    prefer_const_declarations: true' },
    @{ Old = '    prefer_final_fields: false # Too strict';                            New = '    prefer_final_fields: true' },
    @{ Old = '    prefer_final_locals: false # Too strict';                            New = '    prefer_final_locals: true' }
)

foreach ($r in $replacements) {
    if ($content -match [regex]::Escape($r.Old)) {
        $content = $content -replace [regex]::Escape($r.Old), $r.New
        Write-Host "✅ Re-enabled: $($r.New.Trim())" -ForegroundColor Green
    } else {
        Write-Host "ℹ️  Rule not found (already updated?): $($r.Old.Trim())" -ForegroundColor Yellow
    }
}

# ── 3. Write or preview ───────────────────────────────────────────────────────
if ($DryRun) {
    Write-Host "`n--- DRY RUN: showing updated file (not written) ---" -ForegroundColor Cyan
    $content | Write-Host
    exit 0
}

Set-Content -Path $file -Value $content -NoNewline
Write-Host "`n📝 analysis_options.yaml updated." -ForegroundColor Cyan

# ── 4. Verify with flutter analyze ───────────────────────────────────────────
Write-Host "`n🔎 Running flutter analyze --no-fatal-infos ..." -ForegroundColor Cyan
flutter analyze --no-fatal-infos
if ($LASTEXITCODE -ne 0) {
    Write-Host "`n❌ Analyzer found issues after rollback. Fix them, then commit." -ForegroundColor Red
    exit 1
}

Write-Host "`n✅ analysis_options.yaml rollback complete. Clean up any remaining issues, then commit:" -ForegroundColor Green
Write-Host "   git add analysis_options.yaml" -ForegroundColor Gray
Write-Host "   git commit -m 'chore(lint): restore strict analysis_options after staged re-enable'" -ForegroundColor Gray
