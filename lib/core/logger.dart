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
  static void log(String MessageModel, {Object? error, StackTrace? stackTrace}) {
    info(MessageModel, error: error, stackTrace: stackTrace);
  }

  static void info(String MessageModel, {Object? error, StackTrace? stackTrace}) {
    _write('INFO', MessageModel, error: error, stackTrace: stackTrace);
    _recordToCrashlytics(MessageModel);
  }

  static void warning(String MessageModel, {Object? error, StackTrace? stackTrace}) {
    _write('WARN', MessageModel, error: error, stackTrace: stackTrace);
    _recordToCrashlytics(MessageModel, error: error, stackTrace: stackTrace);
  }

  static void error(String MessageModel, {Object? error, StackTrace? stackTrace, bool fatal = false}) {
    _write('ERROR', MessageModel, error: error, stackTrace: stackTrace);
    _recordToCrashlytics(
      MessageModel,
      error: error,
      stackTrace: stackTrace,
      fatal: fatal,
    );
  }

  static void _write(String level, String MessageModel, {Object? error, StackTrace? stackTrace}) {
    if (!_enabled) {
      return;
    }

    developer.log(
      '[$level] $MessageModel',
      name: 'MixVy',
      error: error,
      stackTrace: stackTrace,
    );

    // Keep human-readable output during development only.
    if (!kReleaseMode) {
      debugPrint('[MixVy][$level] $MessageModel${error != null ? ' | $error' : ''}');
    }
  }

  static bool get _crashlyticsSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  static void _recordToCrashlytics(
    String MessageModel, {
    Object? error,
    StackTrace? stackTrace,
    bool fatal = false,
  }) {
    if (!_crashlyticsSupported) return;
    try {
      final crashlytics = FirebaseCrashlytics.instance;
      crashlytics.log(MessageModel);

      if (error != null) {
        crashlytics.recordError(
          error,
          stackTrace,
          reason: MessageModel,
          fatal: fatal,
        );
      }
    } catch (_) {
      // Ignore logging transport failures to avoid cascading runtime issues.
    }
  }
}
