@echo off
echo ========================================
echo Mix & Mingle - Local CI/CD Test Script
echo ========================================
echo.

echo [1/6] Checking Flutter installation...
flutter --version
if %errorlevel% neq 0 (
    echo ERROR: Flutter not found. Please install Flutter SDK.
    pause
    exit /b 1
)
echo ✓ Flutter found
echo.

echo [2/6] Installing Flutter dependencies...
flutter pub get
if %errorlevel% neq 0 (
    echo ERROR: Failed to install Flutter dependencies.
    pause
    exit /b 1
)
echo ✓ Flutter dependencies installed
echo.

echo [3/6] Building Flutter Web app...
flutter build web --release
if %errorlevel% neq 0 (
    echo ERROR: Flutter build failed.
    pause
    exit /b 1
)
echo ✓ Flutter Web app built successfully
echo.

echo [4/6] Checking Node.js installation...
node --version
if %errorlevel% neq 0 (
    echo ERROR: Node.js not found. Please install Node.js 18+.
    pause
    exit /b 1
)
echo ✓ Node.js found
echo.

echo [5/6] Installing Playwright dependencies...
cd playwright-tests
npm ci
if %errorlevel% neq 0 (
    echo ERROR: Failed to install Playwright dependencies.
    cd ..
    pause
    exit /b 1
)
echo ✓ Playwright dependencies installed
echo.

echo [6/6] Installing Playwright browsers...
npx playwright install --with-deps
if %errorlevel% neq 0 (
    echo ERROR: Failed to install Playwright browsers.
    cd ..
    pause
    exit /b 1
)
cd ..
echo ✓ Playwright browsers installed
echo.

echo ========================================
echo ✅ Local CI/CD setup verification PASSED!
echo ========================================
echo.
echo Your project is ready for:
echo • Local testing: Run 'npm test' in playwright-tests/
echo • GitHub Actions: Push to main/master branch
echo • Firebase deployment: Add FIREBASE_SERVICE_ACCOUNT secret
echo.
echo Next steps:
echo 1. Test locally: cd playwright-tests && npm test
echo 2. Push to GitHub to trigger CI/CD
echo 3. Add Firebase service account secret for deployment
echo.
pause