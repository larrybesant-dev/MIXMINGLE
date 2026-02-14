function Run-AppBuild {
    Write-Log "Building Flutter Web release..."
    flutter build web --release --no-tree-shake-icons
    Write-Log "Build complete."
}