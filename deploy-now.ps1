# 🚀 Mix & Mingle — One-Click Deploy Script
# Run this to deploy web + build Android in one go

Write-Host "🚀 Mix & Mingle Deployment Starting..." -ForegroundColor Cyan
Write-Host ""

# Check Flutter
Write-Host "✓ Checking Flutter..." -ForegroundColor Yellow
flutter doctor | Out-Null
if ($LASTEXITCODE -ne 0) {
  Write-Host "❌ Flutter not ready. Run: flutter doctor" -ForegroundColor Red
  exit 1
}

# Check Firebase
Write-Host "✓ Checking Firebase..." -ForegroundColor Yellow
$firebaseCheck = firebase projects:list 2>&1
if ($LASTEXITCODE -ne 0) {
  Write-Host "❌ Firebase not logged in. Run: firebase login" -ForegroundColor Red
  exit 1
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "STEP 1: Building Web App" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

flutter build web --release

if ($LASTEXITCODE -ne 0) {
  Write-Host ""
  Write-Host "❌ Web build failed!" -ForegroundColor Red
  Write-Host "Try: flutter clean && flutter pub get" -ForegroundColor Yellow
  exit 1
}

Write-Host ""
Write-Host "✅ Web build complete!" -ForegroundColor Green
Write-Host ""

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "STEP 2: Deploying to Firebase Hosting" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

firebase deploy --only hosting

if ($LASTEXITCODE -ne 0) {
  Write-Host ""
  Write-Host "❌ Firebase deployment failed!" -ForegroundColor Red
  exit 1
}

Write-Host ""
Write-Host "✅ Web app deployed!" -ForegroundColor Green
Write-Host ""

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "STEP 3: Building Android Release" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

flutter build appbundle --release

if ($LASTEXITCODE -ne 0) {
  Write-Host ""
  Write-Host "⚠️ Android build failed!" -ForegroundColor Yellow
  Write-Host "Web is still deployed. You can upload Android manually." -ForegroundColor Yellow
  Write-Host ""
  Write-Host "To fix Android build:" -ForegroundColor Cyan
  Write-Host "1. Set up app signing: https://docs.flutter.dev/deployment/android#signing-the-app" -ForegroundColor Cyan
  Write-Host "2. Or build APK for testing: flutter build apk --release" -ForegroundColor Cyan
  Write-Host ""
}
else {
  Write-Host ""
  Write-Host "✅ Android build complete!" -ForegroundColor Green
  Write-Host ""
  Write-Host "📦 Your Android app bundle is ready:" -ForegroundColor Cyan
  Write-Host "   build/app/outputs/bundle/release/app-release.aab" -ForegroundColor White
  Write-Host ""
}

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host "🎉 DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host ""

# Get Firebase URL
$firebaseUrl = "https://mixmingle-prod.web.app"
Write-Host "🖥️  WEB APP LIVE:" -ForegroundColor Cyan
Write-Host "   $firebaseUrl" -ForegroundColor White
Write-Host ""

if ($LASTEXITCODE -eq 0) {
  Write-Host "🤖 ANDROID APP READY:" -ForegroundColor Cyan
  Write-Host "   Upload to Play Console:" -ForegroundColor White
  Write-Host "   https://play.google.com/console" -ForegroundColor Blue
  Write-Host ""
  Write-Host "   File location:" -ForegroundColor White
  Write-Host "   build/app/outputs/bundle/release/app-release.aab" -ForegroundColor White
  Write-Host ""
}

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "📋 NEXT STEPS:" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""
Write-Host "1️⃣  Test web app:" -ForegroundColor Yellow
Write-Host "   $firebaseUrl" -ForegroundColor White
Write-Host ""
Write-Host "2️⃣  Upload Android to Play Console:" -ForegroundColor Yellow
Write-Host "   • Go to: play.google.com/console" -ForegroundColor White
Write-Host "   • Testing → Internal Testing → Create Release" -ForegroundColor White
Write-Host "   • Upload: build/app/outputs/bundle/release/app-release.aab" -ForegroundColor White
Write-Host ""
Write-Host "3️⃣  Send tester invitations:" -ForegroundColor Yellow
Write-Host "   See: TESTER_ONBOARDING_MATERIALS.md" -ForegroundColor White
Write-Host ""
Write-Host "4️⃣  Monitor dashboards:" -ForegroundColor Yellow
Write-Host "   • Firebase Console: console.firebase.google.com" -ForegroundColor White
Write-Host "   • Play Console: play.google.com/console" -ForegroundColor White
Write-Host ""
Write-Host "📚 Full guides available:" -ForegroundColor Cyan
Write-Host "   • LAUNCH_MASTER_INDEX.md — All documentation" -ForegroundColor White
Write-Host "   • DEPLOYMENT_EXECUTION_PLAN.md — Detailed walkthrough" -ForegroundColor White
Write-Host "   • VERIFICATION_CHECKLISTS.md — Testing checklists" -ForegroundColor White
Write-Host "   • POST_LAUNCH_MONITORING_GUIDE.md — Operations guide" -ForegroundColor White
Write-Host ""
Write-Host "🎉 You're live! Good luck, Larry! 🚀" -ForegroundColor Green
Write-Host ""
