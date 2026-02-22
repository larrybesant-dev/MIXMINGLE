/// Release Utilities
///
/// Helper utilities for release management, version checking, and update prompts.
library;

import 'package:flutter/foundation.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Check for app updates and version compatibility
class UpdateChecker {
  static UpdateChecker? _instance;
  static UpdateChecker get instance => _instance ??= UpdateChecker._();

  UpdateChecker._();

  /// Check if force update is required
  Future<UpdateInfo> checkForUpdates() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;

      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ));

      await remoteConfig.setDefaults({
        'min_supported_version': '1.0.0',
        'latest_version': '1.0.0',
        'force_update': false,
        'update_message': '',
        'update_url_ios': 'https://apps.apple.com/app/mix-mingle/id123456789',
        'update_url_android': 'https://play.google.com/store/apps/details?id=com.mixmingle.app',
      });

      await remoteConfig.fetchAndActivate();

      final minVersion = remoteConfig.getString('min_supported_version');
      final latestVersion = remoteConfig.getString('latest_version');
      final forceUpdate = remoteConfig.getBool('force_update');
      final updateMessage = remoteConfig.getString('update_message');
      final updateUrlIos = remoteConfig.getString('update_url_ios');
      final updateUrlAndroid = remoteConfig.getString('update_url_android');

      const currentVersion = '1.0.0'; // From AppVersion

      return UpdateInfo(
        currentVersion: currentVersion,
        minSupportedVersion: minVersion,
        latestVersion: latestVersion,
        forceUpdate: forceUpdate || _isVersionLower(currentVersion, minVersion),
        updateAvailable: _isVersionLower(currentVersion, latestVersion),
        updateMessage: updateMessage,
        updateUrl: defaultTargetPlatform == TargetPlatform.iOS
            ? updateUrlIos
            : updateUrlAndroid,
      );
    } catch (e) {
      debugPrint('âŒ [UpdateChecker] Failed to check for updates: $e');
      return UpdateInfo.noUpdate();
    }
  }

  /// Compare version strings (e.g., "1.0.0" < "1.0.1")
  bool _isVersionLower(String current, String target) {
    final currentParts = current.split('.').map(int.parse).toList();
    final targetParts = target.split('.').map(int.parse).toList();

    for (var i = 0; i < 3; i++) {
      final c = i < currentParts.length ? currentParts[i] : 0;
      final t = i < targetParts.length ? targetParts[i] : 0;
      if (c < t) return true;
      if (c > t) return false;
    }
    return false;
  }
}

/// Update information
class UpdateInfo {
  final String currentVersion;
  final String minSupportedVersion;
  final String latestVersion;
  final bool forceUpdate;
  final bool updateAvailable;
  final String updateMessage;
  final String updateUrl;

  const UpdateInfo({
    required this.currentVersion,
    required this.minSupportedVersion,
    required this.latestVersion,
    required this.forceUpdate,
    required this.updateAvailable,
    required this.updateMessage,
    required this.updateUrl,
  });

  factory UpdateInfo.noUpdate() => const UpdateInfo(
        currentVersion: '1.0.0',
        minSupportedVersion: '1.0.0',
        latestVersion: '1.0.0',
        forceUpdate: false,
        updateAvailable: false,
        updateMessage: '',
        updateUrl: '',
      );

  bool get needsAction => forceUpdate || updateAvailable;
}

/// Build information for debugging
class BuildInfo {
  static const String appVersion = '1.0.0';
  static const int buildNumber = 1;
  static const String buildType = kReleaseMode
      ? 'release'
      : kProfileMode
          ? 'profile'
          : 'debug';

  static String get fullVersion => '$appVersion+$buildNumber ($buildType)';

  static Map<String, dynamic> toMap() => {
        'version': appVersion,
        'buildNumber': buildNumber,
        'buildType': buildType,
        'fullVersion': fullVersion,
      };
}
