param([string]$Reason, [string]$FailedStep = "unknown")

# Import rollback module
. "$PSScriptRoot/modules/rollback.ps1"

# Log the rollback with details
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$logEntry = "$timestamp - Rollback triggered: $Reason (Failed Step: $FailedStep)"
Add-Content -Path $rollbackLog -Value $logEntry
Write-Log $logEntry

# Save previous artifact for forensics
$forensicDir = "rollback_artifacts/$(Get-Date -Format 'yyyyMMdd_HHmmss')"
if (-not (Test-Path $forensicDir)) { New-Item -ItemType Directory -Path $forensicDir -Force }
if (Test-Path "build/web") {
    Copy-Item -Recurse "build/web" "$forensicDir/" -Force
    Write-Log "Previous artifact saved to $forensicDir"
}

# Perform rollback
Rollback-Deploy