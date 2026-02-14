function Get-CoveragePercent {
    param([string]$LcovFile)
    if (-not (Test-Path $LcovFile)) { return 0 }
    
    $content = Get-Content $LcovFile
    $totalLines = 0
    $coveredLines = 0
    
    foreach ($line in $content) {
        if ($line -match '^DA:(\d+),(\d+)') {
            $lineNum = [int]$matches[1]
            $hits = [int]$matches[2]
            $totalLines++
            if ($hits -gt 0) { $coveredLines++ }
        }
    }
    
    if ($totalLines -eq 0) { return 0 }
    return [math]::Round(($coveredLines / $totalLines) * 100, 2)
}