param(
  [int[]]$Ports = @(8080, 9090),
  [switch]$IncludeFlutterClean
)

$ErrorActionPreference = 'Stop'

function Write-Info {
  param([string]$Message)
  Write-Host "[dev-reset] $Message"
}

$results = @()

foreach ($port in $Ports) {
  Write-Info "Running deterministic port preflight cleanup for port $port"
  & powershell -ExecutionPolicy Bypass -File tools/port_preflight_guard.ps1 -Port $port -Mode Force -TimeoutSeconds 45 -StabilizationSeconds 3
  $exitCode = $LASTEXITCODE

  $result = [ordered]@{
    port = $port
    preflightExitCode = $exitCode
    released = ($exitCode -eq 0)
  }
  $results += $result

  if ($exitCode -ne 0) {
    Write-Info "Failed to release port $port. Check service ownership and run elevated if required."
  }
}

if ($IncludeFlutterClean) {
  Write-Info 'Running flutter clean and flutter pub get'
  flutter clean
  if ($LASTEXITCODE -ne 0) {
    throw 'flutter clean failed during dev reset.'
  }

  flutter pub get
  if ($LASTEXITCODE -ne 0) {
    throw 'flutter pub get failed during dev reset.'
  }
}

$summary = [ordered]@{
  contractVersion = 'mixvy.dev_reset_report.v1'
  generatedAtUtc = (Get-Date).ToUniversalTime().ToString('o')
  results = $results
}

$summaryPath = 'tools/reports/dev_reset_report.json'
New-Item -ItemType Directory -Path 'tools/reports' -Force | Out-Null
$summary | ConvertTo-Json -Depth 5 | Set-Content -Path $summaryPath -Encoding utf8

$failed = $results | Where-Object { -not $_.released }
if ($failed.Count -gt 0) {
  Write-Info "Dev reset incomplete. See $summaryPath"
  exit 1
}

Write-Info "Dev reset completed successfully. See $summaryPath"
exit 0
