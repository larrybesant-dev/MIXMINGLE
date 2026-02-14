Write-Host "=== GitHub Secure Setup ===" -ForegroundColor Cyan

# Ask for repo name
$repo = Read-Host "Enter your GitHub repository name (example: MIXMINGLE)"

# Ask for PAT securely
$secureToken = Read-Host "Enter your GitHub Personal Access Token" -AsSecureString
$token = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureToken)
)

# Configure Git credential helper
Write-Host "Configuring Git credential manager..." -ForegroundColor Yellow
git config --global credential.helper manager-core

# Set remote
Write-Host "Setting up remote origin..." -ForegroundColor Yellow
git remote remove origin 2>$null
git remote add origin "https://github.com/larrybesant/$repo.git"

# Store credentials using Git credential manager
Write-Host "Storing credentials securely..." -ForegroundColor Yellow
$credentialInput = @"
protocol=https
host=github.com
username=larrybesant
password=$token
"@

$credentialInput | git credential approve

Write-Host "`nTesting GitHub connection..." -ForegroundColor Yellow
git ls-remote origin

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ GitHub authentication SUCCESSFUL" -ForegroundColor Green
    Write-Host "✅ Remote configured: https://github.com/larrybesant/$repo.git" -ForegroundColor Green
    Write-Host "`nYou can now push, pull, and fetch without authentication prompts." -ForegroundColor Cyan
} else {
    Write-Host "`n❌ GitHub authentication FAILED" -ForegroundColor Red
    Write-Host "Please verify:" -ForegroundColor Yellow
    Write-Host "  1. Token has correct permissions (repo, workflow)" -ForegroundColor Yellow
    Write-Host "  2. Repository name is correct" -ForegroundColor Yellow
    Write-Host "  3. Token hasn't been revoked" -ForegroundColor Yellow
}

# Clear the token from memory
$token = $null
$secureToken = $null
[System.GC]::Collect()

Write-Host "`nSetup complete. Token cleared from memory." -ForegroundColor Gray
