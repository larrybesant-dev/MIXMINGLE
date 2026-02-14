/// Optimization Engine
///
/// Self-optimizing systems that automatically tune performance,
/// capacity, and resource allocation based on real-time metrics.
library;

import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../analytics/analytics_service.dart';

/// Video quality optimization result
class VideoQualityOptimization {
  final String roomId;
  final int recommendedBitrate;
  final int recommendedFrameRate;
  final String recommendedResolution;
  final double networkScore;
  final double deviceScore;
  final DateTime optimizedAt;
  final Map<String, dynamic> metrics;

  const VideoQualityOptimization({
    required this.roomId,
    required this.recommendedBitrate,
    required this.recommendedFrameRate,
    required this.recommendedResolution,
    required this.networkScore,
    required this.deviceScore,
    required this.optimizedAt,
    this.metrics = const {},
  });

  Map<String, dynamic> toMap() => {
    'roomId': roomId,
    'recommendedBitrate': recommendedBitrate,
    'recommendedFrameRate': recommendedFrameRate,
    'recommendedResolution': recommendedResolution,
    'networkScore': networkScore,
    'deviceScore': deviceScore,
    'optimizedAt': optimizedAt.toIso8601String(),
    'metrics': metrics,
  };
}

/// Room capacity optimization result
class RoomCapacityOptimization {
  final String roomId;
  final int currentCapacity;
  final int recommendedCapacity;
  final double utilizationRate;
  final int peakParticipants;
  final double performanceScore;
  final String reason;
  final DateTime optimizedAt;

  const RoomCapacityOptimization({
    required this.roomId,
    required this.currentCapacity,
    required this.recommendedCapacity,
    required this.utilizationRate,
    required this.peakParticipants,
    required this.performanceScore,
    required this.reason,
    required this.optimizedAt,
  });

  Map<String, dynamic> toMap() => {
    'roomId': roomId,
    'currentCapacity': currentCapacity,
    'recommendedCapacity': recommendedCapacity,
    'utilizationRate': utilizationRate,
    'peakParticipants': peakParticipants,
    'performanceScore': performanceScore,
    'reason': reason,
    'optimizedAt': optimizedAt.toIso8601String(),
  };
}

/// Firestore index optimization result
class FirestoreIndexOptimization {
  final String collectionPath;
  final List<String> suggestedIndexes;
  final List<String> unusedIndexes;
  final double queryPerformanceScore;
  final int estimatedImprovementPercent;
  final DateTime analyzedAt;

  const FirestoreIndexOptimization({
    required this.collectionPath,
    required this.suggestedIndexes,
    required this.unusedIndexes,
    required this.queryPerformanceScore,
    required this.estimatedImprovementPercent,
    required this.analyzedAt,
  });

  Map<String, dynamic> toMap() => {
    'collectionPath': collectionPath,
    'suggestedIndexes': suggestedIndexes,
    'unusedIndexes': unusedIndexes,
    'queryPerformanceScore': queryPerformanceScore,
    'estimatedImprovementPercent': estimatedImprovementPercent,
    'analyzedAt': analyzedAt.toIso8601String(),
  };
}

/// Server region optimization result
class ServerRegionOptimization {
  final Map<String, int> userDistribution;
  final Map<String, double> latencyByRegion;
  final String recommendedPrimaryRegion;
  final List<String> recommendedSecondaryRegions;
  final double estimatedLatencyImprovement;
  final DateTime analyzedAt;

  const ServerRegionOptimization({
    required this.userDistribution,
    required this.latencyByRegion,
    required this.recommendedPrimaryRegion,
    required this.recommendedSecondaryRegions,
    required this.estimatedLatencyImprovement,
    required this.analyzedAt,
  });

  Map<String, dynamic> toMap() => {
    'userDistribution': userDistribution,
    'latencyByRegion': latencyByRegion,
    'recommendedPrimaryRegion': recommendedPrimaryRegion,
    'recommendedSecondaryRegions': recommendedSecondaryRegions,
    'estimatedLatencyImprovement': estimatedLatencyImprovement,
    'analyzedAt': analyzedAt.toIso8601String(),
  };
}

/// Optimization event types
enum OptimizationType {
  videoQuality,
  roomCapacity,
  firestoreIndex,
  serverRegion,
}

/// Self-optimizing engine for automatic performance tuning
class OptimizationEngine {
  static OptimizationEngine? _instance;
  static OptimizationEngine get instance => _instance ??= OptimizationEngine._();

  OptimizationEngine._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _random = Random();

  // Stream controllers
  final _optimizationController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get optimizationStream => _optimizationController.stream;

  // Collections
  CollectionReference<Map<String, dynamic>> get _optimizationLogsCollection =>
      _firestore.collection('optimization_logs');

  CollectionReference<Map<String, dynamic>> get _roomsCollection =>
      _firestore.collection('rooms');

  CollectionReference<Map<String, dynamic>> get _metricsCollection =>
      _firestore.collection('performance_metrics');

  // ============================================================
  // VIDEO QUALITY AUTO-TUNING
  // ============================================================

  /// Automatically tune video quality based on network and device conditions
  Future<VideoQualityOptimization> autoTuneVideoQuality({
    required String roomId,
    double? networkBandwidth,
    int? deviceCpuPercent,
    int? participantCount,
  }) async {
    debugPrint('🔧 [OptimizationEngine] Auto-tuning video quality for room: $roomId');

    try {
      // Fetch room metrics
      final roomDoc = await _roomsCollection.doc(roomId).get();
      final roomData = roomDoc.data() ?? {};

      // Calculate network score (0-1)
      final bandwidth = networkBandwidth ?? (roomData['avgBandwidth'] as num?)?.toDouble() ?? 5.0;
      final networkScore = _calculateNetworkScore(bandwidth);

      // Calculate device score (0-1)
      final cpuUsage = deviceCpuPercent ?? (roomData['avgCpuUsage'] as num?)?.toInt() ?? 50;
      final deviceScore = _calculateDeviceScore(cpuUsage);

      // Get participant count
      final participants = participantCount ?? (roomData['participantCount'] as num?)?.toInt() ?? 1;

      // Calculate optimal settings
      final combined = (networkScore * 0.6 + deviceScore * 0.4);
      final participantPenalty = _calculateParticipantPenalty(participants);

      final effectiveScore = (combined * participantPenalty).clamp(0.1, 1.0);

      // Determine settings based on score
      final (bitrate, frameRate, resolution) = _determineVideoSettings(effectiveScore);

      final optimization = VideoQualityOptimization(
        roomId: roomId,
        recommendedBitrate: bitrate,
        recommendedFrameRate: frameRate,
        recommendedResolution: resolution,
        networkScore: networkScore,
        deviceScore: deviceScore,
        optimizedAt: DateTime.now(),
        metrics: {
          'bandwidth': bandwidth,
          'cpuUsage': cpuUsage,
          'participantCount': participants,
          'effectiveScore': effectiveScore,
        },
      );

      // Log optimization
      await _logOptimization(OptimizationType.videoQuality, optimization.toMap());

      // Emit event
      _optimizationController.add({
        'type': 'video_quality',
        'optimization': optimization.toMap(),
      });

      debugPrint('✅ [OptimizationEngine] Video quality optimized: $resolution@${frameRate}fps');
      return optimization;
    } catch (e) {
      debugPrint('❌ [OptimizationEngine] Failed to auto-tune video quality: $e');
      rethrow;
    }
  }

  double _calculateNetworkScore(double bandwidthMbps) {
    // Score based on bandwidth (0-1)
    // < 1 Mbps: poor, 1-5 Mbps: fair, 5-20 Mbps: good, > 20 Mbps: excellent
    if (bandwidthMbps >= 20) return 1.0;
    if (bandwidthMbps >= 5) return 0.7 + (bandwidthMbps - 5) / 50;
    if (bandwidthMbps >= 1) return 0.3 + (bandwidthMbps - 1) / 10;
    return bandwidthMbps * 0.3;
  }

  double _calculateDeviceScore(int cpuPercent) {
    // Inverse relationship - lower CPU usage = better score
    if (cpuPercent <= 30) return 1.0;
    if (cpuPercent <= 50) return 0.8;
    if (cpuPercent <= 70) return 0.6;
    if (cpuPercent <= 85) return 0.4;
    return 0.2;
  }

  double _calculateParticipantPenalty(int participants) {
    // More participants = lower quality possible
    if (participants <= 2) return 1.0;
    if (participants <= 5) return 0.9;
    if (participants <= 10) return 0.75;
    if (participants <= 20) return 0.6;
    return 0.5;
  }

  (int, int, String) _determineVideoSettings(double score) {
    if (score >= 0.9) {
      return (2500, 30, '1080p');
    } else if (score >= 0.7) {
      return (1500, 30, '720p');
    } else if (score >= 0.5) {
      return (1000, 24, '720p');
    } else if (score >= 0.3) {
      return (600, 24, '480p');
    } else {
      return (400, 15, '360p');
    }
  }

  // ============================================================
  // ROOM CAPACITY AUTO-TUNING
  // ============================================================

  /// Automatically tune room capacity based on usage patterns
  Future<RoomCapacityOptimization> autoTuneRoomCapacity({
    required String roomId,
  }) async {
    debugPrint('🔧 [OptimizationEngine] Auto-tuning capacity for room: $roomId');

    try {
      // Fetch room data and history
      final roomDoc = await _roomsCollection.doc(roomId).get();
      final roomData = roomDoc.data() ?? {};

      final currentCapacity = (roomData['maxParticipants'] as num?)?.toInt() ?? 10;

      // Fetch historical metrics
      final metricsQuery = await _metricsCollection
          .where('roomId', isEqualTo: roomId)
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      // Calculate utilization
      int peakParticipants = 0;
      double totalUtilization = 0;

      for (final doc in metricsQuery.docs) {
        final data = doc.data();
        final count = (data['participantCount'] as num?)?.toInt() ?? 0;
        peakParticipants = max(peakParticipants, count);
        totalUtilization += count / currentCapacity;
      }

      final avgUtilization = metricsQuery.docs.isNotEmpty
          ? totalUtilization / metricsQuery.docs.length
          : 0.5;

      // Calculate performance score
      final performanceScore = _calculateRoomPerformanceScore(
        utilization: avgUtilization,
        peakParticipants: peakParticipants,
        currentCapacity: currentCapacity,
      );

      // Determine recommended capacity
      final (recommendedCapacity, reason) = _calculateRecommendedCapacity(
        currentCapacity: currentCapacity,
        peakParticipants: peakParticipants,
        utilizationRate: avgUtilization,
        performanceScore: performanceScore,
      );

      final optimization = RoomCapacityOptimization(
        roomId: roomId,
        currentCapacity: currentCapacity,
        recommendedCapacity: recommendedCapacity,
        utilizationRate: avgUtilization,
        peakParticipants: peakParticipants,
        performanceScore: performanceScore,
        reason: reason,
        optimizedAt: DateTime.now(),
      );

      // Log optimization
      await _logOptimization(OptimizationType.roomCapacity, optimization.toMap());

      // Emit event
      _optimizationController.add({
        'type': 'room_capacity',
        'optimization': optimization.toMap(),
      });

      debugPrint('✅ [OptimizationEngine] Room capacity optimized: $currentCapacity -> $recommendedCapacity');
      return optimization;
    } catch (e) {
      debugPrint('❌ [OptimizationEngine] Failed to auto-tune room capacity: $e');
      rethrow;
    }
  }

  double _calculateRoomPerformanceScore({
    required double utilization,
    required int peakParticipants,
    required int currentCapacity,
  }) {
    // Balance between utilization and headroom
    final utilizationScore = utilization >= 0.3 && utilization <= 0.8 ? 1.0 : 0.5;
    final headroomScore = (currentCapacity - peakParticipants) >= 2 ? 1.0 : 0.6;
    return (utilizationScore + headroomScore) / 2;
  }

  (int, String) _calculateRecommendedCapacity({
    required int currentCapacity,
    required int peakParticipants,
    required double utilizationRate,
    required double performanceScore,
  }) {
    // Add 20% headroom above peak
    final targetCapacity = (peakParticipants * 1.2).ceil();

    if (utilizationRate > 0.9) {
      // Over-utilized - increase capacity
      final newCapacity = max(targetCapacity, (currentCapacity * 1.5).ceil());
      return (newCapacity, 'High utilization detected - increasing capacity');
    } else if (utilizationRate < 0.2 && currentCapacity > 5) {
      // Under-utilized - decrease capacity
      final newCapacity = max(5, targetCapacity);
      return (newCapacity, 'Low utilization detected - reducing capacity for efficiency');
    } else if (peakParticipants >= currentCapacity - 1) {
      // Near capacity - increase
      final newCapacity = (currentCapacity * 1.3).ceil();
      return (newCapacity, 'Near-capacity peaks detected - expanding headroom');
    }

    return (currentCapacity, 'Current capacity is optimal');
  }

  // ============================================================
  // FIRESTORE INDEX OPTIMIZATION
  // ============================================================

  /// Analyze and optimize Firestore indexes
  Future<FirestoreIndexOptimization> autoOptimizeFirestoreIndexes({
    required String collectionPath,
  }) async {
    debugPrint('🔧 [OptimizationEngine] Analyzing Firestore indexes for: $collectionPath');

    try {
      // In production, this would analyze query patterns from Firebase console
      // For now, we'll simulate based on common patterns

      final suggestedIndexes = <String>[];
      final unusedIndexes = <String>[];

      // Check collection-specific recommendations
      if (collectionPath == 'rooms') {
        suggestedIndexes.addAll([
          'status + createdAt (desc)',
          'hostId + status',
          'tags + participantCount (desc)',
        ]);
      } else if (collectionPath == 'messages') {
        suggestedIndexes.addAll([
          'roomId + timestamp (desc)',
          'senderId + timestamp (desc)',
        ]);
      } else if (collectionPath == 'users') {
        suggestedIndexes.addAll([
          'createdAt (desc)',
          'lastActiveAt (desc)',
          'tier + createdAt (desc)',
        ]);
      }

      // Simulate query performance analysis
      final queryPerformanceScore = 0.7 + _random.nextDouble() * 0.3;
      final estimatedImprovement = suggestedIndexes.isNotEmpty
          ? (suggestedIndexes.length * 10).clamp(5, 40)
          : 0;

      final optimization = FirestoreIndexOptimization(
        collectionPath: collectionPath,
        suggestedIndexes: suggestedIndexes,
        unusedIndexes: unusedIndexes,
        queryPerformanceScore: queryPerformanceScore,
        estimatedImprovementPercent: estimatedImprovement,
        analyzedAt: DateTime.now(),
      );

      // Log optimization
      await _logOptimization(OptimizationType.firestoreIndex, optimization.toMap());

      // Emit event
      _optimizationController.add({
        'type': 'firestore_index',
        'optimization': optimization.toMap(),
      });

      debugPrint('✅ [OptimizationEngine] Index analysis complete: ${suggestedIndexes.length} suggestions');
      return optimization;
    } catch (e) {
      debugPrint('❌ [OptimizationEngine] Failed to analyze Firestore indexes: $e');
      rethrow;
    }
  }

  // ============================================================
  // SERVER REGION BALANCING
  // ============================================================

  /// Automatically balance server regions based on user distribution
  Future<ServerRegionOptimization> autoBalanceServerRegions() async {
    debugPrint('🔧 [OptimizationEngine] Analyzing server region distribution');

    try {
      // Fetch user location data
      final usersQuery = await _firestore.collection('users')
          .where('lastActiveAt', isGreaterThan: DateTime.now().subtract(const Duration(days: 7)).toIso8601String())
          .get();

      final userDistribution = <String, int>{};
      final latencyByRegion = <String, double>{};

      // Aggregate user locations
      for (final doc in usersQuery.docs) {
        final data = doc.data();
        final region = (data['region'] as String?) ?? 'us-central';
        userDistribution[region] = (userDistribution[region] ?? 0) + 1;
      }

      // Set default regions if none found
      if (userDistribution.isEmpty) {
        userDistribution['us-central'] = 100;
        userDistribution['europe-west'] = 50;
        userDistribution['asia-east'] = 30;
      }

      // Simulate latency measurements (in production, use real measurements)
      for (final region in userDistribution.keys) {
        latencyByRegion[region] = 20 + _random.nextDouble() * 80;
      }

      // Determine optimal regions
      final sortedRegions = userDistribution.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final recommendedPrimary = sortedRegions.first.key;
      final recommendedSecondary = sortedRegions.skip(1).take(2).map((e) => e.key).toList();

      // Calculate estimated improvement
      final currentAvgLatency = latencyByRegion.values.reduce((a, b) => a + b) / latencyByRegion.length;
      final primaryLatency = latencyByRegion[recommendedPrimary] ?? currentAvgLatency;
      final improvement = ((currentAvgLatency - primaryLatency) / currentAvgLatency * 100).clamp(0.0, 50.0);

      final optimization = ServerRegionOptimization(
        userDistribution: userDistribution,
        latencyByRegion: latencyByRegion,
        recommendedPrimaryRegion: recommendedPrimary,
        recommendedSecondaryRegions: recommendedSecondary,
        estimatedLatencyImprovement: improvement,
        analyzedAt: DateTime.now(),
      );

      // Log optimization
      await _logOptimization(OptimizationType.serverRegion, optimization.toMap());

      // Emit event
      _optimizationController.add({
        'type': 'server_region',
        'optimization': optimization.toMap(),
      });

      debugPrint('✅ [OptimizationEngine] Region analysis complete: Primary=$recommendedPrimary');
      return optimization;
    } catch (e) {
      debugPrint('❌ [OptimizationEngine] Failed to balance server regions: $e');
      rethrow;
    }
  }

  // ============================================================
  // BATCH OPTIMIZATION
  // ============================================================

  /// Run all optimizations for a room
  Future<Map<String, dynamic>> optimizeRoom(String roomId) async {
    debugPrint('🔧 [OptimizationEngine] Running full optimization for room: $roomId');

    final results = <String, dynamic>{};

    try {
      results['videoQuality'] = await autoTuneVideoQuality(roomId: roomId);
      results['capacity'] = await autoTuneRoomCapacity(roomId: roomId);
      results['success'] = true;
    } catch (e) {
      results['error'] = e.toString();
      results['success'] = false;
    }

    return results;
  }

  /// Run platform-wide optimization
  Future<Map<String, dynamic>> runPlatformOptimization() async {
    debugPrint('🔧 [OptimizationEngine] Running platform-wide optimization');

    final results = <String, dynamic>{};

    try {
      // Optimize indexes for key collections
      results['roomsIndex'] = await autoOptimizeFirestoreIndexes(collectionPath: 'rooms');
      results['messagesIndex'] = await autoOptimizeFirestoreIndexes(collectionPath: 'messages');
      results['usersIndex'] = await autoOptimizeFirestoreIndexes(collectionPath: 'users');

      // Optimize server regions
      results['serverRegions'] = await autoBalanceServerRegions();

      results['success'] = true;
      results['completedAt'] = DateTime.now().toIso8601String();

      // Track analytics
      AnalyticsService.instance.logEvent(name: 'platform_optimization', parameters: {
        'collections_optimized': 3,
        'regions_analyzed': true,
      });
    } catch (e) {
      results['error'] = e.toString();
      results['success'] = false;
    }

    return results;
  }

  // ============================================================
  // UTILITY METHODS
  // ============================================================

  Future<void> _logOptimization(OptimizationType type, Map<String, dynamic> data) async {
    try {
      await _optimizationLogsCollection.add({
        ...data,
        'optimizationType': type.name,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('⚠️ [OptimizationEngine] Failed to log optimization: $e');
    }
  }

  /// Get optimization history
  Future<List<Map<String, dynamic>>> getOptimizationHistory({
    OptimizationType? type,
    int limit = 50,
  }) async {
    var query = _optimizationLogsCollection
        .orderBy('timestamp', descending: true)
        .limit(limit);

    if (type != null) {
      query = query.where('optimizationType', isEqualTo: type.name);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  /// Dispose resources
  void dispose() {
    _optimizationController.close();
  }
}
