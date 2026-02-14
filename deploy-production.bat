@echo off
REM Mix & Mingle - Full Build and Deploy Script
REM This script will test, build, and deploy your app

echo.
echo ========================================
echo Mix ^& Mingle - Production Deployment
echo ========================================
echo.

cd /d "c:\Users\LARRY\MIXMINGLE"

echo Step 1: Cleaning previous builds...
flutter clean
if errorlevel 1 (
    echo ERROR: Clean failed
    pause
    exit /b 1
)

echo.
echo Step 2: Getting dependencies...
flutter pub get
if errorlevel 1 (
    echo ERROR: pub get failed
    pause
    exit /b 1
)

echo.
echo Step 3: Building web release...
echo This may take 2-3 minutes...
flutter build web --release
if errorlevel 1 (
    echo ERROR: Build failed
    pause
    exit /b 1
)

echo.
echo ========================================
echo Build Complete!
echo ========================================
echo.
echo Output is in: build\web\
echo.
echo Next step: Deploy to Firebase
echo Run: firebase hosting:channel:deploy live
echo.
pause
