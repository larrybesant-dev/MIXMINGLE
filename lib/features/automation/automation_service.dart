/// Automation Service
///
/// Handles automatic cleanup, archival, and maintenance tasks
/// to keep the system healthy and efficient.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../core/analytics/analytics_service.dart';

/// Result of an automation task
class AutomationResult {
  final String taskId;
  final AutomationTaskType type;
  final bool success;
  final int itemsProcessed;
  final Duration duration;
  final String? error;
  final DateTime completedAt;
  final Map<String, dynamic> details;

  const AutomationResult({
    required this.taskId,
    required this.type,
    required this.success,
    required this.itemsProcessed,
    required this.duration,
    this.error,
    required this.completedAt,
    this.details = const {},
  });

  Map<String, dynamic> toMap() => {
    'taskId': taskId,
    'type': type.name,
    'success': success,
    'itemsProcessed': itemsProcessed,
    'durationMs': duration.inMilliseconds,
    'error': error,
    'completedAt': completedAt.toIso8601String(),
    'details': details,
  };
}

enum AutomationTaskType {
  cleanInactiveRooms,
  archiveOldMessages,
  purgeOldLogs,
  detectStalePresence,
  fixCorruptedRoomState,
  cleanupExpiredOffers,
  removeInactiveUsers,
  archiveOldEvents,
}

/// Configuration for automation tasks
class AutomationConfig {
  final Duration roomInactivityThreshold;
  final Duration messageArchiveThreshold;
  final Duration logRetentionPeriod;
  final Duration presenceStaleThreshold;
  final int batchSize;

  const AutomationConfig({
    this.roomInactivityThreshold = const Duration(hours: 24),
    this.messageArchiveThreshold = const Duration(days: 30),
    this.logRetentionPeriod = const Duration(days: 7),
    this.presenceStaleThreshold = const Duration(minutes: 5),
    this.batchSize = 500,
  });
}

/// Service for automated maintenance tasks
class AutomationService {
  static AutomationService? _instance;
  static AutomationService get instance => _instance ??= AutomationService._();

  AutomationService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  CollectionReference<Map<String, dynamic>> get _automationLogsCollection =>
      _firestore.collection('automation_logs');

  CollectionReference<Map<String, dynamic>> get _archivedMessagesCollection =>
      _firestore.collection('archived_messages');

  CollectionReference<Map<String, dynamic>> get _archivedLogsCollection =>
      _firestore.collection('archived_logs');

  // Configuration
  AutomationConfig _config = const AutomationConfig();

  // Stream controllers
  final _taskResultController = StreamController<AutomationResult>.broadcast();

  /// Stream of task results
  Stream<AutomationResult> get taskResultStream => _taskResultController.stream;

  /// Update configuration
  void updateConfig(AutomationConfig config) {
    _config = config;
  }

  /// Initialize the service
  Future<void> initialize() async {
    AnalyticsService.instance.logEvent(
      name: 'automation_service_initialized',
      parameters: {},
    );
  }

  /// Auto-clean inactive rooms
  Future<AutomationResult> autoCleanInactiveRooms() async {
    final startTime = DateTime.now();
    final taskId = 'clean_rooms_${startTime.millisecondsSinceEpoch}';
    int processedCount = 0;
    String? error;

    try {
      final threshold = DateTime.now().subtract(_config.roomInactivityThreshold);

      // Find inactive rooms
      final snapshot = await _firestore
          .collection('rooms')
          .where('status', isEqualTo: 'active')
          .where('lastActivity', isLessThan: Timestamp.fromDate(threshold))
          .limit(_config.batchSize)
          .get();

      if (snapshot.docs.isEmpty) {
        debugPrint('ðŸ§¹ [Automation] No inactive rooms found');
      } else {
        final batch = _firestore.batch();

        for (final doc in snapshot.docs) {
          // Mark room as inactive/closed
          batch.update(doc.reference, {
            'status': 'closed',
            'closedAt': FieldValue.serverTimestamp(),
            'closedReason': 'auto_cleanup_inactivity',
          });

          // Clean up related data
          final participantsSnapshot = await doc.reference
              .collection('participants')
              .get();

          for (final participant in participantsSnapshot.docs) {
            batch.delete(participant.reference);
          }

          processedCount++;
        }

        await batch.commit();
        debugPrint('ðŸ§¹ [Automation] Cleaned $processedCount inactive rooms');
      }
    } catch (e) {
      error = e.toString();
      debugPrint('âŒ [Automation] Failed to clean inactive rooms: $e');
    }

    final result = AutomationResult(
      taskId: taskId,
      type: AutomationTaskType.cleanInactiveRooms,
      success: error == null,
      itemsProcessed: processedCount,
      duration: DateTime.now().difference(startTime),
      error: error,
      completedAt: DateTime.now(),
      details: {
        'threshold_hours': _config.roomInactivityThreshold.inHours,
      },
    );

    await _recordResult(result);
    _taskResultController.add(result);

    return result;
  }

  /// Auto-archive old messages
  Future<AutomationResult> autoArchiveOldMessages() async {
    final startTime = DateTime.now();
    final taskId = 'archive_messages_${startTime.millisecondsSinceEpoch}';
    int processedCount = 0;
    String? error;

    try {
      final threshold = DateTime.now().subtract(_config.messageArchiveThreshold);

      // Find old messages
      final snapshot = await _firestore
          .collectionGroup('messages')
          .where('createdAt', isLessThan: Timestamp.fromDate(threshold))
          .where('archived', isEqualTo: false)
          .limit(_config.batchSize)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final batch = _firestore.batch();

        for (final doc in snapshot.docs) {
          final data = doc.data();

          // Copy to archive
          batch.set(_archivedMessagesCollection.doc(doc.id), {
            ...data,
            'originalPath': doc.reference.path,
            'archivedAt': FieldValue.serverTimestamp(),
          });

          // Mark as archived (or delete if preferred)
          batch.update(doc.reference, {'archived': true});

          processedCount++;
        }

        await batch.commit();
        debugPrint('ðŸ“¦ [Automation] Archived $processedCount old messages');
      }
    } catch (e) {
      error = e.toString();
      debugPrint('âŒ [Automation] Failed to archive messages: $e');
    }

    final result = AutomationResult(
      taskId: taskId,
      type: AutomationTaskType.archiveOldMessages,
      success: error == null,
      itemsProcessed: processedCount,
      duration: DateTime.now().difference(startTime),
      error: error,
      completedAt: DateTime.now(),
      details: {
        'threshold_days': _config.messageArchiveThreshold.inDays,
      },
    );

    await _recordResult(result);
    _taskResultController.add(result);

    return result;
  }

  /// Auto-purge old logs
  Future<AutomationResult> autoPurgeOldLogs() async {
    final startTime = DateTime.now();
    final taskId = 'purge_logs_${startTime.millisecondsSinceEpoch}';
    int processedCount = 0;
    String? error;

    try {
      final threshold = DateTime.now().subtract(_config.logRetentionPeriod);

      // Collections to clean up
      final logCollections = [
        'app_logs',
        'error_logs',
        'analytics_raw',
        'debug_logs',
      ];

      for (final collectionName in logCollections) {
        final snapshot = await _firestore
            .collection(collectionName)
            .where('timestamp', isLessThan: Timestamp.fromDate(threshold))
            .limit(_config.batchSize)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final batch = _firestore.batch();

          for (final doc in snapshot.docs) {
            // Optional: Archive important logs before deletion
            if (collectionName == 'error_logs') {
              batch.set(_archivedLogsCollection.doc(doc.id), {
                ...doc.data(),
                'collection': collectionName,
                'archivedAt': FieldValue.serverTimestamp(),
              });
            }

            batch.delete(doc.reference);
            processedCount++;
          }

          await batch.commit();
        }
      }

      debugPrint('ðŸ—‘ï¸ [Automation] Purged $processedCount old logs');
    } catch (e) {
      error = e.toString();
      debugPrint('âŒ [Automation] Failed to purge logs: $e');
    }

    final result = AutomationResult(
      taskId: taskId,
      type: AutomationTaskType.purgeOldLogs,
      success: error == null,
      itemsProcessed: processedCount,
      duration: DateTime.now().difference(startTime),
      error: error,
      completedAt: DateTime.now(),
      details: {
        'retention_days': _config.logRetentionPeriod.inDays,
      },
    );

    await _recordResult(result);
    _taskResultController.add(result);

    return result;
  }

  /// Auto-detect stale presence records
  Future<AutomationResult> autoDetectStalePresence() async {
    final startTime = DateTime.now();
    final taskId = 'detect_stale_presence_${startTime.millisecondsSinceEpoch}';
    int processedCount = 0;
    String? error;

    try {
      final threshold = DateTime.now().subtract(_config.presenceStaleThreshold);

      // Find stale presence records
      final snapshot = await _firestore
          .collection('user_presence')
          .where('isOnline', isEqualTo: true)
          .where('lastHeartbeat', isLessThan: Timestamp.fromDate(threshold))
          .limit(_config.batchSize)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final batch = _firestore.batch();

        for (final doc in snapshot.docs) {
          final userId = doc.id;
          final data = doc.data();
          final currentRoomId = data['currentRoomId'] as String?;

          // Update presence to offline
          batch.update(doc.reference, {
            'isOnline': false,
            'lastSeen': FieldValue.serverTimestamp(),
            'disconnectReason': 'stale_presence_cleanup',
          });

          // Remove from room if they were in one
          if (currentRoomId != null) {
            batch.update(
              _firestore.collection('rooms').doc(currentRoomId),
              {
                'participants': FieldValue.arrayRemove([userId]),
                'participantCount': FieldValue.increment(-1),
              },
            );
          }

          processedCount++;
        }

        await batch.commit();
        debugPrint('ðŸ‘» [Automation] Fixed $processedCount stale presence records');
      }
    } catch (e) {
      error = e.toString();
      debugPrint('âŒ [Automation] Failed to detect stale presence: $e');
    }

    final result = AutomationResult(
      taskId: taskId,
      type: AutomationTaskType.detectStalePresence,
      success: error == null,
      itemsProcessed: processedCount,
      duration: DateTime.now().difference(startTime),
      error: error,
      completedAt: DateTime.now(),
      details: {
        'threshold_minutes': _config.presenceStaleThreshold.inMinutes,
      },
    );

    await _recordResult(result);
    _taskResultController.add(result);

    return result;
  }

  /// Auto-fix corrupted room state
  Future<AutomationResult> autoFixCorruptedRoomState() async {
    final startTime = DateTime.now();
    final taskId = 'fix_room_state_${startTime.millisecondsSinceEpoch}';
    int processedCount = 0;
    final corruptionTypes = <String, int>{};
    String? error;

    try {
      // Find active rooms
      final roomsSnapshot = await _firestore
          .collection('rooms')
          .where('status', isEqualTo: 'active')
          .limit(_config.batchSize)
          .get();

      for (final roomDoc in roomsSnapshot.docs) {
        final roomId = roomDoc.id;
        final roomData = roomDoc.data();
        final updates = <String, dynamic>{};

        // Check participant count consistency
        final storedCount = (roomData['participantCount'] as int?) ?? 0;
        final participants = roomData['participants'] as List<dynamic>? ?? [];
        final actualCount = participants.length;

        if (storedCount != actualCount) {
          updates['participantCount'] = actualCount;
          corruptionTypes['participant_count_mismatch'] =
              (corruptionTypes['participant_count_mismatch'] ?? 0) + 1;
        }

        // Check for missing required fields
        if (roomData['createdAt'] == null) {
          updates['createdAt'] = FieldValue.serverTimestamp();
          corruptionTypes['missing_created_at'] =
              (corruptionTypes['missing_created_at'] ?? 0) + 1;
        }

        if (roomData['hostId'] == null && participants.isNotEmpty) {
          updates['hostId'] = participants.first;
          corruptionTypes['missing_host'] =
              (corruptionTypes['missing_host'] ?? 0) + 1;
        }

        // Check for rooms with no participants but marked as active
        if (actualCount == 0 && roomData['status'] == 'active') {
          final lastActivity = roomData['lastActivity'] as Timestamp?;
          if (lastActivity != null) {
            final timeSinceActivity = DateTime.now().difference(lastActivity.toDate());
            if (timeSinceActivity.inHours > 1) {
              updates['status'] = 'closed';
              updates['closedReason'] = 'auto_fix_empty_room';
              corruptionTypes['empty_active_room'] =
                  (corruptionTypes['empty_active_room'] ?? 0) + 1;
            }
          }
        }

        // Check for invalid status values
        final validStatuses = ['active', 'paused', 'closed', 'archived'];
        if (!validStatuses.contains(roomData['status'])) {
          updates['status'] = 'closed';
          updates['closedReason'] = 'invalid_status_fix';
          corruptionTypes['invalid_status'] =
              (corruptionTypes['invalid_status'] ?? 0) + 1;
        }

        // Apply fixes if needed
        if (updates.isNotEmpty) {
          updates['lastFixedAt'] = FieldValue.serverTimestamp();
          await _firestore.collection('rooms').doc(roomId).update(updates);
          processedCount++;
        }
      }

      debugPrint('ðŸ”§ [Automation] Fixed $processedCount corrupted room states');
    } catch (e) {
      error = e.toString();
      debugPrint('âŒ [Automation] Failed to fix room states: $e');
    }

    final result = AutomationResult(
      taskId: taskId,
      type: AutomationTaskType.fixCorruptedRoomState,
      success: error == null,
      itemsProcessed: processedCount,
      duration: DateTime.now().difference(startTime),
      error: error,
      completedAt: DateTime.now(),
      details: {
        'corruption_types': corruptionTypes,
        'rooms_checked': _config.batchSize,
      },
    );

    await _recordResult(result);
    _taskResultController.add(result);

    return result;
  }

  /// Get automation statistics
  Future<Map<String, dynamic>> getAutomationStats({
    Duration period = const Duration(days: 7),
  }) async {
    final startDate = DateTime.now().subtract(period);

    final snapshot = await _automationLogsCollection
        .where('completedAt', isGreaterThan: startDate.toIso8601String())
        .get();

    int totalTasks = 0;
    int successfulTasks = 0;
    int totalItemsProcessed = 0;
    Duration totalDuration = Duration.zero;
    final taskCounts = <String, int>{};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      totalTasks++;
      if (data['success'] == true) successfulTasks++;
      totalItemsProcessed += (data['itemsProcessed'] as int?) ?? 0;
      totalDuration += Duration(milliseconds: (data['durationMs'] as int?) ?? 0);

      final type = data['type'] as String?;
      if (type != null) {
        taskCounts[type] = (taskCounts[type] ?? 0) + 1;
      }
    }

    return {
      'period_days': period.inDays,
      'total_tasks': totalTasks,
      'successful_tasks': successfulTasks,
      'success_rate': totalTasks > 0 ? successfulTasks / totalTasks : 0,
      'total_items_processed': totalItemsProcessed,
      'total_duration_minutes': totalDuration.inMinutes,
      'task_counts': taskCounts,
    };
  }

  /// Get recent automation logs
  Future<List<AutomationResult>> getRecentLogs({int limit = 50}) async {
    final snapshot = await _automationLogsCollection
        .orderBy('completedAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return AutomationResult(
        taskId: data['taskId'] as String,
        type: AutomationTaskType.values.firstWhere(
          (e) => e.name == data['type'],
          orElse: () => AutomationTaskType.cleanInactiveRooms,
        ),
        success: data['success'] as bool,
        itemsProcessed: data['itemsProcessed'] as int,
        duration: Duration(milliseconds: data['durationMs'] as int),
        error: data['error'] as String?,
        completedAt: DateTime.parse(data['completedAt'] as String),
        details: Map<String, dynamic>.from(data['details'] ?? {}),
      );
    }).toList();
  }

  // Private methods

  Future<void> _recordResult(AutomationResult result) async {
    await _automationLogsCollection.doc(result.taskId).set(result.toMap());

    AnalyticsService.instance.logEvent(
      name: 'automation_task_completed',
      parameters: {
        'type': result.type.name,
        'success': result.success,
        'items_processed': result.itemsProcessed,
        'duration_ms': result.duration.inMilliseconds,
      },
    );
  }

  /// Dispose resources
  void dispose() {
    _taskResultController.close();
  }
}
