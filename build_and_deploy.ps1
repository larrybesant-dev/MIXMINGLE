# MixMingle Flutter Web Build and Deploy Script
# This script automates the build and deployment process for the MixMingle Flutter web app

param(
    [switch]$SkipDeploy,
    [switch]$CleanOnly
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " MixMingle Flutter Web Build Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if we're in the right directory
if (-not (Test-Path "pubspec.yaml")) {
    Write-Host "ERROR: pubspec.yaml not found!" -ForegroundColor Red
    Write-Host "Please run this script from the root of your Flutter project." -ForegroundColor Red
    Write-Host "Expected location: C:\Users\LARRY\MIXMINGLE" -ForegroundColor Red
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "✓ Found pubspec.yaml - Project root confirmed" -ForegroundColor Green
Write-Host ""

# Check Firebase configuration
Write-Host "Checking Firebase configuration..." -ForegroundColor Yellow
if (Test-Path ".firebaserc") {
    $firebasercContent = Get-Content ".firebaserc" -Raw | ConvertFrom-Json
    if ($firebasercContent.projects -and $firebasercContent.projects.defualt) {
        Write-Host "WARNING: Found typo 'defualt' in .firebaserc (should be 'default')" -ForegroundColor Yellow
        Write-Host "Auto-fixing the typo..." -ForegroundColor Yellow
        $firebasercContent.projects.PSObject.Properties.Remove('defualt')
        $firebasercContent | ConvertTo-Json -Depth 10 | Set-Content ".firebaserc"
        Write-Host "✓ Fixed typo in .firebaserc" -ForegroundColor Green
    } else {
        Write-Host "✓ Firebase configuration looks good" -ForegroundColor Green
    }
} else {
    Write-Host "WARNING: .firebaserc not found - Firebase may not be configured" -ForegroundColor Yellow
}
Write-Host ""

if ($CleanOnly) {
    Write-Host "Cleaning previous build files..." -ForegroundColor Yellow
    & flutter clean
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Flutter clean failed!" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
    Write-Host "✓ Clean completed" -ForegroundColor Green
    Write-Host ""
    Write-Host "Clean-only mode completed." -ForegroundColor Green
    Read-Host "Press Enter to exit"
    exit 0
}

# Clean previous builds
Write-Host "Cleaning previous build files..." -ForegroundColor Yellow
& flutter clean
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Flutter clean failed!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "✓ Clean completed" -ForegroundColor Green
Write-Host ""

# Get dependencies
Write-Host "Getting Flutter dependencies..." -ForegroundColor Yellow
& flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Flutter pub get failed!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "✓ Dependencies installed" -ForegroundColor Green
Write-Host ""

# Build web app in release mode
Write-Host "Building Flutter web app (release mode)..." -ForegroundColor Yellow
& flutter build web --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Flutter build failed!" -ForegroundColor Red
    Write-Host "Check the error messages above for details." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "✓ Web app built successfully" -ForegroundColor Green
Write-Host ""

# Copy Firebase service worker for production
Write-Host "Copying Firebase service worker for production..." -ForegroundColor Yellow
Copy-Item -Path ".\web\firebase-messaging-sw.js" -Destination ".\build\web\firebase-messaging-sw.js" -ErrorAction SilentlyContinue
if ($?) {
    Write-Host "✓ Firebase service worker copied" -ForegroundColor Green
} else {
    Write-Host "⚠️  Warning: Could not copy Firebase service worker" -ForegroundColor Yellow
}
Write-Host ""

if ($SkipDeploy) {
    Write-Host "Skipping deployment as requested." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host " Build Summary (Deploy Skipped)" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "✓ Project root verified" -ForegroundColor Green
    Write-Host "✓ Dependencies installed" -ForegroundColor Green
    Write-Host "✓ Web app built (release mode)" -ForegroundColor Green
    Write-Host ""
    Write-Host "To deploy manually, run: firebase deploy --only hosting" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 0
}

# Check if Firebase CLI is available
$firebaseAvailable = $null
try {
    $firebaseVersion = & firebase --version 2>$null
    $firebaseAvailable = $true
} catch {
    $firebaseAvailable = $false
}

if (-not $firebaseAvailable) {
    Write-Host "WARNING: Firebase CLI not found!" -ForegroundColor Yellow
    Write-Host "To deploy, install Firebase CLI with: npm install -g firebase-tools" -ForegroundColor Yellow
    Write-Host "Then run: firebase login" -ForegroundColor Yellow
    Write-Host "And: firebase init (if not already done)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Build completed but deployment skipped." -ForegroundColor Yellow
    Write-Host "You can manually deploy with: firebase deploy --only hosting" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 0
}

# Deploy to Firebase
Write-Host "Deploying to Firebase Hosting..." -ForegroundColor Yellow
& firebase deploy --only hosting
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Firebase deployment failed!" -ForegroundColor Red
    Write-Host "Check your Firebase configuration and try again." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "✓ Deployment completed successfully!" -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Build and Deploy Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✓ Project root verified" -ForegroundColor Green
Write-Host "✓ Dependencies installed" -ForegroundColor Green
Write-Host "✓ Web app built (release mode)" -ForegroundColor Green
Write-Host "✓ Deployed to Firebase Hosting" -ForegroundColor Green
Write-Host ""
Write-Host "Your app should now be live at your Firebase Hosting URL!" -ForegroundColor Green
Write-Host ""
Write-Host "If you still see a white screen, check:" -ForegroundColor Yellow
Write-Host "1. Browser console for JavaScript errors" -ForegroundColor Yellow
Write-Host "2. Firebase console for hosting issues" -ForegroundColor Yellow
Write-Host "3. Ensure Firebase config is correct in firebase_options.dart" -ForegroundColor Yellow
Write-Host ""
Read-Host "Press Enter to exit"