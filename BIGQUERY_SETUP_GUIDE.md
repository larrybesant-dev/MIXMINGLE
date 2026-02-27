# BigQuery Export Setup Guide for Mix & Mingle

## Prerequisites

- Firebase project: `mixmingle-prod`
- Billing enabled on Google Cloud (required for BigQuery)
- Owner or Editor permissions

---

## Option 1: Firebase Console Setup (Recommended)

### Step 1: Enable BigQuery

1. Open Firebase Console: https://console.firebase.google.com
2. Select project: **mixmingle-prod**
3. Click **⚙️ Project Settings** (top left)
4. Go to **Integrations** tab
5. Find **BigQuery** card
6. Click **Link**

### Step 2: Configure Export Settings

Select the following options:

- ✅ **Export Analytics data**
- ✅ **Include advertising identifier**
- ✅ **Stream data in real-time** (if available on your plan)
- ✅ **Export user data** (optional, for user properties)

Choose dataset location:

- **US** (recommended for lowest latency with Firebase)
- Or select region closest to your primary users

### Step 3: Confirm and Link

1. Review settings
2. Click **Link to BigQuery**
3. Wait 5-10 minutes for initial setup
4. Data will start flowing within 24 hours

---

## Option 2: Command Line Setup

### Step 1: Install Google Cloud SDK

```powershell
# Download from: https://cloud.google.com/sdk/docs/install
# Or use PowerShell:
(New-Object Net.WebClient).DownloadFile("https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe", "$env:Temp\GoogleCloudSDKInstaller.exe")
& $env:Temp\GoogleCloudSDKInstaller.exe
```

### Step 2: Authenticate

```powershell
gcloud auth login
gcloud config set project mixmingle-prod
```

### Step 3: Enable BigQuery API

```powershell
gcloud services enable bigquery.googleapis.com
gcloud services enable bigquerydatatransfer.googleapis.com
```

### Step 4: Verify Setup

```powershell
# List BigQuery datasets (should see analytics_* after 24 hours)
bq ls --project_id=mixmingle-prod

# Show dataset details
bq show --project_id=mixmingle-prod analytics_123456789
```

---

## Option 3: Automated Script (Fastest)

Save this script as `setup_bigquery.ps1`:

```powershell
# Mix & Mingle BigQuery Setup Script
# Run from: C:\Users\LARRY\MIXMINGLE

$PROJECT_ID = "mixmingle-prod"
$DATASET_LOCATION = "US"

Write-Host "🚀 Setting up BigQuery for Mix & Mingle..." -ForegroundColor Cyan

# Check if gcloud is installed
if (-not (Get-Command gcloud -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Google Cloud SDK not found. Please install from:" -ForegroundColor Red
    Write-Host "   https://cloud.google.com/sdk/docs/install" -ForegroundColor Yellow
    exit 1
}

# Set project
Write-Host "📋 Setting project: $PROJECT_ID" -ForegroundColor Green
gcloud config set project $PROJECT_ID

# Enable APIs
Write-Host "⚙️  Enabling BigQuery APIs..." -ForegroundColor Green
gcloud services enable bigquery.googleapis.com
gcloud services enable bigquerydatatransfer.googleapis.com
gcloud services enable firebase.googleapis.com

# Check if BigQuery export is already enabled
Write-Host "🔍 Checking for existing BigQuery datasets..." -ForegroundColor Green
$datasets = bq ls --project_id=$PROJECT_ID 2>&1

if ($datasets -match "analytics_") {
    Write-Host "✅ BigQuery export already configured!" -ForegroundColor Green
    Write-Host "   Dataset found: $(($datasets -match 'analytics_')[0])" -ForegroundColor Cyan
} else {
    Write-Host "⚠️  No BigQuery export detected." -ForegroundColor Yellow
    Write-Host "   Please enable manually in Firebase Console:" -ForegroundColor Yellow
    Write-Host "   https://console.firebase.google.com/project/$PROJECT_ID/settings/integrations" -ForegroundColor Cyan
}

Write-Host "`n📊 Next Steps:" -ForegroundColor Cyan
Write-Host "   1. Wait 24 hours for data to populate" -ForegroundColor White
Write-Host "   2. Run test query: bq query --project_id=$PROJECT_ID 'SELECT COUNT(*) FROM \`analytics_*.events_*\`'" -ForegroundColor White
Write-Host "   3. Set up Data Studio dashboard" -ForegroundColor White

Write-Host "`n✨ Setup complete!" -ForegroundColor Green
```

Run the script:

```powershell
cd C:\Users\LARRY\MIXMINGLE
powershell -ExecutionPolicy Bypass -File .\setup_bigquery.ps1
```

---

## Verification Checklist

After 24-48 hours, verify the export is working:

### Check 1: Dataset Exists

```powershell
bq ls --project_id=mixmingle-prod
```

Expected output:

```
DATASET ID              LOCATION
analytics_123456789     US
```

### Check 2: Tables Populated

```powershell
bq ls --project_id=mixmingle-prod analytics_123456789
```

Expected output:

```
TABLE ID           TYPE
events_20260127    TABLE
events_20260128    TABLE
```

### Check 3: Run Test Query

```powershell
bq query --project_id=mixmingle-prod --use_legacy_sql=false "
SELECT
  event_name,
  COUNT(*) as count
FROM \`analytics_*.events_*\`
WHERE _TABLE_SUFFIX = FORMAT_DATE('%Y%m%d', CURRENT_DATE())
GROUP BY event_name
ORDER BY count DESC
LIMIT 10
"
```

Expected output:

```
event_name          count
user_engagement     1247
screen_view         892
sign_up             234
room_joined         156
```

---

## Troubleshooting

### Issue: "Permission denied"

**Solution**: Ensure you have Owner or Editor role:

```powershell
gcloud projects get-iam-policy mixmingle-prod --flatten="bindings[].members" --filter="bindings.members:user:your-email@gmail.com"
```

### Issue: "Billing not enabled"

**Solution**: Enable billing in Google Cloud Console:

1. Go to https://console.cloud.google.com/billing
2. Link a billing account to mixmingle-prod
3. BigQuery free tier: 1 TB queries/month, 10 GB storage

### Issue: "No data after 24 hours"

**Solution**:

1. Check Firebase Analytics is collecting data:
   - Firebase Console → Analytics → Events
2. Verify BigQuery link status:
   - Firebase Console → Project Settings → Integrations → BigQuery
3. Manually trigger export (if available in your plan)

---

## Cost Estimate

**BigQuery Pricing** (as of Jan 2026):

- **Storage**: $0.02/GB/month (first 10 GB free)
- **Queries**: $5/TB (first 1 TB/month free)

**Mix & Mingle Projected Costs**:

- **Month 1**: $0 (within free tier)
- **Month 3**: ~$5/month (500 MB data, 100 GB queries)
- **Month 12**: ~$50/month (5 GB data, 1.5 TB queries)

**Free tier covers**:

- 10 GB storage (≈ 3-6 months of analytics data)
- 1 TB queries/month (≈ 500 dashboard refreshes)

---

## Next Steps

Once BigQuery is set up:

1. ✅ Run the 7 custom queries from `analytics/bigquery_queries.sql`
2. ✅ Set up Data Studio dashboard (see Deliverable 2, Part B)
3. ✅ Configure real-time alerts (see `functions/src/analyticsAlerts.ts`)
4. ✅ Schedule weekly cohort analysis reports

---

## Support

If you encounter issues:

- Firebase Support: https://firebase.google.com/support
- BigQuery Docs: https://cloud.google.com/bigquery/docs
- Community: StackOverflow tag `google-bigquery` + `firebase`
