@"
# Dart files with most debugPrint calls
`$files = @(
    'lib\services\agora_video_service.dart',  # 116
    'lib\services\room_service.dart',          # 39
    'lib\features\voice_room\presentation\pages\voice_room_page.dart', # 31
    'lib\services\match_service.dart',         # 26
    'lib\services\account_deletion_service.dart' # 25
)

foreach (`$file in `$files) {
    `$fullPath = Join-Path 'c:\Users\LARRY\MIXMINGLE' `$file
    if (-not (Test-Path `$fullPath)) {
        Write-Host "⏭️  SKIP: `$file (not found)" -ForegroundColor Yellow
        continue
    }

    Write-Host "Processing `$file..." -ForegroundColor Cyan

    `$content = Get-Content `$fullPath -Raw
    `$beforeCount = ([regex]::Matches(`$content, 'debugPrint\(').Count)

    # Add import if not present
    if (`$content -notmatch "import.*debug_log\.dart") {
        `$lastImport = `$content.LastIndexOf("import ")
        `$nextNewline = `$content.IndexOf("`n", `$lastImport)
        if (`$lastImport -ge 0 -and `$nextNewline -gt `$lastImport) {
            `$content = `$content.Insert(`$nextNewline + 1, "import '../core/logging/debug_log.dart'`n")
        }
    }

    # Replace debugPrint calls with DebugLog
    `$content = `$content -replace 'debugPrint\(', 'DebugLog.info('

    Set-Content `$fullPath `$content -Encoding UTF8

    `$afterCount = ([regex]::Matches(`$content, 'DebugLog\.info\(').Count)
    Write-Host "  ✅ Replaced `$beforeCount debugPrint → `$afterCount DebugLog.info" -ForegroundColor Green
}

Write-Host "`n✅ Debug print replacement complete!" -ForegroundColor Green
"@ | powershell -NoProfile
