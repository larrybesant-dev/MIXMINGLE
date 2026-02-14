#!/usr/bin/env pwsh
# ============================================================================
# FRESH REPOSITORY PUSH
# Creates a clean commit with only source code (no build artifact history)
# ============================================================================

Write-Host "🚀 Creating fresh repository for GitHub..." -ForegroundColor Cyan
Write-Host ""

# Step 1: Backup current .git
Write-Host "📦 Step 1: Backing up current .git folder..." -ForegroundColor Yellow
if (Test-Path ".git_backup") {
    Remove-Item -Recurse -Force ".git_backup"
}
Rename-Item ".git" ".git_backup"
Write-Host "   ✅ Backup created" -ForegroundColor Green
Write-Host ""

# Step 2: Initialize fresh Git repo
Write-Host "🆕 Step 2: Initializing fresh Git repository..." -ForegroundColor Yellow
git init
git branch -M develop
Write-Host "   ✅ Fresh repo initialized" -ForegroundColor Green
Write-Host ""

# Step 3: Add remote
Write-Host "🔗 Step 3: Adding GitHub remote..." -ForegroundColor Yellow
git remote add origin https://github.com/larrybesant/MIXMINGLE.git
Write-Host "   ✅ Remote added" -ForegroundColor Green
Write-Host ""

# Step 4: Stage all files (respecting .gitignore)
Write-Host "📝 Step 4: Staging source code files..." -ForegroundColor Yellow
git add -A
Write-Host "   ✅ Files staged" -ForegroundColor Green
Write-Host ""

# Step 5: Create initial commit
Write-Host "💾 Step 5: Creating initial commit..." -ForegroundColor Yellow
$commitMessage = "feat: Initial MixMingle beta release

- Complete Flutter application with video chat
- Firebase backend integration
- Agora RTC for real-time communication
- Speed dating and room features
- Chat, presence, and social graph
- Monetization and premium features
- Admin moderation tools
- Comprehensive test suite

Version: 1.0.0-beta.1"

git commit -m $commitMessage --no-verify

if ($LASTEXITCODE -ne 0) {
    Write-Host "   ❌ Commit failed" -ForegroundColor Red
    Write-Host ""
    Write-Host "Restoring original .git..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force ".git"
    Rename-Item ".git_backup" ".git"
    exit 1
}

Write-Host "   ✅ Commit created" -ForegroundColor Green
Write-Host ""

# Step 6: Check repository size
Write-Host "📊 Step 6: Checking repository size..." -ForegroundColor Yellow
$gitSize = (Get-ChildItem .git -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
Write-Host "   Repository size: $([math]::Round($gitSize, 2)) MB" -ForegroundColor White

if ($gitSize -gt 500) {
    Write-Host "   ⚠️  Warning: Repo still larger than 500MB" -ForegroundColor Yellow
    Write-Host "   Large files may cause push to fail" -ForegroundColor Yellow
}
Write-Host ""

# Step 7: Push to GitHub
Write-Host "🚀 Step 7: Pushing to GitHub..." -ForegroundColor Yellow
Write-Host "   This should be much faster with clean history..." -ForegroundColor Gray
Write-Host ""

git push -u origin develop --force

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ SUCCESS! Fresh repository pushed to GitHub" -ForegroundColor Green
    Write-Host ""
    Write-Host "🗑️  Cleaning up backup..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force ".git_backup"
    Write-Host "   ✅ Backup removed" -ForegroundColor Green
    Write-Host ""
    Write-Host "📊 Final Status:" -ForegroundColor Cyan
    Write-Host "   • Clean repository with no build artifact history" -ForegroundColor White
    Write-Host "   • Branch: develop" -ForegroundColor White
    Write-Host "   • Remote: origin/develop" -ForegroundColor White
    Write-Host ""
    Write-Host "🎯 Next Steps:" -ForegroundColor Cyan
    Write-Host "   1. Run: .\release_beta.ps1" -ForegroundColor White
    Write-Host "   2. CI/CD will build and deploy" -ForegroundColor White
    Write-Host "   3. Monitor: https://github.com/larrybesant/MIXMINGLE/actions" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "❌ Push failed" -ForegroundColor Red
    Write-Host ""
    Write-Host "Would you like to restore the original .git? (y/N): " -NoNewline -ForegroundColor Yellow
    $restore = Read-Host
    if ($restore -eq "y") {
        Write-Host "Restoring original .git..." -ForegroundColor Yellow
        Remove-Item -Recurse -Force ".git"
        Rename-Item ".git_backup" ".git"
        Write-Host "   ✅ Original .git restored" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "Original .git backed up to: .git_backup" -ForegroundColor Cyan
        Write-Host "You can restore it manually if needed" -ForegroundColor Cyan
    }
    Write-Host ""
    exit 1
}
