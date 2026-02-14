# Comprehensive pre-test verification script
# Ensures all three auth layers are properly configured

Write-Host "=== PRE-TEST VERIFICATION ===" -ForegroundColor Green
Write-Host ""

# 1. Check web/index.html has Functions SDK
Write-Host "Layer 1: Web Platform - Firebase Functions JS SDK" -ForegroundColor Cyan
$webFile = Get-Content web/index.html -Raw
if ($webFile -match "firebase-functions\.js") {
  Write-Host "  ✅ firebase-functions.js import found" -ForegroundColor Green
}
else {
  Write-Host "  ❌ firebase-functions.js import MISSING" -ForegroundColor Red
}

if ($webFile -match "getFunctions.*app.*us-central1") {
  Write-Host "  ✅ getFunctions() initialized with region us-central1" -ForegroundColor Green
}
else {
  Write-Host "  ❌ getFunctions() not properly initialized" -ForegroundColor Red
}

if ($webFile -match "window\.firebase.*functions") {
  Write-Host "  ✅ Functions exposed to global scope" -ForegroundColor Green
}
else {
  Write-Host "  ❌ Functions not exposed globally" -ForegroundColor Red
}

Write-Host ""

# 2. Check frontend auth verification
Write-Host "Layer 2: Frontend - Auth State Verification" -ForegroundColor Cyan
$dartFile = Get-Content lib/services/agora_video_service.dart -Raw
if ($dartFile -match "authStateChanges.*\.first.*timeout") {
  Write-Host "  ✅ authStateChanges().first with timeout found" -ForegroundColor Green
}
else {
  Write-Host "  ❌ Auth state timeout verification MISSING" -ForegroundColor Red
}

if ($dartFile -match "Auth verified.*User:.*UID:") {
  Write-Host "  ✅ Auth verification logging found" -ForegroundColor Green
}
else {
  Write-Host "  ❌ Auth logging MISSING" -ForegroundColor Red
}

if ($dartFile -match "FirebaseAuth\.instance") {
  Write-Host "  ✅ FirebaseAuth.instance used (default app)" -ForegroundColor Green
}
else {
  Write-Host "  ❌ FirebaseAuth not using default app" -ForegroundColor Red
}

if ($dartFile -match "FirebaseFunctions\.instanceFor.*region.*us-central1") {
  Write-Host "  ✅ FirebaseFunctions.instanceFor(region: 'us-central1') found" -ForegroundColor Green
}
else {
  Write-Host "  ❌ FirebaseFunctions region specification MISSING" -ForegroundColor Red
}

Write-Host ""

# 3. Check backend auth validation
Write-Host "Layer 3: Backend - Auth Context Validation" -ForegroundColor Cyan
$tsFile = Get-Content functions/src/index.ts -Raw
if ($tsFile -match "request\.auth\?\.uid.*NONE") {
  Write-Host "  ✅ request.auth.uid logging found" -ForegroundColor Green
}
else {
  Write-Host "  ⚠️  request.auth logging not as detailed" -ForegroundColor Yellow
}

if ($tsFile -match "request\.auth\?\.uid.*throwing.*Authentication required") {
  Write-Host "  ✅ Auth validation error handling found" -ForegroundColor Green
}
else {
  Write-Host "  ⚠️  Auth error handling may be minimal" -ForegroundColor Yellow
}

Write-Host ""

# 4. Check Firebase configuration consistency
Write-Host "Layer 4: Configuration Consistency" -ForegroundColor Cyan
$projectId = "mix-and-mingle-v2"
if ($webFile -match "projectId.*mix-and-mingle-v2") {
  Write-Host "  ✅ Web config: projectId = $projectId" -ForegroundColor Green
}
else {
  Write-Host "  ❌ Web projectId mismatch" -ForegroundColor Red
}

if ($tsFile -match "mix-and-mingle-v2|process\.env\.GCLOUD_PROJECT") {
  Write-Host "  ✅ Backend using correct project" -ForegroundColor Green
}
else {
  Write-Host "  ⚠️  Backend project not explicitly verified" -ForegroundColor Yellow
}

Write-Host ""

# 5. Check for any direct HTTP calls that might bypass callable
Write-Host "Layer 5: No HTTP Bypass Calls" -ForegroundColor Cyan
$httpCalls = @()
Get-ChildItem lib -Filter "*.dart" -Recurse | ForEach-Object {
  if ((Get-Content $_ -Raw) -match 'http\.(get|post).*cloudfunctions') {
    $httpCalls += $_.FullName
  }
}

if ($httpCalls.Count -eq 0) {
  Write-Host "  ✅ No direct HTTP calls to Cloud Functions found" -ForegroundColor Green
}
else {
  Write-Host "  ❌ Found $($httpCalls.Count) direct HTTP calls to Cloud Functions:" -ForegroundColor Red
  $httpCalls | ForEach-Object {
    Write-Host "     - $_" -ForegroundColor Red
  }
}

Write-Host ""
Write-Host "=== VERIFICATION COMPLETE ===" -ForegroundColor Green
Write-Host ""
Write-Host "If all checks are green, you're ready to test!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Run: flutter clean"
Write-Host "  2. Run: flutter run -d chrome --no-hot"
Write-Host "  3. Open Chrome DevTools (F12) → Console"
Write-Host "  4. In another terminal: .\monitor_backend_logs.ps1"
Write-Host "  5. Sign in and join a room"
Write-Host ""
