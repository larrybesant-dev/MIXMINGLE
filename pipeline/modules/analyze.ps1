function Run-AppAnalysis {
    Write-Log "Running flutter analyze..."
    flutter analyze
    Write-Log "Analysis complete."
}