#!/usr/bin/env pwsh
# install_hooks.ps1 - Installs the pre-commit hook into .git/hooks/
# Run once per developer checkout: .\scripts\install_hooks.ps1

$hookPath = Join-Path $PSScriptRoot '..' '.git' 'hooks' 'pre-commit'
$hookPath = [System.IO.Path]::GetFullPath($hookPath)

$hookContent = @'
#!/bin/sh
# Runs the PowerShell pre-commit checks.
# Requires PowerShell 7+ (pwsh) on PATH.
exec pwsh -NoProfile -NonInteractive -File "scripts/pre_commit_check.ps1"
'@

Set-Content -Path $hookPath -Value $hookContent -Encoding ascii
# Make executable on Unix/mac (no-op on Windows)
if ($IsLinux -or $IsMacOS) {
    chmod +x $hookPath
}

Write-Host "✅ Pre-commit hook installed at $hookPath" -ForegroundColor Green
Write-Host "   It will run 'flutter analyze' + unit tests before every commit." -ForegroundColor Gray
