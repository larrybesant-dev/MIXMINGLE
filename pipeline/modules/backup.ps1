function Backup-Offline {
    Write-Log "Creating offline backup..."
    $backupDir = "backup"
    if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir }
    Copy-Item -Recurse "lib" "$backupDir/lib" -Force
    Copy-Item -Recurse "pubspec.yaml" "$backupDir/" -Force
    if (Test-Path "build") { Copy-Item -Recurse "build" "$backupDir/build" -Force }
    Write-Log "Backup created in $backupDir"
}

function Create-Backup {
    param([string[]]$SourcePaths)
    Write-Log "Creating backup for: $($SourcePaths -join ', ')"
    $backupDir = "backup/$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir -Force }
    foreach ($path in $SourcePaths) {
        if (Test-Path $path) {
            Copy-Item -Recurse $path "$backupDir/" -Force
        }
    }
    Write-Log "Backup created in $backupDir"
}