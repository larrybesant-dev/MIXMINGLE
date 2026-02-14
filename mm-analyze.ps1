# ============================
# MixMingle Analyzer Utility
# ============================

# Timestamp for log file
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logFile = "analyze_$timestamp.txt"

Write-Host "Running Flutter analyzer..." -ForegroundColor Cyan

# Run analyzer and capture output
$analyzeOutput = flutter analyze --no-preamble 2>&1
$analyzeOutput | Out-File -FilePath $logFile -Encoding UTF8

Write-Host "Log saved to $logFile" -ForegroundColor Green

# Count total errors
$totalErrors = ($analyzeOutput | Select-String "error -").Count

# Count lib errors
$libErrors = ($analyzeOutput |
  Select-String "error -" |
  Select-String "lib\\").Count

# Count test errors
$testErrors = ($analyzeOutput |
  Select-String "error -" |
  Select-String "test\\").Count

# Display summary
Write-Host "`n======================" -ForegroundColor Yellow
Write-Host " MixMingle Error Summary" -ForegroundColor Yellow
Write-Host "======================`n" -ForegroundColor Yellow

Write-Host "Total Errors: $totalErrors"
Write-Host "Lib Errors:   $libErrors"
Write-Host "Test Errors:  $testErrors`n"

# Show first 20 lib errors (if any)
if ($libErrors -gt 0) {
  Write-Host "First 20 lib errors:`n" -ForegroundColor Red
  $analyzeOutput |
  Select-String "error -" |
  Select-String "lib\\" |
  Select-Object -First 20 |
  ForEach-Object { Write-Host $_ }
}
else {
  Write-Host "No lib errors detected 🎉" -ForegroundColor Green
}

Write-Host "`nDone."
