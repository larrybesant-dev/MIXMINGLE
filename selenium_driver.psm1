# =====================================================
# SELENIUM WEBDRIVER MODULE - MIXMINGLE
# Zero-tolerance null driver - bulletproof lifecycle
# =====================================================

function Test-ChromeEnvironment {
    <#
    .SYNOPSIS
    Validates Chrome + ChromeDriver compatibility before initialization
    #>

    Write-Host "`n🔍 Validating Chrome environment..." -ForegroundColor Cyan

    # Check Chrome installation
    $chromePaths = @(
        "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe",
        "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
        "${env:LocalAppData}\Google\Chrome\Application\chrome.exe"
    )

    $chromeExe = $chromePaths | Where-Object { Test-Path $_ } | Select-Object -First 1

    if (-not $chromeExe) {
        Write-Host "❌ Chrome not found in standard locations" -ForegroundColor Red
        return $false
    }

    # Get Chrome version
    $chromeVersionFull = (Get-Item $chromeExe).VersionInfo.ProductVersion
    $chromeMajor = $chromeVersionFull.Split('.')[0]
    Write-Host "✅ Chrome found: v$chromeVersionFull" -ForegroundColor Green

    # Check ChromeDriver
    try {
        $driverVersion = (& chromedriver --version 2>&1) -replace '[^0-9.]', ''
        $driverMajor = $driverVersion.Split('.')[0]
        Write-Host "✅ ChromeDriver found: v$driverVersion" -ForegroundColor Green

        if ($chromeMajor -ne $driverMajor) {
            Write-Host "⚠️  Version mismatch detected:" -ForegroundColor Yellow
            Write-Host "   Chrome: $chromeMajor | ChromeDriver: $driverMajor" -ForegroundColor Yellow
            Write-Host "   This may cause initialization failures" -ForegroundColor Yellow
            return $false
        }

        Write-Host "✅ Version compatibility confirmed" -ForegroundColor Green
        return $true

    } catch {
        Write-Host "❌ ChromeDriver not found in PATH" -ForegroundColor Red
        Write-Host "   Install: choco install chromedriver" -ForegroundColor Yellow
        Write-Host "   Or download from: https://chromedriver.chromium.org/" -ForegroundColor Yellow
        return $false
    }
}

function Initialize-SeleniumDriver {
    <#
    .SYNOPSIS
    Creates a ChromeDriver instance with logging enabled and proper error handling

    .PARAMETER Headless
    Run browser in headless mode (no GUI)

    .PARAMETER LogDirectory
    Directory to store browser console logs (default: script directory)

    .RETURNS
    ChromeDriver instance or $null if initialization fails
    #>

    param(
        [switch]$Headless,
        [string]$LogDirectory = $PSScriptRoot
    )

    Write-Host "`n🚀 Initializing WebDriver..." -ForegroundColor Cyan

    # Validate environment first
    if (-not (Test-ChromeEnvironment)) {
        Write-Host "❌ Environment validation failed - cannot initialize driver" -ForegroundColor Red
        return $null
    }

    # Load Selenium assemblies
    try {
        Add-Type -Path "$PSScriptRoot\WebDriver.dll" -ErrorAction Stop
        Write-Host "✅ Selenium assemblies loaded" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to load Selenium WebDriver.dll" -ForegroundColor Red
        Write-Host "   Install: Install-Package Selenium.WebDriver" -ForegroundColor Yellow
        Write-Host "   Or place WebDriver.dll in: $PSScriptRoot" -ForegroundColor Yellow
        return $null
    }

    # Configure ChromeDriver with logging
    try {
        $service = [OpenQA.Selenium.Chrome.ChromeDriverService]::CreateDefaultService()
        $service.HideCommandPromptWindow = $true

        $options = New-Object OpenQA.Selenium.Chrome.ChromeOptions

        # CRITICAL: Enable browser console log capture
        $options.SetLoggingPreference("browser", "ALL")
        $options.SetLoggingPreference("driver", "ALL")

        # Stability flags
        $options.AddArgument("--disable-gpu")
        $options.AddArgument("--no-sandbox")
        $options.AddArgument("--disable-dev-shm-usage")
        $options.AddArgument("--disable-blink-features=AutomationControlled")

        if ($Headless) {
            $options.AddArgument("--headless=new")
            Write-Host "🕶️  Headless mode enabled" -ForegroundColor Cyan
        }

        # Initialize driver
        $driver = New-Object OpenQA.Selenium.Chrome.ChromeDriver($service, $options)

        if (-not $driver) {
            Write-Host "❌ Driver object is null after initialization" -ForegroundColor Red
            return $null
        }

        # Verify driver is functional
        $driver.Manage().Timeouts().ImplicitWait = [TimeSpan]::FromSeconds(10)
        $driver.Manage().Timeouts().PageLoad = [TimeSpan]::FromSeconds(30)

        Write-Host "✅ WebDriver initialized successfully" -ForegroundColor Green
        Write-Host "   Session ID: $($driver.SessionId)" -ForegroundColor DarkGray

        return $driver

    } catch {
        Write-Host "❌ WebDriver initialization failed:" -ForegroundColor Red
        Write-Host "   $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "   $($_.Exception.InnerException.Message)" -ForegroundColor Red
        return $null
    }
}

function Get-BrowserConsoleLogs {
    <#
    .SYNOPSIS
    Captures browser console logs from an active WebDriver session

    .PARAMETER Driver
    Active ChromeDriver instance

    .PARAMETER OutputPath
    File path to save logs (optional)

    .RETURNS
    Array of log entries or empty array if capture fails
    #>

    param(
        [Parameter(Mandatory=$true)]
        $Driver,
        [string]$OutputPath
    )

    if (-not $Driver) {
        Write-Host "⚠️  Cannot capture logs - Driver is null" -ForegroundColor Yellow
        return @()
    }

    try {
        $logs = $Driver.Manage().Logs.GetLog("browser")

        if ($logs.Count -eq 0) {
            Write-Host "ℹ️  No browser console logs captured" -ForegroundColor Cyan
            return @()
        }

        Write-Host "✅ Captured $($logs.Count) browser console log(s)" -ForegroundColor Green

        if ($OutputPath) {
            $logs | ForEach-Object { $_.ToString() } | Out-File $OutputPath -Encoding UTF8
            Write-Host "   Saved to: $OutputPath" -ForegroundColor DarkGray
        }

        return $logs

    } catch {
        Write-Host "❌ Error capturing browser console logs:" -ForegroundColor Red
        Write-Host "   $($_.Exception.Message)" -ForegroundColor Red
        return @()
    }
}

function Stop-SeleniumDriver {
    <#
    .SYNOPSIS
    Safely closes WebDriver session with null guards

    .PARAMETER Driver
    ChromeDriver instance to close
    #>

    param($Driver)

    if (-not $Driver) {
        Write-Host "ℹ️  No WebDriver instance to close" -ForegroundColor Cyan
        return
    }

    try {
        $Driver.Quit()
        Write-Host "🧹 WebDriver closed cleanly" -ForegroundColor Green
    } catch {
        Write-Host "⚠️  Error during driver shutdown (non-critical):" -ForegroundColor Yellow
        Write-Host "   $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# Export module functions
Export-ModuleMember -Function @(
    'Test-ChromeEnvironment',
    'Initialize-SeleniumDriver',
    'Get-BrowserConsoleLogs',
    'Stop-SeleniumDriver'
)
