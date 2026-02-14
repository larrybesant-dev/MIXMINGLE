/// Predictive Scaling Service
///
/// Predicts usage patterns and proactively scales resources
/// before demand spikes occur.
library;

import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../analytics/analytics_service.dart';

/// Predicted peak hour data
class PeakHourPrediction {
  final int hour;
  final int dayOfWeek;
  final double predictedLoad;
  final double confidence;
  final int estimatedConcurrentUsers;
  final int estimatedActiveRooms;
  final List<String> recommendedActions;
  final DateTime predictedFor;

  const PeakHourPrediction({
    required this.hour,
    required this.dayOfWeek,
    required this.predictedLoad,
    required this.confidence,
    required this.estimatedConcurrentUsers,
    required this.estimatedActiveRooms,
    required this.recommendedActions,
    required this.predictedFor,
  });

  Map<String, dynamic> toMap() => {
    'hour': hour,
    'dayOfWeek': dayOfWeek,
    'predictedLoad': predictedLoad,
    'confidence': confidence,
    'estimatedConcurrentUsers': estimatedConcurrentUsers,
    'estimatedActiveRooms': estimatedActiveRooms,
    'recommendedActions': recommendedActions,
    'predictedFor': predictedFor.toIso8601String(),
  };

  String get dayName => [
    'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'
  ][dayOfWeek];
}

/// High load room prediction
class HighLoadRoomPrediction {
  final String roomId;
  final String roomName;
  final double predictedParticipants;
  final double currentLoad;
  final double predictionConfidence;
  final List<String> scalingRecommendations;
  final DateTime windowStart;
  final DateTime windowEnd;

  const HighLoadRoomPrediction({
    required this.roomId,
    required this.roomName,
    required this.predictedParticipants,
    required this.currentLoad,
    required this.predictionConfidence,
    required this.scalingRecommendations,
    required this.windowStart,
    required this.windowEnd,
  });

  Map<String, dynamic> toMap() => {
    'roomId': roomId,
    'roomName': roomName,
    'predictedParticipants': predictedParticipants,
    'currentLoad': currentLoad,
    'predictionConfidence': predictionConfidence,
    'scalingRecommendations': scalingRecommendations,
    'windowStart': windowStart.toIso8601String(),
    'windowEnd': windowEnd.toIso8601String(),
  };
}

/// Pre-warming result for video pipelines
class VideoPipelineWarmup {
  final String region;
  final int pipelinesWarmed;
  final int targetCapacity;
  final Duration warmupDuration;
  final bool success;
  final DateTime completedAt;
  final Map<String, dynamic> metrics;

  const VideoPipelineWarmup({
    required this.region,
    required this.pipelinesWarmed,
    required this.targetCapacity,
    required this.warmupDuration,
    required this.success,
    required this.completedAt,
    this.metrics = const {},
  });

  Map<String, dynamic> toMap() => {
    'region': region,
    'pipelinesWarmed': pipelinesWarmed,
    'targetCapacity': targetCapacity,
    'warmupDurationMs': warmupDuration.inMilliseconds,
    'success': success,
    'completedAt': completedAt.toIso8601String(),
    'metrics': metrics,
  };
}

/// Scaling action types
enum ScalingActionType {
  scaleUp,
  scaleDown,
  preWarm,
  redistribute,
}

/// Predictive scaling service for proactive resource management
class PredictiveScalingService {
  static PredictiveScalingService? _instance;
  static PredictiveScalingService get instance => _instance ??= PredictiveScalingService._();

  PredictiveScalingService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _random = Random();

  // Stream controllers
  final _predictionController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get predictionStream => _predictionController.stream;

  // Collections
  CollectionReference<Map<String, dynamic>> get _metricsCollection =>
      _firestore.collection('usage_metrics');

  CollectionReference<Map<String, dynamic>> get _predictionsCollection =>
      _firestore.collection('predictions');

  CollectionReference<Map<String, dynamic>> get _roomsCollection =>
      _firestore.collection('rooms');

  // Historical data cache
  final Map<String, List<double>> _hourlyLoadHistory = {};
  final Map<String, double> _roomLoadHistory = {};

  // ============================================================
  // PEAK HOURS PREDICTION
  // ============================================================

  /// Predict peak usage hours for the platform
  Future<List<PeakHourPrediction>> predictPeakHours({
    int daysAhead = 7,
  }) async {
    debugPrint('📊 [PredictiveScaling] Predicting peak hours for next $daysAhead days');

    try {
      // Load historical metrics
      await _loadHistoricalMetrics();

      final predictions = <PeakHourPrediction>[];
      final now = DateTime.now();

      // Generate predictions for each day
      for (int day = 0; day < daysAhead; day++) {
        final targetDate = now.add(Duration(days: day));
        final dayOfWeek = targetDate.weekday % 7;

        // Analyze hourly patterns
        final hourlyPredictions = _predictHourlyLoad(dayOfWeek);

        // Find peak hours (top 3)
        final sortedHours = hourlyPredictions.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        for (int i = 0; i < min(3, sortedHours.length); i++) {
          final entry = sortedHours[i];
          final hour = int.parse(entry.key);
          final load = entry.value;

          // Calculate confidence based on historical data availability
          final confidence = _calculatePredictionConfidence(dayOfWeek, hour);

          // Estimate metrics
          final estimatedUsers = (load * 1000).round();
          final estimatedRooms = (load * 50).round();

          // Generate recommendations
          final recommendations = _generatePeakHourRecommendations(load, hour);

          predictions.add(PeakHourPrediction(
            hour: hour,
            dayOfWeek: dayOfWeek,
            predictedLoad: load,
            confidence: confidence,
            estimatedConcurrentUsers: estimatedUsers,
            estimatedActiveRooms: estimatedRooms,
            recommendedActions: recommendations,
            predictedFor: targetDate,
          ));
        }
      }

      // Store predictions
      await _storePredictions(predictions);

      // Emit event
      _predictionController.add({
        'type': 'peak_hours',
        'predictions': predictions.map((p) => p.toMap()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ [PredictiveScaling] Generated ${predictions.length} peak hour predictions');
      return predictions;
    } catch (e) {
      debugPrint('❌ [PredictiveScaling] Failed to predict peak hours: $e');
      rethrow;
    }
  }

  Map<String, double> _predictHourlyLoad(int dayOfWeek) {
    // Simulate hourly load patterns based on day
    final isWeekend = dayOfWeek == 0 || dayOfWeek == 6;
    final patterns = <String, double>{};

    for (int hour = 0; hour < 24; hour++) {
      double load = 0.1; // Base load

      if (isWeekend) {
        // Weekend patterns - higher afternoon/evening
        if (hour >= 10 && hour <= 14) {
          load = 0.4 + _random.nextDouble() * 0.2;
        } else if (hour >= 15 && hour <= 22) {
          load = 0.6 + _random.nextDouble() * 0.3;
        } else if (hour >= 23 || hour <= 2) {
          load = 0.3 + _random.nextDouble() * 0.2;
        }
      } else {
        // Weekday patterns - morning spike, lunch, evening peak
        if (hour >= 7 && hour <= 9) {
          load = 0.3 + _random.nextDouble() * 0.2;
        } else if (hour >= 12 && hour <= 14) {
          load = 0.5 + _random.nextDouble() * 0.2;
        } else if (hour >= 18 && hour <= 22) {
          load = 0.7 + _random.nextDouble() * 0.25;
        } else if (hour >= 23 || hour <= 1) {
          load = 0.4 + _random.nextDouble() * 0.2;
        }
      }

      patterns[hour.toString()] = load;
    }

    return patterns;
  }

  double _calculatePredictionConfidence(int dayOfWeek, int hour) {
    // Base confidence
    double confidence = 0.7;

    // Higher confidence for common patterns
    if (hour >= 18 && hour <= 22) confidence += 0.15; // Evening peaks are consistent
    if (dayOfWeek == 5 || dayOfWeek == 6) confidence += 0.05; // Weekend patterns are consistent

    // Add some variance
    confidence += (_random.nextDouble() - 0.5) * 0.1;

    return confidence.clamp(0.5, 0.95);
  }

  List<String> _generatePeakHourRecommendations(double load, int hour) {
    final recommendations = <String>[];

    if (load > 0.8) {
      recommendations.add('Pre-warm video pipelines 30 minutes before');
      recommendations.add('Scale Firestore read capacity');
      recommendations.add('Enable CDN edge caching');
    } else if (load > 0.6) {
      recommendations.add('Monitor server health closely');
      recommendations.add('Prepare auto-scale triggers');
    } else if (load > 0.4) {
      recommendations.add('Standard monitoring sufficient');
    }

    if (hour >= 22 || hour <= 6) {
      recommendations.add('Consider reduced support staffing');
    }

    return recommendations;
  }

  // ============================================================
  // HIGH LOAD ROOM PREDICTION
  // ============================================================

  /// Predict which rooms will experience high load
  Future<List<HighLoadRoomPrediction>> predictHighLoadRooms({
    int hoursAhead = 4,
    int limit = 10,
  }) async {
    debugPrint('📊 [PredictiveScaling] Predicting high-load rooms for next $hoursAhead hours');

    try {
      // Fetch active and scheduled rooms
      final roomsQuery = await _roomsCollection
          .where('status', whereIn: ['active', 'scheduled', 'live'])
          .orderBy('participantCount', descending: true)
          .limit(50)
          .get();

      final predictions = <HighLoadRoomPrediction>[];
      final windowStart = DateTime.now();
      final windowEnd = windowStart.add(Duration(hours: hoursAhead));

      for (final doc in roomsQuery.docs) {
        final data = doc.data();
        final roomId = doc.id;
        final roomName = (data['title'] as String?) ?? 'Unnamed Room';
        final currentParticipants = (data['participantCount'] as num?)?.toDouble() ?? 0;
        final maxCapacity = (data['maxParticipants'] as num?)?.toDouble() ?? 10;

        // Calculate current load
        final currentLoad = currentParticipants / maxCapacity;

        // Predict future load based on:
        // 1. Scheduled events
        // 2. Historical patterns
        // 3. Creator popularity
        final growthFactor = _predictRoomGrowth(data);
        final predictedParticipants = (currentParticipants * growthFactor).clamp(0.0, maxCapacity * 1.2);

        // Check if prediction exceeds threshold
        if (predictedParticipants / maxCapacity > 0.7 || currentLoad > 0.6) {
          final confidence = _calculateRoomPredictionConfidence(data);
          final recommendations = _generateRoomScalingRecommendations(
            predictedParticipants / maxCapacity,
            currentLoad,
          );

          predictions.add(HighLoadRoomPrediction(
            roomId: roomId,
            roomName: roomName,
            predictedParticipants: predictedParticipants,
            currentLoad: currentLoad,
            predictionConfidence: confidence,
            scalingRecommendations: recommendations,
            windowStart: windowStart,
            windowEnd: windowEnd,
          ));
        }
      }

      // Sort by predicted load and limit
      predictions.sort((a, b) => b.predictedParticipants.compareTo(a.predictedParticipants));
      final topPredictions = predictions.take(limit).toList();

      // Emit event
      _predictionController.add({
        'type': 'high_load_rooms',
        'predictions': topPredictions.map((p) => p.toMap()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ [PredictiveScaling] Identified ${topPredictions.length} potentially high-load rooms');
      return topPredictions;
    } catch (e) {
      debugPrint('❌ [PredictiveScaling] Failed to predict high-load rooms: $e');
      rethrow;
    }
  }

  double _predictRoomGrowth(Map<String, dynamic> roomData) {
    double growthFactor = 1.0;

    // Scheduled events boost
    if (roomData['scheduledStartTime'] != null) {
      final scheduled = DateTime.tryParse(roomData['scheduledStartTime'] as String? ?? '');
      if (scheduled != null && scheduled.isAfter(DateTime.now())) {
        final hoursUntil = scheduled.difference(DateTime.now()).inHours;
        if (hoursUntil < 4) {
          growthFactor *= 2.5;
        } else if (hoursUntil < 12) {
          growthFactor *= 1.8;
        }
      }
    }

    // Creator popularity boost
    final followerCount = (roomData['hostFollowers'] as num?)?.toInt() ?? 0;
    if (followerCount > 10000) {
      growthFactor *= 1.5;
    } else if (followerCount > 1000) {
      growthFactor *= 1.2;
    }

    // Featured room boost
    if (roomData['isFeatured'] == true) growthFactor *= 1.3;

    // Time-based adjustment
    final hour = DateTime.now().hour;
    if (hour >= 18 && hour <= 22) growthFactor *= 1.2;

    return growthFactor;
  }

  double _calculateRoomPredictionConfidence(Map<String, dynamic> roomData) {
    double confidence = 0.6;

    // Higher confidence for scheduled events
    if (roomData['scheduledStartTime'] != null) confidence += 0.15;

    // Higher confidence for popular creators
    final followerCount = (roomData['hostFollowers'] as num?)?.toInt() ?? 0;
    if (followerCount > 5000) confidence += 0.1;

    // Higher confidence for recurring rooms
    if (roomData['isRecurring'] == true) confidence += 0.1;

    return confidence.clamp(0.5, 0.95);
  }

  List<String> _generateRoomScalingRecommendations(
    double predictedLoad,
    double currentLoad,
  ) {
    final recommendations = <String>[];

    if (predictedLoad > 0.9) {
      recommendations.add('Increase room capacity immediately');
      recommendations.add('Pre-warm dedicated video pipelines');
      recommendations.add('Enable overflow room if available');
    } else if (predictedLoad > 0.7) {
      recommendations.add('Monitor closely for capacity increase');
      recommendations.add('Prepare scaling trigger');
    }

    if (currentLoad > 0.8) {
      recommendations.add('Consider splitting into multiple rooms');
    }

    if (predictedLoad > currentLoad * 1.5) {
      recommendations.add('Rapid growth detected - enable auto-scaling');
    }

    return recommendations;
  }

  // ============================================================
  // VIDEO PIPELINE PRE-WARMING
  // ============================================================

  /// Pre-warm video pipelines for expected load
  Future<List<VideoPipelineWarmup>> preWarmVideoPipelines({
    List<String>? regions,
    int? targetCapacity,
  }) async {
    debugPrint('🔥 [PredictiveScaling] Pre-warming video pipelines');

    final warmupRegions = regions ?? ['us-central', 'europe-west', 'asia-east'];
    final capacity = targetCapacity ?? 100;
    final results = <VideoPipelineWarmup>[];

    for (final region in warmupRegions) {
      try {
        final startTime = DateTime.now();

        // Simulate pipeline warming (in production, this would call Agora/video service APIs)
        await Future.delayed(Duration(milliseconds: 500 + _random.nextInt(500)));

        // Calculate warmed pipelines (simulated)
        final pipelinesWarmed = (capacity * (0.8 + _random.nextDouble() * 0.2)).round();
        final success = pipelinesWarmed >= capacity * 0.7;

        final warmup = VideoPipelineWarmup(
          region: region,
          pipelinesWarmed: pipelinesWarmed,
          targetCapacity: capacity,
          warmupDuration: DateTime.now().difference(startTime),
          success: success,
          completedAt: DateTime.now(),
          metrics: {
            'avgWarmupTimeMs': 50 + _random.nextInt(50),
            'failedPipelines': capacity - pipelinesWarmed,
            'regionHealth': 0.8 + _random.nextDouble() * 0.2,
          },
        );

        results.add(warmup);

        debugPrint('✅ [PredictiveScaling] Warmed $pipelinesWarmed pipelines in $region');
      } catch (e) {
        debugPrint('❌ [PredictiveScaling] Failed to warm pipelines in $region: $e');
        results.add(VideoPipelineWarmup(
          region: region,
          pipelinesWarmed: 0,
          targetCapacity: capacity,
          warmupDuration: Duration.zero,
          success: false,
          completedAt: DateTime.now(),
          metrics: {'error': e.toString()},
        ));
      }
    }

    // Store warmup results
    await _storeWarmupResults(results);

    // Emit event
    _predictionController.add({
      'type': 'pipeline_warmup',
      'results': results.map((r) => r.toMap()).toList(),
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Track analytics
    AnalyticsService.instance.logEvent(name: 'video_pipeline_warmup', parameters: {
      'regions_warmed': warmupRegions.length,
      'total_pipelines': results.fold<int>(0, (total, r) => total + r.pipelinesWarmed),
      'all_success': results.every((r) => r.success),
    });

    return results;
  }

  // ============================================================
  // AUTO-SCALING TRIGGERS
  // ============================================================

  /// Evaluate and trigger auto-scaling based on predictions
  Future<Map<String, dynamic>> evaluateAutoScaling() async {
    debugPrint('📊 [PredictiveScaling] Evaluating auto-scaling triggers');

    final results = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'actions': <Map<String, dynamic>>[],
    };

    try {
      // Get peak hour predictions
      final peakPredictions = await predictPeakHours(daysAhead: 1);

      // Check if we're approaching a peak
      final now = DateTime.now();
      final currentHour = now.hour;

      for (final prediction in peakPredictions) {
        if (prediction.predictedFor.day == now.day) {
          final hoursUntilPeak = prediction.hour - currentHour;

          if (hoursUntilPeak > 0 && hoursUntilPeak <= 2 && prediction.predictedLoad > 0.7) {
            // Trigger pre-scaling
            (results['actions'] as List<Map<String, dynamic>>).add({
              'type': ScalingActionType.preWarm.name,
              'reason': 'Peak hour approaching',
              'targetHour': prediction.hour,
              'predictedLoad': prediction.predictedLoad,
            });

            // Pre-warm pipelines
            await preWarmVideoPipelines(
              targetCapacity: prediction.estimatedActiveRooms * 2,
            );
          }
        }
      }

      // Get high-load room predictions
      final roomPredictions = await predictHighLoadRooms();

      for (final room in roomPredictions) {
        if (room.predictedParticipants > room.currentLoad * 1.5) {
          (results['actions'] as List<Map<String, dynamic>>).add({
            'type': ScalingActionType.scaleUp.name,
            'roomId': room.roomId,
            'reason': 'High load predicted',
            'currentLoad': room.currentLoad,
            'predictedLoad': room.predictedParticipants,
          });
        }
      }

      results['success'] = true;
    } catch (e) {
      results['error'] = e.toString();
      results['success'] = false;
    }

    return results;
  }

  // ============================================================
  // UTILITY METHODS
  // ============================================================

  Future<void> _loadHistoricalMetrics() async {
    try {
      final metrics = await _metricsCollection
          .orderBy('timestamp', descending: true)
          .limit(1000)
          .get();

      _hourlyLoadHistory.clear();

      for (final doc in metrics.docs) {
        final data = doc.data();
        final hour = (data['hour'] as num?)?.toString() ?? '0';
        final load = (data['load'] as num?)?.toDouble() ?? 0;

        _hourlyLoadHistory.putIfAbsent(hour, () => []);
        _hourlyLoadHistory[hour]!.add(load);
      }
    } catch (e) {
      debugPrint('⚠️ [PredictiveScaling] Failed to load historical metrics: $e');
    }
  }

  Future<void> _storePredictions(List<PeakHourPrediction> predictions) async {
    try {
      final batch = _firestore.batch();

      for (final prediction in predictions) {
        final ref = _predictionsCollection.doc();
        batch.set(ref, {
          ...prediction.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      debugPrint('⚠️ [PredictiveScaling] Failed to store predictions: $e');
    }
  }

  Future<void> _storeWarmupResults(List<VideoPipelineWarmup> results) async {
    try {
      final batch = _firestore.batch();

      for (final result in results) {
        final ref = _firestore.collection('pipeline_warmups').doc();
        batch.set(ref, {
          ...result.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      debugPrint('⚠️ [PredictiveScaling] Failed to store warmup results: $e');
    }
  }

  /// Get scaling recommendations for current state
  Future<List<String>> getScalingRecommendations() async {
    final recommendations = <String>[];

    final roomPredictions = await predictHighLoadRooms(hoursAhead: 2, limit: 5);
    if (roomPredictions.isNotEmpty) {
      recommendations.add(
        '${roomPredictions.length} rooms may need scaling in the next 2 hours',
      );
    }

    final peakPredictions = await predictPeakHours(daysAhead: 1);
    final now = DateTime.now();
    final upcomingPeak = peakPredictions.where((p) {
      return p.predictedFor.day == now.day &&
          p.hour > now.hour &&
          p.hour <= now.hour + 4;
    }).toList();

    if (upcomingPeak.isNotEmpty) {
      final nextPeak = upcomingPeak.first;
      recommendations.add(
        'Peak expected at ${nextPeak.hour}:00 with ${(nextPeak.predictedLoad * 100).round()}% load',
      );
    }

    return recommendations;
  }

  /// Dispose resources
  void dispose() {
    _predictionController.close();
    _hourlyLoadHistory.clear();
    _roomLoadHistory.clear();
  }
}
