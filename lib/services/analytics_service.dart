import 'package:firebase_analytics/firebase_analytics.dart';

/// Service for handling Firebase Analytics tracking
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;

  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Initialize analytics (call this after Firebase initialization)
  Future<void> initialize() async {
    // Analytics initialization is handled automatically by Firebase
  }

  /// Track screen views
  Future<void> trackScreenView(String screenName, {String? screenClass}) async {
    await _analytics.logEvent(
      name: 'screen_view',
      parameters: {
        'screen_name': screenName,
        'screen_class': screenClass ?? 'Flutter',
      },
    );
  }

  /// Track user login
  Future<void> trackLogin(String method) async {
    await _analytics.logLogin(loginMethod: method);
  }

  /// Track user sign up
  Future<void> trackSignUp(String method) async {
    await _analytics.logSignUp(signUpMethod: method);
  }

  /// Track room creation
  Future<void> trackRoomCreated(String roomId, String roomName) async {
    await _analytics.logEvent(
      name: 'room_created',
      parameters: {
        'room_id': roomId,
        'room_name': roomName,
      },
    );
  }

  /// Track room join
  Future<void> trackRoomJoined(String roomId, String roomName) async {
    await _analytics.logEvent(
      name: 'room_joined',
      parameters: {
        'room_id': roomId,
        'room_name': roomName,
      },
    );
  }

  /// Track video call started
  Future<void> trackVideoCallStarted(String roomId) async {
    await _analytics.logEvent(
      name: 'video_call_started',
      parameters: {
        'room_id': roomId,
      },
    );
  }

  /// Track tip sent
  Future<void> trackTipSent(String recipientId, double amount) async {
    await _analytics.logEvent(
      name: 'tip_sent',
      parameters: {
        'recipient_id': recipientId,
        'amount': amount,
      },
    );
  }

  /// Track message sent
  Future<void> trackMessageSent(String roomId) async {
    await _analytics.logEvent(
      name: 'message_sent',
      parameters: {
        'room_id': roomId,
      },
    );
  }

  /// Track search performed
  Future<void> trackSearch(String searchTerm, String category) async {
    await _analytics.logEvent(
      name: 'search',
      parameters: {
        'search_term': searchTerm,
        'category': category,
      },
    );
  }

  /// Track user engagement
  Future<void> trackEngagement(String action, {Map<String, dynamic>? parameters}) async {
    await _analytics.logEvent(
      name: 'engagement',
      parameters: {
        'action': action,
        ...?parameters,
      },
    );
  }

  /// Set user properties
  Future<void> setUserProperty(String name, String value) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  /// Set user ID
  Future<void> setUserId(String userId) async {
    await _analytics.setUserId(id: userId);
  }

  /// Log generic event
  Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) async {
    await _analytics.logEvent(
      name: name,
      parameters: parameters?.cast<String, Object>(),
    );
  }

  /// Set current screen
  Future<void> setCurrentScreen(String screenName, {String? screenClass}) async {
    await trackScreenView(screenName, screenClass: screenClass);
  }

  /// Track async value load (for provider monitoring)
  Future<void> trackAsyncValueLoad(String providerName, String state, {dynamic error}) async {
    await _analytics.logEvent(
      name: 'async_value_state',
      parameters: {
        'provider': providerName,
        'state': state,
        if (error != null) 'error': error.toString(),
      },
    );
  }

  /// Track async value load with extended metrics
  Future<void> trackAsyncValueLoadExtended({
    required String screenName,
    required String providerName,
    required int durationMs,
    required bool success,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  }) async {
    await _analytics.logEvent(
      name: 'async_value_load_extended',
      parameters: {
        'screen': screenName,
        'provider': providerName,
        'duration_ms': durationMs,
        'success': success,
        if (errorMessage != null) 'error': errorMessage,
        if (metadata != null) ...metadata,
      },
    );
  }

  /// Track retry attempt (stub for analytics tracking)
  Future<void> trackRetryAttempt({
    required String screenName,
    required String providerName,
    required int retryCount,
    required int backoffMs,
    bool? success,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  }) async {
    // Implemented stub for retry tracking
    await logEvent('retry_attempt', parameters: {
      'screen': screenName,
      'provider': providerName,
      'retry_count': retryCount,
      'backoff_ms': backoffMs,
      if (success != null) 'success': success,
      if (errorMessage != null) 'error': errorMessage,
      if (metadata != null) ...metadata,
    });
  }

  /// Track skeleton display (stub)
  void trackSkeletonDisplay({
    required String screenName,
    required String skeletonType,
  }) {
    // Implemented stub for skeleton tracking
    logEvent('skeleton_display', parameters: {
      'screen': screenName,
      'skeleton_type': skeletonType,
    });
  }

  /// Track skeleton duration (stub)
  Future<void> trackSkeletonDuration({
    required String screenName,
    required int durationMs,
    required String skeletonType,
    Map<String, dynamic>? metadata,
  }) async {
    // Implemented stub for skeleton duration tracking
    await logEvent('skeleton_duration', parameters: {
      'screen': screenName,
      'duration_ms': durationMs,
      'skeleton_type': skeletonType,
      if (metadata != null) ...metadata,
    });
  }

  /// Track skeleton interaction (stub)
  Future<void> trackSkeletonInteraction({
    required String screenName,
    required String interactionType,
    required int skeletonVisibleMs,
    Map<String, dynamic>? metadata,
  }) async {
    // Implemented stub for skeleton interaction tracking
    await logEvent('skeleton_interaction', parameters: {
      'screen': screenName,
      'interaction_type': interactionType,
      'visible_ms': skeletonVisibleMs,
      if (metadata != null) ...metadata,
    });
  }

  /// Track provider latency (stub)
  Future<void> trackProviderLatency({
    required String providerName,
    required int durationMs,
    String? screenName,
    Map<String, dynamic>? metadata,
  }) async {
    // Implemented stub for provider latency tracking
    await logEvent('provider_latency', parameters: {
      'provider': providerName,
      'duration_ms': durationMs,
      if (screenName != null) 'screen': screenName,
      if (metadata != null) ...metadata,
    });
  }

  /// Get skeleton metrics (stub)
  Map<String, dynamic> getSkeletonMetrics() {
    return {
      'total_displays': 0,
      'average_duration_ms': 0,
      'interaction_rate': 0.0,
    };
  }

  /// Get retry stats (stub)
  Map<String, dynamic> getRetryStats() {
    return {
      'total_retries': 0,
      'success_rate': 0.0,
      'average_backoff_ms': 0,
    };
  }

  /// Get provider performance (stub)
  Map<String, dynamic> getProviderPerformance(String providerName) {
    return {
      'provider': providerName,
      'average_latency_ms': 0,
      'error_count': 0,
      'success_rate': 0.0,
    };
  }

  /// Track event (generic - delegates to logEvent)
  Future<void> trackEvent(String eventName, {Map<String, dynamic>? parameters}) async {
    await logEvent(eventName, parameters: parameters);
  }

  /// Track error under load (stub)
  Future<void> trackErrorUnderLoad({
    required String screenName,
    required String errorType,
    String? errorMessage,
    String? providerName,
    Map<String, dynamic>? metadata,
  }) async {
    await logEvent('error_under_load', parameters: {
      'screen': screenName,
      'error_type': errorType,
      if (errorMessage != null) 'error_message': errorMessage,
      if (providerName != null) 'provider': providerName,
      if (metadata != null) ...metadata,
    });
  }
}
