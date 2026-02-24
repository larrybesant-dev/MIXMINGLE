/// Performance Service
///
/// Centralized performance monitoring using Firebase Performance.
/// Provides methods for custom traces, metrics, and HTTP monitoring.
library;

import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

/// Singleton service for performance monitoring
class PerformanceService {
  static PerformanceService? _instance;
  static PerformanceService get instance =>
      _instance ??= PerformanceService._();

  PerformanceService._();

  final FirebasePerformance _performance = FirebasePerformance.instance;
  final Map<String, Trace> _activeTraces = {};

  // ============================================================
  // INITIALIZATION
  // ============================================================

  /// Initialize performance monitoring
  Future<void> initialize() async {
    try {
      // Enable performance collection
      await _performance.setPerformanceCollectionEnabled(true);
      debugPrint('âœ… [Performance] Initialized successfully');
    } catch (e) {
      debugPrint('âŒ [Performance] Initialization failed: $e');
    }
  }

  /// Check if performance collection is enabled
  Future<bool> isEnabled() async {
    return await _performance.isPerformanceCollectionEnabled();
  }

  /// Enable or disable performance collection
  Future<void> setEnabled(bool enabled) async {
    await _performance.setPerformanceCollectionEnabled(enabled);
  }

  // ============================================================
  // TRACE MANAGEMENT
  // ============================================================

  /// Start a custom trace
  Future<void> startTrace(String name) async {
    try {
      if (_activeTraces.containsKey(name)) {
        debugPrint('âš ï¸ [Performance] Trace already active: $name');
        return;
      }

      final trace = _performance.newTrace(name);
      await trace.start();
      _activeTraces[name] = trace;
      debugPrint('ðŸ“Š [Performance] Trace started: $name');
    } catch (e) {
      debugPrint('âŒ [Performance] Failed to start trace $name: $e');
    }
  }

  /// Stop a custom trace
  Future<void> stopTrace(String name) async {
    try {
      final trace = _activeTraces.remove(name);
      if (trace == null) {
        debugPrint('âš ï¸ [Performance] No active trace found: $name');
        return;
      }

      await trace.stop();
      debugPrint('ðŸ“Š [Performance] Trace stopped: $name');
    } catch (e) {
      debugPrint('âŒ [Performance] Failed to stop trace $name: $e');
    }
  }

  /// Set a metric for an active trace
  Future<void> setTraceMetric(
      String traceName, String metricName, int value) async {
    try {
      final trace = _activeTraces[traceName];
      if (trace == null) {
        debugPrint('âš ï¸ [Performance] No active trace found: $traceName');
        return;
      }

      trace.setMetric(metricName, value);
      debugPrint(
          'ðŸ“Š [Performance] Metric set: $traceName.$metricName = $value');
    } catch (e) {
      debugPrint('âŒ [Performance] Failed to set metric: $e');
    }
  }

  /// Increment a metric for an active trace
  Future<void> incrementTraceMetric(
      String traceName, String metricName, int incrementBy) async {
    try {
      final trace = _activeTraces[traceName];
      if (trace == null) {
        debugPrint('âš ï¸ [Performance] No active trace found: $traceName');
        return;
      }

      trace.incrementMetric(metricName, incrementBy);
      debugPrint(
          'ðŸ“Š [Performance] Metric incremented: $traceName.$metricName += $incrementBy');
    } catch (e) {
      debugPrint('âŒ [Performance] Failed to increment metric: $e');
    }
  }

  /// Set an attribute for an active trace
  Future<void> setTraceAttribute(
      String traceName, String attributeName, String value) async {
    try {
      final trace = _activeTraces[traceName];
      if (trace == null) {
        debugPrint('âš ï¸ [Performance] No active trace found: $traceName');
        return;
      }

      trace.putAttribute(attributeName, value);
      debugPrint(
          'ðŸ“Š [Performance] Attribute set: $traceName.$attributeName = $value');
    } catch (e) {
      debugPrint('âŒ [Performance] Failed to set attribute: $e');
    }
  }

  // ============================================================
  // CONVENIENCE METHODS FOR TIMED OPERATIONS
  // ============================================================

  /// Execute a function and trace its duration
  Future<T> traceAsync<T>(String name, Future<T> Function() operation) async {
    await startTrace(name);
    try {
      final result = await operation();
      await stopTrace(name);
      return result;
    } catch (e) {
      await setTraceAttribute(name, 'error', e.toString());
      await stopTrace(name);
      rethrow;
    }
  }

  /// Execute a synchronous function and trace its duration
  T traceSync<T>(String name, T Function() operation) {
    final stopwatch = Stopwatch()..start();
    try {
      final result = operation();
      stopwatch.stop();
      debugPrint(
          'ðŸ“Š [Performance] $name completed in ${stopwatch.elapsedMilliseconds}ms');
      return result;
    } catch (e) {
      stopwatch.stop();
      debugPrint(
          'âŒ [Performance] $name failed after ${stopwatch.elapsedMilliseconds}ms: $e');
      rethrow;
    }
  }

  // ============================================================
  // HTTP MONITORING
  // ============================================================

  /// Create an HTTP metric for monitoring network calls
  HttpMetric newHttpMetric(String url, HttpMethod method) {
    return _performance.newHttpMetric(url, method);
  }

  // ============================================================
  // ROOM JOIN TRACES
  // ============================================================

  /// Start room join total trace
  Future<void> startRoomJoinTrace(String roomId) async {
    await startTrace('room_join_total');
    await setTraceAttribute('room_join_total', 'room_id', roomId);
  }

  /// Stop room join total trace with result
  Future<void> stopRoomJoinTrace({bool success = true}) async {
    await setTraceAttribute('room_join_total', 'success', success.toString());
    await stopTrace('room_join_total');
  }

  /// Start Agora connect trace
  Future<void> startAgoraConnectTrace(String roomId) async {
    await startTrace('agora_connect_time');
    await setTraceAttribute('agora_connect_time', 'room_id', roomId);
  }

  /// Stop Agora connect trace
  Future<void> stopAgoraConnectTrace({bool success = true}) async {
    await setTraceAttribute(
        'agora_connect_time', 'success', success.toString());
    await stopTrace('agora_connect_time');
  }

  /// Start Firestore presence write trace
  Future<void> startFirestorePresenceTrace(String roomId) async {
    await startTrace('firestore_presence_write_time');
    await setTraceAttribute('firestore_presence_write_time', 'room_id', roomId);
  }

  /// Stop Firestore presence write trace
  Future<void> stopFirestorePresenceTrace({bool success = true}) async {
    await setTraceAttribute(
        'firestore_presence_write_time', 'success', success.toString());
    await stopTrace('firestore_presence_write_time');
  }

  /// Start video stream start trace
  Future<void> startVideoStreamTrace(String roomId) async {
    await startTrace('video_stream_start_time');
    await setTraceAttribute('video_stream_start_time', 'room_id', roomId);
  }

  /// Stop video stream start trace
  Future<void> stopVideoStreamTrace({bool success = true}) async {
    await setTraceAttribute(
        'video_stream_start_time', 'success', success.toString());
    await stopTrace('video_stream_start_time');
  }

  // ============================================================
  // VIDEO RELIABILITY TRACES
  // ============================================================

  /// Record frame drop rate
  Future<void> recordFrameDropRate(String roomId, double rate) async {
    await startTrace('frame_drop_rate');
    await setTraceAttribute('frame_drop_rate', 'room_id', roomId);
    await setTraceMetric('frame_drop_rate', 'rate', (rate * 100).toInt());
    await stopTrace('frame_drop_rate');
  }

  /// Record bitrate fluctuation
  Future<void> recordBitrateFluctuation(String roomId, int bitrate) async {
    await startTrace('bitrate_fluctuation');
    await setTraceAttribute('bitrate_fluctuation', 'room_id', roomId);
    await setTraceMetric('bitrate_fluctuation', 'bitrate', bitrate);
    await stopTrace('bitrate_fluctuation');
  }

  /// Start network latency trace
  Future<void> startNetworkLatencyTrace(String roomId) async {
    await startTrace('network_latency_trace');
    await setTraceAttribute('network_latency_trace', 'room_id', roomId);
  }

  /// Stop network latency trace with latency value
  Future<void> stopNetworkLatencyTrace(int latencyMs) async {
    await setTraceMetric('network_latency_trace', 'latency_ms', latencyMs);
    await stopTrace('network_latency_trace');
  }

  // ============================================================
  // UI RESPONSIVENESS TRACES
  // ============================================================

  /// Start profile panel open trace
  Future<void> startOpenProfilePanelTrace() async {
    await startTrace('open_profile_panel');
  }

  /// Stop profile panel open trace
  Future<void> stopOpenProfilePanelTrace() async {
    await stopTrace('open_profile_panel');
  }

  /// Start host tools open trace
  Future<void> startOpenHostToolsTrace() async {
    await startTrace('open_host_tools');
  }

  /// Stop host tools open trace
  Future<void> stopOpenHostToolsTrace() async {
    await stopTrace('open_host_tools');
  }

  /// Start coin store open trace
  Future<void> startOpenCoinStoreTrace() async {
    await startTrace('open_coin_store');
  }

  /// Stop coin store open trace
  Future<void> stopOpenCoinStoreTrace() async {
    await stopTrace('open_coin_store');
  }

  // ============================================================
  // UTILITY TRACES
  // ============================================================

  /// Record a simple duration metric
  Future<void> recordDuration(String name, int durationMs,
      {Map<String, String>? attributes}) async {
    await startTrace(name);
    if (attributes != null) {
      for (final entry in attributes.entries) {
        await setTraceAttribute(name, entry.key, entry.value);
      }
    }
    await setTraceMetric(name, 'duration_ms', durationMs);
    await stopTrace(name);
  }
}

/// Trace names constants
class TraceNames {
  TraceNames._();

  // Room join traces
  static const String roomJoinTotal = 'room_join_total';
  static const String agoraConnectTime = 'agora_connect_time';
  static const String firestorePresenceWriteTime =
      'firestore_presence_write_time';
  static const String videoStreamStartTime = 'video_stream_start_time';

  // Video reliability traces
  static const String frameDropRate = 'frame_drop_rate';
  static const String bitrateFluctuation = 'bitrate_fluctuation';
  static const String networkLatencyTrace = 'network_latency_trace';

  // UI responsiveness traces
  static const String openProfilePanel = 'open_profile_panel';
  static const String openHostTools = 'open_host_tools';
  static const String openCoinStore = 'open_coin_store';
}
