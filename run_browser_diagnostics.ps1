# =====================================================
# MIXMINGLE BROWSER DIAGNOSTICS
# Automated browser testing with console log capture
# =====================================================

param(
    [string]$TargetUrl = "http://localhost:5000",
    [switch]$Headless,
    [int]$WaitSeconds = 10
)

$ErrorActionPreference = "Stop"
$logDir = Join-Path $PSScriptRoot "test_logs"

# Create log directory
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   MIXMINGLE BROWSER DIAGNOSTICS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Target URL: $TargetUrl" -ForegroundColor Yellow
Write-Host "Log Directory: $logDir" -ForegroundColor Yellow
Write-Host ""

# Import the hardened driver module
try {
    Import-Module "$PSScriptRoot\selenium_driver.psm1" -Force
    Write-Host "✅ Selenium driver module loaded" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to load selenium_driver.psm1" -ForegroundColor Red
    Write-Host "   Ensure selenium_driver.psm1 is in the same directory" -ForegroundColor Yellow
    exit 1
}

# Initialize driver (with null-guard built-in)
$Driver = Initialize-SeleniumDriver -Headless:$Headless -LogDirectory $logDir

# HARD STOP if driver is null (no silent failures)
if (-not $Driver) {
    Write-Host ""
    Write-Host "❌ WebDriver was NOT initialized. Aborting diagnostics." -ForegroundColor Red
    Write-Host "   Fix the issues above and try again." -ForegroundColor Yellow
    exit 1
}

# Navigation test
try {
    Write-Host ""
    Write-Host "🌐 Navigating to: $TargetUrl" -ForegroundColor Cyan
    $Driver.Navigate().GoToUrl($TargetUrl)
    Write-Host "✅ Page loaded successfully" -ForegroundColor Green
    Write-Host "   Current URL: $($Driver.Url)" -ForegroundColor DarkGray
    Write-Host "   Page Title: $($Driver.Title)" -ForegroundColor DarkGray

} catch {
    Write-Host "❌ Navigation failed:" -ForegroundColor Red
    Write-Host "   $($_.Exception.Message)" -ForegroundColor Red

    # Capture logs even on failure
    Get-BrowserConsoleLogs -Driver $Driver -OutputPath "$logDir\browser_console_error.txt"
    Stop-SeleniumDriver -Driver $Driver
    exit 1
}

# Wait for app to initialize
Write-Host ""
Write-Host "⏳ Waiting ${WaitSeconds}s for app initialization..." -ForegroundColor Cyan
Start-Sleep -Seconds $WaitSeconds

# Capture final console logs
Write-Host ""
Write-Host "📋 Capturing browser console logs..." -ForegroundColor Cyan
$logs = Get-BrowserConsoleLogs -Driver $Driver -OutputPath "$logDir\browser_console_log.txt"

# Analyze logs for errors
$errorPatterns = @("error", "exception", "failed", "refused", "timeout")
$criticalLogs = $logs | Where-Object {
    $logText = $_.ToString().ToLower()
    $errorPatterns | Where-Object { $logText -contains $_ }
}

if ($criticalLogs) {
    Write-Host ""
    Write-Host "⚠️  Detected $($criticalLogs.Count) potential error(s) in console:" -ForegroundColor Yellow
    $criticalLogs | ForEach-Object {
        Write-Host "   $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "✅ No critical errors detected in browser console" -ForegroundColor Green
}

# Screenshot capture (if driver supports it)
try {
    $screenshotPath = Join-Path $logDir "screenshot_$(Get-Date -Format 'yyyyMMdd_HHmmss').png"
    $screenshot = $Driver.GetScreenshot()
    $screenshot.SaveAsFile($screenshotPath)
    Write-Host "📸 Screenshot saved: $screenshotPath" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Screenshot capture unavailable" -ForegroundColor Yellow
}

# Check for specific MixMingle elements (example - customize as needed)
Write-Host ""
Write-Host "🔍 Checking for MixMingle UI elements..." -ForegroundColor Cyan
try {
    # Example: Check if Firebase auth loaded
    $bodyText = $Driver.FindElementByTagName("body").Text

    if ($bodyText -match "MIX.*MINGLE|mixmingle") {
        Write-Host "✅ MixMingle UI detected" -ForegroundColor Green
    } else {
        Write-Host "⚠️  MixMingle branding not found in page text" -ForegroundColor Yellow
    }

} catch {
    Write-Host "⚠️  Element inspection failed (non-critical)" -ForegroundColor Yellow
}

# Clean shutdown (null-guarded)
Write-Host ""
Write-Host "🛑 Shutting down WebDriver..." -ForegroundColor Cyan
Stop-SeleniumDriver -Driver $Driver

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "   DIAGNOSTICS COMPLETE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Check logs in $logDir" -ForegroundColor Cyan
