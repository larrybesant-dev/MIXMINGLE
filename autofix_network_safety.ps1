# Auto-fix Network Safety Issues
# Adds error handling to Image.network, NetworkImage, and unsafe URL assertions

Write-Host "`n═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  🔧 AUTO-FIX NETWORK SAFETY" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

$filesFixed = 0
$patternsFixed = 0

# Read the report to get all issues
$issues = Import-Csv "network_safety_report.csv"
$fileGroups = $issues | Group-Object File

Write-Host "Processing $($fileGroups.Count) files with network safety issues...`n" -ForegroundColor White

foreach ($group in $fileGroups) {
    $filePath = Join-Path "lib" $group.Name
    if (-not (Test-Path $filePath)) {
        Write-Host "⚠️  Skipping $($group.Name) (not found)" -ForegroundColor Yellow
        continue
    }

    $content = Get-Content $filePath -Raw
    $originalContent = $content
    $fixCount = 0

    # FIX 1: Remove ! from avatarUrl/photoUrl/imageUrl
    $urlAssertions = @('avatarUrl!', 'photoUrl!', 'profilePhotoUrl!', 'imageUrl!')
    foreach ($assertion in $urlAssertions) {
        if ($content -match [regex]::Escape($assertion)) {
            $content = $content -replace [regex]::Escape($assertion), ($assertion -replace '!', '')
            $fixCount++
        }
    }

    # FIX 2: Add errorBuilder to Image.network (simple cases on single lines)
    # Pattern: Image.network(url) → Image.network(url, errorBuilder: (c,e,s) => Icon(Icons.broken_image))
    $content = $content -replace
        'Image\.network\s*\(\s*([^,\)]+)\s*\)',
        'Image.network($1, errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.grey))'

    if ($content -ne $originalContent) {
        $fixCount++
    }

    # FIX 3: Wrap NetworkImage with error handling via DecorationImage
    # This is more complex and requires context-aware replacement
    # For now, we'll document it for manual review

    if ($content -ne $originalContent) {
        Set-Content -Path $filePath -Value $content -NoNewline
        $filesFixed++
        $patternsFixed += $fixCount
        Write-Host "✅ Fixed $($group.Name) ($fixCount patterns)" -ForegroundColor Green
    }
}

Write-Host "`n═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  📊 AUTO-FIX COMPLETE" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════`n" -ForegroundColor Cyan
Write-Host "  Files fixed: $filesFixed" -ForegroundColor White
Write-Host "  Patterns fixed: $patternsFixed" -ForegroundColor White
Write-Host "`n  ✅ Removed ! assertions from URLs" -ForegroundColor Green
Write-Host "  ✅ Added errorBuilder to Image.network" -ForegroundColor Green
Write-Host "`n  ⚠️  NetworkImage requires manual fixes (see below)" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

Write-Host "MANUAL FIX TEMPLATE for NetworkImage:" -ForegroundColor Yellow
Write-Host @"

// BEFORE:
CircleAvatar(
  backgroundImage: NetworkImage(user.avatarUrl),
)

// AFTER:
CircleAvatar(
  backgroundImage: NetworkImage(user.avatarUrl ?? ''),
  onBackgroundImageError: (e, s) {
    // Silently ignore CORS/404 errors
  },
  child: user.avatarUrl == null
    ? Icon(Icons.person)
    : null,
)

"@ -ForegroundColor White
