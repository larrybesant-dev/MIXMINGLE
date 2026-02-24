#!/usr/bin/env pwsh
# Quick stub file creator
$stubs = @{
    'core/utils/async_value_utils.dart' = '// Auto-generated stub file'
    'core/utils/navigation_utils.dart' = '// Auto-generated stub file'
    'core/utils/firestore_utils.dart' = '// Auto-generated stub file'
    'shared/widgets/offline_widgets.dart' = '// Auto-generated stub file'
    'shared/widgets/empty_states.dart' = '// Auto-generated stub file'
}

foreach ($file in $stubs.Keys) {
    $path = Join-Path 'lib' $file.Replace('/', '\')
    $dir = Split-Path $path -Parent
    if (!(Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    if (!(Test-Path $path)) {
        Set-Content -Path $path -Value $stubs[$file]
        Write-Host "Created: $file" -ForegroundColor Green
    } else {
        Write-Host "Exists: $file" -ForegroundColor Gray
    }
}
Write-Host "Done!" -ForegroundColor Cyan
