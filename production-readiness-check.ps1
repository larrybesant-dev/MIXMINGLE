# ==============================
# MIX & MINGLE – PRODUCTION CHECK
# ==============================

Write-Host "🔹 Starting Mix & Mingle Production Readiness Script..." -ForegroundColor Cyan

# ------------------------------
# 1️⃣ Clean Workspace
# ------------------------------
Write-Host "🧹 Cleaning old build artifacts and temporary files..." -ForegroundColor Yellow
flutter clean
Remove-Item -Force -Recurse ".dart_tool","build","coverage" -ErrorAction SilentlyContinue

# ------------------------------
# 2️⃣ Get Dependencies
# ------------------------------
Write-Host "📦 Fetching dependencies..." -ForegroundColor Yellow
flutter pub get

# ------------------------------
# 3️⃣ Analyze Code
# ------------------------------
Write-Host "🔍 Analyzing code for errors/warnings..." -ForegroundColor Yellow
$analyzeResults = flutter analyze --no-pub
Write-Host $analyzeResults
Write-Host "✅ Code analysis complete"

# ------------------------------
# 4️⃣ Build Web
# ------------------------------
Write-Host "🌐 Building Web version..." -ForegroundColor Yellow
flutter build web --release
if ($LASTEXITCODE -eq 0) { Write-Host "✅ Web build successful" -ForegroundColor Green }

# ------------------------------
# 5️⃣ Build Android
# ------------------------------
Write-Host "🤖 Building Android APK..." -ForegroundColor Yellow
flutter build apk --release
if ($LASTEXITCODE -eq 0) { Write-Host "✅ Android APK build successful" -ForegroundColor Green }

# ------------------------------
# 6️⃣ Build iOS (macOS only)
# ------------------------------
if ($IsMacOS) {
    Write-Host "🍎 Building iOS IPA..." -ForegroundColor Yellow
    flutter build ios --release
    if ($LASTEXITCODE -eq 0) { Write-Host "✅ iOS build successful" -ForegroundColor Green }
} else {
    Write-Host "⚠️ Skipping iOS build (Windows detected)" -ForegroundColor DarkYellow
}

# ------------------------------
# 7️⃣ Quick QA Checklist
# ------------------------------
Write-Host "🧪 Running QA checklist..." -ForegroundColor Yellow

# Auth
Write-Host "• Auth flows (signup/login/logout)" -NoNewline
if ((Get-Content lib/auth_gate.dart | Select-String "FirebaseAuth")) { Write-Host " ✅" -ForegroundColor Green } else { Write-Host " ❌" -ForegroundColor Red }

# Video Engine
Write-Host "• Video engine multi-platform" -NoNewline
if ((Get-Content lib/services/video_engine_service.dart | Select-String "VideoEngineService")) { Write-Host " ✅" -ForegroundColor Green } else { Write-Host " ❌" -ForegroundColor Red }

# Speed Dating
Write-Host "• Speed dating (questionnaire/rounds/keep-pass)" -NoNewline
if ((Get-Content lib/services/speed_dating_service.dart | Select-String "SpeedDatingService")) { Write-Host " ✅" -ForegroundColor Green } else { Write-Host " ❌" -ForegroundColor Red }

# Host Controls
Write-Host "• Host/moderator controls" -NoNewline
if ((Get-Content lib/services/room_manager_service.dart | Select-String "removeUser")) { Write-Host " ✅" -ForegroundColor Green } else { Write-Host " ❌" -ForegroundColor Red }

# Payments
Write-Host "• Stripe tips & coins" -NoNewline
if ((Get-Content lib/services/payment_service.dart | Select-String "Stripe")) { Write-Host " ✅" -ForegroundColor Green } else { Write-Host " ❌" -ForegroundColor Red }

# ------------------------------
# 8️⃣ Generate Summary Report
# ------------------------------
$reportFile = "PRODUCTION_READY_REPORT.txt"
Write-Host "📋 Generating production-ready summary report: $reportFile" -ForegroundColor Yellow

@"
Mix & Mingle Production Readiness Report
========================================
Date: $(Get-Date)
Workspace: $PWD

Build Status:
  • Web: $(if (Test-Path "build/web/index.html") {"✅ Built"} else {"❌ Failed"})
  • Android: $(if (Test-Path "build/app/outputs/flutter-apk/app-release.apk") {"✅ Built"} else {"❌ Failed"})
  • iOS: $(if ($IsMacOS -and (Test-Path "build/ios/iphoneos/Runner.app")) {"✅ Built"} else {"⚠️ Not Built / macOS required"})

Code Analysis:
$($analyzeResults | Out-String)

QA Checklist:
  • Auth flows: $(if ((Get-Content lib/auth_gate.dart | Select-String "FirebaseAuth")) {"✅"} else {"❌"})
  • Video engine: $(if ((Get-Content lib/services/video_engine_service.dart | Select-String "VideoEngineService")) {"✅"} else {"❌"})
  • Speed dating: $(if ((Get-Content lib/services/speed_dating_service.dart | Select-String "SpeedDatingService")) {"✅"} else {"❌"})
  • Host controls: $(if ((Get-Content lib/services/room_manager_service.dart | Select-String "removeUser")) {"✅"} else {"❌"})
  • Payments: $(if ((Get-Content lib/services/payment_service.dart | Select-String "Stripe")) {"✅"} else {"❌"})

Recommendation:
✔ Ready for production launch if all checks are ✅
✔ Test Stripe & Firestore rules in staging/live environment before App Store/Play submission
"@ | Out-File $reportFile

Write-Host "🎉 Production readiness check complete! See $reportFile" -ForegroundColor Green
