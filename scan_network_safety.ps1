# Network Safety Scanner - Find unsafe Image.network, NetworkImage, and network calls

Write-Host "`n═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  🌐 NETWORK SAFETY SCANNER" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

$results = @()
$totalFiles = 0

Write-Host "Scanning lib/ for unsafe network operations...`n" -ForegroundColor White

Get-ChildItem lib -Recurse -Filter "*.dart" -ErrorAction SilentlyContinue | ForEach-Object {
    $file = $_
    $totalFiles++
    $relativePath = $file.FullName -replace [regex]::Escape((Get-Location).Path + "\lib\"), ""

    $lineNum = 0
    $content = Get-Content $file.FullName -Raw

    Get-Content $file.FullName -ErrorAction SilentlyContinue | ForEach-Object {
        $lineNum++
        $line = $_
        $trimmed = $line.Trim()

        # Skip comments
        if ($trimmed -match '^\s*//' -or $trimmed -eq '') { return }

        # PATTERN 1: Image.network without errorBuilder
        if ($line -match 'Image\.network\s*\(' -and
            $content -notmatch "Image\.network\s*\([^)]*errorBuilder" -and
            $line -notmatch 'errorBuilder') {

            $results += [PSCustomObject]@{
                File = $relativePath
                Line = $lineNum
                Pattern = "UnsafeImageNetwork"
                Severity = "HIGH"
                Code = $trimmed
            }
        }

        # PATTERN 2: NetworkImage without error handling
        if ($line -match 'NetworkImage\s*\(' -and
            $line -notmatch 'errorBuilder' -and
            $line -notmatch 'onError') {

            $results += [PSCustomObject]@{
                File = $relativePath
                Line = $lineNum
                Pattern = "UnsafeNetworkImage"
                Severity = "HIGH"
                Code = $trimmed
            }
        }

        # PATTERN 3: CircleAvatar with NetworkImage without error handling
        if ($line -match 'CircleAvatar\s*\(' -and
            $line -match 'NetworkImage' -and
            $line -notmatch 'onBackgroundImageError') {

            $results += [PSCustomObject]@{
                File = $relativePath
                Line = $lineNum
                Pattern = "UnsafeCircleAvatar"
                Severity = "MEDIUM"
                Code = $trimmed
            }
        }

        # PATTERN 4: FadeInImage without error handling
        if ($line -match 'FadeInImage\s*\(' -and
            $line -notmatch 'imageErrorBuilder' -and
            $line -notmatch 'image:.*errorBuilder') {

            $results += [PSCustomObject]@{
                File = $relativePath
                Line = $lineNum
                Pattern = "UnsafeFadeInImage"
                Severity = "MEDIUM"
                Code = $trimmed
            }
        }

        # PATTERN 5: CachedNetworkImage without error widget
        if ($line -match 'CachedNetworkImage\s*\(' -and
            $line -notmatch 'errorWidget' -and
            $content -notmatch "CachedNetworkImage\s*\([^}]*errorWidget") {

            $results += [PSCustomObject]@{
                File = $relativePath
                Line = $lineNum
                Pattern = "UnsafeCachedNetworkImage"
                Severity = "MEDIUM"
                Code = $trimmed
            }
        }

        # PATTERN 6: Direct avatar/photoUrl access without null check
        if ($line -match '(avatarUrl|photoUrl|profilePhotoUrl|imageUrl)!' -and
            $line -notmatch '^\s*//') {

            $results += [PSCustomObject]@{
                File = $relativePath
                Line = $lineNum
                Pattern = "UnsafeImageUrlAssertion"
                Severity = "CRITICAL"
                Code = $trimmed
            }
        }

        # PATTERN 7: http.get or dio.get without error handling
        if ($line -match '(http|dio)\.get\s*\(' -and
            $line -notmatch 'try\s*{' -and
            $line -notmatch 'catchError') {

            $results += [PSCustomObject]@{
                File = $relativePath
                Line = $lineNum
                Pattern = "UnsafeHttpGet"
                Severity = "MEDIUM"
                Code = $trimmed
            }
        }
    }
}

Write-Host "✅ Scanned $totalFiles Dart files`n" -ForegroundColor Green

# Group and count
$grouped = $results | Group-Object Pattern | Sort-Object Count -Descending

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  📊 NETWORK SAFETY SUMMARY" -ForegroundColor Yellow
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

# Show critical issues
$critical = $results | Where-Object { $_.Severity -eq "CRITICAL" -or $_.Severity -eq "HIGH" } | Select-Object -First 25

if ($critical.Count -gt 0) {
    Write-Host "🚨 TOP CRITICAL/HIGH ISSUES:`n" -ForegroundColor Red

    $critical | ForEach-Object {
        Write-Host "[$($_.Pattern)] " -NoNewline -ForegroundColor Red
        Write-Host "$($_.File):$($_.Line)" -ForegroundColor Yellow
        Write-Host "  $($_.Code)" -ForegroundColor White
        Write-Host ""
    }
}

# Export report
$csvPath = "network_safety_report.csv"
$results | Export-Csv -Path $csvPath -NoTypeInformation
Write-Host "📄 Full report: $csvPath" -ForegroundColor Cyan
Write-Host "   Total issues: $($results.Count)" -ForegroundColor White
Write-Host "`n═══════════════════════════════════════════════════════════`n" -ForegroundColor Cyan
