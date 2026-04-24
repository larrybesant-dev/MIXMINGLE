param(
  [int]$Port = 8080,
  [string]$StartupProbeReportPath = 'tools/reports/startup_probe_report.json',
  [string]$SmokeProbeReportPath = 'tools/reports/web_failure_smoke_report.json',
  [string]$PreflightReportPath = 'artifacts/port_preflight_report.json',
  [string]$OutputPath = 'artifacts/deployment_contract.json'
)

$ErrorActionPreference = 'Stop'

function Get-OsClass {
  if ($env:RUNNER_OS) {
    switch ($env:RUNNER_OS.ToLowerInvariant()) {
      'windows' { return 'windows' }
      'linux' { return 'linux' }
      'macos' { return 'macos' }
    }
  }

  if ($IsWindows) { return 'windows' }
  if ($IsLinux) { return 'linux' }
  if ($IsMacOS) { return 'macos' }
  return 'windows'
}

function Resolve-EnvironmentClass {
  try {
    $raw = & powershell -ExecutionPolicy Bypass -File tools/detect_execution_environment.ps1 -JsonOnly
    $parsed = $raw | ConvertFrom-Json
    if ($parsed.environment -in @('ci', 'local', 'unknown')) {
      return [string]$parsed.environment
    }
  } catch {
    # Fall back to static environment probes.
  }

  if ($env:GITHUB_ACTIONS -eq 'true' -or $env:CI -eq 'true') {
    return 'ci'
  }

  if (-not [string]::IsNullOrWhiteSpace($env:USERNAME)) {
    return 'local'
  }

  return 'unknown'
}

function Resolve-IsAdmin {
  try {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
  } catch {
    return $false
  }
}

function Resolve-PortOwnership {
  param([int]$TargetPort)

  $listenerPid = $null
  try {
    $conn = Get-NetTCPConnection -LocalPort $TargetPort -State Listen -ErrorAction Stop | Select-Object -First 1
    if ($conn) {
      $listenerPid = [int]$conn.OwningProcess
    }
  } catch {
    try {
      $line = netstat -ano -p tcp | Select-String -Pattern "^\s*TCP\s+\S+:$TargetPort\s+\S+\s+LISTENING\s+(\d+)\s*$" | Select-Object -First 1
      if ($line) {
        $m = [regex]::Match($line.Line, "^\s*TCP\s+\S+:$TargetPort\s+\S+\s+LISTENING\s+(\d+)\s*$")
        if ($m.Success) {
          $listenerPid = [int]$m.Groups[1].Value
        }
      }
    } catch {
      $listenerPid = $null
    }
  }

  if ($null -eq $listenerPid) {
    return 'unknown'
  }

  if ($listenerPid -eq 4) {
    return 'system'
  }

  $services = @(Get-CimInstance Win32_Service -Filter "ProcessId = $listenerPid" -ErrorAction SilentlyContinue)
  if ($services.Count -gt 0) {
    return 'service'
  }

  return 'user'
}

function Get-ProbeStatus {
  param($Report)

  if ($null -eq $Report) {
    return 'fail'
  }

  $status = [string]$Report.status
  if ($status.ToUpperInvariant() -eq 'PASS') {
    return 'pass'
  }

  return 'fail'
}

function Read-JsonIfPresent {
  param([string]$Path)

  if (-not (Test-Path $Path)) {
    return $null
  }

  try {
    return (Get-Content -Path $Path -Raw | ConvertFrom-Json)
  } catch {
    return $null
  }
}

$startupReport = Read-JsonIfPresent -Path $StartupProbeReportPath
$smokeReport = Read-JsonIfPresent -Path $SmokeProbeReportPath
$preflightReport = Read-JsonIfPresent -Path $PreflightReportPath

$startupContractVersion = 'unknown'
$startupReady = $false
$startupCheckpoints = @()
if ($null -ne $startupReport -and $null -ne $startupReport.finalContract) {
  $startupContractVersion = [string]$startupReport.finalContract.contractVersion
  if ([string]::IsNullOrWhiteSpace($startupContractVersion)) {
    $startupContractVersion = 'unknown'
  }

  $startupReady = [bool]$startupReport.finalContract.ready

  if ($null -ne $startupReport.finalContract.checkpoints) {
    $startupCheckpoints = @($startupReport.finalContract.checkpoints.PSObject.Properties.Name)
  }
}

$environmentClass = Resolve-EnvironmentClass
$isAdmin = Resolve-IsAdmin
$privilegeClass = if ($isAdmin) {
  'admin'
} elseif ($environmentClass -eq 'ci') {
  'restricted'
} else {
  'non-admin'
}

$portOwnership = Resolve-PortOwnership -TargetPort $Port
if ($null -ne $preflightReport -and -not [string]::IsNullOrWhiteSpace([string]$preflightReport.portOwnership)) {
  $candidate = [string]$preflightReport.portOwnership
  if ($candidate -in @('system', 'service', 'user', 'unknown')) {
    $portOwnership = $candidate
  }
}

$startupProbeStatus = Get-ProbeStatus -Report $startupReport
$smokeProbeStatus = Get-ProbeStatus -Report $smokeReport

$decision = 'deny'
$reasonCode = 'policy_rejection'

$serviceConflict = ($portOwnership -in @('service', 'system'))
$probeFailure = ($startupProbeStatus -eq 'fail' -or $smokeProbeStatus -eq 'fail')
$appContractInvalid = ([string]::IsNullOrWhiteSpace($startupContractVersion) -or $startupContractVersion -eq 'unknown' -or -not $startupReady)
$privilegePolicyBlocked = (($environmentClass -eq 'unknown' -and $privilegeClass -ne 'admin') -or ($environmentClass -eq 'ci' -and $privilegeClass -eq 'restricted' -and -not $serviceConflict))

if ($probeFailure) {
  $decision = 'deny'
  $reasonCode = 'probe_failure'
} elseif ($appContractInvalid) {
  $decision = 'deny'
  $reasonCode = 'app_contract_failure'
} elseif ($privilegePolicyBlocked) {
  $decision = 'deny'
  $reasonCode = 'env_privilege_blocked'
} elseif ($serviceConflict -and $privilegeClass -ne 'admin') {
  $decision = 'allow-with-degradation'
  $reasonCode = 'service_ownership_blocked'
} else {
  $decision = 'allow'
  $reasonCode = 'policy_rejection'
}

$contract = [ordered]@{
  artifact = [ordered]@{
    commitSha = if ([string]::IsNullOrWhiteSpace($env:GITHUB_SHA)) {
      try { (& git rev-parse HEAD 2>$null).Trim() } catch { 'unknown' }
    } else {
      $env:GITHUB_SHA
    }
    buildId = if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_RUN_NUMBER)) { $env:GITHUB_RUN_NUMBER } else { 'unknown' }
    workflowRunId = if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_RUN_ID)) { $env:GITHUB_RUN_ID } else { 'unknown' }
  }
  startup = [ordered]@{
    contractVersion = $startupContractVersion
    ready = $startupReady
    checkpoints = @($startupCheckpoints)
  }
  environment = [ordered]@{
    class = $environmentClass
    os = Get-OsClass
  }
  privilege = [ordered]@{
    class = $privilegeClass
  }
  networking = [ordered]@{
    port = $Port
    portOwnership = $portOwnership
  }
  probeResults = [ordered]@{
    startupProbe = $startupProbeStatus
    smokeProbe = $smokeProbeStatus
  }
  governance = [ordered]@{
    decision = $decision
    reasonCode = $reasonCode
  }
}

New-Item -ItemType Directory -Path (Split-Path -Path $OutputPath -Parent) -Force | Out-Null
$contract | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding utf8
Write-Host "[deployment-contract] Wrote $OutputPath"
