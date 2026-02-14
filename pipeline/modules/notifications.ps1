function Send-Alert {
    param([string]$message)
    Write-Log "Sending alert: $message"
    # For Discord: assume webhook URL in env or config
    $webhookUrl = $env:DISCORD_WEBHOOK_URL
    if ($webhookUrl) {
        $body = @{ content = $message } | ConvertTo-Json
        Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $body -ContentType "application/json"
    } else {
        Write-Log "No Discord webhook configured, logging only."
    }
    # For SMS: placeholder, use Twilio or similar
    # Send-MailMessage -To "yourphone@carrier.com" -Subject "Pipeline Alert" -Body $message -SmtpServer "smtp.gmail.com" -From "alert@example.com"
}

function Send-MultiAlert {
    param (
        [string]$Message,
        [switch]$Critical  # Flag for critical alerts (e.g., SMS)
    )
    # Discord
    if ($env:DISCORD_WEBHOOK_URL) {
        $payload = @{ content = $Message } | ConvertTo-Json
        Invoke-RestMethod -Uri $env:DISCORD_WEBHOOK_URL -Method Post -Body $payload -ContentType "application/json"
    }
    # Slack
    if ($env:SLACK_WEBHOOK_URL) {
        $payload = @{ text = $Message } | ConvertTo-Json
        Invoke-RestMethod -Uri $env:SLACK_WEBHOOK_URL -Method Post -Body $payload -ContentType "application/json"
    }
    # Email (SMTP)
    if ($env:EMAIL_ALERT) {
        Send-MailMessage -To $env:EMAIL_ALERT -From "ci@mixandmingle.local" -Subject "Pipeline Alert" -Body $Message -SmtpServer "smtp.local"
    }
    # SMS (Twilio or SMTP-to-SMS)
    if ($Critical -and $env:TWILIO_SID -and $env:TWILIO_TOKEN -and $env:TWILIO_FROM -and $env:SMS_TO) {
        # Twilio API
        $auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($env:TWILIO_SID):$($env:TWILIO_TOKEN)"))
        $body = @{
            From = $env:TWILIO_FROM
            To = $env:SMS_TO
            Body = $Message
        } | ConvertTo-Json
        Invoke-RestMethod -Uri "https://api.twilio.com/2010-04-01/Accounts/$($env:TWILIO_SID)/Messages.json" -Method Post -Headers @{Authorization = "Basic $auth"} -Body $body -ContentType "application/x-www-form-urlencoded"
        Write-Log "📱 SMS alert sent via Twilio."
    } elseif ($Critical -and $env:SMS_EMAIL) {
        # SMTP-to-SMS (e.g., carrier gateway)
        Send-MailMessage -To $env:SMS_EMAIL -From "ci@mixandmingle.local" -Subject "Critical Alert" -Body $Message -SmtpServer "smtp.local"
        Write-Log "📱 SMS alert sent via email gateway."
    }
    # Local Log
    Write-Log "🔔 Alert: $Message"
}