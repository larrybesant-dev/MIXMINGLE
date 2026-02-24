# -----------------------------------------------
# flutter_clean_run_enhanced.ps1
# Enhanced version with automatic error analysis
# -----------------------------------------------

Write-Host "`n🛑 Killing all Dart/Flutter processes (aggressive mode)..."
# Kill more aggressively
Get-Process -Name dart,flutter -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2

# Second pass to catch stragglers
Get-Process | Where-Object { $_.ProcessName -match "dart|flutter|chrome.*--app" } | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

Write-Host "✅ Processes stopped. Verifying..."
$check = Get-Process | Where-Object { $_.ProcessName -match "dart|flutter" }

if ($check) {
    Write-Host "⚠️ Some processes are still running:" -ForegroundColor Yellow
    $check | Format-Table Id, ProcessName, CPU, PM, WS
    Write-Host "Attempting final force kill..."
    $check | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
}

$finalCheck = Get-Process | Where-Object { $_.ProcessName -match "dart|flutter" }
if (-not $finalCheck) {
    Write-Host "✅ All Dart/Flutter processes stopped.`n" -ForegroundColor Green
}

Write-Host "🧹 Cleaning Flutter build cache..."
flutter clean | Out-Null

Write-Host "🚀 Starting Flutter Web release build with diagnostic logging..."
Write-Host "   Output will be captured to: flutter_diagnostic_log.txt"
Write-Host "   This may take a minute...`n"

# Run flutter and capture output
$output = flutter run -d chrome --web-port=5000 --release -v 2>&1
$output | Out-File -FilePath flutter_diagnostic_log.txt -Encoding UTF8

Write-Host "`n📊 ANALYSIS COMPLETE - Parsing errors...`n" -ForegroundColor Cyan

# Parse for null safety errors
$nullErrors = $output | Select-String -Pattern "Null check operator used on a null value|Cannot read properties of null"
$nullCount = ($nullErrors | Measure-Object).Count

# Parse for specific error locations
$errorLocations = $output | Select-String -Pattern "at (\w+)\.(\w+) \(http://localhost:5000/main\.dart\.js:(\d+):(\d+)\)"

# Find unique error sources
$uniqueErrors = $errorLocations | ForEach-Object {
    if ($_.Line -match "at (\w+)\.(\w+)") {
        "$($matches[1]).$($matches[2])"
    }
} | Select-Object -Unique

Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "         ERROR ANALYSIS SUMMARY            " -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan

if ($nullCount -gt 0) {
    Write-Host "`n❌ Null Safety Errors: $nullCount occurrences" -ForegroundColor Red
    Write-Host "`n🎯 Primary Error Source:" -ForegroundColor Yellow
    Write-Host "   'Cannot read properties of null (reading toString)'" -ForegroundColor White

    if ($uniqueErrors) {
        Write-Host "`n📍 Affected Functions (unique):" -ForegroundColor Yellow
        $uniqueErrors | Select-Object -First 10 | ForEach-Object {
            Write-Host "   • $_" -ForegroundColor White
        }
        if (($uniqueErrors | Measure-Object).Count -gt 10) {
            Write-Host "   ... and $(($uniqueErrors | Measure-Object).Count - 10) more" -ForegroundColor Gray
        }
    }

    Write-Host "`n💡 RECOMMENDATION:" -ForegroundColor Cyan
    Write-Host "   The error 'Cannot read properties of null (reading toString)'" -ForegroundColor White
    Write-Host "   suggests a widget is trying to display null data." -ForegroundColor White
    Write-Host "`n   Common causes:" -ForegroundColor Yellow
    Write-Host "   1. Missing null checks in Text() or similar widgets" -ForegroundColor White
    Write-Host "   2. Provider/Riverpod state not initialized" -ForegroundColor White
    Write-Host "   3. Async data being used before it's loaded" -ForegroundColor White
    Write-Host "`n   To fix: Search your code for .toString() calls on nullable values" -ForegroundColor Green
    Write-Host "   and add null checks: myVar?.toString() ?? 'default'" -ForegroundColor Green
} else {
    Write-Host "`n✅ No null safety errors detected!" -ForegroundColor Green
}

Write-Host "`n═══════════════════════════════════════════`n" -ForegroundColor Cyan

Write-Host "📄 Full diagnostic log saved to: flutter_diagnostic_log.txt" -ForegroundColor Cyan
Write-Host "   View with: notepad flutter_diagnostic_log.txt`n"
