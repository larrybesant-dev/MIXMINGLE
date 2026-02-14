import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service for A/B testing experiments using Firebase Remote Config
final abTestingServiceProvider = Provider<ABTestingService>((ref) {
  return ABTestingService();
});

class ABTestingService {
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
  bool _initialized = false;

  /// Initialize Remote Config with default values and fetch latest config
  Future<void> initialize() async {
    if (_initialized) return;

    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ),
    );

    // Set default values for experiments
    await _remoteConfig.setDefaults({
      'event_layout': 'vertical', // 'vertical' or 'horizontal'
      'onboarding_flow': 'short', // 'short' or 'long'
      'notification_timing': '5', // minutes before event
      'referral_reward': 'boost', // 'boost', 'badge', 'premium'
      'room_preview_enabled': 'false', // 'true' or 'false'
    });

    await _remoteConfig.fetchAndActivate();
    _initialized = true;
  }

  /// Get event layout variant ('vertical' or 'horizontal')
  String getEventLayout() {
    return _remoteConfig.getString('event_layout');
  }

  /// Get onboarding flow variant ('short' or 'long')
  String getOnboardingFlow() {
    return _remoteConfig.getString('onboarding_flow');
  }

  /// Get notification timing in minutes
  int getNotificationTiming() {
    return _remoteConfig.getInt('notification_timing');
  }

  /// Get referral reward type ('boost', 'badge', 'premium')
  String getReferralReward() {
    return _remoteConfig.getString('referral_reward');
  }

  /// Check if room preview is enabled
  bool isRoomPreviewEnabled() {
    return _remoteConfig.getBool('room_preview_enabled');
  }

  /// Get all active experiment values for debugging
  Map<String, dynamic> getAllExperimentValues() {
    return {
      'event_layout': getEventLayout(),
      'onboarding_flow': getOnboardingFlow(),
      'notification_timing': getNotificationTiming(),
      'referral_reward': getReferralReward(),
      'room_preview_enabled': isRoomPreviewEnabled(),
    };
  }
}
