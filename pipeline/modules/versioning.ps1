function Update-Version {
    Write-Log "Updating version..."
    $pubspec = "pubspec.yaml"
    if (Test-Path $pubspec) {
        $content = Get-Content $pubspec
        $versionLine = $content | Where-Object { $_ -match "^version:" }
        if ($versionLine) {
            $version = $versionLine -replace "version: ", ""
            # Remove build number if present
            if ($version -match '\+') {
                $version = $version -replace '\+.*', ''
            }
            $parts = $version -split "\."
            if ($parts.Length -ge 3) {
                $parts[2] = [int]$parts[2] + 1
                $newVersion = $parts -join "."
                $newLine = "version: $newVersion"
                $content = $content -replace $versionLine, $newLine
                Set-Content $pubspec $content
                Write-Log "Version updated to $newVersion"
            } else {
                Write-Log "Invalid version format: $version"
            }
        }
    }
}

function Bump-PatchVersion {
    param([string]$Pubspec)
    Write-Log "Bumping patch version in $Pubspec..."
    if (Test-Path $Pubspec) {
        $content = Get-Content $Pubspec
        $versionLine = $content | Where-Object { $_ -match "^version:" }
        if ($versionLine) {
            $version = $versionLine -replace "version: ", ""
            # Remove build number if present
            if ($version -match '\+') {
                $version = $version -replace '\+.*', ''
            }
            $parts = $version -split "\."
            if ($parts.Length -ge 3) {
                $parts[2] = [int]$parts[2] + 1
                $newVersion = $parts -join "."
                $newLine = "version: $newVersion"
                $content = $content -replace $versionLine, $newLine
                Set-Content $Pubspec $content
                Write-Log "Version bumped to $newVersion"
            } else {
                Write-Log "Invalid version format: $version"
            }
        }
    }
}