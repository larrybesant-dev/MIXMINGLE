# Mix & Mingle - Production Deployment Script
# This script will build and deploy your Flutter web app to Firebase

Write-Host ""
Write-Host "========================================"
Write-Host "Mix & Mingle - Production Deployment"
Write-Host "========================================"
Write-Host ""

Set-Location "c:\Users\LARRY\MIXMINGLE"

# Step 1: Clean
Write-Host "Step 1: Cleaning previous builds..." -ForegroundColor Cyan
flutter clean
if ($LASTEXITCODE -ne 0) {
  Write-Host "ERROR: Clean failed" -ForegroundColor Red
  Read-Host "Press Enter to exit"
  exit 1
}

# Step 2: Get dependencies
Write-Host ""
Write-Host "Step 2: Getting dependencies..." -ForegroundColor Cyan
flutter pub get
if ($LASTEXITCODE -ne 0) {
  Write-Host "ERROR: pub get failed" -ForegroundColor Red
  Read-Host "Press Enter to exit"
  exit 1
}

# Step 3: Build web release
Write-Host ""
Write-Host "Step 3: Building web release..." -ForegroundColor Cyan
Write-Host "This may take 2-3 minutes..." -ForegroundColor Yellow
flutter build web --release
if ($LASTEXITCODE -ne 0) {
  Write-Host "ERROR: Build failed" -ForegroundColor Red
  Read-Host "Press Enter to exit"
  exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Build Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Output is in: build\web\" -ForegroundColor Yellow
Write-Host ""

# Step 4: Deploy to Firebase
Write-Host "Step 4: Deploying to Firebase..." -ForegroundColor Cyan
$deploy = Read-Host "Deploy to Firebase now? (y/n)"
if ($deploy -eq "y" -or $deploy -eq "Y") {
  Write-Host "Deploying to Firebase Hosting..." -ForegroundColor Cyan
  firebase hosting:channel:deploy live
  if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Deployment Complete!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Your app is now live!" -ForegroundColor Green
    Write-Host ""
  }
  else {
    Write-Host "ERROR: Deployment failed" -ForegroundColor Red
  }
}
else {
  Write-Host ""
  Write-Host "Skipping deployment." -ForegroundColor Yellow
  Write-Host "To deploy later, run:" -ForegroundColor Yellow
  Write-Host "  firebase hosting:channel:deploy live" -ForegroundColor Cyan
  Write-Host ""
}

Write-Host ""
Write-Host "Done!" -ForegroundColor Green
Read-Host "Press Enter to exit"
