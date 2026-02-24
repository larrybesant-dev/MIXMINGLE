# deploy_web_pages.ps1
# 🚀 Flutter Web → GitHub Pages Deployment
# Requires: Flutter installed, git configured

param (
    [string]$Branch = "gh-pages",
    [string]$WebBuildDir = "build/web"
)

Write-Host "🌐 Starting GitHub Pages deployment..."

# 1️⃣ Ensure we're on main branch (or develop)
git checkout develop
git pull origin develop

# 2️⃣ Build Flutter Web
Write-Host "⚡ Building Flutter web..."
flutter build web --release

# 3️⃣ Switch/create gh-pages branch
if (git show-ref --quiet refs/heads/$Branch) {
    git checkout $Branch
} else {
    Write-Host "🔹 Branch '$Branch' not found. Creating..."
    git checkout --orphan $Branch
}

# 4️⃣ Remove all old files (safe for orphan branch)
Write-Host "🧹 Cleaning old files..."
Get-ChildItem -Path . -Recurse | Where-Object { $_.FullName -notmatch "\.git" } | Remove-Item -Recurse -Force

# 5️⃣ Copy new web build
Write-Host "📂 Copying Flutter web build to root..."
Copy-Item -Path "$WebBuildDir\*" -Destination "." -Recurse -Force

# 6️⃣ Create/update CNAME file for custom domain (optional)
$CNAME = "mixandmingle.app"
Set-Content -Path "CNAME" -Value $CNAME -Encoding UTF8

# 7️⃣ Commit & push
Write-Host "💾 Committing changes..."
git add .
git commit -m "Deploy Flutter web to GitHub Pages - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"

Write-Host "⬆️ Pushing to remote branch '$Branch'..."
git push origin $Branch --force

Write-Host "✅ Deployment complete!"
Write-Host "Your site should be live at: https://$CNAME or https://<username>.github.io/MIXMINGLE/"
