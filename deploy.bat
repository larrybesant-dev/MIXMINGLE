@echo off
echo ========================================
echo Mix & Mingle - Manual Deployment Script
echo ========================================
echo.

echo [1/4] Building Flutter Web app for production...
flutter build web --release
if %errorlevel% neq 0 (
    echo ERROR: Flutter build failed.
    pause
    exit /b 1
)
echo ✓ Flutter Web app built successfully
echo.

echo [2/4] Checking Firebase CLI installation...
firebase --version
if %errorlevel% neq 0 (
    echo ERROR: Firebase CLI not found.
    echo Please install: npm install -g firebase-tools
    echo Then login: firebase login
    pause
    exit /b 1
)
echo ✓ Firebase CLI found
echo.

echo [3/4] Checking Firebase project configuration...
firebase projects:list
if %errorlevel% neq 0 (
    echo ERROR: Firebase authentication failed.
    echo Please run: firebase login
    pause
    exit /b 1
)
echo ✓ Firebase authenticated
echo.

echo [4/4] Deploying to Firebase Hosting...
firebase deploy --only hosting
if %errorlevel% neq 0 (
    echo ERROR: Firebase deployment failed.
    pause
    exit /b 1
)
echo ✓ Deployment completed successfully!
echo.

echo ========================================
echo 🎉 Deployment Complete!
echo ========================================
echo.
echo Your app is now live at:
echo https://mix-and-mingle-62061.web.app
echo https://mix-and-mingle-62061.firebaseapp.com
echo.
pause