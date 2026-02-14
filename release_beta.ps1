# =============================
# MIXMINGLE Beta Release Script
# =============================
# Automates beta/staging release workflow:
# - Creates develop branch on GitHub if it doesn't exist
# - Ensures develop branch is up to date
# - Tags release version
# - Triggers APK/AAB builds via GitHub Actions
# - Deploys web version to GitHub Pages

Write-Host "`n🚀 MIXMINGLE Beta Release Workflow`n" -ForegroundColor Cyan

# 1️⃣ Ensure we are on develop branch
Write-Host "1️⃣ Checking out develop branch..." -ForegroundColor Yellow
git checkout develop 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "   Creating develop branch from current HEAD..." -ForegroundColor Gray
    git checkout -b develop
}

# 2️⃣ Create develop on GitHub if it doesn't exist
Write-Host "`n2️⃣ Verifying remote develop branch..." -ForegroundColor Yellow
$remoteBranches = git branch -r 2>$null
If (-not ($remoteBranches -match "origin/develop")) {
    Write-Host "   Remote develop branch not found - creating it now..." -ForegroundColor Yellow
    Write-Host "   This may take a few minutes for initial push (uploading ~100MB)...`n" -ForegroundColor Gray

    git push -u origin develop 2>&1 | ForEach-Object {
        if ($_ -match "Writing objects:.+?(\d+)%") {
            $percent = $matches[1]
            Write-Progress -Activity "Pushing to GitHub" -Status "Uploading objects: $percent%" -PercentComplete $percent
        }
    }
    Write-Progress -Activity "Pushing to GitHub" -Completed

    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n   ✅ Remote develop branch created successfully" -ForegroundColor Green
    } else {
        Write-Host "`n   ❌ Failed to create remote develop branch" -ForegroundColor Red
        Write-Host "   Check your network connection and GitHub credentials" -ForegroundColor Yellow
        exit 1
    }
} else {
    Write-Host "   ✅ Remote develop branch exists" -ForegroundColor Green
}

# 3️⃣ Pull latest changes
Write-Host "`n3️⃣ Syncing with remote..." -ForegroundColor Yellow
Write-Host "   Pulling latest changes..." -ForegroundColor Gray
git pull origin develop 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "   ⚠️  Pull failed - you may be ahead of remote (this is OK for first push)" -ForegroundColor Yellow
} else {
    Write-Host "   ✅ Up to date with remote" -ForegroundColor Green
}

# 4️⃣ Tag the beta release
Write-Host "`n4️⃣ Creating and pushing beta tag..." -ForegroundColor Yellow
$betaTag = "v0.1.0-beta"

# Check if tag already exists locally
$existingTag = git tag -l $betaTag
if ($existingTag) {
    Write-Host "   ⚠️  Tag $betaTag already exists locally" -ForegroundColor Yellow
    $response = Read-Host "   Delete and recreate? (y/n)"
    if ($response -eq 'y') {
        git tag -d $betaTag
        Write-Host "   Deleted local tag" -ForegroundColor Gray
    } else {
        Write-Host "   Keeping existing tag" -ForegroundColor Gray
    }
}

Write-Host "   Creating tag: $betaTag" -ForegroundColor Gray
git tag $betaTag
if ($LASTEXITCODE -ne 0) {
    Write-Host "   ❌ Failed to create tag" -ForegroundColor Red
    exit 1
}

Write-Host "   Pushing tag to GitHub..." -ForegroundColor Gray
git push origin $betaTag --force
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ Beta tag pushed successfully" -ForegroundColor Green
    Write-Host "`n   📦 GitHub Actions triggered for APK/AAB build" -ForegroundColor Cyan
    Write-Host "   📍 Check progress: https://github.com/larrybesant/MIXMINGLE/actions`n" -ForegroundColor Cyan
} else {
    Write-Host "   ❌ Failed to push tag" -ForegroundColor Red
    exit 1
}

# 5️⃣ Trigger web deployment
Write-Host "5️⃣ Triggering web deployment..." -ForegroundColor Yellow
Write-Host "   Pushing develop branch..." -ForegroundColor Gray
git push origin develop
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ Web deploy triggered" -ForegroundColor Green
    Write-Host "`n   🌐 Live URL: https://larrybesant.github.io/MIXMINGLE/" -ForegroundColor Cyan
    Write-Host "   📍 Deploy status: https://github.com/larrybesant/MIXMINGLE/actions`n" -ForegroundColor Cyan
} else {
    Write-Host "   ⚠️  Push failed - web deploy may not trigger" -ForegroundColor Yellow
}

# 6️⃣ Finish
Write-Host "`n✅ Beta release workflow complete!" -ForegroundColor Green
Write-Host "`n📋 Next Steps:" -ForegroundColor Cyan
Write-Host "   1. Monitor GitHub Actions: https://github.com/larrybesant/MIXMINGLE/actions" -ForegroundColor White
Write-Host "   2. Download APKs: GitHub → Releases → $betaTag" -ForegroundColor White
Write-Host "   3. Test web app: https://larrybesant.github.io/MIXMINGLE/" -ForegroundColor White
Write-Host "   4. Start new feature work:" -ForegroundColor White
Write-Host "      git checkout -b feature/your-feature-name`n" -ForegroundColor Gray

Write-Host "🎯 Ready for beta testers!`n" -ForegroundColor Green
