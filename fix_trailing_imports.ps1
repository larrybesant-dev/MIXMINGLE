$r = 0
$importPattern = "^import\s+['" + '"' + "]"
Get-ChildItem C:\Users\LARRY\MIXMINGLE\lib -Recurse -Filter "*.dart" | ForEach-Object {
    $lines = Get-Content $_.FullName
    if ($lines.Count -eq 0) { return }
    $last = $lines.Count - 1
    while ($last -ge 0 -and [string]::IsNullOrWhiteSpace($lines[$last])) { $last-- }
    if ($last -ge 0 -and $lines[$last] -match $importPattern) {
        $cut = $last
        while ($cut -ge 0 -and ($lines[$cut] -match $importPattern -or [string]::IsNullOrWhiteSpace($lines[$cut]))) {
            $cut--
        }
        if ($cut -ge 0) {
            $newContent = ($lines[0..$cut] -join "`n") + "`n"
            [System.IO.File]::WriteAllText($_.FullName, $newContent, [System.Text.Encoding]::UTF8)
            $r++
        }
    }
}
Write-Host "Fixed $r files"
