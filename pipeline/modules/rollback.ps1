function Rollback-Deploy {
    Write-Log "Rolling back deployment..."
    # Placeholder: Firebase doesn't have easy rollback, suggest manual
    Write-Log "Manual rollback required: Redeploy previous build from backup."
    # If we have backup, perhaps redeploy
    if (Test-Path "backup/build") {
        Write-Log "Redeploying from backup..."
        firebase deploy --only hosting  # But need to point to backup
        # Actually, copy backup to build/web and deploy
        Copy-Item -Recurse "backup/build/web/*" "build/web/" -Force
        firebase deploy --only hosting
    } else {
        Write-Log "No backup available for rollback."
    }
}

# ================================
# 📝 Rollback Logging
# ================================
$rollbackLog = "pipeline/rollback_log.txt"
if (-Not (Test-Path $rollbackLog)) { New-Item -ItemType File -Path $rollbackLog | Out-Null }
function Log-Rollback {
    param([string]$Reason)
    Add-Content -Path $rollbackLog -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Rollback triggered: $Reason"
}
# Example: call Log-Rollback if a rollback occurs
# Log-Rollback -Reason "Test failure detected"