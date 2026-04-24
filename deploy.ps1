param(
  [int]$Port = 9090,
  [string]$BuildPath = 'build/web',
  [string]$DeployRoot = 'deploy'
)

$ErrorActionPreference = 'Stop'

$startupLogPath = 'tools/reports/startup_timeline.log'
$startupReportPath = 'tools/reports/startup_probe_report.json'
$smokeReportPath = 'tools/reports/web_failure_smoke_report.json'
$preflightReportPath = 'artifacts/port_preflight_report.json'
$contractPath = 'artifacts/deployment_contract.json'
$evaluationPath = 'artifacts/deployment_contract_evaluation.json'
$resolvedContractPath = 'artifacts/deployment_contract.resolved.json'
$previousHashPath = 'artifacts/hash_chain/previous_contract_hash.txt'
$currentHashPath = 'artifacts/hash_chain/current_contract_hash.txt'
$appUrl = "http://127.0.0.1:$Port/"

function Write-Stage {
  param([string]$Name)
  Write-Host ""
  Write-Host "== $Name =="
}

function Invoke-PowerShellScript {
  param(
    [string]$ScriptPath,
    [string[]]$Arguments = @(),
    [switch]$AllowFailure
  )

  $cmdOutput = & powershell -ExecutionPolicy Bypass -File $ScriptPath @Arguments 2>&1
  foreach ($line in $cmdOutput) {
    Write-Host $line
  }
  if (-not $AllowFailure -and $LASTEXITCODE -ne 0) {
    throw "Script failed: $ScriptPath (exit=$LASTEXITCODE)"
  }

  return $LASTEXITCODE
}

function Invoke-CommandWithExitCode {
  param(
    [scriptblock]$Command,
    [string]$Name
  )

  try {
    $cmdOutput = & $Command 2>&1
    foreach ($line in $cmdOutput) {
      Write-Host $line
    }
    return $LASTEXITCODE
  }
  catch {
    Write-Host "[stage-fail] ${Name}: $($_.Exception.Message)"
    return 1
  }
}

function Wait-AppReady {
  param(
    [string]$Url,
    [int]$TimeoutSeconds = 45
  )

  for ($i = 0; $i -lt $TimeoutSeconds; $i++) {
    try {
      Invoke-WebRequest -Uri $Url -UseBasicParsing | Out-Null
      return
    }
    catch {
      Start-Sleep -Seconds 1
    }
  }

  throw "App did not become ready at $Url within $TimeoutSeconds seconds."
}

function Resolve-PortOwnershipClass {
  param([int]$TargetPort)

  $listenerPid = $null
  try {
    $conn = Get-NetTCPConnection -LocalPort $TargetPort -State Listen -ErrorAction Stop | Select-Object -First 1
    if ($conn) {
      $listenerPid = [int]$conn.OwningProcess
    }
  }
  catch {
    try {
      $line = netstat -ano -p tcp | Select-String -Pattern "^\s*TCP\s+\S+:$TargetPort\s+\S+\s+LISTENING\s+(\d+)\s*$" | Select-Object -First 1
      if ($line) {
        $m = [regex]::Match($line.Line, "^\s*TCP\s+\S+:$TargetPort\s+\S+\s+LISTENING\s+(\d+)\s*$")
        if ($m.Success) {
          $listenerPid = [int]$m.Groups[1].Value
        }
      }
    }
    catch {
      $listenerPid = $null
    }
  }

  # Free port is modeled as user-available capacity for deterministic governance.
  if ($null -eq $listenerPid) {
    return 'user'
  }

  if ($listenerPid -eq 4) {
    return 'system'
  }

  $svc = Get-CimInstance Win32_Service -Filter "ProcessId = $listenerPid" -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($svc) {
    return 'service'
  }

  return 'user'
}

function Write-Utf8NoBom {
  param(
    [string]$Path,
    [string]$Content
  )

  New-Item -ItemType Directory -Path (Split-Path -Path $Path -Parent) -Force | Out-Null
  $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
  [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

function Persist-AuditHistory {
  param(
    [string]$Root,
    [string]$ContractFile,
    [string]$ResolvedFile,
    [string]$EvaluationFile,
    $ResolvedContract
  )

  $historyStamp = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ')
  $historyDir = Join-Path $Root "history/$historyStamp"
  New-Item -ItemType Directory -Path $historyDir -Force | Out-Null

  if (-not (Test-Path $ContractFile)) { throw "Missing audit input: $ContractFile" }
  if (-not (Test-Path $ResolvedFile)) { throw "Missing audit input: $ResolvedFile" }
  if (-not (Test-Path $EvaluationFile)) { throw "Missing audit input: $EvaluationFile" }

  Copy-Item -Path $ContractFile -Destination (Join-Path $historyDir 'deployment_contract.json') -Force
  Copy-Item -Path $ResolvedFile -Destination (Join-Path $historyDir 'deployment_contract.resolved.json') -Force
  Copy-Item -Path $EvaluationFile -Destination (Join-Path $historyDir 'evaluation.json') -Force
  Write-Utf8NoBom -Path (Join-Path $historyDir 'hash.txt') -Content "contractHash=$($ResolvedContract.contractHash)`npreviousHash=$($ResolvedContract.previousContractHash)"
}

try {
  New-Item -ItemType Directory -Path 'artifacts' -Force | Out-Null
  New-Item -ItemType Directory -Path 'artifacts/hash_chain' -Force | Out-Null
  New-Item -ItemType Directory -Path 'tools/reports' -Force | Out-Null

  $resetExitCode = 0
  $preflightExitCode = 0
  $buildExitCode = 0
  $startupProbeExitCode = 0
  $smokeProbeExitCode = 0
  $contractBuildExitCode = 0
  $evaluateExitCode = 0

  Write-Stage 'Reset environment'
  $resetExitCode = Invoke-PowerShellScript -ScriptPath 'tools/reset_dev_environment.ps1' -AllowFailure
  if ($resetExitCode -ne 0) {
    Write-Host "[stage-fail] reset_dev_environment exit=$resetExitCode"
  }

  Write-Stage 'Port preflight'
  $mode = if ($env:GITHUB_ACTIONS -eq 'true' -or $env:CI -eq 'true') { 'Force' } else { 'Safe' }
  $preflightExitCode = Invoke-PowerShellScript -ScriptPath 'tools/port_preflight_guard.ps1' -Arguments @(
    '-Port', "$Port",
    '-Mode', $mode,
    '-ExecutionEnvironment', 'auto',
    '-TimeoutSeconds', '45',
    '-StabilizationSeconds', '3'
  ) -AllowFailure
  if ($preflightExitCode -ne 0) {
    Write-Host "[stage-fail] port_preflight_guard exit=$preflightExitCode"
  }

  $environmentClass = 'unknown'
  $privilegeClass = 'restricted'
  $envPayloadRaw = & powershell -ExecutionPolicy Bypass -File tools/detect_execution_environment.ps1 -JsonOnly
  if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($envPayloadRaw)) {
    try {
      $envPayload = $envPayloadRaw | ConvertFrom-Json
      if ([string]$envPayload.environment -in @('ci', 'local')) {
        $environmentClass = [string]$envPayload.environment
      }
      if ([string]$envPayload.privilegeClass -in @('admin', 'non-admin', 'restricted')) {
        $privilegeClass = [string]$envPayload.privilegeClass
      }
    }
    catch {
      Write-Host '[stage-fail] detect_execution_environment produced invalid JSON'
    }
  }

  $portOwnership = Resolve-PortOwnershipClass -TargetPort $Port

  $preflightReport = [ordered]@{
    status = if ($preflightExitCode -eq 0) { 'PASS' } else { 'FAIL' }
    port = $Port
    exitCode = $preflightExitCode
    environmentClass = $environmentClass
    privilegeClass = $privilegeClass
    portOwnership = $portOwnership
  }
  $preflightJson = $preflightReport | ConvertTo-Json -Depth 10
  Write-Utf8NoBom -Path $preflightReportPath -Content $preflightJson

  Write-Stage 'Build Flutter web'
  $buildExitCode = Invoke-CommandWithExitCode -Name 'flutter build web --release' -Command {
    & flutter build web --release
  }
  if ($buildExitCode -ne 0) {
    Write-Host "[stage-fail] flutter build web --release exit=$buildExitCode"
  }

  Write-Stage 'Run startup probe'
  $startupProbeExitCode = Invoke-PowerShellScript -ScriptPath 'tools/run_startup_probe.ps1' -Arguments @(
    '-Mode', 'startup',
    '-SkipPreflight',
    '-Port', "$Port",
    '-BuildPath', $BuildPath,
    '-AppUrl', $appUrl,
    '-StartupLogPath', $startupLogPath,
    '-StartupReportPath', $startupReportPath,
    '-WebSmokeReportPath', $smokeReportPath
  ) -AllowFailure
  if ($startupProbeExitCode -ne 0) {
    Write-Host "[stage-fail] startup probe exit=$startupProbeExitCode"
  }

  if (-not (Test-Path $startupReportPath)) {
    $startupFallback = [ordered]@{
      contractVersion = 'startup_probe_report_v1'
      status = 'FAIL'
      reason = 'probe_failure'
      finalContract = [ordered]@{
        contractVersion = 'unknown'
        ready = $false
        checkpoints = [ordered]@{}
      }
    }
    Write-Utf8NoBom -Path $startupReportPath -Content ($startupFallback | ConvertTo-Json -Depth 10)
  }

  Write-Stage 'Run smoke probe'
  $server = $null
  try {
    $server = Start-Process npx -ArgumentList @('http-server', $BuildPath, '-p', "$Port", '-a', '127.0.0.1', '-s') -PassThru
    Wait-AppReady -Url $appUrl -TimeoutSeconds 45

    $env:STARTUP_APP_URL = $appUrl
    $env:WEB_SMOKE_REPORT_PATH = $smokeReportPath

    & node tools/ci_web_failure_smoke.js
    $smokeProbeExitCode = $LASTEXITCODE
    if ($smokeProbeExitCode -ne 0) {
      Write-Host "[stage-fail] smoke probe exit=$smokeProbeExitCode"
    }
  }
  catch {
    $smokeProbeExitCode = 1
    Write-Host "[stage-fail] smoke probe exception: $($_.Exception.Message)"
  }
  finally {
    if ($null -ne $server) {
      Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue
    }
  }

  if ($smokeProbeExitCode -eq 0 -and -not (Test-Path $smokeReportPath)) {
    $smokeProbeExitCode = 1
    Write-Host '[stage-fail] smoke probe did not produce report file'
  }

  if (-not (Test-Path $smokeReportPath)) {
    $smokeFallback = [ordered]@{
      contractVersion = 'web_smoke_report_v1'
      status = 'FAIL'
      reason = 'probe_failure'
      scenarios = @()
    }
    Write-Utf8NoBom -Path $smokeReportPath -Content ($smokeFallback | ConvertTo-Json -Depth 10)
  }

  Write-Stage 'Build deployment contract'
  if (Test-Path $currentHashPath) {
    $currentHash = (Get-Content -Path $currentHashPath -Raw).Trim()
    if (-not [string]::IsNullOrWhiteSpace($currentHash)) {
      Write-Utf8NoBom -Path $previousHashPath -Content $currentHash
    }
  }

  $contractBuildExitCode = Invoke-PowerShellScript -ScriptPath 'tools/build_deployment_contract.ps1' -Arguments @(
    '-Port', "$Port",
    '-StartupProbeReportPath', $startupReportPath,
    '-SmokeProbeReportPath', $smokeReportPath,
    '-PreflightReportPath', $preflightReportPath,
    '-PreviousHashPath', $previousHashPath,
    '-OutputPath', $contractPath
  ) -AllowFailure
  if ($contractBuildExitCode -ne 0) {
    Write-Host "[stage-fail] build_deployment_contract exit=$contractBuildExitCode"
  }

  Write-Stage 'Evaluate contract'
  $evaluateExitCode = Invoke-PowerShellScript -ScriptPath 'tools/evaluate_deployment_contract.ps1' -Arguments @(
    '-ContractPath', $contractPath,
    '-SchemaPath', 'tools/deployment_contract.schema.json',
    '-OutputPath', $evaluationPath,
    '-ResolvedContractPath', $resolvedContractPath,
    '-CurrentHashPath', $currentHashPath
  ) -AllowFailure

  if (-not (Test-Path $resolvedContractPath)) {
    throw 'Missing resolved contract output.'
  }

  $contract = Get-Content -Path $resolvedContractPath -Raw | ConvertFrom-Json

  if ($contract.governance.decision -ne 'allow') {
    Write-Host "DEPLOYMENT BLOCKED: $($contract.governance.reasonCode)"

    Persist-AuditHistory -Root $DeployRoot -ContractFile $contractPath -ResolvedFile $resolvedContractPath -EvaluationFile $evaluationPath -ResolvedContract $contract

    Write-Host ''
    Write-Host 'Release Summary:'
    Write-Host "- Decision: $($contract.governance.decision)"
    Write-Host "- ReasonCode: $($contract.governance.reasonCode)"
    Write-Host "- Contract Hash: $($contract.contractHash)"
    Write-Host "- Previous Hash: $($contract.previousContractHash)"
    Write-Host "- Environment: $($contract.environment.class)"
    Write-Host "- Stage Exit Codes: reset=$resetExitCode preflight=$preflightExitCode build=$buildExitCode startupProbe=$startupProbeExitCode smokeProbe=$smokeProbeExitCode contractBuild=$contractBuildExitCode evaluate=$evaluateExitCode"

    exit 1
  }

  Write-Stage 'Deploy release'
  $releaseHash = [string]$contract.contractHash
  if ([string]::IsNullOrWhiteSpace($releaseHash)) {
    throw 'Resolved contract hash is empty.'
  }

  $releasesDir = Join-Path $DeployRoot 'releases'
  $releaseDir = Join-Path $releasesDir $releaseHash
  $currentDir = Join-Path $DeployRoot 'current'
  $currentTempDir = Join-Path $DeployRoot 'current_new'

  New-Item -ItemType Directory -Path $releasesDir -Force | Out-Null

  if (Test-Path $releaseDir) {
    Remove-Item -Path $releaseDir -Recurse -Force
  }
  New-Item -ItemType Directory -Path $releaseDir -Force | Out-Null
  Copy-Item -Path (Join-Path $BuildPath '*') -Destination $releaseDir -Recurse -Force

  if (Test-Path $currentTempDir) {
    Remove-Item -Path $currentTempDir -Recurse -Force
  }
  Copy-Item -Path $releaseDir -Destination $currentTempDir -Recurse -Force

  if (Test-Path $currentDir) {
    Remove-Item -Path $currentDir -Recurse -Force
  }
  Rename-Item -Path $currentTempDir -NewName 'current'

  Persist-AuditHistory -Root $DeployRoot -ContractFile $contractPath -ResolvedFile $resolvedContractPath -EvaluationFile $evaluationPath -ResolvedContract $contract

  Write-Host 'DEPLOY SUCCESS'
  Write-Host "contractHash: $($contract.contractHash)"
  Write-Host "previousHash: $($contract.previousContractHash)"

  Write-Host ''
  Write-Host 'Release Summary:'
  Write-Host "- Decision: $($contract.governance.decision)"
  Write-Host "- ReasonCode: $($contract.governance.reasonCode)"
  Write-Host "- Contract Hash: $($contract.contractHash)"
  Write-Host "- Previous Hash: $($contract.previousContractHash)"
  Write-Host "- Environment: $($contract.environment.class)"
  Write-Host "- Stage Exit Codes: reset=$resetExitCode preflight=$preflightExitCode build=$buildExitCode startupProbe=$startupProbeExitCode smokeProbe=$smokeProbeExitCode contractBuild=$contractBuildExitCode evaluate=$evaluateExitCode"
}
catch {
  Write-Host "DEPLOYMENT FAILED: $($_.Exception.Message)"
  exit 1
}
