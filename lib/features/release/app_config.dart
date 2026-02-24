/// App Configuration for Release Engineering
///
/// Provides environment-specific configuration for dev, staging, and production builds.
library;

import 'package:flutter/foundation.dart';

/// Available build flavors
enum AppFlavor {
  dev,
  staging,
  production,
}

/// App configuration singleton
class AppConfig {
  static AppConfig? _instance;
  static AppConfig get instance => _instance ?? AppConfig._();

  AppConfig._();

  /// Current flavor (set at app startup based on build)
  AppFlavor _flavor = AppFlavor.production;
  AppFlavor get flavor => _flavor;

  /// Initialize with specific flavor
  static void initialize(AppFlavor flavor) {
    _instance = AppConfig._();
    _instance!._flavor = flavor;
    debugPrint('ðŸ·ï¸ [AppConfig] Initialized with flavor: ${flavor.name}');
  }

  /// App name based on flavor
  String get appName {
    switch (_flavor) {
      case AppFlavor.dev:
        return 'Mix & Mingle (Dev)';
      case AppFlavor.staging:
        return 'Mix & Mingle (Staging)';
      case AppFlavor.production:
        return 'Mix & Mingle';
    }
  }

  /// Bundle identifier based on flavor
  String get bundleId {
    switch (_flavor) {
      case AppFlavor.dev:
        return 'com.mixmingle.app.dev';
      case AppFlavor.staging:
        return 'com.mixmingle.app.staging';
      case AppFlavor.production:
        return 'com.mixmingle.app';
    }
  }

  /// Firebase project ID based on flavor
  String get firebaseProjectId {
    switch (_flavor) {
      case AppFlavor.dev:
        return 'mix-mingle-dev';
      case AppFlavor.staging:
        return 'mix-mingle-staging';
      case AppFlavor.production:
        return 'mix-mingle-prod';
    }
  }

  /// API base URL based on flavor
  String get apiBaseUrl {
    switch (_flavor) {
      case AppFlavor.dev:
        return 'https://api-dev.mixmingle.app';
      case AppFlavor.staging:
        return 'https://api-staging.mixmingle.app';
      case AppFlavor.production:
        return 'https://api.mixmingle.app';
    }
  }

  /// Whether analytics should be enabled
  bool get analyticsEnabled {
    switch (_flavor) {
      case AppFlavor.dev:
        return false;
      case AppFlavor.staging:
        return true;
      case AppFlavor.production:
        return true;
    }
  }

  /// Whether crashlytics should be enabled
  bool get crashlyticsEnabled {
    switch (_flavor) {
      case AppFlavor.dev:
        return false;
      case AppFlavor.staging:
        return true;
      case AppFlavor.production:
        return true;
    }
  }

  /// Whether performance monitoring should be enabled
  bool get performanceEnabled {
    switch (_flavor) {
      case AppFlavor.dev:
        return false;
      case AppFlavor.staging:
        return true;
      case AppFlavor.production:
        return true;
    }
  }

  /// Debug logging enabled
  bool get debugLogging {
    switch (_flavor) {
      case AppFlavor.dev:
        return true;
      case AppFlavor.staging:
        return true;
      case AppFlavor.production:
        return kDebugMode;
    }
  }

  /// RevenueCat API key based on flavor
  String get revenueCatApiKey {
    switch (_flavor) {
      case AppFlavor.dev:
        return const String.fromEnvironment('REVENUECAT_API_KEY_DEV', defaultValue: '');
      case AppFlavor.staging:
        return const String.fromEnvironment('REVENUECAT_API_KEY_STAGING', defaultValue: '');
      case AppFlavor.production:
        return const String.fromEnvironment('REVENUECAT_API_KEY', defaultValue: '');
    }
  }

  /// Agora App ID based on flavor
  String get agoraAppId {
    switch (_flavor) {
      case AppFlavor.dev:
        return const String.fromEnvironment('AGORA_APP_ID_DEV', defaultValue: '');
      case AppFlavor.staging:
        return const String.fromEnvironment('AGORA_APP_ID_STAGING', defaultValue: '');
      case AppFlavor.production:
        return const String.fromEnvironment('AGORA_APP_ID', defaultValue: '');
    }
  }
}

/// App version information
class AppVersion {
  static const String version = '1.0.0';
  static const int buildNumber = 1;
  static const String fullVersion = '$version+$buildNumber';

  /// Minimum supported versions
  static const String minIosVersion = '14.0';
  static const String minAndroidSdk = '24'; // Android 7.0

  /// Release date
  static final DateTime releaseDate = DateTime(2026, 2, 9);
}
