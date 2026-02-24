import 'dart:async';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Centralized error tracking service with Firebase Crashlytics
class ErrorTrackingService {
  static final ErrorTrackingService _instance = ErrorTrackingService._internal();
  factory ErrorTrackingService() => _instance;
  ErrorTrackingService._internal();

  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  bool _initialized = false;

  /// Initialize error tracking
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Skip Crashlytics on web (not supported)
      const isWeb = kIsWeb;

      if (!isWeb) {
        // Enable Crashlytics collection (only on mobile/desktop)
        await _crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);

        // Pass all uncaught errors to Crashlytics
        FlutterError.onError = (FlutterErrorDetails details) {
          _crashlytics.recordFlutterFatalError(details);
          debugPrint('Flutter Error: ${details.exception}');
        };

        // Pass all uncaught asynchronous errors to Crashlytics
        PlatformDispatcher.instance.onError = (error, stack) {
          _crashlytics.recordError(error, stack, fatal: true);
          debugPrint('Async Error: $error');
          return true;
        };
      } else {
        debugPrint('Crashlytics skipped on web platform');
      }

      _initialized = true;
      debugPrint('Error tracking initialized');
    } catch (e) {
      debugPrint('Failed to initialize error tracking: $e');
    }
  }

  /// Set user identifier for crash reports
  Future<void> setUserId(String userId) async {
    try {
      if (!kIsWeb) {
        await _crashlytics.setUserIdentifier(userId);
      }
      debugPrint('User ID set for crash tracking: $userId');
    } catch (e) {
      debugPrint('Error setting user ID: $e');
    }
  }

  /// Clear user data (on logout)
  Future<void> clearUserData() async {
    try {
      if (!kIsWeb) {
        await _crashlytics.setUserIdentifier('');
      }
      debugPrint('User data cleared from crash tracking');
    } catch (e) {
      debugPrint('Error clearing user data: $e');
    }
  }

  /// Add custom keys for context
  Future<void> setCustomKey(String key, dynamic value) async {
    try {
      if (!kIsWeb) {
        await _crashlytics.setCustomKey(key, value);
      }
    } catch (e) {
      debugPrint('Error setting custom key: $e');
    }
  }

  /// Set multiple custom keys at once
  Future<void> setCustomKeys(Map<String, dynamic> keys) async {
    try {
      if (!kIsWeb) {
        for (final entry in keys.entries) {
          await _crashlytics.setCustomKey(entry.key, entry.value);
        }
      }
    } catch (e) {
      debugPrint('Error setting custom keys: $e');
    }
  }

  /// Log a message for debugging
  void log(String message) {
    try {
      if (!kIsWeb) {
        _crashlytics.log(message);
      }
      debugPrint('Crashlytics log: $message');
    } catch (e) {
      debugPrint('Error logging message: $e');
    }
  }

  /// Record a non-fatal error
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    Iterable<Object> information = const [],
    bool fatal = false,
  }) async {
    try {
      if (!kIsWeb) {
        await _crashlytics.recordError(
          exception,
          stack,
          reason: reason,
          information: information,
          fatal: fatal,
        );
      }

      // Always log to analytics for tracking (works on all platforms)
      await _analytics.logEvent(
        name: 'error_occurred',
        parameters: {
          'error_type': exception.runtimeType.toString(),
          'error_message': exception.toString(),
          'fatal': fatal,
        },
      );

      debugPrint('Error recorded: $exception');
    } catch (e) {
      debugPrint('Error recording error: $e');
    }
  }

  /// Record a Flutter error
  Future<void> recordFlutterError(FlutterErrorDetails details) async {
    try {
      if (!kIsWeb) {
        await _crashlytics.recordFlutterError(details);
      }
      debugPrint('Flutter error recorded: ${details.exception}');
    } catch (e) {
      debugPrint('Error recording Flutter error: $e');
    }
  }

  /// Check if a crash caused previous termination
  Future<bool> didCrashOnPreviousExecution() async {
    try {
      if (kIsWeb) return false; // Web doesn't track crashes
      return await _crashlytics.didCrashOnPreviousExecution();
    } catch (e) {
      debugPrint('Error checking previous crash: $e');
      return false;
    }
  }

  /// Send unsent reports
  Future<void> sendUnsentReports() async {
    try {
      await _crashlytics.sendUnsentReports();
      debugPrint('Unsent reports sent');
    } catch (e) {
      debugPrint('Error sending unsent reports: $e');
    }
  }

  /// Delete unsent reports
  Future<void> deleteUnsentReports() async {
    try {
      await _crashlytics.deleteUnsentReports();
      debugPrint('Unsent reports deleted');
    } catch (e) {
      debugPrint('Error deleting unsent reports: $e');
    }
  }

  /// Test crash (development only)
  void testCrash() {
    if (kDebugMode) {
      throw Exception('Test crash from ErrorTrackingService');
    }
  }

  /// Check if Crashlytics collection is enabled
  bool get isCrashlyticsCollectionEnabled => _crashlytics.isCrashlyticsCollectionEnabled;
}

/// Error tracking mixin for widgets
mixin ErrorTrackingMixin<T extends StatefulWidget> on State<T> {
  final _errorTracking = ErrorTrackingService();

  /// Override to handle errors in your widget
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ErrorWidget.builder = (FlutterErrorDetails details) {
      _errorTracking.recordFlutterError(details);
      return _buildErrorWidget(details);
    };
  }

  Widget _buildErrorWidget(FlutterErrorDetails details) {
    return Material(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Something went wrong',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (kDebugMode) ...[
                Text(
                  details.exception.toString(),
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Retry or navigate away
                  },
                  child: const Text('Try Again'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Safely execute async operations with error tracking
  Future<TResult?> trackAsync<TResult>(
    Future<TResult> Function() operation, {
    String? operationName,
  }) async {
    try {
      _errorTracking.log('Starting: ${operationName ?? 'async operation'}');
      final result = await operation();
      _errorTracking.log('Completed: ${operationName ?? 'async operation'}');
      return result;
    } catch (error, stackTrace) {
      _errorTracking.recordError(
        error,
        stackTrace,
        reason: operationName,
      );
      rethrow;
    }
  }

  /// Safely execute sync operations with error tracking
  TResult? trackSync<TResult>(
    TResult Function() operation, {
    String? operationName,
  }) {
    try {
      _errorTracking.log('Executing: ${operationName ?? 'sync operation'}');
      return operation();
    } catch (error, stackTrace) {
      _errorTracking.recordError(
        error,
        stackTrace,
        reason: operationName,
      );
      rethrow;
    }
  }
}

/// Zone guard for catching all errors
Future<void> runAppWithErrorTracking(Widget app) async {
  await ErrorTrackingService().initialize();

  // Check if app crashed previously
  final didCrash = await ErrorTrackingService().didCrashOnPreviousExecution();
  if (didCrash) {
    debugPrint('App crashed on previous execution');
    // Could show a recovery dialog or send additional diagnostics
  }

  await runZonedGuarded<Future<void>>(
    () async {
      runApp(app);
    },
    (error, stack) {
      ErrorTrackingService().recordError(
        error,
        stack,
        reason: 'Uncaught zone error',
        fatal: true,
      );
    },
  );
}

/// Extension for easily logging breadcrumbs
extension ErrorTrackingContext on BuildContext {
  void logBreadcrumb(String message) {
    ErrorTrackingService().log(message);
  }

  void reportError(dynamic error, StackTrace? stack) {
    ErrorTrackingService().recordError(error, stack);
  }
}

/// Common error types for consistent tracking
class AppError implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppError(this.message, {this.code, this.originalError});

  @override
  String toString() => 'AppError: $message ${code != null ? '($code)' : ''}';
}

class NetworkError extends AppError {
  NetworkError(super.message, {super.code, super.originalError});
}

class AuthError extends AppError {
  AuthError(super.message, {super.code, super.originalError});
}

class ValidationError extends AppError {
  ValidationError(super.message, {super.code, super.originalError});
}

class PermissionError extends AppError {
  PermissionError(super.message, {super.code, super.originalError});
}
