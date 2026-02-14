# Auto-fix missing imports for UserProfile, AuthService, and ProfileService
$dartFiles = Get-ChildItem -Path lib -Recurse -Include *.dart
$userProfilePath = 'package:mix_and_mingle/shared/models/user_profile.dart'
$authServicePath = 'package:mix_and_mingle/services/auth_service.dart'
$profileServicePath = 'package:mix_and_mingle/services/profile_service.dart'
$fixedCount = 0

Write-Host "Scanning Dart files for missing imports..." -ForegroundColor Cyan

foreach ($file in $dartFiles) {
    try {
        $content = Get-Content $file.FullName -Raw -ErrorAction Stop
        $originalContent = $content
        $needsUpdate = $false

        # Check if file uses these types but doesn't import them
        $needsUserProfile = ($content -match '\bUserProfile\b') -and (-not ($content -match 'user_profile\.dart'))
        $needsAuthService = ($content -match '\bAuthService\b') -and (-not ($content -match 'auth_service\.dart'))
        $needsProfileService = ($content -match '\bProfileService\b') -and (-not ($content -match 'profile_service\.dart'))

        if ($needsUserProfile -or $needsAuthService -or $needsProfileService) {
            $lines = $content -split "`r?`n"
            $insertIndex = -1

            # Find last import line
            for ($i = 0; $i -lt $lines.Length; $i++) {
                if ($lines[$i] -match "^import ") {
                    $insertIndex = $i
                }
            }

            if ($insertIndex -ge 0) {
                $newImports = @()
                if ($needsUserProfile) { $newImports += "import '$userProfilePath';" }
                if ($needsAuthService) { $newImports += "import '$authServicePath';" }
                if ($needsProfileService) { $newImports += "import '$profileServicePath';" }

                # Insert after last import
                $newLines = @()
                $newLines += $lines[0..$insertIndex]
                $newLines += $newImports
                if ($insertIndex + 1 -lt $lines.Length) {
                    $newLines += $lines[($insertIndex+1)..($lines.Length-1)]
                }

                $content = ($newLines -join "`n")
                $needsUpdate = $true
            }
        }

        if ($needsUpdate -and $content -ne $originalContent) {
            Set-Content -Path $file.FullName -Value $content -NoNewline -ErrorAction Stop
            Write-Host "  ✅ $($file.Name)" -ForegroundColor Green
            $fixedCount++
        }
    }
    catch {
        Write-Host "  ⚠️ Error processing $($file.Name): $_" -ForegroundColor Yellow
    }
}

Write-Host "`n🎯 Fixed $fixedCount files with missing imports" -ForegroundColor Cyan
