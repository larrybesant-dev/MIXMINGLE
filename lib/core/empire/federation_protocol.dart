/// Federation Protocol
///
/// Low-level protocol for federation handshakes, state sync, and conflict resolution.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// Protocol message type
enum ProtocolMessageType {
  handshake,
  handshakeAck,
  syncRequest,
  syncResponse,
  syncDelta,
  conflictDetected,
  conflictResolution,
  heartbeat,
  disconnect,
}

/// Conflict resolution strategy
enum ConflictStrategy {
  lastWriteWins,
  sourceWins,
  targetWins,
  merge,
  manual,
}

/// Sync state status
enum SyncStatus {
  idle,
  syncing,
  conflicted,
  error,
  completed,
}

/// Protocol message
class ProtocolMessage {
  final String messageId;
  final ProtocolMessageType type;
  final String senderId;
  final String receiverId;
  final Map<String, dynamic> payload;
  final String signature;
  final DateTime timestamp;
  final int sequenceNumber;

  const ProtocolMessage({
    required this.messageId,
    required this.type,
    required this.senderId,
    required this.receiverId,
    required this.payload,
    required this.signature,
    required this.timestamp,
    required this.sequenceNumber,
  });

  factory ProtocolMessage.fromJson(Map<String, dynamic> json) {
    return ProtocolMessage(
      messageId: json['messageId'] ?? '',
      type: ProtocolMessageType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => ProtocolMessageType.heartbeat,
      ),
      senderId: json['senderId'] ?? '',
      receiverId: json['receiverId'] ?? '',
      payload: Map<String, dynamic>.from(json['payload'] ?? {}),
      signature: json['signature'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      sequenceNumber: json['sequenceNumber'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'messageId': messageId,
        'type': type.name,
        'senderId': senderId,
        'receiverId': receiverId,
        'payload': payload,
        'signature': signature,
        'timestamp': timestamp.toIso8601String(),
        'sequenceNumber': sequenceNumber,
      };
}

/// Handshake result
class HandshakeResult {
  final bool success;
  final String sessionId;
  final String? errorMessage;
  final Map<String, dynamic> capabilities;
  final DateTime? expiresAt;

  const HandshakeResult({
    required this.success,
    required this.sessionId,
    this.errorMessage,
    this.capabilities = const {},
    this.expiresAt,
  });

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
}

/// Sync state
class SyncState {
  final String syncId;
  final String partnerId;
  final String entityType;
  final SyncStatus status;
  final int lastSequence;
  final DateTime lastSyncAt;
  final String? lastHash;
  final List<SyncDelta> pendingDeltas;
  final List<SyncConflict> conflicts;

  const SyncState({
    required this.syncId,
    required this.partnerId,
    required this.entityType,
    required this.status,
    this.lastSequence = 0,
    required this.lastSyncAt,
    this.lastHash,
    this.pendingDeltas = const [],
    this.conflicts = const [],
  });

  factory SyncState.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SyncState(
      syncId: doc.id,
      partnerId: data['partnerId'] ?? '',
      entityType: data['entityType'] ?? '',
      status: SyncStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => SyncStatus.idle,
      ),
      lastSequence: data['lastSequence'] ?? 0,
      lastSyncAt: (data['lastSyncAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastHash: data['lastHash'],
      pendingDeltas: [],
      conflicts: [],
    );
  }

  Map<String, dynamic> toFirestore() => {
        'partnerId': partnerId,
        'entityType': entityType,
        'status': status.name,
        'lastSequence': lastSequence,
        'lastSyncAt': Timestamp.fromDate(lastSyncAt),
        'lastHash': lastHash,
      };

  SyncState copyWith({
    SyncStatus? status,
    int? lastSequence,
    DateTime? lastSyncAt,
    String? lastHash,
    List<SyncDelta>? pendingDeltas,
    List<SyncConflict>? conflicts,
  }) {
    return SyncState(
      syncId: syncId,
      partnerId: partnerId,
      entityType: entityType,
      status: status ?? this.status,
      lastSequence: lastSequence ?? this.lastSequence,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      lastHash: lastHash ?? this.lastHash,
      pendingDeltas: pendingDeltas ?? this.pendingDeltas,
      conflicts: conflicts ?? this.conflicts,
    );
  }
}

/// Sync delta representing a change
class SyncDelta {
  final String deltaId;
  final String entityId;
  final String operation;
  final Map<String, dynamic> data;
  final Map<String, dynamic>? previousData;
  final int sequenceNumber;
  final DateTime timestamp;
  final String hash;

  const SyncDelta({
    required this.deltaId,
    required this.entityId,
    required this.operation,
    required this.data,
    this.previousData,
    required this.sequenceNumber,
    required this.timestamp,
    required this.hash,
  });

  factory SyncDelta.fromJson(Map<String, dynamic> json) {
    return SyncDelta(
      deltaId: json['deltaId'] ?? '',
      entityId: json['entityId'] ?? '',
      operation: json['operation'] ?? 'update',
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      previousData: json['previousData'] != null
          ? Map<String, dynamic>.from(json['previousData'])
          : null,
      sequenceNumber: json['sequenceNumber'] ?? 0,
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      hash: json['hash'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'deltaId': deltaId,
        'entityId': entityId,
        'operation': operation,
        'data': data,
        'previousData': previousData,
        'sequenceNumber': sequenceNumber,
        'timestamp': timestamp.toIso8601String(),
        'hash': hash,
      };
}

/// Sync conflict
class SyncConflict {
  final String conflictId;
  final String entityId;
  final SyncDelta localDelta;
  final SyncDelta remoteDelta;
  final ConflictStrategy? suggestedStrategy;
  final DateTime detectedAt;
  final bool isResolved;
  final SyncDelta? resolution;

  const SyncConflict({
    required this.conflictId,
    required this.entityId,
    required this.localDelta,
    required this.remoteDelta,
    this.suggestedStrategy,
    required this.detectedAt,
    this.isResolved = false,
    this.resolution,
  });
}

/// Federation protocol service
class FederationProtocol {
  static FederationProtocol? _instance;
  static FederationProtocol get instance => _instance ??= FederationProtocol._();

  FederationProtocol._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _syncStatesCollection =>
      _firestore.collection('sync_states');
  CollectionReference get _conflictsCollection =>
      _firestore.collection('sync_conflicts');
  CollectionReference get _sessionsCollection =>
      _firestore.collection('federation_sessions');

  final Map<String, HandshakeResult> _activeSessions = {};
  final Map<String, int> _sequenceNumbers = {};
  final String _nodeId = _generateNodeId();

  static String _generateNodeId() {
    final random = Random.secure();
    final bytes =
        List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  // ============================================================
  // HANDSHAKE
  // ============================================================

  /// Initiate handshake with federation partner
  Future<HandshakeResult> handshake({
    required String partnerId,
    required String apiEndpoint,
    required String publicKey,
    Map<String, dynamic>? capabilities,
  }) async {
    debugPrint('🤝 [Protocol] Initiating handshake with: $partnerId');

    try {
      // Generate session
      final sessionId = _generateSessionId();
      final timestamp = DateTime.now();

      // Create handshake message
      final message = ProtocolMessage(
        messageId: _generateMessageId(),
        type: ProtocolMessageType.handshake,
        senderId: _nodeId,
        receiverId: partnerId,
        payload: {
          'sessionId': sessionId,
          'capabilities': capabilities ?? _getDefaultCapabilities(),
          'protocolVersion': '1.0',
          'timestamp': timestamp.toIso8601String(),
        },
        signature: _signMessage(sessionId, publicKey),
        timestamp: timestamp,
        sequenceNumber: 0,
      );

      // Store pending session
      await _sessionsCollection.doc(sessionId).set({
        'partnerId': partnerId,
        'status': 'pending',
        'createdAt': Timestamp.fromDate(timestamp),
        'message': message.toJson(),
      });

      // Simulate partner response (in production, this would be an HTTP call)
      await Future.delayed(const Duration(milliseconds: 100));

      final result = HandshakeResult(
        success: true,
        sessionId: sessionId,
        capabilities: capabilities ?? _getDefaultCapabilities(),
        expiresAt: timestamp.add(const Duration(hours: 24)),
      );

      _activeSessions[partnerId] = result;
      _sequenceNumbers[partnerId] = 0;

      await _sessionsCollection.doc(sessionId).update({
        'status': 'active',
        'activatedAt': Timestamp.now(),
        'expiresAt': Timestamp.fromDate(result.expiresAt!),
      });

      debugPrint('✅ [Protocol] Handshake successful: $sessionId');
      return result;
    } catch (e) {
      debugPrint('❌ [Protocol] Handshake failed: $e');
      return HandshakeResult(
        success: false,
        sessionId: '',
        errorMessage: e.toString(),
      );
    }
  }

  Map<String, dynamic> _getDefaultCapabilities() {
    return {
      'syncTypes': ['identity', 'room', 'creator', 'moderation'],
      'conflictStrategies': ['lastWriteWins', 'merge'],
      'compressionSupported': true,
      'maxBatchSize': 100,
    };
  }

  String _generateSessionId() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  String _generateMessageId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';
  }

  String _signMessage(String content, String publicKey) {
    final bytes = utf8.encode('$content:$publicKey:${DateTime.now().toIso8601String()}');
    return sha256.convert(bytes).toString();
  }

  /// Check if session is active
  bool hasActiveSession(String partnerId) {
    final session = _activeSessions[partnerId];
    return session != null && session.success && !session.isExpired;
  }

  // ============================================================
  // STATE SYNC
  // ============================================================

  /// Synchronize state with partner
  Future<SyncState> syncState({
    required String partnerId,
    required String entityType,
    List<SyncDelta>? localDeltas,
  }) async {
    debugPrint('🔄 [Protocol] Syncing $entityType with: $partnerId');

    if (!hasActiveSession(partnerId)) {
      throw Exception('No active session with partner');
    }

    // Get or create sync state
    var syncState = await _getSyncState(partnerId, entityType);
    syncState = syncState.copyWith(status: SyncStatus.syncing);

    try {
      final sequence = (_sequenceNumbers[partnerId] ?? 0) + 1;
      _sequenceNumbers[partnerId] = sequence;

      // Create sync request message (for logging/auditing purposes)
      // ignore: unused_local_variable
      final message = ProtocolMessage(
        messageId: _generateMessageId(),
        type: ProtocolMessageType.syncRequest,
        senderId: _nodeId,
        receiverId: partnerId,
        payload: {
          'entityType': entityType,
          'lastSequence': syncState.lastSequence,
          'lastHash': syncState.lastHash,
          'localDeltas': localDeltas?.map((d) => d.toJson()).toList() ?? [],
        },
        signature: _signMessage(syncState.syncId, partnerId),
        timestamp: DateTime.now(),
        sequenceNumber: sequence,
      );

      // Simulate sync response (in production, this would be real API call)
      await Future.delayed(const Duration(milliseconds: 50));

      // Process remote deltas (simulated)
      final remoteDeltas = _simulateRemoteDeltas(entityType, syncState.lastSequence);

      // Check for conflicts
      final conflicts = _detectConflicts(localDeltas ?? [], remoteDeltas);

      if (conflicts.isNotEmpty) {
        syncState = syncState.copyWith(
          status: SyncStatus.conflicted,
          conflicts: conflicts,
        );

        // Store conflicts
        for (final conflict in conflicts) {
          await _conflictsCollection.doc(conflict.conflictId).set({
            'entityId': conflict.entityId,
            'partnerId': partnerId,
            'entityType': entityType,
            'localDelta': conflict.localDelta.toJson(),
            'remoteDelta': conflict.remoteDelta.toJson(),
            'detectedAt': Timestamp.fromDate(conflict.detectedAt),
            'isResolved': false,
          });
        }
      } else {
        // Update sync state
        final newHash = _computeStateHash(remoteDeltas);
        syncState = syncState.copyWith(
          status: SyncStatus.completed,
          lastSequence: sequence,
          lastSyncAt: DateTime.now(),
          lastHash: newHash,
        );
      }

      // Persist sync state
      await _syncStatesCollection.doc(syncState.syncId).set(syncState.toFirestore());

      debugPrint('✅ [Protocol] Sync completed: ${syncState.status}');
      return syncState;
    } catch (e) {
      debugPrint('❌ [Protocol] Sync failed: $e');
      return syncState.copyWith(status: SyncStatus.error);
    }
  }

  Future<SyncState> _getSyncState(String partnerId, String entityType) async {
    final syncId = '${partnerId}_$entityType';
    final doc = await _syncStatesCollection.doc(syncId).get();

    if (doc.exists) {
      return SyncState.fromFirestore(doc);
    }

    return SyncState(
      syncId: syncId,
      partnerId: partnerId,
      entityType: entityType,
      status: SyncStatus.idle,
      lastSyncAt: DateTime.now(),
    );
  }

  List<SyncDelta> _simulateRemoteDeltas(String entityType, int lastSequence) {
    // In production, these would come from the partner
    return [];
  }

  List<SyncConflict> _detectConflicts(
    List<SyncDelta> localDeltas,
    List<SyncDelta> remoteDeltas,
  ) {
    final conflicts = <SyncConflict>[];

    for (final local in localDeltas) {
      for (final remote in remoteDeltas) {
        if (local.entityId == remote.entityId &&
            local.timestamp != remote.timestamp) {
          conflicts.add(SyncConflict(
            conflictId: '${local.deltaId}_${remote.deltaId}',
            entityId: local.entityId,
            localDelta: local,
            remoteDelta: remote,
            suggestedStrategy: _suggestStrategy(local, remote),
            detectedAt: DateTime.now(),
          ));
        }
      }
    }

    return conflicts;
  }

  ConflictStrategy _suggestStrategy(SyncDelta local, SyncDelta remote) {
    // Last write wins by default
    if (local.timestamp.isAfter(remote.timestamp)) {
      return ConflictStrategy.sourceWins;
    }
    return ConflictStrategy.targetWins;
  }

  String _computeStateHash(List<SyncDelta> deltas) {
    final content = deltas.map((d) => d.toJson().toString()).join();
    return sha256.convert(utf8.encode(content)).toString().substring(0, 16);
  }

  // ============================================================
  // CONFLICT RESOLUTION
  // ============================================================

  /// Resolve a sync conflict
  Future<SyncDelta> resolveConflicts({
    required String conflictId,
    required ConflictStrategy strategy,
    Map<String, dynamic>? manualResolution,
  }) async {
    debugPrint('⚖️ [Protocol] Resolving conflict: $conflictId with $strategy');

    final conflictDoc = await _conflictsCollection.doc(conflictId).get();
    if (!conflictDoc.exists) {
      throw Exception('Conflict not found');
    }

    final data = conflictDoc.data() as Map<String, dynamic>;
    final localDelta = SyncDelta.fromJson(data['localDelta']);
    final remoteDelta = SyncDelta.fromJson(data['remoteDelta']);

    SyncDelta resolution;

    switch (strategy) {
      case ConflictStrategy.lastWriteWins:
        resolution = localDelta.timestamp.isAfter(remoteDelta.timestamp)
            ? localDelta
            : remoteDelta;
        break;

      case ConflictStrategy.sourceWins:
        resolution = localDelta;
        break;

      case ConflictStrategy.targetWins:
        resolution = remoteDelta;
        break;

      case ConflictStrategy.merge:
        resolution = _mergeDeltas(localDelta, remoteDelta);
        break;

      case ConflictStrategy.manual:
        if (manualResolution == null) {
          throw Exception('Manual resolution data required');
        }
        resolution = SyncDelta(
          deltaId: _generateMessageId(),
          entityId: localDelta.entityId,
          operation: 'update',
          data: manualResolution,
          sequenceNumber: max(localDelta.sequenceNumber, remoteDelta.sequenceNumber) + 1,
          timestamp: DateTime.now(),
          hash: _computeStateHash([localDelta, remoteDelta]),
        );
        break;
    }

    // Mark conflict as resolved
    await _conflictsCollection.doc(conflictId).update({
      'isResolved': true,
      'resolvedAt': Timestamp.now(),
      'strategy': strategy.name,
      'resolution': resolution.toJson(),
    });

    debugPrint('✅ [Protocol] Conflict resolved: $conflictId');
    return resolution;
  }

  SyncDelta _mergeDeltas(SyncDelta local, SyncDelta remote) {
    // Deep merge strategy: combine non-conflicting fields from both
    final merged = <String, dynamic>{};

    // Start with remote data as base
    merged.addAll(remote.data);

    // Overlay local data (local wins on field-level conflicts)
    merged.addAll(local.data);

    return SyncDelta(
      deltaId: _generateMessageId(),
      entityId: local.entityId,
      operation: 'update',
      data: merged,
      previousData: remote.data,
      sequenceNumber: max(local.sequenceNumber, remote.sequenceNumber) + 1,
      timestamp: DateTime.now(),
      hash: _computeStateHash([local, remote]),
    );
  }

  /// Get unresolved conflicts
  Future<List<SyncConflict>> getUnresolvedConflicts(String partnerId) async {
    final snapshot = await _conflictsCollection
        .where('partnerId', isEqualTo: partnerId)
        .where('isResolved', isEqualTo: false)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return SyncConflict(
        conflictId: doc.id,
        entityId: data['entityId'],
        localDelta: SyncDelta.fromJson(data['localDelta']),
        remoteDelta: SyncDelta.fromJson(data['remoteDelta']),
        detectedAt: (data['detectedAt'] as Timestamp).toDate(),
      );
    }).toList();
  }

  // ============================================================
  // UTILITIES
  // ============================================================

  /// Send heartbeat to keep session alive
  Future<void> sendHeartbeat(String partnerId) async {
    if (!hasActiveSession(partnerId)) return;

    final session = _activeSessions[partnerId]!;
    await _sessionsCollection.doc(session.sessionId).update({
      'lastHeartbeat': Timestamp.now(),
    });
  }

  /// Disconnect from partner
  Future<void> disconnect(String partnerId) async {
    final session = _activeSessions.remove(partnerId);
    _sequenceNumbers.remove(partnerId);

    if (session != null) {
      await _sessionsCollection.doc(session.sessionId).update({
        'status': 'disconnected',
        'disconnectedAt': Timestamp.now(),
      });
    }

    debugPrint('👋 [Protocol] Disconnected from: $partnerId');
  }

  /// Get protocol statistics
  Future<Map<String, dynamic>> getProtocolStatistics() async {
    final sessions = await _sessionsCollection
        .where('status', isEqualTo: 'active')
        .get();

    final conflicts = await _conflictsCollection
        .where('isResolved', isEqualTo: false)
        .get();

    final syncStates = await _syncStatesCollection.get();

    return {
      'activeSessions': sessions.docs.length,
      'unresolvedConflicts': conflicts.docs.length,
      'trackedSyncStates': syncStates.docs.length,
      'localNodeId': _nodeId,
    };
  }
}
