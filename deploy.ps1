Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Mix & Mingle - Manual Deployment Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/4] Building Flutter Web app for production..." -ForegroundColor Yellow
try {
    flutter build web --release
    Write-Host "✓ Flutter Web app built successfully" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Flutter build failed." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host ""

Write-Host "[2/4] Checking Firebase CLI installation..." -ForegroundColor Yellow
try {
    $firebaseVersion = firebase --version
    Write-Host "✓ Firebase CLI found" -ForegroundColor Green
    Write-Host $firebaseVersion
} catch {
    Write-Host "ERROR: Firebase CLI not found." -ForegroundColor Red
    Write-Host "Please install: npm install -g firebase-tools" -ForegroundColor Yellow
    Write-Host "Then login: firebase login" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host ""

Write-Host "[3/4] Checking Firebase project configuration..." -ForegroundColor Yellow
try {
    firebase projects:list
    Write-Host "✓ Firebase authenticated" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Firebase authentication failed." -ForegroundColor Red
    Write-Host "Please run: firebase login" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host ""

Write-Host "[4/4] Deploying to Firebase Hosting..." -ForegroundColor Yellow
try {
    firebase deploy --only hosting
    Write-Host "✓ Deployment completed successfully!" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Firebase deployment failed." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "🎉 Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Your app is now live at:" -ForegroundColor White
Write-Host "https://mix-and-mingle-62061.web.app" -ForegroundColor Cyan
Write-Host "https://mix-and-mingle-62061.firebaseapp.com" -ForegroundColor Cyan
Write-Host ""
Read-Host "Press Enter to exit"