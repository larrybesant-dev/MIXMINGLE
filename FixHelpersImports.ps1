# FixAllHelpersImports.ps1
# Fixes all broken helpers.dart imports in the MIXMINGLE project

$root = "C:\Users\LARRY\MIXMINGLE\lib"

# All Dart files
$dartFiles = Get-ChildItem -Recurse -Include *.dart $root

foreach ($file in $dartFiles) {
    $content = Get-Content $file.FullName
    $updated = $false
    $newContent = @()

    foreach ($line in $content) {
        # Match any line that looks like a broken helpers import
        if ($line -match "helpers\.dart") {
            Write-Host "✅ Fixing helpers import in $($file.FullName)"
            $line = "import 'package:mixmingle/helpers/helpers.dart';"
            $updated = $true
        }
        $newContent += $line
    }

    if ($updated) {
        # Save updated file
        Set-Content -Path $file.FullName -Value $newContent -Encoding UTF8
    }
}

Write-Host "🎯 All helpers imports fixed across the project."
