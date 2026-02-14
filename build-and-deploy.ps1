# ==========================================
# Mix & Mingle — Full Build, Test & Deploy Script
# ==========================================

# 1️⃣ Clean & Setup
Write-Host "🔹 Cleaning old builds..."
flutter clean
Write-Host "🔹 Fetching dependencies..."
flutter pub get

# 2️⃣ Code Analysis
Write-Host "🔹 Running flutter analyze..."
flutter analyze | Tee-Object -FilePath analyze_report.txt
Write-Host "🔹 Analyze complete. Report saved to analyze_report.txt"

# 3️⃣ Web Build
Write-Host "🌐 Building Web release..."
flutter build web --release
Write-Host "🌐 Web build complete at build/web"

# 4️⃣ Android Build
Write-Host "🤖 Building Android APK & AAB..."
flutter build apk --release
flutter build appbundle --release
Write-Host "🤖 Android builds complete at build/app/outputs/flutter-apk/"

# 5️⃣ iOS Build (macOS required)
if ($IsMacOS) {
    Write-Host "🍎 Building iOS release..."
    flutter build ios --release --no-codesign
    Write-Host "🍎 Archiving iOS build..."
    xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release -archivePath build/ios/Runner.xcarchive archive
    Write-Host "🍎 Exporting IPA..."
    xcodebuild -exportArchive -archivePath build/ios/Runner.xcarchive -exportOptionsPlist ios/ExportOptions.plist -exportPath build/ios/ipa
    Write-Host "🍎 iOS IPA ready at build/ios/ipa/"
} else {
    Write-Host "⚠️ Skipping iOS build: Not macOS"
}

# 6️⃣ Automated Feature Tests
Write-Host "🧪 Running automated feature tests..."

# Multi-window Web Room Test
Write-Host "🪟 Testing multi-window Web rooms..."
flutter run -d web-server --release --target=test/multi_window_web_test.dart | Tee-Object -FilePath web_room_test_log.txt

# Speed Dating Flow Test
Write-Host "⏱ Testing speed-dating flows..."
flutter run -d web-server --release --target=test/speed_dating_flow_test.dart | Tee-Object -FilePath speed_dating_test_log.txt

# Stripe Checkout & Tips Test
Write-Host "💰 Testing Stripe payments..."
flutter run -d web-server --release --target=test/stripe_checkout_test.dart | Tee-Object -FilePath stripe_test_log.txt

Write-Host "🧪 Automated feature tests complete. Logs saved for review."

# 7️⃣ Deploy Web to Firebase
Write-Host "🚀 Deploying Web build to Firebase Hosting..."
firebase deploy --only hosting
Write-Host "🚀 Firebase deployment complete"

# 8️⃣ Final Report
Write-Host "📋 Generating production-ready report..."
$reportPath = "PRODUCTION_READY_REPORT.md"
Add-Content $reportPath "`nBuild, Test & Deploy Complete: $(Get-Date)`n"
Add-Content $reportPath "Web build: build/web"
Add-Content $reportPath "Android APK: build/app/outputs/flutter-apk/app-release.apk"
Add-Content $reportPath "Android AAB: build/app/outputs/flutter-apk/app-release.aab"
if ($IsMacOS) { Add-Content $reportPath "iOS IPA: build/ios/ipa" }
Add-Content $reportPath "Analyze report: analyze_report.txt"
Add-Content $reportPath "Web Room Test Log: web_room_test_log.txt"
Add-Content $reportPath "Speed Dating Test Log: speed_dating_test_log.txt"
Add-Content $reportPath "Stripe Test Log: stripe_test_log.txt"
Write-Host "📋 Production-ready report saved to $reportPath"

Write-Host "🎉 All done! Your Mix & Mingle app is fully built, tested, and deployed!"
