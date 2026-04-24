param(
  [string]$ContractPath = 'artifacts/deployment_contract.json',
  [string]$SchemaPath = 'tools/deployment_contract.schema.json',
  [string]$OutputPath = 'artifacts/deployment_contract_evaluation.json',
  [string]$ResolvedContractPath = 'artifacts/deployment_contract.resolved.json',
  [string]$CurrentHashPath = 'artifacts/hash_chain/current_contract_hash.txt'
)

$ErrorActionPreference = 'Stop'

$allowedReasonCodes = @(
  'app_contract_failure',
  'env_privilege_blocked',
  'service_ownership_blocked',
  'probe_failure',
  'schema_invalid',
  'policy_rejection'
)

$stateSequence = @('INIT', 'COLLECTING', 'VALIDATED', 'GOVERNED', 'BOOTSTRAP', 'FINAL')

function Write-Utf8NoBom {
  param(
    [string]$Path,
    [string]$Content
  )

  New-Item -ItemType Directory -Path (Split-Path -Path $Path -Parent) -Force | Out-Null
  $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
  [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

function Convert-ToCanonicalData {
  param($Value)

  if ($null -eq $Value) {
    return $null
  }

  if ($Value -is [System.Collections.IDictionary]) {
    $ordered = [ordered]@{}
    foreach ($key in @($Value.Keys | ForEach-Object { [string]$_ } | Sort-Object)) {
      $ordered[$key] = Convert-ToCanonicalData -Value $Value[$key]
    }
    return $ordered
  }

  if ($Value -is [System.Management.Automation.PSCustomObject]) {
    $ordered = [ordered]@{}
    $keys = @($Value.PSObject.Properties.Name | Sort-Object)
    foreach ($key in $keys) {
      $ordered[$key] = Convert-ToCanonicalData -Value $Value.$key
    }
    return $ordered
  }

  if ($Value -is [System.Collections.IEnumerable] -and -not ($Value -is [string])) {
    $items = @()
    foreach ($item in $Value) {
      $items += ,(Convert-ToCanonicalData -Value $item)
    }
    return $items
  }

  return $Value
}

function Convert-ToCanonicalJson {
  param($Value)

  $canonical = Convert-ToCanonicalData -Value $Value
  return ($canonical | ConvertTo-Json -Depth 50 -Compress)
}

function Test-ExactShape {
  param(
    $Object,
    [string[]]$RequiredKeys,
    [string[]]$AllowedKeys
  )

  if ($null -eq $Object) {
    return $false
  }

  $keys = @($Object.PSObject.Properties.Name)
  foreach ($key in $keys) {
    if ($key -notin $AllowedKeys) {
      return $false
    }
  }

  foreach ($requiredKey in $RequiredKeys) {
    if ($requiredKey -notin $keys) {
      return $false
    }
  }

  return $true
}

function Write-Evaluation {
  param(
    [string]$Status,
    [string]$ReasonCode,
    $FinalContract
  )

  if ($ReasonCode -notin $allowedReasonCodes) {
    $ReasonCode = 'schema_invalid'
    $Status = 'FAIL'
    $FinalContract.governance.reasonCode = $ReasonCode
    $FinalContract.governance.decision = 'deny'
  }

  $resolvedJson = $FinalContract | ConvertTo-Json -Depth 30
  Write-Utf8NoBom -Path $ResolvedContractPath -Content $resolvedJson

  Write-Utf8NoBom -Path $CurrentHashPath -Content $FinalContract.contractHash

  $result = [ordered]@{
    status = $Status
    reasonCode = $ReasonCode
    summary = $FinalContract
  }

  $resultJson = $result | ConvertTo-Json -Depth 30
  Write-Utf8NoBom -Path $OutputPath -Content $resultJson
  $result | ConvertTo-Json -Depth 30 | Write-Output

  if ($Status -eq 'FAIL') {
    exit 1
  }

  exit 0
}

function Get-CanonicalHash {
  param($Contract)

  $json = Convert-ToCanonicalJson -Value $Contract
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
  $hashBytes = [System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes)
  return ([System.BitConverter]::ToString($hashBytes)).Replace('-', '').ToLowerInvariant()
}

function Set-Deny {
  param(
    $Contract,
    [string]$ReasonCode
  )

  $Contract.governance.decision = 'deny'
  $Contract.governance.reasonCode = $ReasonCode
}

if (-not (Test-Path $ContractPath)) {
  $fallback = [ordered]@{
    authority = [ordered]@{ runtime = 'flutter'; ci = 'github-actions'; resolvedBy = 'deployment_contract' }
    contractState = 'FINAL'
    contractHash = 'missing'
    previousContractHash = $null
    artifact = [ordered]@{ commitSha = 'unknown'; buildId = 'unknown'; workflowRunId = 'unknown' }
    startup = [ordered]@{ contractVersion = 'unknown'; ready = $false; checkpoints = @() }
    environment = [ordered]@{ class = 'unknown'; os = 'windows' }
    privilege = [ordered]@{ class = 'restricted' }
    networking = [ordered]@{ port = 8080; portOwnership = 'unknown' }
    probeResults = [ordered]@{ startupProbe = 'fail'; smokeProbe = 'fail' }
    governance = [ordered]@{ decision = 'deny'; reasonCode = 'schema_invalid' }
  }
  Write-Evaluation -Status 'FAIL' -ReasonCode 'schema_invalid' -FinalContract $fallback
}

$rawContract = ''
$contract = $null

try {
  $rawContract = Get-Content -Path $ContractPath -Raw
  $contract = $rawContract | ConvertFrom-Json
} catch {
  $fallback = [ordered]@{
    authority = [ordered]@{ runtime = 'flutter'; ci = 'github-actions'; resolvedBy = 'deployment_contract' }
    contractState = 'FINAL'
    contractHash = 'invalid'
    previousContractHash = $null
    artifact = [ordered]@{ commitSha = 'unknown'; buildId = 'unknown'; workflowRunId = 'unknown' }
    startup = [ordered]@{ contractVersion = 'unknown'; ready = $false; checkpoints = @() }
    environment = [ordered]@{ class = 'unknown'; os = 'windows' }
    privilege = [ordered]@{ class = 'restricted' }
    networking = [ordered]@{ port = 8080; portOwnership = 'unknown' }
    probeResults = [ordered]@{ startupProbe = 'fail'; smokeProbe = 'fail' }
    governance = [ordered]@{ decision = 'deny'; reasonCode = 'schema_invalid' }
  }
  Write-Evaluation -Status 'FAIL' -ReasonCode 'schema_invalid' -FinalContract $fallback
}

$schemaOk = $true

if ($schemaOk) {
  if (-not (Test-ExactShape -Object $contract -RequiredKeys @('authority', 'contractState', 'contractHash', 'previousContractHash', 'artifact', 'startup', 'environment', 'privilege', 'networking', 'probeResults', 'governance') -AllowedKeys @('authority', 'contractState', 'contractHash', 'previousContractHash', 'artifact', 'startup', 'environment', 'privilege', 'networking', 'probeResults', 'governance'))) {
    $schemaOk = $false
  }
}

if ($schemaOk) {
  if (-not (Test-ExactShape -Object $contract.authority -RequiredKeys @('runtime', 'ci', 'resolvedBy') -AllowedKeys @('runtime', 'ci', 'resolvedBy'))) { $schemaOk = $false }
  if (-not (Test-ExactShape -Object $contract.artifact -RequiredKeys @('commitSha', 'buildId', 'workflowRunId') -AllowedKeys @('commitSha', 'buildId', 'workflowRunId'))) { $schemaOk = $false }
  if (-not (Test-ExactShape -Object $contract.startup -RequiredKeys @('contractVersion', 'ready', 'checkpoints') -AllowedKeys @('contractVersion', 'ready', 'checkpoints'))) { $schemaOk = $false }
  if (-not (Test-ExactShape -Object $contract.environment -RequiredKeys @('class', 'os') -AllowedKeys @('class', 'os'))) { $schemaOk = $false }
  if (-not (Test-ExactShape -Object $contract.privilege -RequiredKeys @('class') -AllowedKeys @('class'))) { $schemaOk = $false }
  if (-not (Test-ExactShape -Object $contract.networking -RequiredKeys @('port', 'portOwnership') -AllowedKeys @('port', 'portOwnership'))) { $schemaOk = $false }
  if (-not (Test-ExactShape -Object $contract.probeResults -RequiredKeys @('startupProbe', 'smokeProbe') -AllowedKeys @('startupProbe', 'smokeProbe'))) { $schemaOk = $false }
  if (-not (Test-ExactShape -Object $contract.governance -RequiredKeys @('decision', 'reasonCode') -AllowedKeys @('decision', 'reasonCode'))) { $schemaOk = $false }
}

if ($schemaOk) {
  if ($contract.authority.runtime -ne 'flutter' -or $contract.authority.ci -ne 'github-actions' -or $contract.authority.resolvedBy -ne 'deployment_contract') { $schemaOk = $false }
  if ($contract.contractState -notin $stateSequence) { $schemaOk = $false }
  if ($contract.environment.class -notin @('ci', 'local', 'unknown')) { $schemaOk = $false }
  if ($contract.environment.os -notin @('windows', 'linux', 'macos')) { $schemaOk = $false }
  if ($contract.privilege.class -notin @('admin', 'non-admin', 'restricted')) { $schemaOk = $false }
  if ($contract.networking.portOwnership -notin @('system', 'service', 'user', 'unknown')) { $schemaOk = $false }
  if ($contract.probeResults.startupProbe -notin @('pass', 'fail')) { $schemaOk = $false }
  if ($contract.probeResults.smokeProbe -notin @('pass', 'fail')) { $schemaOk = $false }
  if ($contract.governance.decision -notin @('allow', 'deny', 'allow-with-degradation')) { $schemaOk = $false }
  if ($contract.governance.reasonCode -notin $allowedReasonCodes) { $schemaOk = $false }
}

$final = [ordered]@{
  authority = [ordered]@{ runtime = 'flutter'; ci = 'github-actions'; resolvedBy = 'deployment_contract' }
  contractState = 'INIT'
  contractHash = 'unknown'
  previousContractHash = $contract.previousContractHash
  artifact = [ordered]@{ commitSha = [string]$contract.artifact.commitSha; buildId = [string]$contract.artifact.buildId; workflowRunId = [string]$contract.artifact.workflowRunId }
  startup = [ordered]@{ contractVersion = [string]$contract.startup.contractVersion; ready = [bool]$contract.startup.ready; checkpoints = @($contract.startup.checkpoints) }
  environment = [ordered]@{ class = [string]$contract.environment.class; os = [string]$contract.environment.os }
  privilege = [ordered]@{ class = [string]$contract.privilege.class }
  networking = [ordered]@{ port = [int]$contract.networking.port; portOwnership = [string]$contract.networking.portOwnership }
  probeResults = [ordered]@{ startupProbe = [string]$contract.probeResults.startupProbe; smokeProbe = [string]$contract.probeResults.smokeProbe }
  governance = [ordered]@{ decision = 'deny'; reasonCode = 'schema_invalid' }
}

if (-not $schemaOk) {
  $final.contractState = 'FINAL'
  Set-Deny -Contract $final -ReasonCode 'schema_invalid'
  $final.contractHash = Get-CanonicalHash -Contract $final
  Write-Evaluation -Status 'FAIL' -ReasonCode 'schema_invalid' -FinalContract $final
}

# State transition: INIT -> COLLECTING -> VALIDATED
if ($contract.contractState -ne 'INIT') {
  $final.contractState = 'FINAL'
  Set-Deny -Contract $final -ReasonCode 'schema_invalid'
  $final.contractHash = Get-CanonicalHash -Contract $final
  Write-Evaluation -Status 'FAIL' -ReasonCode 'schema_invalid' -FinalContract $final
}

$final.contractState = 'COLLECTING'
$final.contractState = 'VALIDATED'

if ($final.environment.class -eq 'ci' -and $null -eq $final.previousContractHash) {
  $final.contractState = 'BOOTSTRAP'
  Set-Deny -Contract $final -ReasonCode 'policy_rejection'
  $final.contractHash = Get-CanonicalHash -Contract $final
  Write-Evaluation -Status 'FAIL' -ReasonCode 'policy_rejection' -FinalContract $final
}
$reasonCode = 'policy_rejection'
$decision = 'allow'

if ([string]::IsNullOrWhiteSpace($final.startup.contractVersion) -or $final.startup.contractVersion -eq 'unknown' -or -not $final.startup.ready) {
  $decision = 'deny'
  $reasonCode = 'app_contract_failure'
}

if ($decision -eq 'allow' -and ($final.probeResults.startupProbe -ne 'pass' -or $final.probeResults.smokeProbe -ne 'pass')) {
  $decision = 'deny'
  $reasonCode = 'probe_failure'
}

$serviceConflict = $final.networking.portOwnership -in @('service', 'system')
if ($decision -eq 'allow' -and $final.environment.class -eq 'unknown' -and $final.privilege.class -ne 'admin') {
  $decision = 'deny'
  $reasonCode = 'env_privilege_blocked'
}

if ($decision -eq 'allow' -and $final.environment.class -eq 'ci' -and $final.privilege.class -eq 'restricted' -and -not $serviceConflict) {
  $decision = 'deny'
  $reasonCode = 'env_privilege_blocked'
}

$final.contractState = 'GOVERNED'
if ($decision -eq 'allow' -and $serviceConflict -and $final.privilege.class -ne 'admin') {
  $decision = 'allow-with-degradation'
  $reasonCode = 'service_ownership_blocked'
}

if ($decision -eq 'allow-with-degradation' -and ($final.probeResults.startupProbe -ne 'pass' -or $final.probeResults.smokeProbe -ne 'pass')) {
  $decision = 'deny'
  $reasonCode = 'probe_failure'
}

if ($decision -eq 'allow-with-degradation' -and $final.environment.class -eq 'unknown') {
  $decision = 'deny'
  $reasonCode = 'env_privilege_blocked'
}

$final.governance.decision = $decision
$final.governance.reasonCode = $reasonCode

$final.contractState = 'FINAL'
$final.contractHash = Get-CanonicalHash -Contract $final

$status = if ($decision -eq 'allow') { 'PASS' } else { 'FAIL' }
Write-Evaluation -Status $status -ReasonCode $reasonCode -FinalContract $final
