# -----------------------------------------------
# flutter_clean_run.ps1
# -----------------------------------------------

Write-Host "🛑 Killing all Dart/Flutter processes..."
Get-Process | Where-Object { $_.ProcessName -match "dart|flutter" } | Stop-Process -Force

Write-Host "✅ Processes stopped. Verifying..."
$check = Get-Process | Where-Object { $_.ProcessName -match "dart|flutter" }

if ($check) {
    Write-Host "⚠️ Some processes are still running:" -ForegroundColor Red
    $check | Format-Table Id, ProcessName, CPU, PM, WS
} else {
    Write-Host "✅ No Dart/Flutter processes running."
}

Write-Host "🚀 Starting Flutter Web release build (Chrome) with verbose logging..."
flutter run -d chrome --web-port=5000 --release -v > flutter_diagnostic_log.txt

Write-Host "📄 Build output is saved to flutter_diagnostic_log.txt"
Write-Host "You can open it with: notepad flutter_diagnostic_log.txt"
