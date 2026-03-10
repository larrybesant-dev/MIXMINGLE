import 'package:flutter/foundation.dart';

/// Performance logging utilities (debug mode only)
class PerformanceLogger {
  static final Map<String, DateTime> _startTimes = {};
  static final Map<String, List<Duration>> _durations = {};

  /// Start timing an operation
  static void start(String operationName) {
    if (!kDebugMode) return;
    _startTimes[operationName] = DateTime.now();
  }

  /// Stop timing an operation and log the duration
  static void stop(String operationName, {String? details}) {
    if (!kDebugMode) return;

    final startTime = _startTimes[operationName];
    if (startTime == null) {
      debugPrint('âš ï¸ PerformanceLogger: No start time for $operationName');
      return;
    }

    final duration = DateTime.now().difference(startTime);
    _startTimes.remove(operationName);

    // Store duration for statistics
    _durations.putIfAbsent(operationName, () => []);
    _durations[operationName]!.add(duration);

    // Log the duration
    final detailsStr = details != null ? ' ($details)' : '';
    debugPrint('â±ï¸ $operationName: ${duration.inMilliseconds}ms$detailsStr');

    // Warn if slow
    if (duration.inMilliseconds > 1000) {
      debugPrint('ðŸŒ SLOW OPERATION: $operationName took ${duration.inMilliseconds}ms');
    }
  }

  /// Execute and measure a synchronous operation
  static T measure<T>(String operationName, T Function() operation, {String? details}) {
    if (!kDebugMode) return operation();

    start(operationName);
    try {
      return operation();
    } finally {
      stop(operationName, details: details);
    }
  }

  /// Execute and measure an asynchronous operation
  static Future<T> measureAsync<T>(
    String operationName,
    Future<T> Function() operation, {
    String? details,
  }) async {
    if (!kDebugMode) return operation();

    start(operationName);
    try {
      return await operation();
    } finally {
      stop(operationName, details: details);
    }
  }

  /// Get statistics for an operation
  static String getStats(String operationName) {
    if (!kDebugMode) return 'Stats only available in debug mode';

    final durations = _durations[operationName];
    if (durations == null || durations.isEmpty) {
      return 'No data for $operationName';
    }

    final totalMs = durations.fold<int>(0, (sum, d) => sum + d.inMilliseconds);
    final avgMs = totalMs ~/ durations.length;
    final maxMs = durations.map((d) => d.inMilliseconds).reduce((a, b) => a > b ? a : b);
    final minMs = durations.map((d) => d.inMilliseconds).reduce((a, b) => a < b ? a : b);

    return '''
$operationName Statistics:
  Count: ${durations.length}
  Avg: ${avgMs}ms
  Min: ${minMs}ms
  Max: ${maxMs}ms
  Total: ${totalMs}ms
''';
  }

  /// Print all statistics
  static void printAllStats() {
    if (!kDebugMode) return;

    if (_durations.isEmpty) {
      debugPrint('ðŸ“Š No performance data collected');
      return;
    }

    debugPrint('ðŸ“Š Performance Statistics:');
    debugPrint('=' * 50);
    for (final operationName in _durations.keys) {
      debugPrint(getStats(operationName));
      debugPrint('-' * 50);
    }
  }

  /// Clear all collected data
  static void clear() {
    _startTimes.clear();
    _durations.clear();
  }

  /// Log a custom metric
  static void logMetric(String name, dynamic value, {String? unit}) {
    if (!kDebugMode) return;
    final unitStr = unit != null ? ' $unit' : '';
    debugPrint('ðŸ“ˆ $name: $value$unitStr');
  }

  /// Log memory usage
  static void logMemoryUsage(String context) {
    if (!kDebugMode) return;
    // Note: Actual memory usage would require platform-specific implementations
    debugPrint('ðŸ’¾ Memory check at: $context');
  }

  /// Log frame time
  static void logFrameTime(Duration frameTime) {
    if (!kDebugMode) return;
    if (frameTime.inMilliseconds > 16) {
      debugPrint('ðŸŽ¬ Slow frame: ${frameTime.inMilliseconds}ms');
    }
  }
}

/// Widget performance tracker
class WidgetPerformanceTracker {
  final String widgetName;
  DateTime? _buildStartTime;

  WidgetPerformanceTracker(this.widgetName);

  void startBuild() {
    if (!kDebugMode) return;
    _buildStartTime = DateTime.now();
  }

  void endBuild() {
    if (!kDebugMode) return;
    if (_buildStartTime == null) return;

    final duration = DateTime.now().difference(_buildStartTime!);
    if (duration.inMilliseconds > 16) {
      debugPrint('ðŸ”´ Slow widget build: $widgetName took ${duration.inMilliseconds}ms');
    }
    _buildStartTime = null;
  }
}
