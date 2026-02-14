# Mix & Mingle BigQuery Setup Script
# Run from: C:\Users\LARRY\MIXMINGLE

$PROJECT_ID = "mixmingle-prod"
$DATASET_LOCATION = "US"

Write-Host "[*] Setting up BigQuery for Mix & Mingle..." -ForegroundColor Cyan

# Check if gcloud is installed
if (-not (Get-Command gcloud -ErrorAction SilentlyContinue)) {
  Write-Host "[!] Google Cloud SDK not found. Installing..." -ForegroundColor Red
  Write-Host "    Downloading Google Cloud SDK installer..." -ForegroundColor Yellow

  $installerPath = "$env:Temp\GoogleCloudSDKInstaller.exe"
  try {
    (New-Object Net.WebClient).DownloadFile("https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe", $installerPath)
    Write-Host "    Running installer..." -ForegroundColor Yellow
    Start-Process -FilePath $installerPath -Wait
    Write-Host "    [OK] Google Cloud SDK installed. Please restart PowerShell and run this script again." -ForegroundColor Green
    exit 0
  }
  catch {
    Write-Host "    [ERROR] Failed to download installer. Please install manually from:" -ForegroundColor Red
    Write-Host "    https://cloud.google.com/sdk/docs/install" -ForegroundColor Cyan
    exit 1
  }
}

Write-Host "[OK] Google Cloud SDK found" -ForegroundColor Green

# Check authentication
Write-Host "`n[*] Checking authentication..." -ForegroundColor Cyan
$authList = gcloud auth list --format="value(account)" 2>&1
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrEmpty($authList)) {
  Write-Host "[!] Not authenticated. Launching browser for login..." -ForegroundColor Yellow
  gcloud auth login
  if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Authentication failed" -ForegroundColor Red
    exit 1
  }
}
Write-Host "[OK] Authenticated as: $authList" -ForegroundColor Green

# Set project
Write-Host "`n[*] Setting project: $PROJECT_ID" -ForegroundColor Cyan
gcloud config set project $PROJECT_ID 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
  Write-Host "[ERROR] Failed to set project. Please check project ID." -ForegroundColor Red
  exit 1
}
Write-Host "[OK] Project set" -ForegroundColor Green

# Enable APIs
Write-Host "`n[*] Enabling required APIs..." -ForegroundColor Cyan
$apis = @(
  "bigquery.googleapis.com",
  "bigquerydatatransfer.googleapis.com",
  "firebase.googleapis.com",
  "firebaseanalytics.googleapis.com"
)

foreach ($api in $apis) {
  Write-Host "    Enabling $api..." -ForegroundColor White
  gcloud services enable $api 2>&1 | Out-Null
  if ($LASTEXITCODE -eq 0) {
    Write-Host "    [OK] $api enabled" -ForegroundColor Green
  }
  else {
    Write-Host "    [WARN] $api may already be enabled" -ForegroundColor Yellow
  }
}

# Check for existing BigQuery datasets
Write-Host "`n[*] Checking for existing BigQuery datasets..." -ForegroundColor Cyan
$datasets = bq ls --project_id=$PROJECT_ID 2>&1
if ($datasets -match "analytics_") {
  $datasetMatch = $datasets | Select-String -Pattern "analytics_\d+" -AllMatches
  $datasetId = $datasetMatch.Matches[0].Value
  Write-Host "[OK] BigQuery export already configured!" -ForegroundColor Green
  Write-Host "     Dataset: $datasetId" -ForegroundColor Cyan

  # Check for recent data
  Write-Host "`n[*] Checking for recent data..." -ForegroundColor Cyan
  $today = Get-Date -Format "yyyyMMdd"
  $yesterday = (Get-Date).AddDays(-1).ToString("yyyyMMdd")

  $tables = bq ls --project_id=$PROJECT_ID $datasetId 2>&1
  if ($tables -match "events_$today" -or $tables -match "events_$yesterday") {
    Write-Host "[OK] Recent data found! Export is working." -ForegroundColor Green
  }
  else {
    Write-Host "[WARN] No recent data. Export may still be initializing (wait 24 hours)." -ForegroundColor Yellow
  }
}
else {
  Write-Host "[WARN] No BigQuery export detected." -ForegroundColor Yellow
  Write-Host "`nTo enable BigQuery export:" -ForegroundColor Cyan
  Write-Host "  1. Open Firebase Console:" -ForegroundColor White
  Write-Host "     https://console.firebase.google.com/project/$PROJECT_ID/settings/integrations" -ForegroundColor Cyan
  Write-Host "  2. Find 'BigQuery' card and click 'Link'" -ForegroundColor White
  Write-Host "  3. Select options:" -ForegroundColor White
  Write-Host "     [x] Export Analytics data" -ForegroundColor White
  Write-Host "     [x] Include advertising identifier" -ForegroundColor White
  Write-Host "     [x] Stream data in real-time" -ForegroundColor White
  Write-Host "  4. Choose location: $DATASET_LOCATION" -ForegroundColor White
  Write-Host "  5. Click 'Link to BigQuery'" -ForegroundColor White
  Write-Host "`nNote: Data will start flowing within 24 hours" -ForegroundColor Yellow
}

# Summary
Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host "BIGQUERY SETUP SUMMARY" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan

if ($datasets -match "analytics_") {
  Write-Host "Status: ACTIVE" -ForegroundColor Green
  Write-Host "Dataset: $datasetId" -ForegroundColor Green
  Write-Host "Location: $DATASET_LOCATION" -ForegroundColor Green
}
else {
  Write-Host "Status: NOT CONFIGURED" -ForegroundColor Yellow
  Write-Host "Action Required: Enable in Firebase Console" -ForegroundColor Yellow
}

Write-Host "`nNEXT STEPS:" -ForegroundColor Cyan
Write-Host "  1. Wait 24-48 hours for initial data population" -ForegroundColor White
Write-Host "  2. Run custom analytics queries from:" -ForegroundColor White
Write-Host "     C:\Users\LARRY\MIXMINGLE\analytics\bigquery_queries.sql" -ForegroundColor Cyan
Write-Host "  3. Set up Data Studio dashboard" -ForegroundColor White
Write-Host "  4. Configure real-time alerts (see analyticsAlerts.ts)" -ForegroundColor White

Write-Host "`nCOST ESTIMATE:" -ForegroundColor Cyan
Write-Host "  First 10 GB storage: FREE" -ForegroundColor Green
Write-Host "  First 1 TB queries/month: FREE" -ForegroundColor Green
Write-Host "  Expected Month 1-3 cost: `$0" -ForegroundColor Green

Write-Host "`nDOCUMENTATION:" -ForegroundColor Cyan
Write-Host "  Setup Guide: C:\Users\LARRY\MIXMINGLE\BIGQUERY_SETUP_GUIDE.md" -ForegroundColor White
Write-Host "  Firebase Console: https://console.firebase.google.com/project/$PROJECT_ID" -ForegroundColor Cyan
Write-Host "  BigQuery Console: https://console.cloud.google.com/bigquery?project=$PROJECT_ID" -ForegroundColor Cyan

Write-Host "`n[OK] Setup complete!" -ForegroundColor Green
Write-Host "======================================================================" -ForegroundColor Cyan
