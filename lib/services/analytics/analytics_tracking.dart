import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'analytics_service.dart';
import '../../shared/providers/providers.dart';

/// Extension on AsyncValue to add automatic analytics tracking
/// Usage:
/// ```dart
/// final dataAsync = ref.watch(myProvider);
/// await dataAsync.trackWithAnalytics(
///   analytics: analyticsService,
///   screenName: 'MyScreen',
///   providerName: 'myProvider',
/// );
/// ```
extension AsyncValueAnalytics<T> on AsyncValue<T> {
  /// Track this AsyncValue with analytics
  Future<void> trackWithAnalytics({
    required AnalyticsService analytics,
    required String screenName,
    required String providerName,
    DateTime? startTime,
    Map<String, dynamic>? metadata,
  }) async {
    final start = startTime ?? DateTime.now();

    when(
      data: (data) {
        final duration = DateTime.now().difference(start).inMilliseconds;
        analytics.trackAsyncValueLoadExtended(
          screenName: screenName,
          providerName: providerName,
          durationMs: duration,
          success: true,
          metadata: metadata,
        );
      },
      loading: () {},
      error: (error, stack) {
        final duration = DateTime.now().difference(start).inMilliseconds;
        analytics.trackAsyncValueLoadExtended(
          screenName: screenName,
          providerName: providerName,
          durationMs: duration,
          success: false,
          errorMessage: error.toString(),
          metadata: metadata,
        );
      },
    );
  }
}

/// Wrapper to track provider loads with timing
class ProviderTracker {
  final AnalyticsService analytics;
  final String screenName;
  final String providerName;
  late final DateTime _startTime;

  ProviderTracker({
    required this.analytics,
    required this.screenName,
    required this.providerName,
  }) {
    _startTime = DateTime.now();
  }

  /// Record successful load
  Future<void> recordSuccess(Map<String, dynamic>? metadata) async {
    final duration = DateTime.now().difference(_startTime).inMilliseconds;
    await analytics.trackAsyncValueLoadExtended(
      screenName: screenName,
      providerName: providerName,
      durationMs: duration,
      success: true,
      metadata: metadata,
    );
  }

  /// Record error
  Future<void> recordError(
    String errorMessage, [
    Map<String, dynamic>? metadata,
  ]) async {
    final duration = DateTime.now().difference(_startTime).inMilliseconds;
    await analytics.trackAsyncValueLoadExtended(
      screenName: screenName,
      providerName: providerName,
      durationMs: duration,
      success: false,
      errorMessage: errorMessage,
      metadata: metadata,
    );
  }

  /// Record retry
  Future<void> recordRetry({
    required int retryCount,
    required int backoffMs,
    bool? success,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  }) async {
    await analytics.trackRetryAttempt(
      screenName: screenName,
      providerName: providerName,
      retryCount: retryCount,
      backoffMs: backoffMs,
      success: success,
      errorMessage: errorMessage,
      metadata: metadata,
    );
  }
}

/// Wrapper to track skeleton performance
class SkeletonTracker {
  final AnalyticsService analytics;
  final String screenName;
  final String skeletonType;
  late final DateTime _displayTime;

  SkeletonTracker({
    required this.analytics,
    required this.screenName,
    required this.skeletonType,
  }) {
    _displayTime = DateTime.now();
    _recordDisplay();
  }

  void _recordDisplay() {
    analytics.trackSkeletonDisplay(
      screenName: screenName,
      skeletonType: skeletonType,
    );
  }

  /// Record when skeleton is replaced by real data
  Future<void> recordDataArrival({
    int? itemCount,
    Map<String, dynamic>? metadata,
  }) async {
    final duration = DateTime.now().difference(_displayTime).inMilliseconds;
    await analytics.trackSkeletonDuration(
      screenName: screenName,
      durationMs: duration,
      skeletonType: skeletonType,
      metadata: {
        'item_count': itemCount,
        ...?metadata,
      },
    );
  }

  /// Record user interaction while skeleton is visible
  Future<void> recordInteraction(
    String interactionType, [
    Map<String, dynamic>? metadata,
  ]) async {
    final visibleDuration =
        DateTime.now().difference(_displayTime).inMilliseconds;
    await analytics.trackSkeletonInteraction(
      screenName: screenName,
      interactionType: interactionType,
      skeletonVisibleMs: visibleDuration,
      metadata: metadata,
    );
  }
}

/// Provider for analytics tracking throughout the app
final analyticsTrackingProvider = Provider<AnalyticsTracker>((ref) {
  final analytics = ref.watch(analyticsServiceProvider);
  return AnalyticsTracker(analytics);
});

/// Main analytics tracker aggregator
class AnalyticsTracker {
  final AnalyticsService service;

  AnalyticsTracker(this.service);

  /// Create provider tracker
  ProviderTracker createProviderTracker({
    required String screenName,
    required String providerName,
  }) {
    return ProviderTracker(
      analytics: service,
      screenName: screenName,
      providerName: providerName,
    );
  }

  /// Create skeleton tracker
  SkeletonTracker createSkeletonTracker({
    required String screenName,
    required String skeletonType,
  }) {
    return SkeletonTracker(
      analytics: service,
      screenName: screenName,
      skeletonType: skeletonType,
    );
  }

  /// Track latency
  Future<void> trackLatency({
    required String providerName,
    required int durationMs,
    required String screenName,
  }) async {
    await service.trackProviderLatency(
      providerName: providerName,
      durationMs: durationMs,
      screenName: screenName,
    );
  }

  /// Get skeleton metrics for dashboard
  Future<Map<String, dynamic>> getSkeletonMetrics() async {
    return service.getSkeletonMetrics();
  }

  /// Get retry statistics for dashboard
  Future<Map<String, dynamic>> getRetryStats() async {
    return service.getRetryStats();
  }

  /// Get provider performance for dashboard
  Future<Map<String, dynamic>> getProviderPerformance(
      String providerName) async {
    return service.getProviderPerformance(providerName);
  }
}
