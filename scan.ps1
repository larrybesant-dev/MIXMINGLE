# scan.ps1 - run from project root
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$analyzeOut = "analyze_$timestamp.txt"
$testOut = "test_$timestamp.txt"

Write-Host "Running flutter analyze..."
flutter analyze 2>&1 | Tee-Object -FilePath $analyzeOut

Write-Host "Running flutter test..."
flutter test --reporter expanded 2>&1 | Tee-Object -FilePath $testOut

Write-Host "Filtering analyzer errors..."
Select-String -Path $analyzeOut -Pattern "error" -Context 0,2 | Out-File "analyze_errors_$timestamp.txt"

Write-Host "Summary:"
if ((Get-Content $analyzeOut) -match "No issues found") {
  Write-Host "No analyzer issues."
} else {
  Write-Host "Analyzer output saved to $analyzeOut"
  Write-Host "Filtered errors saved to analyze_errors_$timestamp.txt"
}
Write-Host "Test output saved to $testOut"
exit 0
