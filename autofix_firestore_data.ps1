# Auto-fix Firestore .data()! assertions
# Finds lines with .data()! and converts them to safer patterns

Write-Host "`n═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  🔧 AUTO-FIX FIRESTORE .data()! ASSERTIONS" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

$filesFixed = 0
$linesFixed = 0

# Target files with .data()! patterns
$targetFiles = @(
    "lib\services\messaging_service.dart",
    "lib\services\events_service.dart",
    "lib\services\profile_service.dart",
    "lib\services\room_service.dart",
    "lib\services\firestore_service.dart",
    "lib\services\camera_permission_service.dart",
    "lib\services\broadcaster_service.dart",
    "lib\services\chat_service.dart",
    "lib\services\gamification_service.dart",
    "lib\services\presence_service.dart",
    "lib\services\subscription_service.dart",
    "lib\services\video_subscription_service.dart",
    "lib\services\mic_service.dart",
    "lib\services\badge_service.dart",
    "lib\services\data_export_service.dart",
    "lib\services\social_graph_service.dart"
)

foreach ($relativePath in $targetFiles) {
    $fullPath = Join-Path (Get-Location) $relativePath
    if (-not (Test-Path $fullPath)) {
        Write-Host "⚠️  Skipping $relativePath (not found)" -ForegroundColor Yellow
        continue
    }

    $content = Get-Content $fullPath -Raw
    if ($content -notmatch '\.data\(\)!') {
        continue
    }

    Write-Host "🔧 Fixing: $relativePath" -ForegroundColor Cyan

    # Pattern 1: doc.data()! where doc might be null/non-existent
    # Replace with safer pattern: doc.data() ?? {}
    $originalContent = $content

    # Fix: userDoc.data()! -> (userDoc.data() ?? {})
    $content = $content -replace '(\w+Doc)\.data\(\)!', '($1.data() ?? <String, dynamic>{})'

    # Fix: snapshot.data()! -> (snapshot.data() ?? {})
    $content = $content -replace '(snapshot)\.data\(\)!', '($1.data() ?? <String, dynamic>{})'

    # Fix: doc.data()! -> (doc.data() ?? {})
    $content = $content -replace '(\bdoc\b)\.data\(\)!', '($1.data() ?? <String, dynamic>{})'

    if ($content -ne $originalContent) {
        Set-Content -Path $fullPath -Value $content -NoNewline
        $filesFixed++
        $changesCount = ([regex]::Matches($originalContent, '\.data\(\)!')).Count
        $linesFixed += $changesCount
        Write-Host "  ✅ Fixed $changesCount patterns" -ForegroundColor Green
    }
}

Write-Host "`n═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  📊 AUTO-FIX COMPLETE" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════`n" -ForegroundColor Cyan
Write-Host "  Files fixed: $filesFixed" -ForegroundColor White
Write-Host "  Patterns converted: $linesFixed" -ForegroundColor White
Write-Host "`n  Pattern: .data()! → (data() ?? <String, dynamic>{})" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════`n" -ForegroundColor Cyan
