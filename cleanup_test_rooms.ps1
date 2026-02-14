# Delete all test rooms from Firestore
# Run: pwsh .\cleanup_test_rooms.ps1

Write-Host "🗑️  Clearing test rooms from Firestore..." -ForegroundColor Yellow

firebase firestore:delete rooms --recursive --yes

Write-Host "✅ Test rooms cleared!" -ForegroundColor Green
Write-Host "📌 Ready to create new live rooms" -ForegroundColor Cyan
