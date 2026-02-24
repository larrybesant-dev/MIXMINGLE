#!/usr/bin/env pwsh
# ==============================================
# Flutter Web Auto-Fix Script
# Fix missing imports and duplicate 'child:' params
# Run in your project root (C:\Users\LARRY\MIXMINGLE)
# ==============================================

Write-Host "🔧 Flutter Web Auto-Fix Script" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

$fixedFiles = 0
$createdStubs = 0
$skippedExisting = 0

# 1️⃣ Define missing files (paths relative to lib/)
$missingFiles = @{
    # Utility files
    "core/utils/async_value_utils.dart" = @"
/// Async value utilities for error handling
import 'package:flutter_riverpod/flutter_riverpod.dart';

extension AsyncValueUI on AsyncValue {
  void showSnackBarOnError(context) {
    if (hasError) {
      // TODO: Implement snackbar display
    }
  }
}
"@
    "core/utils/navigation_utils.dart" = @"
/// Navigation utilities
import 'package:flutter/material.dart';

class NavigationUtils {
  static Future<T?> pushNamed<T>(BuildContext context, String routeName, {Object? arguments}) {
    return Navigator.of(context).pushNamed<T>(routeName, arguments: arguments);
  }

  static void pop<T>(BuildContext context, [T? result]) {
    Navigator.of(context).pop(result);
  }
}
"@
    "core/utils/firestore_utils.dart" = @"
/// Firestore utilities
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreUtils {
  static CollectionReference collection(String path) {
    return FirebaseFirestore.instance.collection(path);
  }

  static DocumentReference doc(String path) {
    return FirebaseFirestore.instance.doc(path);
  }
}
"@

    # Widget files
    "shared/widgets/offline_widgets.dart" = @"
/// Offline state widgets
import 'package:flutter/material.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.red,
      padding: const EdgeInsets.all(8),
      child: const Text('Offline', style: TextStyle(color: Colors.white)),
    );
  }
}
"@
    "shared/widgets/empty_states.dart" = @"
/// Empty state widgets
import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final String message;
  const EmptyState({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(message, style: const TextStyle(fontSize: 16, color: Colors.grey)),
    );
  }
}
"@

    # Provider files
    "providers/speed_dating_controller.dart" = @"
/// Speed dating controller (disabled feature)
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SpeedDatingController extends StateNotifier<void> {
  SpeedDatingController() : super(null);

  // TODO: Implement when feature is re-enabled
}

final speedDatingControllerProvider = StateNotifierProvider<SpeedDatingController, void>((ref) {
  return SpeedDatingController();
});
"@
    "providers/profile_controller.dart" = @"
/// Profile controller
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileController extends StateNotifier<void> {
  ProfileController() : super(null);

  // TODO: Implement profile management
}

final profileControllerProvider = StateNotifierProvider<ProfileController, void>((ref) {
  return ProfileController();
});
"@
    "features/onboarding/providers/onboarding_controller.dart" = @"
/// Onboarding controller
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingController extends StateNotifier<void> {
  OnboardingController() : super(null);

  bool isAgeVerified() => true; // TODO: Implement
  bool isProfileComplete() => true; // TODO: Implement
}

final onboardingControllerProvider = StateNotifierProvider<OnboardingController, void>((ref) {
  return OnboardingController();
});
"@
    "features/onboarding/screens/age_gate_page.dart" = @"
/// Age gate page
import 'package:flutter/material.dart';

class AgeGatePage extends StatelessWidget {
  const AgeGatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: const Text('Age Verification Required'),
      ),
    );
  }
}
"@
    "features/onboarding/onboarding_flow.dart" = @"
/// Onboarding flow
import 'package:flutter/material.dart';

class OnboardingFlow extends StatelessWidget {
  const OnboardingFlow({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: const Text('Onboarding Flow'),
      ),
    );
  }
}
"@

    # Shared model files
    "shared/models/speed_dating_round.dart" = @"
/// Speed dating round model
class SpeedDatingRound {
  final String id;
  final String sessionId;

  SpeedDatingRound({required this.id, required this.sessionId});
}
"@
    "shared/models/speed_dating_result.dart" = @"
/// Speed dating result model
class SpeedDatingResult {
  final String id;
  final bool matched;

  SpeedDatingResult({required this.id, required this.matched});
}
"@

    # Other missing files
    "shared/club_background.dart" = @"
/// Club background widget
import 'package:flutter/material.dart';

class ClubBackground extends StatelessWidget {
  final Widget child;
  const ClubBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple, Colors.black],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: child,
    );
  }
}
"@
    "shared/glow_text.dart" = @"
/// Glowing text widget
import 'package:flutter/material.dart';

class GlowText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const GlowText(this.text, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: style);
  }
}
"@
    "shared/neon_button.dart" = @"
/// Neon button widget
import 'package:flutter/material.dart';

class NeonButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  const NeonButton({super.key, required this.text, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(text),
    );
  }
}
"@
    "shared/auth_guard.dart" = @"
/// Authentication guard widget
import 'package:flutter/material.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;
  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // TODO: Check auth state
    return child;
  }
}
"@
    "shared/gift_selector.dart" = @"
/// Gift selector widget
import 'package:flutter/material.dart';

class GiftSelector extends StatelessWidget {
  const GiftSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: const Text('Gift Selector'),
    );
  }
}
"@
    "shared/loading_states_guide.dart" = @"
/// Loading states guide
import 'package:flutter/material.dart';

class LoadingStatesGuide extends StatelessWidget {
  const LoadingStatesGuide({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
"@
    "providers/providers.dart" = @"
/// Central providers export file
export 'package:flutter_riverpod/flutter_riverpod.dart';

// TODO: Export all app providers here
"@
}

# Create missing stub files
Write-Host "📄 Creating missing stub files..." -ForegroundColor Yellow
foreach ($file in $missingFiles.Keys) {
    $fullPath = Join-Path -Path $PWD -ChildPath "lib\$file"
    $fullPath = $fullPath -replace '/', '\'
    $dir = Split-Path $fullPath -Parent

    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }

    if (!(Test-Path $fullPath)) {
        Set-Content -Path $fullPath -Value $missingFiles[$file] -Encoding UTF8
        $createdStubs++
        Write-Host "  ✅ Created: $file" -ForegroundColor Green
    }
    else {
        $skippedExisting++
        Write-Host "  ⏭️  Exists: $file, skipping" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "📝 Stub file creation summary:" -ForegroundColor Cyan
Write-Host "  Created: $createdStubs files" -ForegroundColor Green
Write-Host "  Skipped (already exist): $skippedExisting files" -ForegroundColor Gray

# 2️⃣ Fix duplicate 'child:' parameters in all Dart files
Write-Host ""
Write-Host "🔧 Fixing duplicate 'child:' parameters..." -ForegroundColor Yellow

$dartFiles = Get-ChildItem -Path .\lib -Recurse -Filter *.dart
$totalFiles = $dartFiles.Count
$processedFiles = 0

foreach ($file in $dartFiles) {
    $processedFiles++
    $path = $file.FullName
    $content = Get-Content $path -Raw

    # More sophisticated regex to detect duplicate child: in same widget
    # This pattern looks for child: ... child: within the same parentheses context
    $originalContent = $content

    # Pattern 1: Simple consecutive duplicates
    $content = $content -replace '(\bchild\s*:\s*[^,}]+,)\s*child\s*:', '$1/* removed duplicate child: */'

    # Pattern 2: child: with another parameter in between
    $content = $content -replace '(\bchild\s*:\s*[^,}]+,\s*\w+\s*:[^,}]+,)\s*child\s*:', '$1/* removed duplicate child: */'

    if ($content -ne $originalContent) {
        Set-Content -Path $path -Value $content -Encoding UTF8
        $fixedFiles++
        $relativePath = $path.Replace("$PWD\", "")
        Write-Host "  ✅ Fixed: $relativePath" -ForegroundColor Green
    }

    # Progress indicator every 100 files
    if ($processedFiles % 100 -eq 0) {
        Write-Host "  Progress: $processedFiles/$totalFiles files scanned..." -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "📊 AUTO-FIX SUMMARY" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Stub files created: $createdStubs" -ForegroundColor Green
Write-Host "Files with duplicate 'child:' fixed: $fixedFiles" -ForegroundColor Green
Write-Host "Total Dart files scanned: $totalFiles" -ForegroundColor White
Write-Host ""

if ($createdStubs -gt 0 -or $fixedFiles -gt 0) {
    Write-Host "✅ Auto-fix complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Run: flutter clean" -ForegroundColor White
    Write-Host "  2. Run: flutter pub get" -ForegroundColor White
    Write-Host "  3. Run: flutter build web" -ForegroundColor White
    Write-Host ""
    Write-Host "⚠️  Note: Stub files contain placeholder implementations." -ForegroundColor Yellow
    Write-Host "   You may need to implement actual logic in some of them." -ForegroundColor Yellow
} else {
    Write-Host "ℹ️  No changes were needed." -ForegroundColor Cyan
}

Write-Host ""
Write-Host "📄 Detailed log saved to: auto_fix_results.log" -ForegroundColor Cyan

# Create log file
$logContent = @"
Flutter Web Auto-Fix Results
=============================
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

STUB FILES CREATED: $createdStubs
DUPLICATE 'child:' FIXED: $fixedFiles
TOTAL FILES SCANNED: $totalFiles

FILES CREATED:
$(if ($createdStubs -gt 0) { $missingFiles.Keys | Where-Object { !(Test-Path "lib\$_") } | ForEach-Object { "- $_" } } else { "None" })

FILES FIXED:
$(if ($fixedFiles -gt 0) { "See console output above" } else { "None" })

NEXT STEPS:
1. Run: flutter clean
2. Run: flutter pub get
3. Run: flutter build web
4. Review stub files and implement missing logic where needed
5. Test your application thoroughly

NOTES:
- All stub files are basic implementations
- Speed dating features are in _disabled folder and may need updates
- Check core/design_system/design_constants.dart if build still fails
"@

$logContent | Out-File -FilePath "auto_fix_results.log" -Encoding UTF8
