# MixMingle Browser Test Setup

## What you just got

**Two files, zero null-driver failures:**

1. **`selenium_driver.psm1`** — Reusable PowerShell module
   - Chrome/ChromeDriver version validation
   - Hardened WebDriver initialization
   - Browser log capture with null guards
   - Clean shutdown (never throws)

2. **`run_browser_diagnostics.ps1`** — Diagnostic harness
   - Launches browser
   - Loads your local/deployed MixMingle
   - Captures console logs + screenshot
   - Analyzes errors automatically

---

## First-time setup (5 minutes)

### 1. Install ChromeDriver (if not already present)

**Option A: Chocolatey (fastest)**

```powershell
choco install chromedriver -y
```

**Option B: Manual install**

1. Check Chrome version: `chrome://version`
2. Download matching ChromeDriver: https://chromedriver.chromium.org/downloads
3. Place `chromedriver.exe` in `C:\Windows\System32` (or add to PATH)

### 2. Get Selenium WebDriver DLL

**Option A: NuGet (recommended)**

```powershell
# In MIXMINGLE directory
Install-Package Selenium.WebDriver -ProviderName NuGet -Destination . -Force
```

Then copy `WebDriver.dll` to the MIXMINGLE root:

```powershell
Copy-Item ".\Selenium.WebDriver.*\lib\netstandard2.0\WebDriver.dll" . -Force
```

**Option B: Download directly**

1. Go to: https://www.nuget.org/packages/Selenium.WebDriver
2. Download `.nupkg` → rename to `.zip` → extract
3. Copy `lib\netstandard2.0\WebDriver.dll` to `C:\Users\LARRY\MIXMINGLE\`

### 3. Verify setup

```powershell
.\run_browser_diagnostics.ps1 -TargetUrl "http://localhost:5000"
```

Expected output:

```
✅ Chrome found: v131.x.x
✅ ChromeDriver found: v131.x.x
✅ Version compatibility confirmed
✅ Selenium assemblies loaded
✅ WebDriver initialized successfully
```

---

## Usage

### Basic diagnostics

```powershell
# Test local dev server
.\run_browser_diagnostics.ps1

# Test deployed app
.\run_browser_diagnostics.ps1 -TargetUrl "https://mix-and-mingle-v2.web.app"

# Headless mode (no GUI)
.\run_browser_diagnostics.ps1 -Headless

# Custom wait time
.\run_browser_diagnostics.ps1 -WaitSeconds 20
```

### Use module in your own scripts

```powershell
Import-Module .\selenium_driver.psm1

# Initialize
$Driver = Initialize-SeleniumDriver -Headless

# Hard stop if null (prevents the error you saw)
if (-not $Driver) {
    Write-Host "Driver failed - aborting"
    exit 1
}

# Your test logic here
$Driver.Navigate().GoToUrl("https://yourapp.com")

# Capture logs
Get-BrowserConsoleLogs -Driver $Driver -OutputPath "logs.txt"

# Always clean up
Stop-SeleniumDriver -Driver $Driver
```

---

## What this fixes

### Before (your original code)

```powershell
$Driver = New-Object OpenQA.Selenium.Chrome.ChromeDriver  # might fail silently
$logs = $Driver.Manage().Logs.GetLog("browser")  # ❌ null-valued expression
$Driver.Quit()  # ❌ null-valued expression
```

### After (this module)

```powershell
$Driver = Initialize-SeleniumDriver  # validates environment first, fails loudly

if (-not $Driver) {  # HARD GUARD
    exit 1
}

Get-BrowserConsoleLogs -Driver $Driver  # null-guarded internally
Stop-SeleniumDriver -Driver $Driver  # null-guarded internally
```

**Every function checks for null before doing anything.**

---

## Troubleshooting

### "WebDriver.dll not found"

→ Run step 2 above (install Selenium.WebDriver package)

### "ChromeDriver not found in PATH"

→ Run step 1 above (install ChromeDriver)

### "Version mismatch detected"

→ Update ChromeDriver to match Chrome version:

```powershell
choco upgrade chromedriver -y
```

### "Cannot bind argument to parameter 'Path'"

→ You're in the wrong directory. Run from `C:\Users\LARRY\MIXMINGLE`

---

## Logs location

All test outputs go to `test_logs/`:

- `browser_console_log.txt` — Full browser console output
- `browser_console_error.txt` — Logs captured on navigation failure
- `screenshot_YYYYMMDD_HHMMSS.png` — Visual state of the page

---

## Next steps

1. Run setup (steps 1-2 above)
2. Test with local server: `.\run_browser_diagnostics.ps1`
3. Integrate into your CI/CD or manual testing workflow

**No more null driver errors. Ever.**
