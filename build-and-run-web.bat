@echo off
REM Mix & Mingle Flutter Web Build and Run Script

echo.
echo ========================================
echo Mix & Mingle Web Build & Run
echo ========================================
echo.

cd /d "c:\Users\LARRY\MIXMINGLE"

echo Step 1: Getting dependencies...
flutter pub get
if errorlevel 1 (
    echo ERROR: pub get failed
    pause
    exit /b 1
)

echo.
echo Step 2: Running on Chrome...
echo The app will open at http://localhost:54671
echo.
flutter run -d chrome --no-hot

pause
