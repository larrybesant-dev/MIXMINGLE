import 'dart:developer' as developer;

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class Logger {
  Logger._();

  static bool _enabled = true;

  static void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  // Backward-compatible entrypoint used across the codebase.
  static void log(String message, {Object? error, StackTrace? stackTrace}) {
    info(message, error: error, stackTrace: stackTrace);
  }

  static void info(String message, {Object? error, StackTrace? stackTrace}) {
    _write('INFO', message, error: error, stackTrace: stackTrace);
  }

  static void warning(String message, {Object? error, StackTrace? stackTrace}) {
    _write('WARN', message, error: error, stackTrace: stackTrace);
  }

  static void error(String message, {Object? error, StackTrace? stackTrace, bool fatal = false}) {
    _write('ERROR', message, error: error, stackTrace: stackTrace);
    _recordToCrashlytics(
      message,
      error: error,
      stackTrace: stackTrace,
      fatal: fatal,
    );
  }

  static void _write(String level, String message, {Object? error, StackTrace? stackTrace}) {
    if (!_enabled) {
      return;
    }

    developer.log(
      '[$level] $message',
      name: 'MixVy',
      error: error,
      stackTrace: stackTrace,
    );

    // Keep human-readable output during development only.
    if (!kReleaseMode) {
      debugPrint('[MixVy][$level] $message${error != null ? ' | $error' : ''}');
    }
  }

  static bool get _crashlyticsSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  static void _recordToCrashlytics(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    bool fatal = false,
  }) {
    if (!_crashlyticsSupported) return;
    try {
      final crashlytics = FirebaseCrashlytics.instance;
      crashlytics.log(message);

      if (error != null) {
        crashlytics.recordError(
          error,
          stackTrace,
          reason: message,
          fatal: fatal,
        );
      }
    } catch (_) {
      // Ignore logging transport failures to avoid cascading runtime issues.
    }
  }
}
