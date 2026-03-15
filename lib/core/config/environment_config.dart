/// Environment configuration for different build flavors
enum Environment { development, staging, production }

class EnvironmentConfig {
  // Use --dart-define=ENV=dev|staging|production
  // Defaults to production if not specified for safety
  static Environment current = const String.fromEnvironment('ENV') == 'dev'
      ? Environment.development
      : const String.fromEnvironment('ENV') == 'staging'
          ? Environment.staging
          : Environment.production;

  // Firebase project IDs
  static const String firebaseProjectDev = 'mixmingle-dev';
  static const String firebaseProjectStaging = 'mixmingle-staging';
  static const String firebaseProjectProd = 'mixmingle-prod';

  // Agora App IDs
  static const String agoraAppIdDev = 'dev_agora_id';
  static const String agoraAppIdStaging = 'staging_agora_id';
  static const String agoraAppIdProd = 'ec1b578586d24976a89d787d9ee4d5c7';

  // API endpoints
    static const String apiUrlDev =
      'https://us-central1-mix-and-mingle-v2.cloudfunctions.net';
    static const String apiUrlStaging =
      'https://us-central1-mix-and-mingle-v2.cloudfunctions.net';
    static const String apiUrlProd =
      'https://us-central1-mix-and-mingle-v2.cloudfunctions.net';

  // Feature flags
  static const Map<String, bool> featureFlags = {
    'enable_payment': false, // Disable for MVP
    'enable_live_streaming': true,
// SPEED_DATING_FEATURE_REMOVED
    'enable_events': true,
    'enable_matching': true,
    'enable_groups': false, // Future feature
    'enable_ai_moderation': false, // Gradual rollout
    'maintenance_mode': false,
  };

  // Rate limiting
  static const int messagesPerMinute = 30;
  static const int roomCreationsPerHour = 10;
  static const int reportSubmissionsPerDay = 20;

  // Thresholds for safety
  static const int reportThresholdForUserSuspension = 5;
  static const int warningThresholdBeforeSuspension = 3;

  // API timeouts (seconds)
  static const int networkTimeout = 30;
  static const int slowNetworkTimeout = 60;

  static bool get isDevelopment => current == Environment.development;
  static bool get isStaging => current == Environment.staging;
  static bool get isProduction => current == Environment.production;

  static bool isFeatureEnabled(String featureName) {
    return featureFlags[featureName] ?? false;
  }

  static String getApiUrl() {
    switch (current) {
      case Environment.development:
        return apiUrlDev;
      case Environment.staging:
        return apiUrlStaging;
      case Environment.production:
        return apiUrlProd;
    }
  }

  static String getAgoraAppId() {
    switch (current) {
      case Environment.development:
        return agoraAppIdDev;
      case Environment.staging:
        return agoraAppIdStaging;
      case Environment.production:
        return agoraAppIdProd;
    }
  }

  static String getFirebaseProject() {
    switch (current) {
      case Environment.development:
        return firebaseProjectDev;
      case Environment.staging:
        return firebaseProjectStaging;
      case Environment.production:
        return firebaseProjectProd;
    }
  }
}
