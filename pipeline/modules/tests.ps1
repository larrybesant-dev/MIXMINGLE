function Run-AppTests {
    Write-Log "Running flutter tests..."
    flutter test
    Write-Log "Tests complete."
}