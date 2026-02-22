/// Scale Service
///
/// Manages auto-scaling of rooms, video pipelines, Firestore listeners,
/// and load distribution across regions for optimal performance at scale.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../analytics/analytics_service.dart';
import 'load_monitor.dart';

/// Configuration for scaling thresholds
class ScaleConfig {
  final int maxParticipantsPerRoom;
  final int maxStreamsPerPipeline;
  final int firestoreListenerThreshold;
  final double cpuThreshold;
  final double memoryThreshold;
  final int shardThreshold;

  const ScaleConfig({
    this.maxParticipantsPerRoom = 100,
    this.maxStreamsPerPipeline = 50,
    this.firestoreListenerThreshold = 1000,
    this.cpuThreshold = 0.8,
    this.memoryThreshold = 0.85,
    this.shardThreshold = 10000,
  });
}

/// Represents a scaling action taken
class ScaleAction {
  final String id;
  final ScaleActionType type;
  final String resourceId;
  final ScaleDirection direction;
  final int previousCapacity;
  final int newCapacity;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  ScaleAction({
    required this.id,
    required this.type,
    required this.resourceId,
    required this.direction,
    required this.previousCapacity,
    required this.newCapacity,
    required this.timestamp,
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type.name,
    'resourceId': resourceId,
    'direction': direction.name,
    'previousCapacity': previousCapacity,
    'newCapacity': newCapacity,
    'timestamp': timestamp.toIso8601String(),
    'metadata': metadata,
  };
}

enum ScaleActionType {
  room,
  videoPipeline,
  firestoreListener,
  shard,
  regionDistribution,
}

enum ScaleDirection {
  up,
  down,
  rebalance,
}

/// Represents a region for load distribution
class Region {
  final String id;
  final String name;
  final double latency;
  final double currentLoad;
  final int activeRooms;
  final bool isHealthy;

  const Region({
    required this.id,
    required this.name,
    required this.latency,
    required this.currentLoad,
    required this.activeRooms,
    this.isHealthy = true,
  });

  factory Region.fromMap(Map<String, dynamic> map) {
    return Region(
      id: map['id'] as String,
      name: map['name'] as String,
      latency: (map['latency'] as num).toDouble(),
      currentLoad: (map['currentLoad'] as num).toDouble(),
      activeRooms: map['activeRooms'] as int,
      isHealthy: map['isHealthy'] as bool? ?? true,
    );
  }
}

/// Represents a sharded room configuration
class ShardedRoom {
  final String roomId;
  final int shardCount;
  final List<String> shardIds;
  final int totalParticipants;
  final Map<String, int> participantsPerShard;

  const ShardedRoom({
    required this.roomId,
    required this.shardCount,
    required this.shardIds,
    required this.totalParticipants,
    required this.participantsPerShard,
  });
}

/// Service for managing auto-scaling and load distribution
class ScaleService {
  static ScaleService? _instance;
  static ScaleService get instance => _instance ??= ScaleService._();

  ScaleService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // ignore: unused_field
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  CollectionReference<Map<String, dynamic>> get _scaleActionsCollection =>
      _firestore.collection('scale_actions');

  CollectionReference<Map<String, dynamic>> get _regionsCollection =>
      _firestore.collection('regions');

  CollectionReference<Map<String, dynamic>> get _shardsCollection =>
      _firestore.collection('room_shards');

  // Configuration
  ScaleConfig _config = const ScaleConfig();

  // Cache
  final Map<String, int> _roomCapacities = {};
  final Map<String, int> _pipelineCapacities = {};
  final List<Region> _availableRegions = [];
  final Map<String, ShardedRoom> _shardedRooms = {};

  // Timers
  Timer? _autoScaleTimer;

  // Stream controllers
  final _scaleActionController = StreamController<ScaleAction>.broadcast();

  /// Stream of scaling actions
  Stream<ScaleAction> get scaleActionStream => _scaleActionController.stream;

  /// Update scale configuration
  void updateConfig(ScaleConfig config) {
    _config = config;
  }

  /// Initialize the service
  Future<void> initialize() async {
    await _loadRegions();
    _startAutoScaling();

    AnalyticsService.instance.logEvent(
      name: 'scale_service_initialized',
      parameters: {
        'regions_count': _availableRegions.length,
      },
    );
  }

  /// Auto-scale rooms based on participant count
  Future<List<ScaleAction>> autoscaleRooms() async {
    final actions = <ScaleAction>[];

    // Get rooms that need scaling
    final roomsSnapshot = await _firestore
        .collection('rooms')
        .where('status', isEqualTo: 'active')
        .get();

    for (final doc in roomsSnapshot.docs) {
      final roomId = doc.id;
      final data = doc.data();
      final participantCount = (data['participantCount'] as int?) ?? 0;
      final currentCapacity = _roomCapacities[roomId] ?? _config.maxParticipantsPerRoom;

      // Scale up if approaching capacity
      if (participantCount > currentCapacity * 0.8) {
        final action = await _scaleRoomUp(roomId, currentCapacity);
        if (action != null) actions.add(action);
      }
      // Scale down if underutilized
      else if (participantCount < currentCapacity * 0.3 && currentCapacity > _config.maxParticipantsPerRoom) {
        final action = await _scaleRoomDown(roomId, currentCapacity);
        if (action != null) actions.add(action);
      }
    }

    if (actions.isNotEmpty) {
      AnalyticsService.instance.logEvent(
        name: 'rooms_autoscaled',
        parameters: {
          'actions_count': actions.length,
          'scale_ups': actions.where((a) => a.direction == ScaleDirection.up).length,
          'scale_downs': actions.where((a) => a.direction == ScaleDirection.down).length,
        },
      );
    }

    return actions;
  }

  /// Auto-scale video pipelines based on stream count
  Future<List<ScaleAction>> autoscaleVideoPipelines() async {
    final actions = <ScaleAction>[];

    // Get active video sessions
    final sessionsSnapshot = await _firestore
        .collection('video_sessions')
        .where('status', isEqualTo: 'active')
        .get();

    // Group by pipeline
    final pipelineStreams = <String, int>{};
    for (final doc in sessionsSnapshot.docs) {
      final pipelineId = doc.data()['pipelineId'] as String? ?? 'default';
      pipelineStreams[pipelineId] = (pipelineStreams[pipelineId] ?? 0) + 1;
    }

    for (final entry in pipelineStreams.entries) {
      final pipelineId = entry.key;
      final streamCount = entry.value;
      final currentCapacity = _pipelineCapacities[pipelineId] ?? _config.maxStreamsPerPipeline;

      // Scale up if approaching capacity
      if (streamCount > currentCapacity * 0.75) {
        final newCapacity = (currentCapacity * 1.5).round();

        final action = ScaleAction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: ScaleActionType.videoPipeline,
          resourceId: pipelineId,
          direction: ScaleDirection.up,
          previousCapacity: currentCapacity,
          newCapacity: newCapacity,
          timestamp: DateTime.now(),
          metadata: {'streamCount': streamCount},
        );

        await _recordScaleAction(action);
        _pipelineCapacities[pipelineId] = newCapacity;
        actions.add(action);
      }
    }

    if (actions.isNotEmpty) {
      AnalyticsService.instance.logEvent(
        name: 'video_pipelines_autoscaled',
        parameters: {'actions_count': actions.length},
      );
    }

    return actions;
  }

  /// Auto-scale Firestore listeners based on load
  Future<List<ScaleAction>> autoscaleFirestoreListeners() async {
    final actions = <ScaleAction>[];

    final stats = LoadMonitor.instance.currentStats;
    if (stats == null) return actions;

    final activeListeners = stats.activeFirestoreListeners;

    // Check if we need to optimize listeners
    if (activeListeners > _config.firestoreListenerThreshold) {
      // Consolidate listeners for efficiency
      final action = ScaleAction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: ScaleActionType.firestoreListener,
        resourceId: 'global',
        direction: ScaleDirection.rebalance,
        previousCapacity: activeListeners,
        newCapacity: (activeListeners * 0.7).round(),
        timestamp: DateTime.now(),
        metadata: {'reason': 'threshold_exceeded'},
      );

      await _recordScaleAction(action);
      actions.add(action);

      AnalyticsService.instance.logEvent(
        name: 'firestore_listeners_optimized',
        parameters: {
          'previous_count': activeListeners,
          'target_reduction': 30,
        },
      );
    }

    return actions;
  }

  /// Shard high-traffic rooms for better performance
  Future<ShardedRoom?> shardHighTrafficRooms(String roomId) async {
    final roomDoc = await _firestore.collection('rooms').doc(roomId).get();
    if (!roomDoc.exists) return null;

    final data = roomDoc.data()!;
    final participantCount = (data['participantCount'] as int?) ?? 0;

    // Check if room needs sharding
    if (participantCount < _config.shardThreshold) return null;

    // Check if already sharded
    if (_shardedRooms.containsKey(roomId)) {
      return _expandShards(roomId, participantCount);
    }

    // Calculate shard count
    final shardCount = (participantCount / _config.maxParticipantsPerRoom).ceil();
    final shardIds = <String>[];

    // Create shards
    final batch = _firestore.batch();
    for (var i = 0; i < shardCount; i++) {
      final shardId = '${roomId}_shard_$i';
      shardIds.add(shardId);

      batch.set(_shardsCollection.doc(shardId), {
        'roomId': roomId,
        'shardIndex': i,
        'capacity': _config.maxParticipantsPerRoom,
        'participantCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();

    // Update room to sharded status
    await _firestore.collection('rooms').doc(roomId).update({
      'isSharded': true,
      'shardCount': shardCount,
      'shardIds': shardIds,
    });

    final shardedRoom = ShardedRoom(
      roomId: roomId,
      shardCount: shardCount,
      shardIds: shardIds,
      totalParticipants: participantCount,
      participantsPerShard: {},
    );

    _shardedRooms[roomId] = shardedRoom;

    AnalyticsService.instance.logEvent(
      name: 'room_sharded',
      parameters: {
        'room_id': roomId,
        'shard_count': shardCount,
        'participant_count': participantCount,
      },
    );

    return shardedRoom;
  }

  /// Distribute load across regions
  Future<Map<String, double>> distributeLoadAcrossRegions() async {
    if (_availableRegions.isEmpty) await _loadRegions();

    final healthyRegions = _availableRegions.where((r) => r.isHealthy).toList();
    if (healthyRegions.isEmpty) return {};

    // Calculate total load
    final totalLoad = healthyRegions.fold<double>(
      0,
      (total, region) => total + region.currentLoad,
    );

    // Calculate ideal distribution
    final idealLoadPerRegion = totalLoad / healthyRegions.length;

    // Calculate rebalancing targets
    final targets = <String, double>{};
    for (final region in healthyRegions) {
      final currentLoad = region.currentLoad;
      final targetAdjustment = idealLoadPerRegion - currentLoad;
      targets[region.id] = targetAdjustment;
    }

    // Record rebalancing action
    final action = ScaleAction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: ScaleActionType.regionDistribution,
      resourceId: 'global',
      direction: ScaleDirection.rebalance,
      previousCapacity: totalLoad.round(),
      newCapacity: totalLoad.round(),
      timestamp: DateTime.now(),
      metadata: {
        'regions': healthyRegions.map((r) => r.id).toList(),
        'targets': targets,
      },
    );

    await _recordScaleAction(action);

    AnalyticsService.instance.logEvent(
      name: 'load_distributed',
      parameters: {
        'region_count': healthyRegions.length,
        'total_load': totalLoad,
      },
    );

    return targets;
  }

  /// Get optimal shard for a user joining a room
  Future<String?> getOptimalShardForJoin(String roomId) async {
    final shardedRoom = _shardedRooms[roomId];
    if (shardedRoom == null) return null;

    // Find shard with lowest participant count
    String? optimalShard;
    int lowestCount = _config.maxParticipantsPerRoom;

    for (final shardId in shardedRoom.shardIds) {
      final shardDoc = await _shardsCollection.doc(shardId).get();
      if (!shardDoc.exists) continue;

      final count = (shardDoc.data()?['participantCount'] as int?) ?? 0;
      if (count < lowestCount) {
        lowestCount = count;
        optimalShard = shardId;
      }
    }

    return optimalShard;
  }

  /// Get best region for a user based on latency
  Future<Region?> getBestRegionForUser(String userId) async {
    if (_availableRegions.isEmpty) await _loadRegions();

    final healthyRegions = _availableRegions.where((r) => r.isHealthy).toList();
    if (healthyRegions.isEmpty) return null;

    // Sort by combination of latency and load
    healthyRegions.sort((a, b) {
      final scoreA = a.latency * 0.7 + a.currentLoad * 0.3;
      final scoreB = b.latency * 0.7 + b.currentLoad * 0.3;
      return scoreA.compareTo(scoreB);
    });

    return healthyRegions.first;
  }

  /// Get scaling statistics
  Future<Map<String, dynamic>> getScalingStats() async {
    final stats = LoadMonitor.instance.currentStats;

    return {
      'activeRegions': _availableRegions.where((r) => r.isHealthy).length,
      'shardedRooms': _shardedRooms.length,
      'roomCapacities': _roomCapacities.length,
      'pipelineCapacities': _pipelineCapacities.length,
      'loadStats': stats?.toMap(),
    };
  }

  // Private methods

  Future<void> _loadRegions() async {
    final snapshot = await _regionsCollection.get();

    _availableRegions.clear();
    for (final doc in snapshot.docs) {
      _availableRegions.add(Region.fromMap(doc.data()));
    }

    // Add default regions if none exist
    if (_availableRegions.isEmpty) {
      _availableRegions.addAll([
        const Region(
          id: 'us-east-1',
          name: 'US East',
          latency: 50,
          currentLoad: 0.4,
          activeRooms: 0,
        ),
        const Region(
          id: 'us-west-2',
          name: 'US West',
          latency: 70,
          currentLoad: 0.3,
          activeRooms: 0,
        ),
        const Region(
          id: 'eu-west-1',
          name: 'Europe',
          latency: 100,
          currentLoad: 0.35,
          activeRooms: 0,
        ),
        const Region(
          id: 'ap-southeast-1',
          name: 'Asia Pacific',
          latency: 150,
          currentLoad: 0.25,
          activeRooms: 0,
        ),
      ]);
    }
  }

  void _startAutoScaling() {
    _autoScaleTimer?.cancel();
    _autoScaleTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      await autoscaleRooms();
      await autoscaleVideoPipelines();
      await autoscaleFirestoreListeners();
    });
  }

  Future<ScaleAction?> _scaleRoomUp(String roomId, int currentCapacity) async {
    final newCapacity = (currentCapacity * 1.5).round();

    final action = ScaleAction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: ScaleActionType.room,
      resourceId: roomId,
      direction: ScaleDirection.up,
      previousCapacity: currentCapacity,
      newCapacity: newCapacity,
      timestamp: DateTime.now(),
    );

    await _recordScaleAction(action);
    _roomCapacities[roomId] = newCapacity;
    _scaleActionController.add(action);

    return action;
  }

  Future<ScaleAction?> _scaleRoomDown(String roomId, int currentCapacity) async {
    final newCapacity = (currentCapacity * 0.7).round().clamp(
      _config.maxParticipantsPerRoom,
      currentCapacity,
    );

    if (newCapacity >= currentCapacity) return null;

    final action = ScaleAction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: ScaleActionType.room,
      resourceId: roomId,
      direction: ScaleDirection.down,
      previousCapacity: currentCapacity,
      newCapacity: newCapacity,
      timestamp: DateTime.now(),
    );

    await _recordScaleAction(action);
    _roomCapacities[roomId] = newCapacity;
    _scaleActionController.add(action);

    return action;
  }

  Future<ShardedRoom?> _expandShards(String roomId, int participantCount) async {
    final existing = _shardedRooms[roomId];
    if (existing == null) return null;

    final neededShards = (participantCount / _config.maxParticipantsPerRoom).ceil();
    if (neededShards <= existing.shardCount) return existing;

    // Add new shards
    final newShardIds = List<String>.from(existing.shardIds);
    final batch = _firestore.batch();

    for (var i = existing.shardCount; i < neededShards; i++) {
      final shardId = '${roomId}_shard_$i';
      newShardIds.add(shardId);

      batch.set(_shardsCollection.doc(shardId), {
        'roomId': roomId,
        'shardIndex': i,
        'capacity': _config.maxParticipantsPerRoom,
        'participantCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();

    await _firestore.collection('rooms').doc(roomId).update({
      'shardCount': neededShards,
      'shardIds': newShardIds,
    });

    final updatedRoom = ShardedRoom(
      roomId: roomId,
      shardCount: neededShards,
      shardIds: newShardIds,
      totalParticipants: participantCount,
      participantsPerShard: existing.participantsPerShard,
    );

    _shardedRooms[roomId] = updatedRoom;
    return updatedRoom;
  }

  Future<void> _recordScaleAction(ScaleAction action) async {
    await _scaleActionsCollection.doc(action.id).set(action.toMap());
  }

  /// Dispose resources
  void dispose() {
    _autoScaleTimer?.cancel();
    _scaleActionController.close();
  }
}


