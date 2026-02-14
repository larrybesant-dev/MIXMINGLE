# Update Firestore config/agora with Agora credentials
# This script uses the Firestore REST API to update the Agora configuration

$projectId = "mix-and-mingle-v2"
$appId = "ec1b578586d24976a89d787d9ee4d5c7"
$appCertificate = "79a3e92a657042d08c3c26a26d1e70b6"

# Get Firebase token
Write-Host "🔑 Getting Firebase authentication token..." -ForegroundColor Yellow
$tokenResponse = firebase auth:export --account-file=/tmp/token.json 2>&1

# Try using default gcloud auth
Write-Host "📝 Using gcloud authentication..." -ForegroundColor Yellow
$accessToken = & gcloud auth application-default print-access-token 2>&1

if ($null -eq $accessToken -or $accessToken -match "ERROR") {
  Write-Host "⚠️  Could not get gcloud token, trying firebase CLI..." -ForegroundColor Yellow
  # Try to get token from firebase
  $output = firebase login:ci 2>&1
  Write-Host $output
}

# Firestore REST API endpoint
$firestoreUrl = "https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/config/agora"

# Prepare the document body
$documentBody = @{
  fields = @{
    appId          = @{
      stringValue = $appId
    }
    appCertificate = @{
      stringValue = $appCertificate
    }
    updatedAt      = @{
      timestampValue = (Get-Date -AsUTC -Format "yyyy-MM-ddTHH:mm:ss.fffZ")
    }
    updatedBy      = @{
      stringValue = "update_agora_config_script"
    }
  }
} | ConvertTo-Json -Depth 10

Write-Host "📝 Document body: $documentBody" -ForegroundColor Gray

Write-Host "🔧 Sending update to Firestore..." -ForegroundColor Yellow

# Send the update using REST API
try {
  $response = Invoke-WebRequest -Uri $firestoreUrl `
    -Method PATCH `
    -Headers @{
    "Authorization" = "Bearer $accessToken"
    "Content-Type"  = "application/json"
  } `
    -Body $documentBody `
    -ErrorAction Stop

  Write-Host "✅ Successfully updated Agora config in Firestore!" -ForegroundColor Green
  Write-Host "   📄 Document: config/agora" -ForegroundColor Green
  Write-Host "   🔑 AppId: $appId" -ForegroundColor Green
  Write-Host "   🔐 AppCertificate: $appCertificate" -ForegroundColor Green
  Write-Host "   ⏰ Updated: $(Get-Date)" -ForegroundColor Green
  Write-Host "`n✨ Config is ready. Your token generation should work now!`n" -ForegroundColor Green
}
catch {
  Write-Host "❌ Error updating Firestore: $_" -ForegroundColor Red
  Write-Host "`nTroubleshooting:" -ForegroundColor Yellow
  Write-Host "1. Ensure you are logged in: firebase login" -ForegroundColor Yellow
  Write-Host "2. Check your project is set: firebase use mix-and-mingle-v2" -ForegroundColor Yellow
  Write-Host "3. Make sure Firestore is enabled in your Firebase project" -ForegroundColor Yellow
  exit 1
}
