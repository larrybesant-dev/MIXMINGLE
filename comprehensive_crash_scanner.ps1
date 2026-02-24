# Comprehensive Crash Pattern Scanner
# Finds: 1) Unsafe .toString() calls, 2) Invalid list/map indexing

Write-Host "`n═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  🔍 COMPREHENSIVE CRASH PATTERN SCANNER" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

$results = @()
$totalFiles = 0

Write-Host "Scanning lib/ directory for crash patterns...`n" -ForegroundColor White

Get-ChildItem lib -Recurse -Filter "*.dart" -ErrorAction SilentlyContinue | ForEach-Object {
    $file = $_
    $totalFiles++
    $relativePath = $file.FullName -replace [regex]::Escape((Get-Location).Path + "\lib\"), ""

    $lineNum = 0
    Get-Content $file.FullName -ErrorAction SilentlyContinue | ForEach-Object {
        $lineNum++
        $line = $_
        $trimmed = $line.Trim()

        # Skip comments and blank lines
        if ($trimmed -match '^\s*//' -or $trimmed -eq '') { return }

        # PATTERN 1: Invalid list/map indexing with string keys
        if ($line -match "\['(city|location|address|name|email|phone|age|gender|bio|id|uid|userId)'\]" -and
            $line -notmatch '^\s*//' -and
            $line -notmatch 'Map<' -and
            $line -notmatch 'json' -and
            $line -notmatch 'data\[' -and
            $line -notmatch 'map\[') {
            $results += [PSCustomObject]@{
                File = $relativePath
                Line = $lineNum
                Pattern = "InvalidIndexing"
                Severity = "CRITICAL"
                Code = $trimmed
            }
        }

        # PATTERN 2: Unsafe snapshot.data! usage
        if ($line -match 'snapshot\.data!' -and $line -notmatch '^\s*//') {
            $results += [PSCustomObject]@{
                File = $relativePath
                Line = $lineNum
                Pattern = "SnapshotDataAssertion"
                Severity = "CRITICAL"
                Code = $trimmed
            }
        }

        # PATTERN 3: Property chain .toString() without null safety
        if ($line -match '(?<![\?])\b\w+\.\w+\.toString\(\)' -and
            $line -notmatch '^\s*//' -and
            $line -notmatch '//' -and
            $line -notmatch 'error' -and
            $line -notmatch 'Exception' -and
            $line -notmatch 'runtimeType' -and
            $line -notmatch '\.toString\(\)\.toString\(\)') {

            $results += [PSCustomObject]@{
                File = $relativePath
                Line = $lineNum
                Pattern = "UnsafePropertyToString"
                Severity = "HIGH"
                Code = $trimmed
            }
        }

        # PATTERN 4: Map access with .toString() without null safety
        if ($line -match "\['[^']+'\]\.toString\(\)" -and
            $line -notmatch '\?\?' -and
            $line -notmatch '^\s*//') {

            $results += [PSCustomObject]@{
                File = $relativePath
                Line = $lineNum
                Pattern = "UnsafeMapAccessToString"
                Severity = "HIGH"
                Code = $trimmed
            }
        }

        # PATTERN 5: Firestore .data()! assertions
        if ($line -match '\.data\(\)!' -and $line -notmatch '^\s*//') {
            $results += [PSCustomObject]@{
                File = $relativePath
                Line = $lineNum
                Pattern = "FirestoreDataAssertion"
                Severity = "HIGH"
                Code = $trimmed
            }
        }

        # PATTERN 6: Text widget with unsafe interpolation
        if ($line -match 'Text\s*\(' -and
            $line -match '\$\{?[a-zA-Z_]+' -and
            $line -notmatch '\?\?' -and
            $line -notmatch '\.toString\(\)' -and
            $line -notmatch '^\s*//') {

            $results += [PSCustomObject]@{
                File = $relativePath
                Line = $lineNum
                Pattern = "UnsafeTextInterpolation"
                Severity = "MEDIUM"
                Code = $trimmed
            }
        }
    }
}

Write-Host "✅ Scanned $totalFiles Dart files`n" -ForegroundColor Green

# Group and count by pattern
$grouped = $results | Group-Object Pattern | Sort-Object Count -Descending

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  📊 CRASH PATTERN SUMMARY" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

$grouped | ForEach-Object {
    $severity = ($_.Group[0].Severity)
    $color = switch ($severity) {
        "CRITICAL" { "Red" }
        "HIGH" { "Yellow" }
        "MEDIUM" { "White" }
        default { "Gray" }
    }
    Write-Host "  $($_.Name): $($_.Count) issues [$severity]" -ForegroundColor $color
}

Write-Host "`n═══════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

# Show top 30 CRITICAL issues
$critical = $results | Where-Object { $_.Severity -eq "CRITICAL" } | Select-Object -First 30

if ($critical.Count -gt 0) {
    Write-Host "🚨 TOP $($critical.Count) CRITICAL ISSUES:`n" -ForegroundColor Red

    $critical | ForEach-Object {
        Write-Host "[$($_.Pattern)] " -NoNewline -ForegroundColor Red
        Write-Host "$($_.File):$($_.Line)" -ForegroundColor Yellow
        Write-Host "  $($_.Code)" -ForegroundColor White
        Write-Host ""
    }
}

# Export full results
$csvPath = "crash_patterns_full_report.csv"
$results | Export-Csv -Path $csvPath -NoTypeInformation
Write-Host "📄 Full report exported: $csvPath" -ForegroundColor Cyan
Write-Host "   Total issues found: $($results.Count)" -ForegroundColor White
Write-Host "`n═══════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

# Summary by severity
$bySeverity = $results | Group-Object Severity | Sort-Object Name
Write-Host "SEVERITY BREAKDOWN:" -ForegroundColor Yellow
$bySeverity | ForEach-Object {
    Write-Host "  $($_.Name): $($_.Count) issues" -ForegroundColor White
}
Write-Host ""
