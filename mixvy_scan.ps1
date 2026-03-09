Write-Host "=== MIXVY FULL SYSTEM SCAN START ==="

Write-Host "`n[1] Checking Flutter SDK..."
flutter --version

Write-Host "`n[2] Checking Dart SDK..."
dart --version

Write-Host "`n[3] Checking Flutter doctor..."
flutter doctor -v

Write-Host "`n[4] Checking pubspec dependencies..."
flutter pub outdated

Write-Host "`n[5] Running flutter pub get..."
flutter pub get

Write-Host "`n[6] Running analyzer..."
flutter analyze

Write-Host "`n[7] Checking Firebase CLI..."
firebase --version

Write-Host "`n[8] Checking Firebase project config..."
firebase projects:list
firebase apps:list

Write-Host "`n[9] Validating firebase.json..."
Get-Content .\firebase.json

Write-Host "`n[10] Checking Firestore rules..."
firebase firestore:rules:test

Write-Host "`n[11] Checking Firestore indexes..."
firebase firestore:indexes

Write-Host "`n[12] Checking for missing assets..."
Get-ChildItem -Recurse .\assets | Select-Object FullName

Write-Host "`n[13] Checking for invalid imports..."
Get-ChildItem -Recurse .\lib -Filter *.dart | ForEach-Object {
    if (Select-String -Path $_.FullName -Pattern "package:state_notifier" -Quiet) {
        Write-Host "Invalid import found in $($_.FullName)"
    }
}

Write-Host "`n[14] Building web..."
flutter build web --release --no-wasm-dry-run

Write-Host "`n[15] Checking web build output..."
Get-ChildItem -Recurse .\build\web

Write-Host "`n[16] Checking for Stripe errors..."
Select-String -Path .\build\web\main.dart.js -Pattern "stripe"

Write-Host "`n[17] Checking for Agora errors..."
Select-String -Path .\build\web\main.dart.js -Pattern "agora"

Write-Host "`n[18] Checking for runtime errors..."
Select-String -Path .\build\web\main.dart.js -Pattern "Error"

Write-Host "`n=== MIXVY FULL SYSTEM SCAN COMPLETE ==="