# ==============================
# MIX & MINGLE – FUNCTIONS ONLY DEPLOY
# ==============================
# Use this to deploy only Firebase Functions after hosting is live

Write-Host "🚀 Starting Mix & Mingle Functions-Only Deployment" -ForegroundColor Cyan

# 1️⃣ Install function dependencies
Write-Host "📦 Installing function dependencies..." -ForegroundColor Yellow
Push-Location functions
npm install
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to install dependencies." -ForegroundColor Red
    Pop-Location
    Read-Host "Press Enter to exit"
    exit 1
}
Pop-Location

# 2️⃣ Set environment variables (if not already set)
Write-Host "🔧 Checking environment variables..." -ForegroundColor Yellow

$envFile = "functions\.env"
if (Test-Path $envFile) {
    Write-Host "✅ Found .env file in functions directory" -ForegroundColor Green

    # Read Agora credentials from .env
    $envContent = Get-Content $envFile
    $agoraAppId = ($envContent | Select-String "AGORA_APP_ID=(.+)").Matches.Groups[1].Value
    $agoraCert = ($envContent | Select-String "AGORA_APP_CERTIFICATE=(.+)").Matches.Groups[1].Value

    if ($agoraAppId -and $agoraCert) {
        Write-Host "📝 Setting Firebase environment config..." -ForegroundColor Yellow
        firebase functions:config:set agora.appid="$agoraAppId" agora.cert="$agoraCert"
        if ($LASTEXITCODE -ne 0) {
            Write-Host "⚠️  Failed to set config, but continuing..." -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "⚠️  No .env file found. Functions will use Firebase environment config." -ForegroundColor Yellow
}

# 3️⃣ Deploy Functions
Write-Host "☁️ Deploying Functions to Mix & Mingle v2..." -ForegroundColor Yellow
firebase deploy --only functions --project mix-and-mingle-v2
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Functions deployment failed." -ForegroundColor Red
    Write-Host ""
    Write-Host "💡 Troubleshooting tips:" -ForegroundColor Yellow
    Write-Host "1. Run: firebase emulators:start --only functions" -ForegroundColor Cyan
    Write-Host "   This will show you local errors" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Check functions logs:" -ForegroundColor Cyan
    Write-Host "   firebase functions:log --project mix-and-mingle-v2" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. Verify environment variables:" -ForegroundColor Cyan
    Write-Host "   firebase functions:config:get --project mix-and-mingle-v2" -ForegroundColor Gray
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "✅ Functions deployed successfully!" -ForegroundColor Green

Write-Host ""
Write-Host "🎉 Functions deployment complete!" -ForegroundColor Cyan
Write-Host ""
Write-Host "Test your Agora token function:" -ForegroundColor Yellow
Write-Host "firebase functions:log --project mix-and-mingle-v2" -ForegroundColor Cyan
Write-Host ""
Read-Host "Press Enter to exit"
