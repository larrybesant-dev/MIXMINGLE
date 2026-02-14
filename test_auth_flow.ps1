# Test script: Monitor auth flow during room join on Flutter Web
# Captures:
# 1. Flutter Web frontend logs (debugPrint statements)
# 2. Cloud Functions backend logs (gcloud)
# 3. Network requests (Chrome DevTools via console)

Write-Host "=== AUTH FLOW TEST SETUP ===" -ForegroundColor Green
Write-Host ""
Write-Host "Step 1: Starting Flutter Web app (check Chrome browser)" -ForegroundColor Cyan
Write-Host "  - App will start on http://localhost:5000"
Write-Host "  - Open Chrome DevTools (F12) → Console"
Write-Host "  - Look for auth verification logs"
Write-Host ""
Write-Host "Step 2: User flow" -ForegroundColor Cyan
Write-Host "  - Sign in with Firebase Auth"
Write-Host "  - Navigate to a room"
Write-Host "  - Click 'Join Room'"
Write-Host ""
Write-Host "Step 3: Monitor these outputs" -ForegroundColor Cyan
Write-Host "  - This terminal will tail Flutter logs"
Write-Host "  - Another window will show Cloud Functions logs"
Write-Host "  - Chrome console will show network requests"
Write-Host ""
Write-Host "=== EXPECTED LOGS ===" -ForegroundColor Yellow
Write-Host ""
Write-Host "Frontend (Flutter):" -ForegroundColor Cyan
Write-Host "  ✓ Step 2: Joining room: [roomId]"
Write-Host "  ✓ Verifying authentication state..."
Write-Host "  ✓ Auth verified - User: user@email.com, UID: [uid]"
Write-Host "  ✓ Requesting Agora token..."
Write-Host "  ✓ FirebaseFunctions region: us-central1"
Write-Host "  ✓ Auth state: VERIFIED"
Write-Host "  ✓ Token response received"
Write-Host ""
Write-Host "Backend (Cloud Functions):" -ForegroundColor Cyan
Write-Host "  ✓ Callable request verification passed"
Write-Host "  ✓ Auth context - UID: [present], Token: PRESENT"
Write-Host "  ✓ Generated Agora token for user [uid] in room [roomId]"
Write-Host ""
Write-Host "=== STARTING TEST ===" -ForegroundColor Green
Write-Host ""

# Start Flutter Web
Write-Host "Starting Flutter Web..." -ForegroundColor Yellow
flutter run -d chrome --no-hot 2>&1 | Tee-Object -FilePath flutter_test.log &
$flutterPid = $?

# Give app time to start
Start-Sleep -Seconds 15

# In another terminal, start tailing Cloud Functions logs
Write-Host ""
Write-Host "In a NEW terminal, run:" -ForegroundColor Cyan
Write-Host "  gcloud functions logs read generateAgoraToken --region us-central1 --follow --limit 30"
Write-Host ""
Write-Host "=== CHROME CONSOLE COMMANDS ===" -ForegroundColor Yellow
Write-Host ""
Write-Host "To inspect network requests in Chrome DevTools, paste in console:" -ForegroundColor Cyan
Write-Host "  performance.getEntriesByName('generateAgoraToken', 'measure')"
Write-Host "  performance.getEntriesByType('resource').filter(e => e.name.includes('generateAgoraToken'))"
Write-Host ""
