#!/usr/bin/env pwsh
# Optimized duplicate 'child:' fixer
Write-Host "🔧 Fixing duplicate 'child:' parameters..." -ForegroundColor Cyan

$fixed = 0
$dartFiles = Get-ChildItem -Path .\lib -Recurse -Filter *.dart
$total = $dartFiles.Count
$current = 0

Write-Host "Found $total Dart files to scan" -ForegroundColor Yellow

foreach ($file in $dartFiles) {
    $current++
    if ($current % 50 -eq 0) {
        Write-Host "Progress: $current/$total ($([math]::Round($current/$total*100))%)" -ForegroundColor Gray
    }

    $content = Get-Content $file.FullName -Raw
    if ($content -match '\bchild\s*:[^}]*\bchild\s*:') {
        # Fix duplicate child: parameters
        $newContent = $content -replace '(\bchild\s*:\s*[^,}]+,)\s*child\s*:', '$1/* removed duplicate child */ //'

        if ($newContent -ne $content) {
            Set-Content -Path $file.FullName -Value $newContent -Encoding UTF8
            $fixed++
            Write-Host "  Fixed: $($file.FullName.Replace($PWD,''))" -ForegroundColor Green
        }
    }
}

Write-Host ""
Write-Host "✅ Complete! Fixed $fixed files" -ForegroundColor Green
Write-Host "Run: flutter clean && flutter pub get && flutter build web" -ForegroundColor Cyan
