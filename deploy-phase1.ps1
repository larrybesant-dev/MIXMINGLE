# ============================================
# MIX & MINGLE - PHASE 1 DEPLOYMENT SCRIPT
# ============================================
#
# Purpose: Deploy server-authoritative speed dating system
# Run this AFTER reviewing PHASE_1_SPEED_DATING_HARDENED.md
#
# IMPORTANT: This deploys to PRODUCTION Firebase
# Make sure you've tested locally first!
# ============================================

param(
    [switch]$DryRun,
    [switch]$FunctionsOnly,
    [switch]$RulesOnly
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 MIX & MINGLE - PHASE 1 DEPLOYMENT" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""

# Check if firebase CLI is available
Write-Host "🔍 Checking Firebase CLI..." -ForegroundColor Yellow
try {
    $firebaseVersion = firebase --version
    Write-Host "✅ Firebase CLI found: $firebaseVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Firebase CLI not found!" -ForegroundColor Red
    Write-Host "Install: npm install -g firebase-tools" -ForegroundColor Yellow
    exit 1
}

# Check current project
Write-Host ""
Write-Host "🔍 Checking Firebase project..." -ForegroundColor Yellow
$currentProject = firebase use
Write-Host "Current project: $currentProject" -ForegroundColor Cyan

Write-Host ""
Write-Host "⚠️  WARNING: This will deploy to PRODUCTION" -ForegroundColor Yellow
Write-Host ""
Write-Host "Components to deploy:" -ForegroundColor White
if (-not $RulesOnly) {
    Write-Host "  - Cloud Functions (speed dating server logic)" -ForegroundColor White
}
if (-not $FunctionsOnly) {
    Write-Host "  - Firestore Rules (security rules)" -ForegroundColor White
}
Write-Host ""

if ($DryRun) {
    Write-Host "🧪 DRY RUN MODE - No actual deployment" -ForegroundColor Magenta
    Write-Host ""
} else {
    $confirmation = Read-Host "Continue with deployment? (yes/no)"
    if ($confirmation -ne "yes") {
        Write-Host "❌ Deployment cancelled" -ForegroundColor Red
        exit 0
    }
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "STEP 1: Build Cloud Functions" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

if (-not $RulesOnly) {
    Push-Location functions

    try {
        Write-Host "📦 Installing dependencies..." -ForegroundColor Yellow
        if ($DryRun) {
            Write-Host "[DRY RUN] Would run: npm install" -ForegroundColor Magenta
        } else {
            npm install
            if ($LASTEXITCODE -ne 0) {
                throw "npm install failed"
            }
            Write-Host "✅ Dependencies installed" -ForegroundColor Green
        }

        Write-Host ""
        Write-Host "🔨 Building TypeScript..." -ForegroundColor Yellow
        if ($DryRun) {
            Write-Host "[DRY RUN] Would run: npm run build" -ForegroundColor Magenta
        } else {
            npm run build
            if ($LASTEXITCODE -ne 0) {
                throw "Build failed"
            }
            Write-Host "✅ Build successful" -ForegroundColor Green
        }
    }
    finally {
        Pop-Location
    }
} else {
    Write-Host "⏩ Skipping functions build (--RulesOnly)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "STEP 2: Deploy Cloud Functions" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

if (-not $RulesOnly) {
    Write-Host "🚀 Deploying speed dating functions..." -ForegroundColor Yellow
    Write-Host "   - onSpeedDatingSessionCreated" -ForegroundColor White
    Write-Host "   - submitSpeedDatingDecision" -ForegroundColor White
    Write-Host "   - leaveSpeedDatingSession" -ForegroundColor White
    Write-Host ""

    if ($DryRun) {
        Write-Host "[DRY RUN] Would run:" -ForegroundColor Magenta
        Write-Host "firebase deploy --only functions:onSpeedDatingSessionCreated,functions:submitSpeedDatingDecision,functions:leaveSpeedDatingSession" -ForegroundColor Gray
    } else {
        firebase deploy --only functions:onSpeedDatingSessionCreated,functions:submitSpeedDatingDecision,functions:leaveSpeedDatingSession

        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ Function deployment failed!" -ForegroundColor Red
            Write-Host "Check logs above for errors" -ForegroundColor Yellow
            exit 1
        }

        Write-Host "✅ Functions deployed successfully" -ForegroundColor Green
    }
} else {
    Write-Host "⏩ Skipping functions deployment (--RulesOnly)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "STEP 3: Deploy Firestore Security Rules" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

if (-not $FunctionsOnly) {
    Write-Host "🔒 Deploying Firestore rules..." -ForegroundColor Yellow
    Write-Host "   - speed_dating_queue rules" -ForegroundColor White
    Write-Host "   - speed_dating_sessions rules (locked decisions)" -ForegroundColor White
    Write-Host "   - speed_dating_results rules (server-only)" -ForegroundColor White
    Write-Host ""

    if ($DryRun) {
        Write-Host "[DRY RUN] Would run:" -ForegroundColor Magenta
        Write-Host "firebase deploy --only firestore:rules" -ForegroundColor Gray
    } else {
        firebase deploy --only firestore:rules

        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ Rules deployment failed!" -ForegroundColor Red
            Write-Host "Check firestore.rules for syntax errors" -ForegroundColor Yellow
            exit 1
        }

        Write-Host "✅ Rules deployed successfully" -ForegroundColor Green
    }
} else {
    Write-Host "⏩ Skipping rules deployment (--FunctionsOnly)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

if ($DryRun) {
    Write-Host "🧪 DRY RUN completed - no actual changes made" -ForegroundColor Magenta
    Write-Host "Run without -DryRun to deploy for real" -ForegroundColor Yellow
} else {
    Write-Host "✅ Phase 1 backend is now live!" -ForegroundColor Green
    Write-Host ""
    Write-Host "NEXT STEPS:" -ForegroundColor Yellow
    Write-Host "1. Deploy Flutter web app:" -ForegroundColor White
    Write-Host "   flutter build web --release" -ForegroundColor Gray
    Write-Host "   firebase deploy --only hosting" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Run abuse tests (see PHASE_1_SPEED_DATING_HARDENED.md)" -ForegroundColor White
    Write-Host "   - Test 1: Session expiry at 5 minutes" -ForegroundColor Gray
    Write-Host "   - Test 2: Late decision rejection" -ForegroundColor Gray
    Write-Host "   - Test 3: Firestore rule enforcement" -ForegroundColor Gray
    Write-Host "   - Test 4: Cross-user decision prevention" -ForegroundColor Gray
    Write-Host "   - Test 5: Duplicate decision prevention" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. Monitor Cloud Function logs:" -ForegroundColor White
    Write-Host "   firebase functions:log --only submitSpeedDatingDecision" -ForegroundColor Gray
    Write-Host ""
    Write-Host "🚨 DO NOT SKIP ABUSE TESTS!" -ForegroundColor Red
    Write-Host "   Speed dating is your highest legal risk feature" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
