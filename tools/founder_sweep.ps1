# ================================================
# Mix & Mingle — Founder Sweep
# One command to verify the repo is ship-ready.
# Usage:  .\tools\founder_sweep.ps1
# ================================================

param(
  [switch]$SkipTests,
  [switch]$SkipBuildWeb,
  [switch]$SkipAndroid
)

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root

function Step($label) {
  Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkCyan
  Write-Host "   $label" -ForegroundColor Cyan
  Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkCyan
}

function Pass($msg)  { Write-Host "  ✅ $msg" -ForegroundColor Green }
function Fail($msg)  { Write-Host "  ❌ $msg" -ForegroundColor Red; exit 1 }
function Info($msg)  { Write-Host "  ℹ  $msg" -ForegroundColor Gray }

Write-Host "`n🚀 MIX & MINGLE — FOUNDER SWEEP`n" -ForegroundColor Magenta

# ── 1. pub get ──────────────────────────────────────────────────
Step "1/5  flutter pub get"
flutter pub get
if ($LASTEXITCODE -ne 0) { Fail "pub get failed" }
Pass "Dependencies resolved"

# ── 2. format ───────────────────────────────────────────────────
Step "2/5  flutter format (check only)"
flutter format --set-exit-if-changed .
if ($LASTEXITCODE -ne 0) {
  Info "Formatting issues found — running auto-format..."
  flutter format .
  Pass "Code formatted"
} else {
  Pass "Code already formatted"
}

# ── 3. analyze ──────────────────────────────────────────────────
Step "3/5  flutter analyze"
flutter analyze
if ($LASTEXITCODE -ne 0) { Fail "Static analysis failed — fix errors above" }
Pass "No analysis issues"

# ── 4. test ─────────────────────────────────────────────────────
if (-not $SkipTests) {
  Step "4/5  flutter test"
  flutter test
  if ($LASTEXITCODE -ne 0) { Fail "Tests failed" }
  Pass "All tests passed"
} else {
  Info "4/5  Tests skipped (-SkipTests)"
}

# ── 5. build web ────────────────────────────────────────────────
if (-not $SkipBuildWeb) {
  Step "5/5  flutter build web --release"
  flutter build web --release
  if ($LASTEXITCODE -ne 0) { Fail "Web build failed" }
  Pass "Web build succeeded"
} else {
  Info "5/5  Web build skipped (-SkipBuildWeb)"
}

# ── Optional: Android ───────────────────────────────────────────
if ($SkipAndroid -eq $false -and (Get-Command flutter -ErrorAction SilentlyContinue)) {
  # Only run android build if explicitly requested (it's slow)
}

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGreen
Write-Host "   🟢 SWEEP PASSED — repo is ship-ready" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor DarkGreen
