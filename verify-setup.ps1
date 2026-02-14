Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Mix & Mingle - Local CI/CD Test Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/6] Checking Flutter installation..." -ForegroundColor Yellow
try {
    $flutterVersion = flutter --version
    Write-Host "✓ Flutter found" -ForegroundColor Green
    Write-Host $flutterVersion
} catch {
    Write-Host "ERROR: Flutter not found. Please install Flutter SDK." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host ""

Write-Host "[2/6] Installing Flutter dependencies..." -ForegroundColor Yellow
try {
    flutter pub get
    Write-Host "✓ Flutter dependencies installed" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to install Flutter dependencies." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host ""

Write-Host "[3/6] Building Flutter Web app..." -ForegroundColor Yellow
try {
    flutter build web --release
    Write-Host "✓ Flutter Web app built successfully" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Flutter build failed." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host ""

Write-Host "[4/6] Checking Node.js installation..." -ForegroundColor Yellow
try {
    $nodeVersion = node --version
    Write-Host "✓ Node.js found" -ForegroundColor Green
    Write-Host $nodeVersion
} catch {
    Write-Host "ERROR: Node.js not found. Please install Node.js 18+." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host ""

Write-Host "[5/6] Installing Playwright dependencies..." -ForegroundColor Yellow
try {
    Set-Location playwright-tests
    npm ci
    Write-Host "✓ Playwright dependencies installed" -ForegroundColor Green
} catch {
    Set-Location ..
    Write-Host "ERROR: Failed to install Playwright dependencies." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host ""

Write-Host "[6/6] Installing Playwright browsers..." -ForegroundColor Yellow
try {
    npx playwright install --with-deps
    Set-Location ..
    Write-Host "✓ Playwright browsers installed" -ForegroundColor Green
} catch {
    Set-Location ..
    Write-Host "ERROR: Failed to install Playwright browsers." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ Local CI/CD setup verification PASSED!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Your project is ready for:" -ForegroundColor White
Write-Host "• Local testing: Run 'npm test' in playwright-tests/" -ForegroundColor White
Write-Host "• GitHub Actions: Push to main/master branch" -ForegroundColor White
Write-Host "• Firebase deployment: Add FIREBASE_SERVICE_ACCOUNT secret" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Test locally: cd playwright-tests; npm test" -ForegroundColor White
Write-Host "2. Push to GitHub to trigger CI/CD" -ForegroundColor White
Write-Host "3. Add Firebase service account secret for deployment" -ForegroundColor White
Write-Host ""
Read-Host "Press Enter to exit"