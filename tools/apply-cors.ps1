# tools/apply-cors.ps1
# Applies Firebase Storage CORS policy so web uploads work.
# Run this ONCE after installing Google Cloud SDK.
#
# If Google Cloud SDK is not installed, this script will install it first.

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root

$bucket = "gs://mix-and-mingle-v2.firebasestorage.app"
$corsFile = "$root\cors.json"

Write-Host "`n🔒 Firebase Storage CORS Setup`n" -ForegroundColor Cyan

# Check if gsutil is available
$gsutil = Get-Command gsutil -ErrorAction SilentlyContinue
if (-not $gsutil) {
  Write-Host "gsutil not found. Installing Google Cloud SDK..." -ForegroundColor Yellow
  Write-Host "Downloading installer..." -ForegroundColor Gray

  $installer = "$env:TEMP\GoogleCloudSDKInstaller.exe"
  Invoke-WebRequest -Uri "https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe" -OutFile $installer
  Start-Process $installer -Wait

  # Reload PATH
  $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

  $gsutil = Get-Command gsutil -ErrorAction SilentlyContinue
  if (-not $gsutil) {
    Write-Host "`n❌ gsutil still not found after install." -ForegroundColor Red
    Write-Host "   Restart your terminal and run this script again." -ForegroundColor Yellow
    exit 1
  }
}

Write-Host "✅ gsutil found at: $($gsutil.Source)" -ForegroundColor Green

# Authenticate if needed
Write-Host "`nChecking authentication..." -ForegroundColor Gray
$authList = gsutil config -l 2>&1
if ($LASTEXITCODE -ne 0 -or $authList -match "No credenti") {
  Write-Host "Running gcloud auth login..." -ForegroundColor Yellow
  gcloud auth login
}

Write-Host "`nApplying CORS policy to $bucket ..." -ForegroundColor Cyan
gsutil cors set $corsFile $bucket
if ($LASTEXITCODE -eq 0) {
  Write-Host "✅ CORS policy applied successfully!" -ForegroundColor Green
  Write-Host "   Web photo uploads should now work." -ForegroundColor Gray
} else {
  Write-Host "❌ Failed to apply CORS policy." -ForegroundColor Red
  exit 1
}

# Verify
Write-Host "`nVerifying..." -ForegroundColor Gray
gsutil cors get $bucket
