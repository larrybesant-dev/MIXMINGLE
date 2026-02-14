/// Crashlytics Service
///
/// Centralized crash reporting using Firebase Crashlytics.
/// Provides methods for logging errors, setting user identifiers,
/// and recording non-fatal exceptions.
///
/// NOTE: Firebase Crashlytics is NOT supported on web.
/// All methods gracefully skip on web platform.
library;

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Singleton service for crash reporting
class CrashlyticsService {
  static CrashlyticsService? _instance;
  static CrashlyticsService get instance => _instance ??= CrashlyticsService._();

  CrashlyticsService._();

  /// Crashlytics is not supported on web
  bool get _isSupported => !kIsWeb;

  /// Only access Crashlytics instance on supported platforms
  FirebaseCrashlytics? get _crashlytics => _isSupported ? FirebaseCrashlytics.instance : null;

  // ============================================================
  // INITIALIZATION
  // ============================================================

  /// Initialize Crashlytics with error handlers
  Future<void> initialize() async {
    if (!_isSupported) {
      debugPrint('ℹ️ [Crashlytics] Skipped on web (not supported)');
      return;
    }

    try {
      // Enable Crashlytics collection
      await _crashlytics?.setCrashlyticsCollectionEnabled(true);

      // Set up Flutter error handler
      FlutterError.onError = (FlutterErrorDetails details) {
        debugPrint('❌ [Crashlytics] Flutter error: ${details.exception}');
        _crashlytics?.recordFlutterFatalError(details);
      };

      debugPrint('✅ [Crashlytics] Initialized successfully');
    } catch (e) {
      debugPrint('❌ [Crashlytics] Initialization failed: $e');
    }
  }

  // ============================================================
  // USER IDENTIFICATION
  // ============================================================

  /// Set user identifier for crash reports
  Future<void> setUserId(String userId) async {
    if (!_isSupported) return;
    try {
      await _crashlytics?.setUserIdentifier(userId);
      debugPrint('📊 [Crashlytics] User ID set: $userId');
    } catch (e) {
      debugPrint('❌ [Crashlytics] Failed to set user ID: $e');
    }
  }

  /// Set membership tier as a custom key
  Future<void> setMembershipTier(String tier) async {
    if (!_isSupported) return;
    try {
      await _crashlytics?.setCustomKey('membership_tier', tier);
      debugPrint('📊 [Crashlytics] Membership tier set: $tier');
    } catch (e) {
      debugPrint('❌ [Crashlytics] Failed to set membership tier: $e');
    }
  }

  /// Set custom key-value pair
  Future<void> setCustomKey(String key, dynamic value) async {
    if (!_isSupported) return;
    try {
      if (value is String) {
        await _crashlytics?.setCustomKey(key, value);
      } else if (value is int) {
        await _crashlytics?.setCustomKey(key, value);
      } else if (value is double) {
        await _crashlytics?.setCustomKey(key, value);
      } else if (value is bool) {
        await _crashlytics?.setCustomKey(key, value);
      } else {
        await _crashlytics?.setCustomKey(key, value.toString());
      }
    } catch (e) {
      debugPrint('❌ [Crashlytics] Failed to set custom key: $e');
    }
  }

  // ============================================================
  // ERROR LOGGING
  // ============================================================

  /// Log a non-fatal error
  Future<void> recordError(
    dynamic exception, {
    StackTrace? stackTrace,
    String? reason,
    bool fatal = false,
    Iterable<Object> information = const [],
  }) async {
    // Always log to console for debugging
    debugPrint('❌ [Crashlytics] Recording error: $exception');
    if (!_isSupported) return;
    try {
      await _crashlytics?.recordError(
        exception,
        stackTrace ?? StackTrace.current,
        reason: reason,
        fatal: fatal,
        information: information,
      );
    } catch (e) {
      debugPrint('❌ [Crashlytics] Failed to record error: $e');
    }
  }

  /// Log a message to Crashlytics
  Future<void> log(String message) async {
    debugPrint('📝 [Crashlytics] Log: $message');
    if (!_isSupported) return;
    try {
      await _crashlytics?.log(message);
    } catch (e) {
      debugPrint('❌ [Crashlytics] Failed to log message: $e');
    }
  }

  // ============================================================
  // SPECIFIC ERROR TYPES
  // ============================================================

  /// Log a room join failure
  Future<void> logRoomJoinFailure({
    required String roomId,
    required String error,
    StackTrace? stackTrace,
  }) async {
    await log('Room join failed: $roomId');
    await setCustomKey('last_failed_room', roomId);
    await setCustomKey('room_join_error', error);
    await recordError(
      Exception('Room join failed: $error'),
      stackTrace: stackTrace,
      reason: 'room_join_failure',
    );
  }

  /// Log an Agora error
  Future<void> logAgoraError({
    required String errorCode,
    required String errorMessage,
    String? roomId,
    StackTrace? stackTrace,
  }) async {
    await log('Agora error: $errorCode - $errorMessage');
    await setCustomKey('agora_error_code', errorCode);
    await setCustomKey('agora_error_message', errorMessage);
    if (roomId != null) {
      await setCustomKey('agora_error_room', roomId);
    }
    await recordError(
      Exception('Agora error: $errorCode - $errorMessage'),
      stackTrace: stackTrace,
      reason: 'agora_error',
    );
  }

  /// Log a Firestore error
  Future<void> logFirestoreError({
    required String operation,
    required String collection,
    required String error,
    StackTrace? stackTrace,
  }) async {
    await log('Firestore error: $operation on $collection');
    await setCustomKey('firestore_operation', operation);
    await setCustomKey('firestore_collection', collection);
    await setCustomKey('firestore_error', error);
    await recordError(
      Exception('Firestore error: $operation on $collection - $error'),
      stackTrace: stackTrace,
      reason: 'firestore_error',
    );
  }

  /// Log a payment failure
  Future<void> logPaymentFailure({
    required String productId,
    required String error,
    String? transactionId,
    StackTrace? stackTrace,
  }) async {
    await log('Payment failed: $productId');
    await setCustomKey('payment_product_id', productId);
    await setCustomKey('payment_error', error);
    if (transactionId != null) {
      await setCustomKey('payment_transaction_id', transactionId);
    }
    await recordError(
      Exception('Payment failed: $error'),
      stackTrace: stackTrace,
      reason: 'payment_failure',
    );
  }

  /// Log a moderation failure
  Future<void> logModerationFailure({
    required String action,
    required String error,
    String? targetUserId,
    String? roomId,
    StackTrace? stackTrace,
  }) async {
    await log('Moderation action failed: $action');
    await setCustomKey('moderation_action', action);
    await setCustomKey('moderation_error', error);
    if (targetUserId != null) {
      await setCustomKey('moderation_target_user', targetUserId);
    }
    if (roomId != null) {
      await setCustomKey('moderation_room', roomId);
    }
    await recordError(
      Exception('Moderation failed: $action - $error'),
      stackTrace: stackTrace,
      reason: 'moderation_failure',
    );
  }

  /// Log a network error
  Future<void> logNetworkError({
    required String url,
    required String error,
    int? statusCode,
    StackTrace? stackTrace,
  }) async {
    await log('Network error: $url');
    await setCustomKey('network_url', url);
    await setCustomKey('network_error', error);
    if (statusCode != null) {
      await setCustomKey('network_status_code', statusCode);
    }
    await recordError(
      Exception('Network error: $error'),
      stackTrace: stackTrace,
      reason: 'network_error',
    );
  }

  /// Log an authentication error
  Future<void> logAuthError({
    required String method,
    required String error,
    StackTrace? stackTrace,
  }) async {
    await log('Auth error: $method');
    await setCustomKey('auth_method', method);
    await setCustomKey('auth_error', error);
    await recordError(
      Exception('Auth error: $method - $error'),
      stackTrace: stackTrace,
      reason: 'auth_error',
    );
  }

  // ============================================================
  // TESTING
  // ============================================================

  /// Force a test crash (for testing Crashlytics setup)
  void testCrash() {
    if (!_isSupported) {
      debugPrint('ℹ️ [Crashlytics] Test crash skipped on web');
      return;
    }
    debugPrint('🔥 [Crashlytics] Triggering test crash');
    _crashlytics?.crash();
  }
}
