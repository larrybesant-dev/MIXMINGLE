function Run-HealthCheck {
    Write-Log "Checking live site..."
    try {
        $status = Invoke-WebRequest "https://mix-and-mingle-v2.web.app/" -UseBasicParsing -TimeoutSec 10
        if ($status.StatusCode -eq 200) {
            Write-Log "Health Check: Site is live and responsive."
        } else {
            Write-Log "Health Check FAILED: $($status.StatusCode)"
        }
    }
    catch {
        Write-Log "Health Check FAILED: $_"
    }
}