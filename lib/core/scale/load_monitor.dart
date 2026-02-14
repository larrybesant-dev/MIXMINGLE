/// Load Monitor
///
/// Tracks active rooms, concurrent streams, Firestore load, and Agora load
/// to provide real-time metrics for scaling decisions.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../analytics/analytics_service.dart';

/// Statistics snapshot of current load
class LoadStats {
  final int activeRooms;
  final int concurrentStreams;
  final int activeFirestoreListeners;
  final int agoraChannels;
  final double cpuUsage;
  final double memoryUsage;
  final double firestoreReadOps;
  final double firestoreWriteOps;
  final DateTime timestamp;

  const LoadStats({
    required this.activeRooms,
    required this.concurrentStreams,
    required this.activeFirestoreListeners,
    required this.agoraChannels,
    required this.cpuUsage,
    required this.memoryUsage,
    required this.firestoreReadOps,
    required this.firestoreWriteOps,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'activeRooms': activeRooms,
    'concurrentStreams': concurrentStreams,
    'activeFirestoreListeners': activeFirestoreListeners,
    'agoraChannels': agoraChannels,
    'cpuUsage': cpuUsage,
    'memoryUsage': memoryUsage,
    'firestoreReadOps': firestoreReadOps,
    'firestoreWriteOps': firestoreWriteOps,
    'timestamp': timestamp.toIso8601String(),
  };

  factory LoadStats.fromMap(Map<String, dynamic> map) {
    return LoadStats(
      activeRooms: map['activeRooms'] as int? ?? 0,
      concurrentStreams: map['concurrentStreams'] as int? ?? 0,
      activeFirestoreListeners: map['activeFirestoreListeners'] as int? ?? 0,
      agoraChannels: map['agoraChannels'] as int? ?? 0,
      cpuUsage: (map['cpuUsage'] as num?)?.toDouble() ?? 0,
      memoryUsage: (map['memoryUsage'] as num?)?.toDouble() ?? 0,
      firestoreReadOps: (map['firestoreReadOps'] as num?)?.toDouble() ?? 0,
      firestoreWriteOps: (map['firestoreWriteOps'] as num?)?.toDouble() ?? 0,
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'] as String)
          : DateTime.now(),
    );
  }

  /// Check if any metric exceeds threshold
  bool isOverloaded({
    int roomThreshold = 1000,
    int streamThreshold = 5000,
    double cpuThreshold = 0.8,
    double memoryThreshold = 0.85,
  }) {
    return activeRooms > roomThreshold ||
        concurrentStreams > streamThreshold ||
        cpuUsage > cpuThreshold ||
        memoryUsage > memoryThreshold;
  }
}

/// Represents a load alert
class LoadAlert {
  final String id;
  final LoadAlertType type;
  final LoadAlertSeverity severity;
  final String message;
  final double currentValue;
  final double threshold;
  final DateTime timestamp;

  const LoadAlert({
    required this.id,
    required this.type,
    required this.severity,
    required this.message,
    required this.currentValue,
    required this.threshold,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type.name,
    'severity': severity.name,
    'message': message,
    'currentValue': currentValue,
    'threshold': threshold,
    'timestamp': timestamp.toIso8601String(),
  };
}

enum LoadAlertType {
  highRoomCount,
  highStreamCount,
  highCpuUsage,
  highMemoryUsage,
  highFirestoreOps,
  highAgoraLoad,
}

enum LoadAlertSeverity {
  warning,
  critical,
  emergency,
}

/// Historical load data point
class LoadHistoryPoint {
  final DateTime timestamp;
  final LoadStats stats;

  const LoadHistoryPoint({
    required this.timestamp,
    required this.stats,
  });
}

/// Service for monitoring load across the system
class LoadMonitor {
  static LoadMonitor? _instance;
  static LoadMonitor get instance => _instance ??= LoadMonitor._();

  LoadMonitor._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  CollectionReference<Map<String, dynamic>> get _metricsCollection =>
      _firestore.collection('load_metrics');

  CollectionReference<Map<String, dynamic>> get _alertsCollection =>
      _firestore.collection('load_alerts');

  // Current stats
  LoadStats? _currentStats;

  // History
  final List<LoadHistoryPoint> _history = [];
  static const int _maxHistorySize = 288; // 24 hours at 5-min intervals

  // Timers
  Timer? _monitoringTimer;

  // Subscriptions
  StreamSubscription<QuerySnapshot>? _roomsSubscription;
  StreamSubscription<QuerySnapshot>? _sessionsSubscription;

  // Counters
  int _activeFirestoreListeners = 0;
  int _agoraChannels = 0;

  // Stream controllers
  final _statsController = StreamController<LoadStats>.broadcast();
  final _alertController = StreamController<LoadAlert>.broadcast();

  /// Stream of load statistics
  Stream<LoadStats> get statsStream => _statsController.stream;

  /// Stream of load alerts
  Stream<LoadAlert> get alertStream => _alertController.stream;

  /// Current load statistics
  LoadStats? get currentStats => _currentStats;

  /// Load history
  List<LoadHistoryPoint> get history => List.unmodifiable(_history);

  /// Initialize the monitor
  Future<void> initialize() async {
    await _startRealTimeTracking();
    _startPeriodicMonitoring();

    AnalyticsService.instance.logEvent(
      name: 'load_monitor_initialized',
      parameters: {},
    );
  }

  /// Track active rooms count
  Future<int> trackActiveRooms() async {
    final snapshot = await _firestore
        .collection('rooms')
        .where('status', isEqualTo: 'active')
        .count()
        .get();

    final count = snapshot.count ?? 0;

    // Check for alerts
    _checkAndEmitAlert(
      type: LoadAlertType.highRoomCount,
      currentValue: count.toDouble(),
      warningThreshold: 500,
      criticalThreshold: 800,
      emergencyThreshold: 1000,
      message: 'High active room count',
    );

    debugPrint('📊 [LoadMonitor] Active rooms: $count');
    return count;
  }

  /// Track concurrent video streams
  Future<int> trackConcurrentStreams() async {
    final snapshot = await _firestore
        .collection('video_sessions')
        .where('status', isEqualTo: 'active')
        .count()
        .get();

    final count = snapshot.count ?? 0;

    // Check for alerts
    _checkAndEmitAlert(
      type: LoadAlertType.highStreamCount,
      currentValue: count.toDouble(),
      warningThreshold: 2000,
      criticalThreshold: 4000,
      emergencyThreshold: 5000,
      message: 'High concurrent stream count',
    );

    debugPrint('📊 [LoadMonitor] Concurrent streams: $count');
    return count;
  }

  /// Track Firestore read/write operations
  Future<Map<String, double>> trackFirestoreLoad() async {
    // Get operations from metrics collection
    final now = DateTime.now();
    final fiveMinutesAgo = now.subtract(const Duration(minutes: 5));

    final snapshot = await _firestore
        .collection('operation_logs')
        .where('timestamp', isGreaterThan: Timestamp.fromDate(fiveMinutesAgo))
        .get();

    int reads = 0;
    int writes = 0;

    for (final doc in snapshot.docs) {
      final type = doc.data()['type'] as String?;
      if (type == 'read') {
        reads++;
      } else if (type == 'write') {
        writes++;
      }
    }

    // Normalize to per-second rate
    final readOps = reads / 300.0;
    final writeOps = writes / 300.0;

    // Check for alerts
    _checkAndEmitAlert(
      type: LoadAlertType.highFirestoreOps,
      currentValue: readOps + writeOps,
      warningThreshold: 100,
      criticalThreshold: 200,
      emergencyThreshold: 500,
      message: 'High Firestore operation rate',
    );

    debugPrint('📊 [LoadMonitor] Firestore ops: ${readOps.toStringAsFixed(2)} reads/s, ${writeOps.toStringAsFixed(2)} writes/s');

    return {
      'readOps': readOps,
      'writeOps': writeOps,
    };
  }

  /// Track Agora service load
  Future<int> trackAgoraLoad() async {
    // Track active Agora channels
    final snapshot = await _firestore
        .collection('agora_channels')
        .where('status', isEqualTo: 'active')
        .count()
        .get();

    _agoraChannels = snapshot.count ?? 0;

    // Check for alerts
    _checkAndEmitAlert(
      type: LoadAlertType.highAgoraLoad,
      currentValue: _agoraChannels.toDouble(),
      warningThreshold: 500,
      criticalThreshold: 800,
      emergencyThreshold: 1000,
      message: 'High Agora channel count',
    );

    debugPrint('📊 [LoadMonitor] Agora channels: $_agoraChannels');
    return _agoraChannels;
  }

  /// Increment Firestore listener count
  void incrementFirestoreListeners() {
    _activeFirestoreListeners++;
  }

  /// Decrement Firestore listener count
  void decrementFirestoreListeners() {
    _activeFirestoreListeners = (_activeFirestoreListeners - 1).clamp(0, double.maxFinite.toInt());
  }

  /// Get current system resource usage
  Future<Map<String, double>> getSystemResourceUsage() async {
    // In production, this would integrate with actual system monitoring
    // For now, we estimate based on activity
    final activeRooms = await trackActiveRooms();
    final streams = await trackConcurrentStreams();

    // Estimated CPU usage based on activity
    final cpuUsage = ((activeRooms * 0.001) + (streams * 0.0001)).clamp(0.0, 1.0);

    // Estimated memory usage
    final memoryUsage = ((activeRooms * 0.0005) + (streams * 0.00005) + 0.3).clamp(0.0, 1.0);

    return {
      'cpuUsage': cpuUsage,
      'memoryUsage': memoryUsage,
    };
  }

  /// Get load trend (increasing, decreasing, stable)
  String getLoadTrend() {
    if (_history.length < 3) return 'unknown';

    final recent = _history.take(3).toList();
    final avgRecent = recent.fold<double>(
      0,
      (total, point) => total + point.stats.activeRooms,
    ) / 3;

    if (_history.length < 6) return 'stable';

    final older = _history.skip(3).take(3).toList();
    final avgOlder = older.fold<double>(
      0,
      (total, point) => total + point.stats.activeRooms,
    ) / 3;

    final change = (avgRecent - avgOlder) / avgOlder;

    if (change > 0.1) return 'increasing';
    if (change < -0.1) return 'decreasing';
    return 'stable';
  }

  /// Get peak load times based on history
  List<int> getPeakHours() {
    if (_history.isEmpty) return [12, 18, 21]; // Default peak hours

    final hourlyLoad = <int, double>{};
    final hourlyCount = <int, int>{};

    for (final point in _history) {
      final hour = point.timestamp.hour;
      hourlyLoad[hour] = (hourlyLoad[hour] ?? 0) + point.stats.activeRooms;
      hourlyCount[hour] = (hourlyCount[hour] ?? 0) + 1;
    }

    // Calculate average load per hour
    final hourlyAvg = <int, double>{};
    for (final hour in hourlyLoad.keys) {
      hourlyAvg[hour] = hourlyLoad[hour]! / hourlyCount[hour]!;
    }

    // Sort by load and return top 3 hours
    final sorted = hourlyAvg.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(3).map((e) => e.key).toList();
  }

  /// Record metrics snapshot to Firestore
  Future<void> recordMetricsSnapshot() async {
    if (_currentStats == null) return;

    await _metricsCollection.add({
      ..._currentStats!.toMap(),
      'recordedAt': FieldValue.serverTimestamp(),
    });
  }

  // Private methods

  Future<void> _startRealTimeTracking() async {
    // Track active rooms in real-time
    _roomsSubscription = _firestore
        .collection('rooms')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .listen((snapshot) {
      _updateStats(activeRooms: snapshot.docs.length);
    });

    // Track video sessions in real-time
    _sessionsSubscription = _firestore
        .collection('video_sessions')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .listen((snapshot) {
      _updateStats(concurrentStreams: snapshot.docs.length);
    });
  }

  void _startPeriodicMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      await _collectFullStats();
      await recordMetricsSnapshot();
    });

    // Initial collection
    _collectFullStats();
  }

  Future<void> _collectFullStats() async {
    final activeRooms = await trackActiveRooms();
    final concurrentStreams = await trackConcurrentStreams();
    final firestoreOps = await trackFirestoreLoad();
    final agoraChannels = await trackAgoraLoad();
    final resources = await getSystemResourceUsage();

    final stats = LoadStats(
      activeRooms: activeRooms,
      concurrentStreams: concurrentStreams,
      activeFirestoreListeners: _activeFirestoreListeners,
      agoraChannels: agoraChannels,
      cpuUsage: resources['cpuUsage']!,
      memoryUsage: resources['memoryUsage']!,
      firestoreReadOps: firestoreOps['readOps']!,
      firestoreWriteOps: firestoreOps['writeOps']!,
      timestamp: DateTime.now(),
    );

    _currentStats = stats;
    _statsController.add(stats);

    // Add to history
    _history.insert(0, LoadHistoryPoint(
      timestamp: DateTime.now(),
      stats: stats,
    ));

    // Trim history
    if (_history.length > _maxHistorySize) {
      _history.removeRange(_maxHistorySize, _history.length);
    }

    AnalyticsService.instance.logEvent(
      name: 'load_stats_collected',
      parameters: {
        'active_rooms': activeRooms,
        'concurrent_streams': concurrentStreams,
        'cpu_usage': resources['cpuUsage'] ?? 0.0,
      },
    );
  }

  void _updateStats({int? activeRooms, int? concurrentStreams}) {
    if (_currentStats == null) return;

    final updated = LoadStats(
      activeRooms: activeRooms ?? _currentStats!.activeRooms,
      concurrentStreams: concurrentStreams ?? _currentStats!.concurrentStreams,
      activeFirestoreListeners: _currentStats!.activeFirestoreListeners,
      agoraChannels: _currentStats!.agoraChannels,
      cpuUsage: _currentStats!.cpuUsage,
      memoryUsage: _currentStats!.memoryUsage,
      firestoreReadOps: _currentStats!.firestoreReadOps,
      firestoreWriteOps: _currentStats!.firestoreWriteOps,
      timestamp: DateTime.now(),
    );

    _currentStats = updated;
    _statsController.add(updated);
  }

  void _checkAndEmitAlert({
    required LoadAlertType type,
    required double currentValue,
    required double warningThreshold,
    required double criticalThreshold,
    required double emergencyThreshold,
    required String message,
  }) {
    LoadAlertSeverity? severity;

    if (currentValue >= emergencyThreshold) {
      severity = LoadAlertSeverity.emergency;
    } else if (currentValue >= criticalThreshold) {
      severity = LoadAlertSeverity.critical;
    } else if (currentValue >= warningThreshold) {
      severity = LoadAlertSeverity.warning;
    }

    if (severity != null) {
      final alert = LoadAlert(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: type,
        severity: severity,
        message: message,
        currentValue: currentValue,
        threshold: severity == LoadAlertSeverity.emergency
            ? emergencyThreshold
            : severity == LoadAlertSeverity.critical
                ? criticalThreshold
                : warningThreshold,
        timestamp: DateTime.now(),
      );

      _alertController.add(alert);
      _recordAlert(alert);

      AnalyticsService.instance.logEvent(
        name: 'load_alert',
        parameters: {
          'type': type.name,
          'severity': severity.name,
          'value': currentValue,
        },
      );
    }
  }

  Future<void> _recordAlert(LoadAlert alert) async {
    await _alertsCollection.add(alert.toMap());
  }

  /// Dispose resources
  void dispose() {
    _monitoringTimer?.cancel();
    _roomsSubscription?.cancel();
    _sessionsSubscription?.cancel();
    _statsController.close();
    _alertController.close();
  }
}
