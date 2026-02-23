import 'dart:async';
import 'package:flutter/foundation.dart';

/// Batches analytics events to reduce network overhead
/// Combines multiple events into fewer network calls
class BatchedAnalyticsService {
  static final BatchedAnalyticsService _instance = BatchedAnalyticsService._internal();
  factory BatchedAnalyticsService() => _instance;
  BatchedAnalyticsService._internal();

  final List<Map<String, dynamic>> _eventBatch = [];
  Timer? _flushTimer;
  final Duration _flushInterval = const Duration(seconds: 5);
  final int _batchSize = 20;

  /// Add event to batch
  void addEvent(Map<String, dynamic> event) {
    _eventBatch.add({
      ...event,
      'timestamp': DateTime.now().toIso8601String(),
    });

    if (kDebugMode) {
      debugPrint('[BatchedAnalytics] Event added. Batch size: ${_eventBatch.length}');
    }

    // Flush if batch is full
    if (_eventBatch.length >= _batchSize) {
      _flush();
    } else {
      // Schedule flush if not already scheduled
      _flushTimer ??= Timer(_flushInterval, _flush);
    }
  }

  /// Flush batched events
  void _flush() {
    if (_eventBatch.isEmpty) return;

    _flushTimer?.cancel();
    _flushTimer = null;

    if (kDebugMode) {
      debugPrint('[BatchedAnalytics] Flushing ${_eventBatch.length} events');
    }

    // Here you would send batched events to your analytics backend
    // For now, just log them
    _eventBatch.clear();
  }

  /// Force flush all pending events
  Future<void> flush() async {
    _flush();
  }

  /// Dispose and clean up
  void dispose() {
    _flushTimer?.cancel();
    _flushTimer = null;
    _eventBatch.clear();
  }
}
