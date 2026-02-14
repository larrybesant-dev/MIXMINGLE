#!/usr/bin/env pwsh
# Setup script for Agora configuration

Write-Host "🎥 Agora Configuration Setup" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

$APP_ID = "ec1b578586d24976a89d787d9ee4d5c7"
$APP_CERTIFICATE = "79a3e92a657042d08c3c26a26d1e70b6"

Write-Host "📋 Step 1: Agora Credentials" -ForegroundColor Yellow
Write-Host "App ID: $APP_ID" -ForegroundColor White
Write-Host "Certificate: $APP_CERTIFICATE" -ForegroundColor White
Write-Host ""

Write-Host ""
Write-Host "📦 Step 2: Installing Agora token builder for Firebase Functions..." -ForegroundColor Yellow

Push-Location functions
npm install agora-access-token
Pop-Location

Write-Host "✅ Dependencies installed" -ForegroundColor Green
Write-Host ""

Write-Host "🔥 Step 3: Configuring Firestore..." -ForegroundColor Yellow
Write-Host "Creating config/agora document..." -ForegroundColor White

# Create a temporary Firebase script to set the config
$firebaseScript = @"
const admin = require('firebase-admin');
const serviceAccount = require('./firebase-service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

db.collection('config').doc('agora').set({
  appId: '$APP_ID',
  appCertificate: '$APP_CERTIFICATE',
  updatedAt: admin.firestore.FieldValue.serverTimestamp()
})
.then(() => {
  console.log('✅ Agora configuration saved to Firestore');
  process.exit(0);
})
.catch((error) => {
  console.error('❌ Error:', error);
  process.exit(1);
});
"@

$firebaseScript | Out-File -FilePath "setup-agora-config.js" -Encoding UTF8

Write-Host "Running configuration script..." -ForegroundColor White
node setup-agora-config.js

Remove-Item "setup-agora-config.js"

Write-Host ""
Write-Host "✅ Agora Setup Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📝 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Deploy Firebase Functions: firebase deploy --only functions" -ForegroundColor White
Write-Host "2. Test the video calling feature in your app" -ForegroundColor White
Write-Host ""
Write-Host "🎉 Your app is now ready for video calling!" -ForegroundColor Green
