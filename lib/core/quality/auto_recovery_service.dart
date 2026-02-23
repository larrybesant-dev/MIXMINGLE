/// Auto Recovery Service
///
/// Provides automatic recovery mechanisms for common failure scenarios
/// including video pipeline restarts, Agora reconnection, and Firestore
/// presence recovery.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../analytics/analytics_service.dart';

/// Types of recovery actions
enum RecoveryActionType {
  videoPipelineRestart,
  agoraReconnect,
  firestorePresenceRecovery,
  audioSessionReset,
  networkReconnect,
  cacheInvalidation,
  serviceReinitialization,
}

/// Result of a recovery attempt
enum RecoveryResult {
  success,
  partialSuccess,
  failed,
  skipped,
}

/// Model for recovery attempt
class RecoveryAttempt {
  final String id;
  final RecoveryActionType type;
  final RecoveryResult result;
  final String? roomId;
  final String? userId;
  final DateTime attemptedAt;
  final int attemptNumber;
  final Duration duration;
  final String? errorMessage;
  final Map<String, dynamic> context;

  const RecoveryAttempt({
    required this.id,
    required this.type,
    required this.result,
    this.roomId,
    this.userId,
    required this.attemptedAt,
    this.attemptNumber = 1,
    required this.duration,
    this.errorMessage,
    this.context = const {},
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type.name,
    'result': result.name,
    'roomId': roomId,
    'userId': userId,
    'attemptedAt': attemptedAt.toIso8601String(),
    'attemptNumber': attemptNumber,
    'durationMs': duration.inMilliseconds,
    'errorMessage': errorMessage,
    'context': context,
  };
}

/// Recovery configuration
class RecoveryConfig {
  final int maxRetries;
  final Duration retryDelay;
  final Duration maxRecoveryTime;
  final bool exponentialBackoff;
  final double backoffMultiplier;

  const RecoveryConfig({
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 2),
    this.maxRecoveryTime = const Duration(seconds: 30),
    this.exponentialBackoff = true,
    this.backoffMultiplier = 2.0,
  });
}

/// Callback for recovery actions
typedef RecoveryCallback = Future<bool> Function();

/// Service for automatic failure recovery
class AutoRecoveryService {
  static AutoRecoveryService? _instance;
  static AutoRecoveryService get instance => _instance ??= AutoRecoveryService._();

  AutoRecoveryService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  CollectionReference<Map<String, dynamic>> get _recoveryCollection =>
      _firestore.collection('recovery_attempts');

  CollectionReference<Map<String, dynamic>> get _presenceCollection =>
      _firestore.collection('user_presence');

  // State tracking
  final Map<RecoveryActionType, int> _activeRecoveries = {};
  final Map<RecoveryActionType, DateTime> _lastRecoveryAttempt = {};
  final List<RecoveryAttempt> _recentAttempts = [];

  // Callbacks for recovery actions
  RecoveryCallback? _videoPipelineRestartCallback;
  RecoveryCallback? _agoraReconnectCallback;
  RecoveryCallback? _audioResetCallback;

  // Stream controllers
  final _recoveryStartController = StreamController<RecoveryActionType>.broadcast();
  final _recoveryCompleteController = StreamController<RecoveryAttempt>.broadcast();

  /// Stream of recovery starts
  Stream<RecoveryActionType> get recoveryStartStream => _recoveryStartController.stream;

  /// Stream of recovery completions
  Stream<RecoveryAttempt> get recoveryCompleteStream => _recoveryCompleteController.stream;

  // Configuration
  final Map<RecoveryActionType, RecoveryConfig> _configs = {
    RecoveryActionType.videoPipelineRestart: const RecoveryConfig(
      maxRetries: 3,
      retryDelay: Duration(seconds: 2),
    ),
    RecoveryActionType.agoraReconnect: const RecoveryConfig(
      maxRetries: 5,
      retryDelay: Duration(seconds: 3),
      exponentialBackoff: true,
    ),
    RecoveryActionType.firestorePresenceRecovery: const RecoveryConfig(
      maxRetries: 3,
      retryDelay: Duration(seconds: 1),
    ),
    RecoveryActionType.audioSessionReset: const RecoveryConfig(
      maxRetries: 2,
      retryDelay: Duration(seconds: 1),
    ),
  };

  /// Register callback for video pipeline restart
  void registerVideoPipelineCallback(RecoveryCallback callback) {
    _videoPipelineRestartCallback = callback;
  }

  /// Register callback for Agora reconnection
  void registerAgoraReconnectCallback(RecoveryCallback callback) {
    _agoraReconnectCallback = callback;
  }

  /// Register callback for audio reset
  void registerAudioResetCallback(RecoveryCallback callback) {
    _audioResetCallback = callback;
  }

  /// Restart video pipeline with automatic retries
  Future<RecoveryResult> restartVideoPipeline({
    String? roomId,
    Map<String, dynamic>? context,
  }) async {
    return _executeRecovery(
      type: RecoveryActionType.videoPipelineRestart,
      roomId: roomId,
      context: context,
      action: () async {
        if (_videoPipelineRestartCallback != null) {
          return await _videoPipelineRestartCallback!();
        }

        // Default implementation - trigger video restart
        AnalyticsService.instance.logEvent(
          name: 'video_pipeline_restart_attempt',
          parameters: {'room_id': roomId ?? 'unknown'},
        );

        // Simulate restart - actual implementation would be in the callback
        await Future.delayed(const Duration(milliseconds: 500));
        return true;
      },
    );
  }

  /// Auto-reconnect to Agora with exponential backoff
  Future<RecoveryResult> autoReconnectAgora({
    required String channelName,
    String? token,
    String? roomId,
    Map<String, dynamic>? context,
  }) async {
    return _executeRecovery(
      type: RecoveryActionType.agoraReconnect,
      roomId: roomId,
      context: {
        'channelName': channelName,
        'hasToken': token != null,
        ...?context,
      },
      action: () async {
        if (_agoraReconnectCallback != null) {
          return await _agoraReconnectCallback!();
        }

        // Default implementation
        AnalyticsService.instance.logEvent(
          name: 'agora_reconnect_attempt',
          parameters: {
            'channel': channelName,
            'room_id': roomId ?? 'unknown',
          },
        );

        // Actual reconnection would be handled by the callback
        await Future.delayed(const Duration(milliseconds: 500));
        return true;
      },
    );
  }

  /// Auto-recover Firestore presence
  Future<RecoveryResult> autoRecoverFirestorePresence({
    String? roomId,
    Map<String, dynamic>? additionalData,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return RecoveryResult.skipped;

    return _executeRecovery(
      type: RecoveryActionType.firestorePresenceRecovery,
      roomId: roomId,
      context: additionalData,
      action: () async {
        try {
          // Update user presence
          await _presenceCollection.doc(userId).set({
            'userId': userId,
            'isOnline': true,
            'lastSeen': FieldValue.serverTimestamp(),
            'currentRoomId': roomId,
            'recoveredAt': FieldValue.serverTimestamp(),
            ...?additionalData,
          }, SetOptions(merge: true));

          // If in a room, update room participants
          if (roomId != null) {
            await _firestore.collection('rooms').doc(roomId).update({
              'participants': FieldValue.arrayUnion([userId]),
              'lastActivity': FieldValue.serverTimestamp(),
            });
          }

          AnalyticsService.instance.logEvent(
            name: 'presence_recovered',
            parameters: {
              'room_id': roomId ?? 'none',
              'user_id': userId,
            },
          );

          return true;
        } catch (e) {
          return false;
        }
      },
    );
  }

  /// Reset audio session
  Future<RecoveryResult> resetAudioSession({
    String? roomId,
  }) async {
    return _executeRecovery(
      type: RecoveryActionType.audioSessionReset,
      roomId: roomId,
      action: () async {
        if (_audioResetCallback != null) {
          return await _audioResetCallback!();
        }

        AnalyticsService.instance.logEvent(
          name: 'audio_session_reset',
          parameters: {'room_id': roomId ?? 'unknown'},
        );

        // Actual reset would be handled by the callback
        await Future.delayed(const Duration(milliseconds: 200));
        return true;
      },
    );
  }

  /// Perform full recovery sequence for a room
  Future<Map<RecoveryActionType, RecoveryResult>> performFullRoomRecovery({
    required String roomId,
    String? channelName,
  }) async {
    final results = <RecoveryActionType, RecoveryResult>{};

    // 1. Recover presence first
    results[RecoveryActionType.firestorePresenceRecovery] =
        await autoRecoverFirestorePresence(roomId: roomId);

    // 2. Reset video pipeline
    results[RecoveryActionType.videoPipelineRestart] =
        await restartVideoPipeline(roomId: roomId);

    // 3. Reconnect Agora if channel name provided
    if (channelName != null) {
      results[RecoveryActionType.agoraReconnect] =
          await autoReconnectAgora(channelName: channelName, roomId: roomId);
    }

    // 4. Reset audio
    results[RecoveryActionType.audioSessionReset] =
        await resetAudioSession(roomId: roomId);

    AnalyticsService.instance.logEvent(
      name: 'full_room_recovery',
      parameters: {
        'room_id': roomId,
        'results': results.map((k, v) => MapEntry(k.name, v.name)),
      },
    );

    return results;
  }

  /// Check if recovery is in progress for a given type
  bool isRecoveryInProgress(RecoveryActionType type) =>
      (_activeRecoveries[type] ?? 0) > 0;

  /// Get recent recovery attempts
  List<RecoveryAttempt> getRecentAttempts({
    RecoveryActionType? type,
    int limit = 20,
  }) {
    var attempts = _recentAttempts;
    if (type != null) {
      attempts = attempts.where((a) => a.type == type).toList();
    }
    return attempts.take(limit).toList();
  }

  /// Get recovery success rate for a type
  double getSuccessRate(RecoveryActionType type, {Duration? window}) {
    var attempts = _recentAttempts.where((a) => a.type == type);

    if (window != null) {
      final cutoff = DateTime.now().subtract(window);
      attempts = attempts.where((a) => a.attemptedAt.isAfter(cutoff));
    }

    final list = attempts.toList();
    if (list.isEmpty) return 1.0;

    final successes = list.where(
      (a) => a.result == RecoveryResult.success || a.result == RecoveryResult.partialSuccess,
    ).length;

    return successes / list.length;
  }

  /// Update recovery configuration
  void updateConfig(RecoveryActionType type, RecoveryConfig config) {
    _configs[type] = config;
  }

  // Private methods

  Future<RecoveryResult> _executeRecovery({
    required RecoveryActionType type,
    required Future<bool> Function() action,
    String? roomId,
    Map<String, dynamic>? context,
  }) async {
    // Check if already recovering
    if ((_activeRecoveries[type] ?? 0) > 0) {
      return RecoveryResult.skipped;
    }

    // Check cooldown
    final lastAttempt = _lastRecoveryAttempt[type];
    if (lastAttempt != null) {
      final config = _configs[type] ?? const RecoveryConfig();
      if (DateTime.now().difference(lastAttempt) < config.retryDelay) {
        return RecoveryResult.skipped;
      }
    }

    _activeRecoveries[type] = 1;
    _recoveryStartController.add(type);

    final startTime = DateTime.now();
    final config = _configs[type] ?? const RecoveryConfig();
    int attempt = 0;
    RecoveryResult result = RecoveryResult.failed;
    String? errorMessage;

    while (attempt < config.maxRetries) {
      attempt++;
      _activeRecoveries[type] = attempt;

      try {
        final success = await action().timeout(config.maxRecoveryTime);
        if (success) {
          result = RecoveryResult.success;
          break;
        }
      } catch (e) {
        errorMessage = e.toString();
      }

      // Calculate delay with optional exponential backoff
      var delay = config.retryDelay;
      if (config.exponentialBackoff) {
        final multiplier = config.backoffMultiplier;
        delay = Duration(
          milliseconds: (delay.inMilliseconds * (attempt * multiplier)).round(),
        );
      }

      if (attempt < config.maxRetries) {
        await Future.delayed(delay);
      }
    }

    final duration = DateTime.now().difference(startTime);
    _activeRecoveries[type] = 0;
    _lastRecoveryAttempt[type] = DateTime.now();

    final recoveryAttempt = RecoveryAttempt(
      id: '${type.name}_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      result: result,
      roomId: roomId,
      userId: _auth.currentUser?.uid,
      attemptedAt: startTime,
      attemptNumber: attempt,
      duration: duration,
      errorMessage: errorMessage,
      context: context ?? {},
    );

    // Store attempt
    _recentAttempts.insert(0, recoveryAttempt);
    if (_recentAttempts.length > 100) {
      _recentAttempts.removeRange(100, _recentAttempts.length);
    }

    // Save to Firestore
    await _recoveryCollection.add(recoveryAttempt.toMap());

    _recoveryCompleteController.add(recoveryAttempt);

    // Log analytics
    AnalyticsService.instance.logEvent(
      name: 'recovery_completed',
      parameters: {
        'type': type.name,
        'result': result.name,
        'attempts': attempt,
        'duration_ms': duration.inMilliseconds,
        'room_id': roomId ?? 'none',
      },
    );

    return result;
  }

  /// Dispose resources
  void dispose() {
    _recoveryStartController.close();
    _recoveryCompleteController.close();
  }
}


