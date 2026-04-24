param(
  [int]$Port = 8080,
  [ValidateSet('Safe', 'Force')]
  [string]$Mode = 'Safe',
  [ValidateSet('auto', 'ci', 'local', 'unknown')]
  [string]$ExecutionEnvironment = 'auto',
  [int]$TimeoutSeconds = 45,
  [int]$PollIntervalMs = 500,
  [int]$StabilizationSeconds = 3,
  [switch]$BreakRestartLoop
)

$ErrorActionPreference = 'Stop'

function Write-Info {
  param([string]$Message)
  Write-Host "[preflight] $Message"
}

function Test-IsAdmin {
  $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = [Security.Principal.WindowsPrincipal]::new($identity)
  return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Resolve-ExecutionEnvironment {
  param([string]$Raw)

  if ($Raw -and $Raw -ne 'auto') {
    return $Raw
  }

  if ($env:GITHUB_ACTIONS -eq 'true' -or $env:CI -eq 'true') {
    return 'ci'
  }

  if (-not [string]::IsNullOrWhiteSpace($env:USERNAME)) {
    return 'local'
  }

  return 'unknown'
}

function Get-ListeningPids {
  param([int]$TargetPort)

  try {
    $connections = Get-NetTCPConnection -LocalPort $TargetPort -State Listen -ErrorAction Stop
    if (-not $connections) {
      return @()
    }

    return @($connections | Select-Object -ExpandProperty OwningProcess -Unique)
  } catch {
    # Fallback path for constrained environments where NetTCP cmdlets are unavailable.
    $netstatLines = netstat -ano -p tcp | Select-String -Pattern "^\s*TCP\s+\S+:$TargetPort\s+\S+\s+LISTENING\s+(\d+)\s*$"
    if (-not $netstatLines) {
      return @()
    }

    $pids = @()
    foreach ($line in $netstatLines) {
      $match = [regex]::Match($line.Line, "^\s*TCP\s+\S+:$TargetPort\s+\S+\s+LISTENING\s+(\d+)\s*$")
      if ($match.Success) {
        $pids += [int]$match.Groups[1].Value
      }
    }

    return @($pids | Select-Object -Unique)
  }
}

function Wait-ServiceStopped {
  param(
    [string]$ServiceName,
    [int]$WaitSeconds,
    [int]$PollMs
  )

  $deadline = (Get-Date).AddSeconds($WaitSeconds)
  do {
    $svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if (-not $svc -or $svc.Status -eq 'Stopped') {
      return $true
    }
    Start-Sleep -Milliseconds $PollMs
  } while ((Get-Date) -lt $deadline)

  return $false
}

function Disable-ServiceRestartPolicies {
  param([string]$ServiceName)

  Write-Info "Disabling restart actions for service '$ServiceName' (explicit override enabled)."
  & sc.exe failure $ServiceName reset= 0 actions= "" | Out-Null
  & sc.exe config $ServiceName start= demand | Out-Null
}

function Stop-ServiceDeterministic {
  param(
    [string]$ServiceName,
    [int]$WaitSeconds,
    [int]$PollMs,
    [switch]$AllowBreakLoop
  )

  Write-Info "Query service state: sc queryex $ServiceName"
  & sc.exe queryex $ServiceName | Out-Host

  try {
    Write-Info "Stopping service with Stop-Service: $ServiceName"
    Stop-Service -Name $ServiceName -ErrorAction Stop
  } catch {
    Write-Info "Stop-Service failed for '$ServiceName': $($_.Exception.Message)"
  }

  # Always attempt SCM stop path explicitly to support hosts where Stop-Service is constrained.
  Write-Info "Stopping service with sc stop: $ServiceName"
  $scStopOutput = & sc.exe stop $ServiceName 2>&1
  $scStopOutput | Out-Host

  $scStopText = ($scStopOutput | Out-String)
  if ($scStopText -match 'FAILED\s+5|Access is denied') {
    Write-Info "SCM stop denied for service '$ServiceName'; elevation is required."
    return $false
  }

  if (Wait-ServiceStopped -ServiceName $ServiceName -WaitSeconds $WaitSeconds -PollMs $PollMs) {
    Write-Info "Service '$ServiceName' is stopped."
    return $true
  }

  if ($AllowBreakLoop) {
    try {
      Disable-ServiceRestartPolicies -ServiceName $ServiceName
      Write-Info "Retrying service stop after restart-policy override: $ServiceName"
      & sc.exe stop $ServiceName | Out-Null
      if (Wait-ServiceStopped -ServiceName $ServiceName -WaitSeconds $WaitSeconds -PollMs $PollMs) {
        Write-Info "Service '$ServiceName' stopped after restart-policy override."
        return $true
      }
    } catch {
      Write-Info "Restart-policy override failed for '$ServiceName': $($_.Exception.Message)"
    }
  }

  Write-Info "Service '$ServiceName' did not reach Stopped state within timeout."
  return $false
}

function Wait-PortFreeStable {
  param(
    [int]$TargetPort,
    [int]$StableSeconds,
    [int]$PollMs,
    [int]$MaxWaitSeconds
  )

  $mustStayFreeUntil = (Get-Date).AddSeconds($StableSeconds)
  $deadline = (Get-Date).AddSeconds($MaxWaitSeconds)

  do {
    $pids = Get-ListeningPids -TargetPort $TargetPort
    if ($pids.Count -eq 0) {
      if ((Get-Date) -ge $mustStayFreeUntil) {
        return $true
      }
    } else {
      $mustStayFreeUntil = (Get-Date).AddSeconds($StableSeconds)
    }
    Start-Sleep -Milliseconds $PollMs
  } while ((Get-Date) -lt $deadline)

  return $false
}

function Stop-IisHttpSysOwners {
  param(
    [int]$WaitSeconds,
    [int]$PollMs
  )

  foreach ($svcName in @('W3SVC', 'WAS')) {
    $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
    if (-not $svc) {
      continue
    }

    Write-Info "Attempting stop for HTTP.sys edge service '$svcName'."
    try {
      Stop-Service -Name $svcName -ErrorAction Stop
    } catch {
      Write-Info "Stop-Service failed for '$svcName': $($_.Exception.Message)"
    }

    $svcStopOutput = & sc.exe stop $svcName 2>&1
    $svcStopOutput | Out-Host
    Wait-ServiceStopped -ServiceName $svcName -WaitSeconds $WaitSeconds -PollMs $PollMs | Out-Null
  }
}

Write-Info "Starting preflight guard on port $Port in mode '$Mode'."
$isAdmin = Test-IsAdmin
 $resolvedEnvironment = Resolve-ExecutionEnvironment -Raw $ExecutionEnvironment
if ($resolvedEnvironment -eq 'ci' -and $Mode -eq 'Safe') {
  Write-Info "CI environment detected: elevating from Safe mode to Force mode for deterministic cleanup."
  $Mode = 'Force'
}
Write-Info "Execution environment: $resolvedEnvironment"
Write-Info "Admin session: $isAdmin"

$initialPids = Get-ListeningPids -TargetPort $Port
if ($initialPids.Count -eq 0) {
  Write-Info "Port $Port is already free."
  exit 0
}

Write-Info "Port $Port listeners at start: $($initialPids -join ', ')"

$overallSuccess = $true

foreach ($listenerPid in $initialPids) {
  $services = @(Get-CimInstance Win32_Service -Filter "ProcessId = $listenerPid" -ErrorAction SilentlyContinue)
  if ($services.Count -gt 0) {
    foreach ($svc in $services) {
      Write-Info "PID $listenerPid maps to service '$($svc.Name)' running as '$($svc.StartName)'."
      $stopped = Stop-ServiceDeterministic -ServiceName $svc.Name -WaitSeconds $TimeoutSeconds -PollMs $PollIntervalMs -AllowBreakLoop:$BreakRestartLoop
      if (-not $stopped) {
        if ($Mode -eq 'Force') {
          Write-Info "Force mode fallback: taskkill /F /PID $listenerPid /T"
          & taskkill.exe /F /PID $listenerPid /T
        } else {
          $overallSuccess = $false
        }
      }
    }
  } else {
    Write-Info "PID $listenerPid has no SCM service owner."
    if ($listenerPid -eq 4) {
      Write-Info "PID 4 indicates HTTP.sys kernel listener; attempting IIS service shutdown path."
      Stop-IisHttpSysOwners -WaitSeconds $TimeoutSeconds -PollMs $PollIntervalMs
      continue
    }

    if ($Mode -eq 'Force') {
      Write-Info "Force mode: taskkill /F /PID $listenerPid /T"
      & taskkill.exe /F /PID $listenerPid /T
    } else {
      Write-Info "Safe mode refuses PID kill; leaving process untouched."
      $overallSuccess = $false
    }
  }
}

$stable = Wait-PortFreeStable -TargetPort $Port -StableSeconds $StabilizationSeconds -PollMs $PollIntervalMs -MaxWaitSeconds $TimeoutSeconds
$finalListeners = Get-ListeningPids -TargetPort $Port

if ($overallSuccess -and $stable -and $finalListeners.Count -eq 0) {
  Write-Info "Port $Port is free and stable."
  exit 0
}

if ($finalListeners.Count -gt 0) {
  Write-Info "Port $Port is still occupied by PID(s): $($finalListeners -join ', ')"
  foreach ($finalPid in $finalListeners) {
    $owners = @(Get-CimInstance Win32_Service -Filter "ProcessId = $finalPid" -ErrorAction SilentlyContinue)
    if ($owners.Count -gt 0) {
      foreach ($owner in $owners) {
        Write-Info "Listener PID $finalPid service owner: $($owner.Name) ($($owner.DisplayName))"
      }
    } else {
      Write-Info "Listener PID $finalPid has no SCM service mapping."
    }
  }
}

Write-Info "Preflight failed: could not guarantee port $Port is free."
exit 1