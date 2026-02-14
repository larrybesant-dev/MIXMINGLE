# ==============================
# MIX & MINGLE – HOSTING ONLY DEPLOY
# ==============================
# Use this if Firebase Functions are timing out
# This deploys only the web app, skipping functions

Write-Host "🚀 Starting Mix & Mingle Hosting-Only Deployment" -ForegroundColor Cyan

# 1️⃣ Clean & Get Packages
Write-Host "🧹 Cleaning project..." -ForegroundColor Yellow
flutter clean
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Flutter clean failed." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "📦 Getting packages..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to get packages." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# 2️⃣ Analyze for Errors
Write-Host "🔍 Analyzing code..." -ForegroundColor Yellow
flutter analyze
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Analyze found issues. Fix them before deployment." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# 3️⃣ Build Web Release
Write-Host "🌐 Building Web Release..." -ForegroundColor Yellow
flutter build web --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Web build failed." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# 4️⃣ Deploy Firebase Hosting ONLY (skip functions)
Write-Host "☁️ Deploying Hosting to Mix & Mingle v2..." -ForegroundColor Yellow
firebase deploy --only hosting --project mix-and-mingle-v2
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Firebase deployment failed." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "✅ Hosting deployed successfully!" -ForegroundColor Green

Write-Host ""
Write-Host "🎉 Hosting deployment complete!" -ForegroundColor Cyan
Write-Host ""
Write-Host "Your app is now live at:" -ForegroundColor Yellow
Write-Host "https://mix-and-mingle-v2.web.app" -ForegroundColor Cyan
Write-Host "https://mix-and-mingle-v2.firebaseapp.com" -ForegroundColor Cyan
Write-Host ""
Write-Host "⚠️  Note: Functions were NOT deployed." -ForegroundColor Yellow
Write-Host "To deploy functions separately, run:" -ForegroundColor Yellow
Write-Host "firebase deploy --only functions --project mix-and-mingle-v2" -ForegroundColor Cyan
Write-Host ""
Read-Host "Press Enter to exit"
