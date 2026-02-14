@echo off
REM MixMingle Flutter Web Build and Deploy Script
REM This script automates the build and deployment process for the MixMingle Flutter web app

echo ========================================
echo  MixMingle Flutter Web Build Script
echo ========================================
echo.

REM Check if we're in the right directory
if not exist "pubspec.yaml" (
    echo ERROR: pubspec.yaml not found!
    echo Please run this script from the root of your Flutter project.
    echo Expected location: C:\Users\LARRY\MIXMINGLE
    echo.
    pause
    exit /b 1
)

echo ✓ Found pubspec.yaml - Project root confirmed
echo.

REM Clean previous builds
echo Cleaning previous build files...
flutter clean
if %errorlevel% neq 0 (
    echo ERROR: Flutter clean failed!
    pause
    exit /b 1
)
echo ✓ Clean completed
echo.

REM Get dependencies
echo Getting Flutter dependencies...
flutter pub get
if %errorlevel% neq 0 (
    echo ERROR: Flutter pub get failed!
    pause
    exit /b 1
)
echo ✓ Dependencies installed
echo.

REM Build web app in release mode
echo Building Flutter web app (release mode)...
flutter build web --release
if %errorlevel% neq 0 (
    echo ERROR: Flutter build failed!
    echo Check the error messages above for details.
    pause
    exit /b 1
)
echo ✓ Web app built successfully
echo.

REM Copy Firebase service worker for production
echo Copying Firebase service worker for production...
copy "web\firebase-messaging-sw.js" "build\web\" >nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ Firebase service worker copied
) else (
    echo ⚠️  Warning: Could not copy Firebase service worker
)
echo.

REM Check if Firebase CLI is available
firebase --version >nul 2>&1
if %errorlevel% neq 0 (
    echo WARNING: Firebase CLI not found!
    echo To deploy, install Firebase CLI with: npm install -g firebase-tools
    echo Then run: firebase login
    echo And: firebase init (if not already done)
    echo.
    echo Build completed but deployment skipped.
    echo You can manually deploy with: firebase deploy
    echo.
    pause
    exit /b 0
)

REM Deploy to Firebase
echo Deploying to Firebase Hosting...
firebase deploy --only hosting
if %errorlevel% neq 0 (
    echo ERROR: Firebase deployment failed!
    echo Check your Firebase configuration and try again.
    pause
    exit /b 1
)
echo ✓ Deployment completed successfully!
echo.

echo ========================================
echo  Build and Deploy Summary
echo ========================================
echo ✓ Project root verified
echo ✓ Dependencies installed
echo ✓ Web app built (release mode)
echo ✓ Deployed to Firebase Hosting
echo.
echo Your app should now be live at your Firebase Hosting URL!
echo.
echo If you still see a white screen, check:
echo 1. Browser console for JavaScript errors
echo 2. Firebase console for hosting issues
echo 3. Ensure Firebase config is correct in firebase_options.dart
echo.
pause