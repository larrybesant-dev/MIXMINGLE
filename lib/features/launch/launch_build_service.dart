/// Launch Build Service
///
/// Manages iOS and Android build preparation for TestFlight
/// and Play Store internal/production releases.
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/analytics/analytics_service.dart';

/// Service for managing build preparation and verification
class LaunchBuildService {
  static LaunchBuildService? _instance;
  static LaunchBuildService get instance =>
      _instance ??= LaunchBuildService._();

  LaunchBuildService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // ignore: unused_field
  final AnalyticsService _analytics = AnalyticsService.instance;

  // Build configuration
  // ignore: unused_field
  static const String _buildConfigDoc = 'app_config/builds';

  // ============================================================
  // IOS BUILD
  // ============================================================

  /// Build iOS for internal testing (TestFlight)
  Future<BuildResult> buildIosInternal({
    String flavor = 'production',
    bool exportComplianceRequired = false,
  }) async {
    try {
      debugPrint('ðŸ”§ [Build] Starting iOS internal build...');

      // Verify prerequisites
      final prereqResult = await _verifyIosPrerequisites();
      if (!prereqResult.passed) {
        return BuildResult(
          success: false,
          platform: BuildPlatform.ios,
          error: 'Prerequisites failed: ${prereqResult.failures.join(', ')}',
        );
      }

      // Log build start
      await _logBuildStart(BuildPlatform.ios, flavor, 'internal');

      // Build command (to be run manually or via CI)
      final buildCommand = '''
flutter build ios --flavor $flavor --release
cd ios && xcodebuild -exportArchive -archivePath build/Runner.xcarchive -exportPath build/ipa -exportOptionsPlist ExportOptions.plist
''';

      debugPrint('ðŸ“‹ [Build] iOS build command:\n$buildCommand');

      // Record build info
      await _recordBuildInfo(
        platform: BuildPlatform.ios,
        flavor: flavor,
        buildType: 'internal',
        exportCompliance: exportComplianceRequired,
      );

      return BuildResult(
        success: true,
        platform: BuildPlatform.ios,
        buildCommand: buildCommand,
        message: 'iOS internal build prepared. Run the command to build.',
      );
    } catch (e) {
      debugPrint('âŒ [Build] iOS internal build failed: $e');
      return BuildResult(
        success: false,
        platform: BuildPlatform.ios,
        error: e.toString(),
      );
    }
  }

  /// Build iOS for production (App Store)
  Future<BuildResult> buildIosProduction({
    required String version,
    required int buildNumber,
  }) async {
    try {
      debugPrint('ðŸ”§ [Build] Starting iOS production build...');

      final prereqResult = await _verifyIosPrerequisites();
      if (!prereqResult.passed) {
        return BuildResult(
          success: false,
          platform: BuildPlatform.ios,
          error: 'Prerequisites failed: ${prereqResult.failures.join(', ')}',
        );
      }

      await _logBuildStart(BuildPlatform.ios, 'production', 'production');

      final buildCommand = '''
flutter build ios --flavor production --release --build-name=$version --build-number=$buildNumber
cd ios && xcodebuild -exportArchive -archivePath build/Runner.xcarchive -exportPath build/ipa -exportOptionsPlist ExportOptions.plist
''';

      await _recordBuildInfo(
        platform: BuildPlatform.ios,
        flavor: 'production',
        buildType: 'production',
        version: version,
        buildNumber: buildNumber,
      );

      return BuildResult(
        success: true,
        platform: BuildPlatform.ios,
        buildCommand: buildCommand,
        version: version,
        buildNumber: buildNumber,
        message: 'iOS production build prepared.',
      );
    } catch (e) {
      debugPrint('âŒ [Build] iOS production build failed: $e');
      return BuildResult(
        success: false,
        platform: BuildPlatform.ios,
        error: e.toString(),
      );
    }
  }

  // ============================================================
  // ANDROID BUILD
  // ============================================================

  /// Build Android for internal testing (Play Console Internal)
  Future<BuildResult> buildAndroidInternal({
    String flavor = 'production',
  }) async {
    try {
      debugPrint('ðŸ”§ [Build] Starting Android internal build...');

      final prereqResult = await _verifyAndroidPrerequisites();
      if (!prereqResult.passed) {
        return BuildResult(
          success: false,
          platform: BuildPlatform.android,
          error: 'Prerequisites failed: ${prereqResult.failures.join(', ')}',
        );
      }

      await _logBuildStart(BuildPlatform.android, flavor, 'internal');

      final buildCommand = '''
flutter build appbundle --flavor $flavor --release
# Upload to Play Console Internal Testing track
''';

      await _recordBuildInfo(
        platform: BuildPlatform.android,
        flavor: flavor,
        buildType: 'internal',
      );

      return BuildResult(
        success: true,
        platform: BuildPlatform.android,
        buildCommand: buildCommand,
        message: 'Android internal build prepared.',
      );
    } catch (e) {
      debugPrint('âŒ [Build] Android internal build failed: $e');
      return BuildResult(
        success: false,
        platform: BuildPlatform.android,
        error: e.toString(),
      );
    }
  }

  /// Build Android for production (Play Store)
  Future<BuildResult> buildAndroidProduction({
    required String version,
    required int buildNumber,
  }) async {
    try {
      debugPrint('ðŸ”§ [Build] Starting Android production build...');

      final prereqResult = await _verifyAndroidPrerequisites();
      if (!prereqResult.passed) {
        return BuildResult(
          success: false,
          platform: BuildPlatform.android,
          error: 'Prerequisites failed: ${prereqResult.failures.join(', ')}',
        );
      }

      await _logBuildStart(BuildPlatform.android, 'production', 'production');

      final buildCommand = '''
flutter build appbundle --flavor production --release --build-name=$version --build-number=$buildNumber
# Upload to Play Console Production track
''';

      await _recordBuildInfo(
        platform: BuildPlatform.android,
        flavor: 'production',
        buildType: 'production',
        version: version,
        buildNumber: buildNumber,
      );

      return BuildResult(
        success: true,
        platform: BuildPlatform.android,
        buildCommand: buildCommand,
        version: version,
        buildNumber: buildNumber,
        message: 'Android production build prepared.',
      );
    } catch (e) {
      debugPrint('âŒ [Build] Android production build failed: $e');
      return BuildResult(
        success: false,
        platform: BuildPlatform.android,
        error: e.toString(),
      );
    }
  }

  // ============================================================
  // VERIFICATION METHODS
  // ============================================================

  /// Verify flavor configurations exist
  Future<FlavorVerificationResult> verifyFlavors() async {
    try {
      debugPrint('ðŸ” [Build] Verifying flavors...');

      final checks = <String, bool>{};
      final failures = <String>[];

      // Check Android flavors (build.gradle)
      const androidGradlePath = 'android/app/build.gradle';
      if (File(androidGradlePath).existsSync()) {
        final content = File(androidGradlePath).readAsStringSync();
        checks['android_development'] = content.contains('development {');
        checks['android_staging'] = content.contains('staging {');
        checks['android_production'] = content.contains('production {');

        if (!checks['android_development']!) failures.add('Android development flavor missing');
        if (!checks['android_production']!) failures.add('Android production flavor missing');
      } else {
        failures.add('Android build.gradle not found');
      }

      // Check iOS schemes (xcscheme)
      const iosSchemesPath = 'ios/Runner.xcodeproj/xcshareddata/xcschemes';
      if (Directory(iosSchemesPath).existsSync()) {
        final schemes = Directory(iosSchemesPath).listSync();
        checks['ios_development'] = schemes.any((f) => f.path.contains('development'));
        checks['ios_production'] = schemes.any((f) => f.path.contains('production'));

        if (!checks['ios_production']!) {
          // Production might be named "Runner"
          checks['ios_production'] = schemes.any((f) => f.path.contains('Runner'));
        }
      }

      final passed = failures.isEmpty;

      debugPrint(passed
          ? 'âœ… [Build] Flavors verified'
          : 'âŒ [Build] Flavor verification failed');

      return FlavorVerificationResult(
        passed: passed,
        checks: checks,
        failures: failures,
      );
    } catch (e) {
      debugPrint('âŒ [Build] Flavor verification error: $e');
      return FlavorVerificationResult(
        passed: false,
        checks: {},
        failures: [e.toString()],
      );
    }
  }

  /// Verify app icons are configured
  Future<IconVerificationResult> verifyIcons() async {
    try {
      debugPrint('ðŸ” [Build] Verifying icons...');

      final checks = <String, bool>{};
      final failures = <String>[];

      // Check Android icons
      const androidResPath = 'android/app/src/main/res';
      final androidIconPaths = [
        '$androidResPath/mipmap-hdpi/ic_launcher.png',
        '$androidResPath/mipmap-mdpi/ic_launcher.png',
        '$androidResPath/mipmap-xhdpi/ic_launcher.png',
        '$androidResPath/mipmap-xxhdpi/ic_launcher.png',
        '$androidResPath/mipmap-xxxhdpi/ic_launcher.png',
      ];

      for (final path in androidIconPaths) {
        final exists = File(path).existsSync();
        final density = path.split('/').reversed.skip(1).first;
        checks['android_$density'] = exists;
        if (!exists) failures.add('Missing Android icon: $density');
      }

      // Check iOS icons
      const iosIconPath = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
      if (Directory(iosIconPath).existsSync()) {
        final contents = File('$iosIconPath/Contents.json').readAsStringSync();
        checks['ios_icon_contents'] = contents.contains('"filename"');

        // Check for common icon sizes
        final files = Directory(iosIconPath).listSync();
        checks['ios_icons_exist'] = files.length > 5; // Should have multiple icon files
      } else {
        failures.add('iOS AppIcon.appiconset not found');
      }

      final passed = failures.isEmpty;

      debugPrint(passed
          ? 'âœ… [Build] Icons verified'
          : 'âŒ [Build] Icon verification failed');

      return IconVerificationResult(
        passed: passed,
        checks: checks,
        failures: failures,
      );
    } catch (e) {
      debugPrint('âŒ [Build] Icon verification error: $e');
      return IconVerificationResult(
        passed: false,
        checks: {},
        failures: [e.toString()],
      );
    }
  }

  /// Verify splash screens are configured
  Future<SplashVerificationResult> verifySplash() async {
    try {
      debugPrint('ðŸ” [Build] Verifying splash screens...');

      final checks = <String, bool>{};
      final failures = <String>[];

      // Check flutter_native_splash config in pubspec.yaml
      const pubspecPath = 'pubspec.yaml';
      if (File(pubspecPath).existsSync()) {
        final content = File(pubspecPath).readAsStringSync();
        checks['native_splash_config'] = content.contains('flutter_native_splash');

        if (!checks['native_splash_config']!) {
          failures.add('flutter_native_splash not configured in pubspec.yaml');
        }
      }

      // Check Android splash
      const androidSplashPath = 'android/app/src/main/res/drawable/launch_background.xml';
      checks['android_splash'] = File(androidSplashPath).existsSync();
      if (!checks['android_splash']!) {
        failures.add('Android launch_background.xml not found');
      }

      // Check iOS splash (LaunchScreen.storyboard)
      const iosSplashPath = 'ios/Runner/Base.lproj/LaunchScreen.storyboard';
      checks['ios_splash'] = File(iosSplashPath).existsSync();
      if (!checks['ios_splash']!) {
        failures.add('iOS LaunchScreen.storyboard not found');
      }

      final passed = failures.isEmpty;

      debugPrint(passed
          ? 'âœ… [Build] Splash screens verified'
          : 'âŒ [Build] Splash verification failed');

      return SplashVerificationResult(
        passed: passed,
        checks: checks,
        failures: failures,
      );
    } catch (e) {
      debugPrint('âŒ [Build] Splash verification error: $e');
      return SplashVerificationResult(
        passed: false,
        checks: {},
        failures: [e.toString()],
      );
    }
  }

  /// Verify privacy manifests (iOS 17+ requirement)
  Future<PrivacyManifestResult> verifyPrivacyManifests() async {
    try {
      debugPrint('ðŸ” [Build] Verifying privacy manifests...');

      final checks = <String, bool>{};
      final failures = <String>[];

      // Check iOS PrivacyInfo.xcprivacy
      const privacyManifestPath = 'ios/Runner/PrivacyInfo.xcprivacy';
      checks['privacy_manifest_exists'] = File(privacyManifestPath).existsSync();

      if (checks['privacy_manifest_exists']!) {
        final content = File(privacyManifestPath).readAsStringSync();

        // Check required keys
        checks['nsPrivacyTracking'] = content.contains('NSPrivacyTracking');
        checks['nsPrivacyTrackingDomains'] = content.contains('NSPrivacyTrackingDomains');
        checks['nsPrivacyCollectedDataTypes'] = content.contains('NSPrivacyCollectedDataTypes');
        checks['nsPrivacyAccessedAPITypes'] = content.contains('NSPrivacyAccessedAPITypes');

        // Check for required API declarations (iOS 17+)
        final requiredAPIs = [
          'NSPrivacyAccessedAPICategoryFileTimestamp',
          'NSPrivacyAccessedAPICategorySystemBootTime',
          'NSPrivacyAccessedAPICategoryDiskSpace',
          'NSPrivacyAccessedAPICategoryUserDefaults',
        ];

        for (final api in requiredAPIs) {
          if (!content.contains(api)) {
            // Not all APIs are required for all apps, just note them
            debugPrint('â„¹ï¸ [Build] API not declared: $api');
          }
        }
      } else {
        failures.add('iOS PrivacyInfo.xcprivacy not found (required for iOS 17+)');
      }

      // Check Info.plist for usage descriptions
      const infoPlistPath = 'ios/Runner/Info.plist';
      if (File(infoPlistPath).existsSync()) {
        final content = File(infoPlistPath).readAsStringSync();

        checks['camera_usage'] = content.contains('NSCameraUsageDescription');
        checks['microphone_usage'] = content.contains('NSMicrophoneUsageDescription');
        checks['photo_usage'] = content.contains('NSPhotoLibraryUsageDescription');

        if (!checks['camera_usage']!) failures.add('Missing NSCameraUsageDescription');
        if (!checks['microphone_usage']!) failures.add('Missing NSMicrophoneUsageDescription');
      }

      final passed = failures.isEmpty;

      debugPrint(passed
          ? 'âœ… [Build] Privacy manifests verified'
          : 'âŒ [Build] Privacy manifest verification failed');

      return PrivacyManifestResult(
        passed: passed,
        checks: checks,
        failures: failures,
      );
    } catch (e) {
      debugPrint('âŒ [Build] Privacy manifest verification error: $e');
      return PrivacyManifestResult(
        passed: false,
        checks: {},
        failures: [e.toString()],
      );
    }
  }

  /// Run all verifications
  Future<FullVerificationResult> runAllVerifications() async {
    final flavors = await verifyFlavors();
    final icons = await verifyIcons();
    final splash = await verifySplash();
    final privacy = await verifyPrivacyManifests();

    final allPassed = flavors.passed && icons.passed && splash.passed && privacy.passed;

    return FullVerificationResult(
      passed: allPassed,
      flavors: flavors,
      icons: icons,
      splash: splash,
      privacy: privacy,
    );
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  Future<PrerequisiteResult> _verifyIosPrerequisites() async {
    final failures = <String>[];

    // Check Xcode is available (only on macOS)
    if (Platform.isMacOS) {
      final result = await Process.run('xcodebuild', ['-version']);
      if (result.exitCode != 0) {
        failures.add('Xcode not installed or not configured');
      }
    }

    // Check ios folder exists
    if (!Directory('ios').existsSync()) {
      failures.add('iOS folder not found');
    }

    // Check Podfile exists
    if (!File('ios/Podfile').existsSync()) {
      failures.add('Podfile not found');
    }

    return PrerequisiteResult(
      passed: failures.isEmpty,
      failures: failures,
    );
  }

  Future<PrerequisiteResult> _verifyAndroidPrerequisites() async {
    final failures = <String>[];

    // Check android folder exists
    if (!Directory('android').existsSync()) {
      failures.add('Android folder not found');
    }

    // Check key.properties exists (for signing)
    if (!File('android/key.properties').existsSync()) {
      debugPrint('âš ï¸ [Build] key.properties not found - signing may fail');
      // Don't fail, just warn
    }

    // Check build.gradle exists
    if (!File('android/app/build.gradle').existsSync()) {
      failures.add('build.gradle not found');
    }

    return PrerequisiteResult(
      passed: failures.isEmpty,
      failures: failures,
    );
  }

  Future<void> _logBuildStart(
    BuildPlatform platform,
    String flavor,
    String buildType,
  ) async {
    await _analytics.logEvent(
      name: 'build_started',
      parameters: {
        'platform': platform.name,
        'flavor': flavor,
        'build_type': buildType,
      },
    );
  }

  Future<void> _recordBuildInfo({
    required BuildPlatform platform,
    required String flavor,
    required String buildType,
    String? version,
    int? buildNumber,
    bool? exportCompliance,
  }) async {
    try {
      await _firestore.collection('builds').add({
        'platform': platform.name,
        'flavor': flavor,
        'buildType': buildType,
        'version': version,
        'buildNumber': buildNumber,
        'exportCompliance': exportCompliance,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'prepared',
      });
    } catch (e) {
      debugPrint('âš ï¸ [Build] Failed to record build info: $e');
    }
  }
}

// ============================================================
// ENUMS
// ============================================================

enum BuildPlatform {
  ios,
  android,
}

// ============================================================
// RESULT CLASSES
// ============================================================

class BuildResult {
  final bool success;
  final BuildPlatform platform;
  final String? buildCommand;
  final String? version;
  final int? buildNumber;
  final String? message;
  final String? error;

  const BuildResult({
    required this.success,
    required this.platform,
    this.buildCommand,
    this.version,
    this.buildNumber,
    this.message,
    this.error,
  });
}

class PrerequisiteResult {
  final bool passed;
  final List<String> failures;

  const PrerequisiteResult({
    required this.passed,
    required this.failures,
  });
}

class FlavorVerificationResult {
  final bool passed;
  final Map<String, bool> checks;
  final List<String> failures;

  const FlavorVerificationResult({
    required this.passed,
    required this.checks,
    required this.failures,
  });
}

class IconVerificationResult {
  final bool passed;
  final Map<String, bool> checks;
  final List<String> failures;

  const IconVerificationResult({
    required this.passed,
    required this.checks,
    required this.failures,
  });
}

class SplashVerificationResult {
  final bool passed;
  final Map<String, bool> checks;
  final List<String> failures;

  const SplashVerificationResult({
    required this.passed,
    required this.checks,
    required this.failures,
  });
}

class PrivacyManifestResult {
  final bool passed;
  final Map<String, bool> checks;
  final List<String> failures;

  const PrivacyManifestResult({
    required this.passed,
    required this.checks,
    required this.failures,
  });
}

class FullVerificationResult {
  final bool passed;
  final FlavorVerificationResult flavors;
  final IconVerificationResult icons;
  final SplashVerificationResult splash;
  final PrivacyManifestResult privacy;

  const FullVerificationResult({
    required this.passed,
    required this.flavors,
    required this.icons,
    required this.splash,
    required this.privacy,
  });

  List<String> get allFailures => [
        ...flavors.failures,
        ...icons.failures,
        ...splash.failures,
        ...privacy.failures,
      ];
}
