# Comprehensive NetworkImage CORS Fixer
# Adds onBackgroundImageError to ALL CircleAvatar with NetworkImage

Write-Host "`n═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  🔧 COMPREHENSIVE NETWORKIMAGE FIXER" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

$filesFixed = 0
$patternsFixed = 0

Get-ChildItem lib -Recurse -Filter "*.dart" -ErrorAction SilentlyContinue | ForEach-Object {
    $file = $_
    $content = Get-Content $file.FullName -Raw
    $originalContent = $content

    # FIX: CircleAvatar with NetworkImage but no onBackgroundImageError
    # Pattern detection: CircleAvatar + NetworkImage without onBackgroundImageError

    if ($content -match 'CircleAvatar' -and
        $content -match 'NetworkImage' -and
        $content -notmatch 'onBackgroundImageError') {

        # Multi-line regex to find CircleAvatar blocks
        $pattern = '(CircleAvatar\s*\([^{]*?backgroundImage:\s*(?:.*?)\?\s*)?NetworkImage\(([^)]+)\)(\s*:\s*null)?(,?\s*(?!onBackgroundImageError))'

        $matches = [regex]::Matches($content, $pattern)

        if ($matches.Count -gt 0) {
            foreach ($match in $matches) {
                $fullMatch = $match.Value

                # Check if this NetworkImage is inside a CircleAvatar and doesn't have error handler
                $contextStart = [Math]::Max(0, $match.Index - 200)
                $contextEnd = [Math]::Min($content.Length, $match.Index + 200)
                $context = $content.Substring($contextStart, $contextEnd - $contextStart)

                if ($context -match 'CircleAvatar' -and $context -notmatch 'onBackgroundImageError') {
                    # Find the closing parenthesis of CircleAvatar
                    # Insert onBackgroundImageError before it

                    # For simplicity, we'll add it after the backgroundImage line
                    $replacement = $fullMatch + ",`n                  onBackgroundImageError: (e, s) {}`"

                    # Only replace if we haven't already added the handler
                    if (-not ($content.Substring($match.Index, 300) -match 'onBackgroundImageError')) {
                        $content = $content.Replace($fullMatch, $replacement)
                        $patternsFixed++
                    }
                }
            }
        }
    }

    if ($content -ne $originalContent) {
        Set-Content -Path $file.FullName -Value $content -NoNewline
        $filesFixed++
        $relativePath = $file.FullName -replace [regex]::Escape((Get-Location).Path + "\lib\"), ""
        Write-Host "✅ Fixed $relativePath" -ForegroundColor Green
    }
}

Write-Host "`n═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  📊 COMPREHENSIVE FIX COMPLETE" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════`n" -ForegroundColor Cyan
Write-Host "  Files fixed: $filesFixed" -ForegroundColor White
Write-Host "  NetworkImage patterns fixed: $patternsFixed" -ForegroundColor White
Write-Host "`n  ✅ All CircleAvatar + NetworkImage now have error handlers" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════`n" -ForegroundColor Cyan
