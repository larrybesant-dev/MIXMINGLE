param(
    [switch]$SkipWebBuild
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Push-Location $repoRoot

Write-Host 'Running release gate: flutter analyze...'
flutter analyze
if ($LASTEXITCODE -ne 0) {
    Write-Error 'Release gate failed: flutter analyze'
    exit $LASTEXITCODE
}

Write-Host 'Running release gate: architecture guardrails...'
powershell -ExecutionPolicy Bypass -File tools/validate_architecture_guardrails.ps1
if ($LASTEXITCODE -ne 0) {
    Write-Error 'Release gate failed: architecture guardrails'
    exit $LASTEXITCODE
}

if (-not $SkipWebBuild) {
    Write-Host "Running release gate: flutter build web --release --base-href '/'..."
    flutter build web --release --base-href '/'
    if ($LASTEXITCODE -ne 0) {
        Write-Error 'Release gate failed: web release build'
        exit $LASTEXITCODE
    }
}

Write-Host 'Release gate passed.'
Pop-Location
exit 0
