/// Quality Monitor Service
///
/// Monitors application quality metrics including room join failures,
/// video stability, crash-free sessions, and auto-flags problematic rooms.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../analytics/analytics_service.dart';

/// Types of quality issues
enum QualityIssueType {
  roomJoinFailure,
  videoStabilityIssue,
  audioQualityIssue,
  connectionTimeout,
  unexpectedDisconnect,
  highLatency,
  packetLoss,
  crashReport,
  anrReport,
  memoryIssue,
  firestoreSyncFailure,
}

/// Severity levels for quality issues
enum IssueSeverity {
  low,
  medium,
  high,
  critical,
}

/// Quality metric threshold configuration
class QualityThreshold {
  final QualityIssueType type;
  final double warningThreshold;
  final double criticalThreshold;
  final Duration monitoringWindow;
  final int minSampleSize;

  const QualityThreshold({
    required this.type,
    required this.warningThreshold,
    required this.criticalThreshold,
    this.monitoringWindow = const Duration(hours: 1),
    this.minSampleSize = 100,
  });
}

/// Model for quality incidents
class QualityIncident {
  final String id;
  final QualityIssueType type;
  final IssueSeverity severity;
  final String description;
  final String? roomId;
  final String? userId;
  final Map<String, dynamic> context;
  final DateTime occurredAt;
  final bool resolved;
  final DateTime? resolvedAt;

  const QualityIncident({
    required this.id,
    required this.type,
    required this.severity,
    required this.description,
    this.roomId,
    this.userId,
    this.context = const {},
    required this.occurredAt,
    this.resolved = false,
    this.resolvedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type.name,
    'severity': severity.name,
    'description': description,
    'roomId': roomId,
    'userId': userId,
    'context': context,
    'occurredAt': occurredAt.toIso8601String(),
    'resolved': resolved,
    'resolvedAt': resolvedAt?.toIso8601String(),
  };
}

/// Room health status
class RoomHealthStatus {
  final String roomId;
  final double joinSuccessRate;
  final double videoStabilityScore;
  final double audioQualityScore;
  final int activeIssues;
  final bool flagged;
  final String? flagReason;
  final DateTime lastChecked;

  const RoomHealthStatus({
    required this.roomId,
    required this.joinSuccessRate,
    required this.videoStabilityScore,
    required this.audioQualityScore,
    required this.activeIssues,
    this.flagged = false,
    this.flagReason,
    required this.lastChecked,
  });

  bool get isHealthy =>
      joinSuccessRate > 0.95 &&
      videoStabilityScore > 0.9 &&
      audioQualityScore > 0.9 &&
      activeIssues == 0;

  Map<String, dynamic> toMap() => {
    'roomId': roomId,
    'joinSuccessRate': joinSuccessRate,
    'videoStabilityScore': videoStabilityScore,
    'audioQualityScore': audioQualityScore,
    'activeIssues': activeIssues,
    'flagged': flagged,
    'flagReason': flagReason,
    'lastChecked': lastChecked.toIso8601String(),
  };
}

/// Service for monitoring application quality
class QualityMonitorService {
  static QualityMonitorService? _instance;
  static QualityMonitorService get instance => _instance ??= QualityMonitorService._();

  QualityMonitorService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  CollectionReference<Map<String, dynamic>> get _incidentsCollection =>
      _firestore.collection('quality_incidents');

  CollectionReference<Map<String, dynamic>> get _metricsCollection =>
      _firestore.collection('quality_metrics');

  CollectionReference<Map<String, dynamic>> get _roomHealthCollection =>
      _firestore.collection('room_health');

  // Monitoring state
  Timer? _monitoringTimer;
  final Map<String, List<QualityIncident>> _recentIncidents = {};
  final Map<String, RoomHealthStatus> _roomHealthCache = {};

  // Stream controllers
  final _incidentController = StreamController<QualityIncident>.broadcast();
  final _alertController = StreamController<String>.broadcast();

  /// Stream of new incidents
  Stream<QualityIncident> get incidentStream => _incidentController.stream;

  /// Stream of quality alerts
  Stream<String> get alertStream => _alertController.stream;

  // Quality thresholds
  static const List<QualityThreshold> _thresholds = [
    QualityThreshold(
      type: QualityIssueType.roomJoinFailure,
      warningThreshold: 0.05,
      criticalThreshold: 0.15,
    ),
    QualityThreshold(
      type: QualityIssueType.videoStabilityIssue,
      warningThreshold: 0.1,
      criticalThreshold: 0.25,
    ),
    QualityThreshold(
      type: QualityIssueType.audioQualityIssue,
      warningThreshold: 0.1,
      criticalThreshold: 0.2,
    ),
    QualityThreshold(
      type: QualityIssueType.connectionTimeout,
      warningThreshold: 0.05,
      criticalThreshold: 0.1,
    ),
    QualityThreshold(
      type: QualityIssueType.crashReport,
      warningThreshold: 0.01,
      criticalThreshold: 0.03,
    ),
  ];

  /// Initialize the monitoring service
  Future<void> initialize() async {
    startContinuousMonitoring();

    AnalyticsService.instance.logEvent(
      name: 'quality_monitor_initialized',
      parameters: {},
    );
  }

  /// Start continuous monitoring
  void startContinuousMonitoring({Duration interval = const Duration(minutes: 5)}) {
    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(interval, (_) => _runHealthChecks());
  }

  /// Stop continuous monitoring
  void stopContinuousMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
  }

  /// Monitor room join failures
  Future<double> monitorRoomJoinFailures({
    String? roomId,
    Duration window = const Duration(hours: 1),
  }) async {
    final startTime = DateTime.now().subtract(window);

    Query<Map<String, dynamic>> query = _metricsCollection
        .where('type', isEqualTo: 'room_join')
        .where('timestamp', isGreaterThan: Timestamp.fromDate(startTime));

    if (roomId != null) {
      query = query.where('roomId', isEqualTo: roomId);
    }

    final snapshot = await query.get();
    if (snapshot.docs.isEmpty) return 0.0;

    int totalAttempts = 0;
    int failures = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      totalAttempts++;
      if (data['success'] == false) {
        failures++;
      }
    }

    final failureRate = totalAttempts > 0 ? failures / totalAttempts : 0.0;

    // Check threshold
    final threshold = _thresholds.firstWhere(
      (t) => t.type == QualityIssueType.roomJoinFailure,
    );

    if (failureRate >= threshold.criticalThreshold) {
      await _recordIncident(
        type: QualityIssueType.roomJoinFailure,
        severity: IssueSeverity.critical,
        description: 'Room join failure rate at ${(failureRate * 100).toStringAsFixed(1)}%',
        roomId: roomId,
        context: {
          'failureRate': failureRate,
          'totalAttempts': totalAttempts,
          'failures': failures,
        },
      );
    } else if (failureRate >= threshold.warningThreshold) {
      await _recordIncident(
        type: QualityIssueType.roomJoinFailure,
        severity: IssueSeverity.medium,
        description: 'Elevated room join failure rate: ${(failureRate * 100).toStringAsFixed(1)}%',
        roomId: roomId,
        context: {
          'failureRate': failureRate,
          'totalAttempts': totalAttempts,
          'failures': failures,
        },
      );
    }

    return failureRate;
  }

  /// Monitor video stability
  Future<double> monitorVideoStability({
    String? roomId,
    Duration window = const Duration(minutes: 30),
  }) async {
    final startTime = DateTime.now().subtract(window);

    Query<Map<String, dynamic>> query = _metricsCollection
        .where('type', isEqualTo: 'video_quality')
        .where('timestamp', isGreaterThan: Timestamp.fromDate(startTime));

    if (roomId != null) {
      query = query.where('roomId', isEqualTo: roomId);
    }

    final snapshot = await query.get();
    if (snapshot.docs.isEmpty) return 1.0;

    double totalQuality = 0.0;
    int freezeEvents = 0;
    int jitterEvents = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      totalQuality += (data['qualityScore'] as num?)?.toDouble() ?? 1.0;
      if (data['freeze'] == true) freezeEvents++;
      if (((data['jitter'] as num?)?.toDouble() ?? 0) > 100) jitterEvents++;
    }

    final avgQuality = totalQuality / snapshot.docs.length;
    final stabilityScore = avgQuality * (1 - freezeEvents / snapshot.docs.length);

    // Check threshold
    final threshold = _thresholds.firstWhere(
      (t) => t.type == QualityIssueType.videoStabilityIssue,
    );

    final issueRate = 1 - stabilityScore;
    if (issueRate >= threshold.criticalThreshold) {
      await _recordIncident(
        type: QualityIssueType.videoStabilityIssue,
        severity: IssueSeverity.critical,
        description: 'Critical video stability issues detected',
        roomId: roomId,
        context: {
          'stabilityScore': stabilityScore,
          'freezeEvents': freezeEvents,
          'jitterEvents': jitterEvents,
        },
      );
    }

    return stabilityScore;
  }

  /// Monitor crash-free sessions
  Future<double> monitorCrashFreeSessions({
    Duration window = const Duration(days: 1),
  }) async {
    final startTime = DateTime.now().subtract(window);

    final sessionsSnapshot = await _metricsCollection
        .where('type', isEqualTo: 'session')
        .where('timestamp', isGreaterThan: Timestamp.fromDate(startTime))
        .get();

    final crashSnapshot = await _metricsCollection
        .where('type', isEqualTo: 'crash')
        .where('timestamp', isGreaterThan: Timestamp.fromDate(startTime))
        .get();

    final totalSessions = sessionsSnapshot.docs.length;
    final crashedSessions = crashSnapshot.docs.length;

    if (totalSessions == 0) return 1.0;

    final crashFreeRate = (totalSessions - crashedSessions) / totalSessions;

    // Check threshold
    final threshold = _thresholds.firstWhere(
      (t) => t.type == QualityIssueType.crashReport,
    );

    final crashRate = 1 - crashFreeRate;
    if (crashRate >= threshold.criticalThreshold) {
      await _recordIncident(
        type: QualityIssueType.crashReport,
        severity: IssueSeverity.critical,
        description: 'Crash rate exceeds critical threshold: ${(crashRate * 100).toStringAsFixed(2)}%',
        context: {
          'crashRate': crashRate,
          'totalSessions': totalSessions,
          'crashedSessions': crashedSessions,
        },
      );
      _alertController.add('CRITICAL: Crash rate at ${(crashRate * 100).toStringAsFixed(2)}%');
    }

    return crashFreeRate;
  }

  /// Auto-flag problematic rooms
  Future<List<String>> autoFlagProblematicRooms({
    double failureThreshold = 0.2,
    double stabilityThreshold = 0.7,
    int minIssues = 3,
  }) async {
    final flaggedRooms = <String>[];

    // Get all active rooms
    final roomsSnapshot = await _firestore.collection('rooms')
        .where('isActive', isEqualTo: true)
        .get();

    for (final roomDoc in roomsSnapshot.docs) {
      final roomId = roomDoc.id;

      // Check join failure rate
      final failureRate = await monitorRoomJoinFailures(roomId: roomId);

      // Check video stability
      final stabilityScore = await monitorVideoStability(roomId: roomId);

      // Count recent incidents
      final recentIncidents = _recentIncidents[roomId]?.length ?? 0;

      // Determine if room should be flagged
      final shouldFlag = failureRate > failureThreshold ||
          stabilityScore < stabilityThreshold ||
          recentIncidents >= minIssues;

      String? flagReason;
      if (failureRate > failureThreshold) {
        flagReason = 'High join failure rate: ${(failureRate * 100).toStringAsFixed(1)}%';
      } else if (stabilityScore < stabilityThreshold) {
        flagReason = 'Low video stability: ${(stabilityScore * 100).toStringAsFixed(1)}%';
      } else if (recentIncidents >= minIssues) {
        flagReason = 'Multiple quality incidents: $recentIncidents';
      }

      final healthStatus = RoomHealthStatus(
        roomId: roomId,
        joinSuccessRate: 1 - failureRate,
        videoStabilityScore: stabilityScore,
        audioQualityScore: 1.0, // Would be calculated similarly
        activeIssues: recentIncidents,
        flagged: shouldFlag,
        flagReason: flagReason,
        lastChecked: DateTime.now(),
      );

      _roomHealthCache[roomId] = healthStatus;

      // Update in Firestore
      await _roomHealthCollection.doc(roomId).set(healthStatus.toMap());

      if (shouldFlag) {
        flaggedRooms.add(roomId);

        AnalyticsService.instance.logEvent(
          name: 'room_auto_flagged',
          parameters: {
            'room_id': roomId,
            'reason': flagReason ?? 'unknown',
          },
        );
      }
    }

    return flaggedRooms;
  }

  /// Record a quality metric
  Future<void> recordMetric({
    required String type,
    required Map<String, dynamic> data,
    String? roomId,
    String? userId,
  }) async {
    await _metricsCollection.add({
      'type': type,
      'data': data,
      'roomId': roomId,
      'userId': userId ?? _auth.currentUser?.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Record room join attempt
  Future<void> recordRoomJoinAttempt({
    required String roomId,
    required bool success,
    String? errorCode,
    int? latencyMs,
  }) async {
    await recordMetric(
      type: 'room_join',
      roomId: roomId,
      data: {
        'success': success,
        'errorCode': errorCode,
        'latencyMs': latencyMs,
      },
    );
  }

  /// Record video quality metric
  Future<void> recordVideoQuality({
    required String roomId,
    required double qualityScore,
    bool freeze = false,
    double? jitter,
    double? packetLoss,
  }) async {
    await recordMetric(
      type: 'video_quality',
      roomId: roomId,
      data: {
        'qualityScore': qualityScore,
        'freeze': freeze,
        'jitter': jitter,
        'packetLoss': packetLoss,
      },
    );
  }

  /// Get room health status
  RoomHealthStatus? getRoomHealth(String roomId) => _roomHealthCache[roomId];

  /// Get all flagged rooms
  List<RoomHealthStatus> get flaggedRooms =>
      _roomHealthCache.values.where((r) => r.flagged).toList();

  /// Get recent incidents
  List<QualityIncident> getRecentIncidents({
    String? roomId,
    QualityIssueType? type,
    int limit = 50,
  }) {
    List<QualityIncident> incidents;

    if (roomId != null) {
      incidents = _recentIncidents[roomId] ?? [];
    } else {
      incidents = _recentIncidents.values.expand((i) => i).toList();
    }

    if (type != null) {
      incidents = incidents.where((i) => i.type == type).toList();
    }

    incidents.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return incidents.take(limit).toList();
  }

  // Private methods

  Future<void> _runHealthChecks() async {
    await monitorRoomJoinFailures();
    await monitorVideoStability();
    await monitorCrashFreeSessions();
    await autoFlagProblematicRooms();
  }

  Future<void> _recordIncident({
    required QualityIssueType type,
    required IssueSeverity severity,
    required String description,
    String? roomId,
    String? userId,
    Map<String, dynamic> context = const {},
  }) async {
    final docRef = _incidentsCollection.doc();
    final incident = QualityIncident(
      id: docRef.id,
      type: type,
      severity: severity,
      description: description,
      roomId: roomId,
      userId: userId ?? _auth.currentUser?.uid,
      context: context,
      occurredAt: DateTime.now(),
    );

    await docRef.set(incident.toMap());

    // Cache incident
    if (roomId != null) {
      _recentIncidents.putIfAbsent(roomId, () => []);
      _recentIncidents[roomId]!.add(incident);

      // Keep only recent incidents
      if (_recentIncidents[roomId]!.length > 100) {
        _recentIncidents[roomId] = _recentIncidents[roomId]!.sublist(50);
      }
    }

    _incidentController.add(incident);

    AnalyticsService.instance.logEvent(
      name: 'quality_incident',
      parameters: {
        'type': type.name,
        'severity': severity.name,
        'room_id': roomId ?? 'global',
      },
    );
  }

  /// Dispose resources
  void dispose() {
    _monitoringTimer?.cancel();
    _incidentController.close();
    _alertController.close();
  }
}
