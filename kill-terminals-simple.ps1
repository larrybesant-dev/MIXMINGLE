powershell -Command {
Write-Host "Cleaning up VS Code terminals..." -ForegroundColor Cyan

# Kill all powershell and cmd processes that are children of VS Code
Get-Process | Where-Object { ($_.ProcessName -like "*conhost*" -or $_.ProcessName -like "*pwsh*") } | ForEach-Object {
    try {
        Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
        Write-Host "Closed terminal PID $($_.Id)" -ForegroundColor Green
    }
    catch { }
}

# Kill any lingering flutter processes
Get-Process -Name "flutter*" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

Write-Host "Done! Restart VS Code now." -ForegroundColor Green
}
