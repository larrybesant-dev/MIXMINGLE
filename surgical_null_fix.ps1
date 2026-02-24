# ============================================================
# SURGICAL NULL-SAFETY FIXER
# Targets the most dangerous patterns causing infinite loops
# ============================================================

Write-Host "🎯 SURGICAL NULL-SAFETY FIX" -ForegroundColor Cyan
Write-Host "============================`n" -ForegroundColor Cyan

$dangerous = @()
$fileCount = 0

Write-Host "🔍 Phase 1: Finding DANGEROUS patterns (build methods, Text widgets)...`n" -ForegroundColor Yellow

# Scan for patterns that cause infinite loops
Get-ChildItem lib -Recurse -Filter "*.dart" | ForEach-Object {
    $file = $_
    $fileCount++
    $shortPath = $file.FullName -replace [regex]::Escape((Get-Location).Path + "\lib\"), ""

    $lines = Get-Content $file.FullName
    $inBuildMethod = $false
    $lineNum = 0

    foreach ($line in $lines) {
        $lineNum++

        # Track if we're inside a build method
        if ($line -match '^\s*Widget\s+build\s*\(') {
            $inBuildMethod = $true
        }
        if ($line -match '^\s*\}' -and $inBuildMethod) {
            $inBuildMethod = $false
        }

        # Skip comments
        if ($line -match '^\s*//' -or $line -match 'catch.*e\.toString' -or $line -match 'Exception') {
            continue
        }

        # CRITICAL PATTERN 1: Null assertion in build method
        if ($inBuildMethod -and $line -match '![\.\[\;]' -and $line -notmatch '!=') {
            $dangerous += [PSCustomObject]@{
                File = $shortPath
                Line = $lineNum
                Severity = 'CRITICAL-BUILD'
                Code = $line.Trim()
                Pattern = 'NullAssertionInBuild'
            }
        }

        # CRITICAL PATTERN 2: Text widget with direct variable interpolation (no null check)
        if ($line -match 'Text\s*\([^)]*\$\{?(\w+)' -and $line -notmatch '\?\?' -and $line -notmatch 'const Text' -and $line -notmatch '//') {
            $dangerous += [PSCustomObject]@{
                File = $shortPath
                Line = $lineNum
                Severity = 'CRITICAL-TEXT'
                Code = $line.Trim()
                Pattern = 'UnsafeTextInterpolation'
            }
        }

        # CRITICAL PATTERN 3: snapshot.data! (very common crash point)
        if ($line -match 'snapshot\.data!' -and $line -notmatch '//') {
            $dangerous += [PSCustomObject]@{
                File = $shortPath
                Line = $lineNum
                Severity = 'CRITICAL-SNAPSHOT'
                Code = $line.Trim()
                Pattern = 'SnapshotDataAssertion'
            }
        }

        # CRITICAL PATTERN 4: .data()! on Firestore documents
        if ($line -match '\.data\(\)!' -and $line -notmatch '//') {
            $dangerous += [PSCustomObject]@{
                File = $shortPath
                Line = $lineNum
                Severity = 'CRITICAL-FIRESTORE'
                Code = $line.Trim()
                Pattern = 'FirestoreDataAssertion'
            }
        }
    }
}

Write-Host "✅ Scan complete!" -ForegroundColor Green
Write-Host "   Files scanned: $fileCount" -ForegroundColor Cyan
Write-Host "   Dangerous patterns: $($dangerous.Count)`n" -ForegroundColor Red

# Group by severity
$buildIssues = $dangerous | Where-Object { $_.Severity -eq 'CRITICAL-BUILD' }
$textIssues = $dangerous | Where-Object { $_.Severity -eq 'CRITICAL-TEXT' }
$snapshotIssues = $dangerous | Where-Object { $_.Severity -eq 'CRITICAL-SNAPSHOT' }
$firestoreIssues = $dangerous | Where-Object { $_.Severity -eq 'CRITICAL-FIRESTORE' }

Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "         DANGEROUS PATTERNS FOUND          " -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🔴 Null assertions in build(): $($buildIssues.Count)" -ForegroundColor Red
Write-Host "🔴 Unsafe Text interpolation: $($textIssues.Count)" -ForegroundColor Red
Write-Host "🔴 snapshot.data! usage: $($snapshotIssues.Count)" -ForegroundColor Red
Write-Host "🔴 .data()! on Firestore: $($firestoreIssues.Count)" -ForegroundColor Red
Write-Host ""

# Show top offenders
if ($snapshotIssues.Count -gt 0) {
    Write-Host "🎯 TOP SNAPSHOT.DATA! ISSUES (most likely culprit):" -ForegroundColor Red
    Write-Host ""

    $snapshotIssues | Select-Object -First 15 | ForEach-Object {
        Write-Host "📄 $($_.File):$($_.Line)" -ForegroundColor Yellow
        Write-Host "   $($_.Code)" -ForegroundColor White
        Write-Host "   FIX: Replace snapshot.data! with snapshot.data ?? defaultValue" -ForegroundColor Green
        Write-Host ""
    }
}

if ($firestoreIssues.Count -gt 0) {
    Write-Host "🎯 TOP FIRESTORE .DATA()! ISSUES:" -ForegroundColor Red
    Write-Host ""

    $firestoreIssues | Select-Object -First 10 | ForEach-Object {
        Write-Host "📄 $($_.File):$($_.Line)" -ForegroundColor Yellow
        Write-Host "   $($_.Code)" -ForegroundColor White
        Write-Host "   FIX: Add null check before using .data()!" -ForegroundColor Green
        Write-Host ""
    }
}

if ($textIssues.Count -gt 0) {
    Write-Host "🎯 UNSAFE TEXT WIDGETS (first 10):" -ForegroundColor Red
    Write-Host ""

    $textIssues | Select-Object -First 10 | ForEach-Object {
        Write-Host "📄 $($_.File):$($_.Line)" -ForegroundColor Yellow
        Write-Host "   $($_.Code)" -ForegroundColor White
        Write-Host "   FIX: Add ?? to handle nulls" -ForegroundColor Green
        Write-Host ""
    }
}

# Export for manual review
$reportPath = "critical_null_patterns.csv"
$dangerous | Export-Csv -Path $reportPath -NoTypeInformation -Encoding UTF8
Write-Host "📊 Full report: $reportPath`n" -ForegroundColor Cyan

Write-Host "═══════════════════════════════════════════`n" -ForegroundColor Cyan

Write-Host "💡 RECOMMENDED FIX ORDER:" -ForegroundColor Cyan
Write-Host "1. Fix snapshot.data! issues (highest priority)" -ForegroundColor White
Write-Host "2. Fix Firestore .data()! issues" -ForegroundColor White
Write-Host "3. Fix unsafe Text widgets" -ForegroundColor White
Write-Host "4. Fix null assertions in build methods" -ForegroundColor White
Write-Host ""
Write-Host "🔧 Use find-and-replace in VS Code:" -ForegroundColor Yellow
Write-Host "   • snapshot.data! → snapshot.data ?? defaultValue" -ForegroundColor Green
Write-Host "   • .data()! → .data() with null check" -ForegroundColor Green
Write-Host "   • Text('\$var') → Text('\${var ?? \"\"}')" -ForegroundColor Green
Write-Host ""
