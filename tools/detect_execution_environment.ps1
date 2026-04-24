param(
  [switch]$JsonOnly,
  [switch]$EmitGitHubEnv
)

$ErrorActionPreference = 'Stop'

function Test-IsAdmin {
  $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = [Security.Principal.WindowsPrincipal]::new($identity)
  return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

$environmentName = 'unknown'
if ($env:GITHUB_ACTIONS -eq 'true' -or $env:CI -eq 'true') {
  $environmentName = 'ci'
} elseif (-not [string]::IsNullOrWhiteSpace($env:USERNAME) -or -not [string]::IsNullOrWhiteSpace($env:USERPROFILE)) {
  $environmentName = 'local'
}

$result = [ordered]@{
  contractVersion = 'mixvy.execution_environment.v1'
  detectedAtUtc = (Get-Date).ToUniversalTime().ToString('o')
  environment = $environmentName
  isCi = ($environmentName -eq 'ci')
  isLocal = ($environmentName -eq 'local')
  isGitHubActions = ($env:GITHUB_ACTIONS -eq 'true')
  isAdmin = (Test-IsAdmin)
  machineName = $env:COMPUTERNAME
  userName = $env:USERNAME
}

$json = $result | ConvertTo-Json -Depth 5

if ($EmitGitHubEnv -and -not [string]::IsNullOrWhiteSpace($env:GITHUB_ENV)) {
  Add-Content -Path $env:GITHUB_ENV -Value "MIXVY_EXEC_ENV=$($result.environment)"
  Add-Content -Path $env:GITHUB_ENV -Value "MIXVY_EXEC_IS_ADMIN=$($result.isAdmin)"
}

if ($JsonOnly) {
  Write-Output $json
} else {
  Write-Host "[env] $json"
}
