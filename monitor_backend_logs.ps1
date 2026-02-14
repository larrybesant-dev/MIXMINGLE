# Real-time backend log monitoring during test
# Run this in a separate terminal while testing on Flutter Web

Write-Host "=== CLOUD FUNCTIONS LOG MONITOR ===" -ForegroundColor Green
Write-Host ""
Write-Host "Monitoring generateAgoraToken logs in real-time..." -ForegroundColor Yellow
Write-Host "This will show:"
Write-Host "  - Auth context verification"
Write-Host "  - Request data validation"
Write-Host "  - Token generation success/failure"
Write-Host ""
Write-Host "Press Ctrl+C to stop monitoring"
Write-Host ""

# Start real-time log stream
gcloud functions logs read generateAgoraToken --region us-central1 --follow --limit 30 --format="table(time_utc.strftime('%H:%M:%S'), severity, log)"
