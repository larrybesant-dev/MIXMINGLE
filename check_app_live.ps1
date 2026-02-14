# ==========================
# MIX & MINGLE – LIVE STATUS CHECK SCRIPT
# ==========================

param(
    [string]$DeployedUrl = "https://mix-and-mingle-v2.web.app"  # Replace with your actual deployed URL
)

$transcriptPath = Join-Path $PSScriptRoot "check_app_live_output.txt"
try { Start-Transcript -Path $transcriptPath -Force | Out-Null } catch { }

Write-Host "🔍 Checking Flutter web app live status..." -ForegroundColor Cyan
Write-Host "Deployed URL: $DeployedUrl" -ForegroundColor Yellow

# Step 1: Build the Flutter web app for release
Write-Host "`n📦 Step 1: Building Flutter web app for release..." -ForegroundColor Yellow
flutter build web --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Build successful" -ForegroundColor Green

# Step 2: Serve locally to check for runtime errors (brief check)
Write-Host "`n🌐 Step 2: Starting local server to check for runtime errors..." -ForegroundColor Yellow
Push-Location build\web
$job = Start-Job -ScriptBlock {
    python -m http.server 5000
} -Name "LocalServer"
Pop-Location

# Wait a bit for server to start
Start-Sleep -Seconds 5

# Check if local server is responding
try {
    $localResponse = Invoke-WebRequest -UseBasicParsing "http://127.0.0.1:5000" -TimeoutSec 5
    Write-Host "✅ Local server started successfully (Status: $($localResponse.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "❌ Local server failed to start or respond" -ForegroundColor Red
    Stop-Job -Job $job
    Remove-Job -Job $job
    exit 1
}

# Stop the local server
Stop-Job -Job $job
Remove-Job -Job $job
Write-Host "🛑 Local server stopped" -ForegroundColor Cyan

# Step 3: Ping the deployed URL
Write-Host "`n🌍 Step 3: Pinging deployed URL..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -UseBasicParsing $DeployedUrl -TimeoutSec 10
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Deployed URL reachable (Status: $($response.StatusCode))" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Deployed URL responded with status $($response.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Deployed URL not reachable" -ForegroundColor Red
    exit 1
}

# Step 4: Fetch main JS file and check for errors
Write-Host "`n🧪 Step 4: Checking main JavaScript file for runtime error patterns..." -ForegroundColor Yellow
try {
    $jsContent = Invoke-WebRequest "$DeployedUrl/main.dart.js" -UseBasicParsing

    # Searching for generic "error" in minified JS is extremely noisy (often the whole file is one line).
    # Use a narrower set of runtime-error indicators and report counts only.
    $pattern = "Uncaught|TypeError|ReferenceError|RangeError|FirebaseError|Exception"
    $matchInfo = $jsContent.Content | Select-String -Pattern $pattern -AllMatches

    if ($matchInfo) {
        $matchCount = 0
        $matchInfo | ForEach-Object { $matchCount += $_.Matches.Count }
        Write-Host "⚠️ Found $matchCount runtime-error indicator(s) in main.dart.js (pattern: $pattern)." -ForegroundColor Yellow
        Write-Host "   This is a heuristic check; investigate only if users see runtime failures." -ForegroundColor Yellow
    } else {
        Write-Host "✅ No runtime-error indicators found in main.dart.js" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Could not fetch main JS file" -ForegroundColor Red
}

# Step 5: Verify service worker (optional for PWA)
Write-Host "`n🧩 Step 5: Checking service worker..." -ForegroundColor Yellow
try {
    Invoke-WebRequest "$DeployedUrl/flutter_service_worker.js" -UseBasicParsing | Out-Null
    Write-Host "✅ Service worker is present" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Service worker not found (PWA features may not work)" -ForegroundColor Yellow
}

# ==========================
# MIX & MINGLE – STORAGE TEST
# ==========================

Write-Host "`n6️⃣ Firebase Storage programmatic test..."
try {
    $authUp = Test-NetConnection -ComputerName 127.0.0.1 -Port 9099 -InformationLevel Quiet
    $storageUp = Test-NetConnection -ComputerName 127.0.0.1 -Port 9199 -InformationLevel Quiet

    if (-not $authUp -or -not $storageUp) {
        Write-Host "❌ Firebase emulators are not reachable." -ForegroundColor Red
        Write-Host "   Required: Auth emulator on 127.0.0.1:9099 and Storage emulator on 127.0.0.1:9199" -ForegroundColor Red
        Write-Host "   Start them with: firebase emulators:start --only \"auth,storage\"" -ForegroundColor Yellow
        exit 1
    }

    # Capture both stdout+stderr so failures are visible in storage_test_results.txt.
    # Note: Flutter's `--timeout` does NOT apply to the *test suite loading timeout*.
    # We disable test timeouts and enforce a PowerShell-level wall-clock timeout instead.
    $storageResultsPath = Join-Path $PSScriptRoot "storage_test_results.txt"
    $storageWallClockTimeoutSec = 900  # 15 minutes

    Remove-Item -Force -ErrorAction SilentlyContinue $storageResultsPath

    $storageTestJob = Start-Job -ScriptBlock {
        param($resultsPath)
        flutter test --platform chrome --ignore-timeouts test/firebase_storage_integration_test.dart 2>&1 |
            Tee-Object -FilePath $resultsPath
    } -ArgumentList $storageResultsPath

    $completed = Wait-Job -Job $storageTestJob -Timeout $storageWallClockTimeoutSec
    if (-not $completed) {
        Write-Host "❌ Storage test exceeded ${storageWallClockTimeoutSec}s and was terminated." -ForegroundColor Red
        Stop-Job -Job $storageTestJob -Force | Out-Null
        Remove-Job -Job $storageTestJob -Force | Out-Null
        exit 1
    }

    Receive-Job -Job $storageTestJob | Out-Null
    Remove-Job -Job $storageTestJob -Force | Out-Null

    if (-not (Test-Path $storageResultsPath)) {
        Write-Host "❌ Storage test produced no output file at: $storageResultsPath" -ForegroundColor Red
        exit 1
    }

    $exitCodeLine = Get-Content $storageResultsPath -ErrorAction SilentlyContinue | Select-Object -Last 1
    if ($exitCodeLine) {
        Write-Host "(storage test last line) $exitCodeLine" -ForegroundColor DarkGray
    }

    $results = Get-Content storage_test_results.txt | Select-String "Upload successful"

    if ($results) {
        Write-Host "✅ Storage upload confirmed" -ForegroundColor Green
    } else {
        Write-Host "❌ Storage upload failed. See storage_test_results.txt" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Running storage test failed:" -ForegroundColor Red
    Write-Host $_
    exit 1
}

Write-Host "`n🎉 App status verification complete!" -ForegroundColor Green

try { Stop-Transcript | Out-Null } catch { }
Write-Host "Full output saved to: $transcriptPath" -ForegroundColor Cyan