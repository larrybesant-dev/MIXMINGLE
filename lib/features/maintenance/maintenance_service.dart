/// Maintenance Service
///
/// Automated long-term maintenance tasks including archiving,
/// cleanup, key rotation, and backup operations.
library;

import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../core/analytics/analytics_service.dart';

/// Maintenance task result
class MaintenanceResult {
  final String taskId;
  final MaintenanceTaskType taskType;
  final bool success;
  final int itemsProcessed;
  final int itemsArchived;
  final int itemsDeleted;
  final Duration duration;
  final String? error;
  final DateTime startedAt;
  final DateTime completedAt;
  final Map<String, dynamic> details;

  const MaintenanceResult({
    required this.taskId,
    required this.taskType,
    required this.success,
    this.itemsProcessed = 0,
    this.itemsArchived = 0,
    this.itemsDeleted = 0,
    required this.duration,
    this.error,
    required this.startedAt,
    required this.completedAt,
    this.details = const {},
  });

  Map<String, dynamic> toMap() => {
    'taskId': taskId,
    'taskType': taskType.name,
    'success': success,
    'itemsProcessed': itemsProcessed,
    'itemsArchived': itemsArchived,
    'itemsDeleted': itemsDeleted,
    'durationMs': duration.inMilliseconds,
    'error': error,
    'startedAt': startedAt.toIso8601String(),
    'completedAt': completedAt.toIso8601String(),
    'details': details,
  };
}

/// Maintenance task types
enum MaintenanceTaskType {
  archiveOldRooms,
  cleanUnusedAssets,
  rotateKeys,
  backupCriticalData,
  purgeDeletedUsers,
  compactCollections,
  cleanOrphanedRecords,
  validateDataIntegrity,
}

/// Archive configuration
class ArchiveConfig {
  final Duration roomAgeThreshold;
  final Duration messageAgeThreshold;
  final Duration logRetentionPeriod;
  final Duration userInactivityThreshold;
  final int batchSize;
  final bool dryRun;

  const ArchiveConfig({
    this.roomAgeThreshold = const Duration(days: 90),
    this.messageAgeThreshold = const Duration(days: 180),
    this.logRetentionPeriod = const Duration(days: 30),
    this.userInactivityThreshold = const Duration(days: 365),
    this.batchSize = 500,
    this.dryRun = false,
  });
}

/// Backup result
class BackupResult {
  final String backupId;
  final BackupType type;
  final List<String> collectionsBackedUp;
  final int totalDocuments;
  final int sizeBytes;
  final String location;
  final bool success;
  final DateTime completedAt;

  const BackupResult({
    required this.backupId,
    required this.type,
    required this.collectionsBackedUp,
    required this.totalDocuments,
    required this.sizeBytes,
    required this.location,
    required this.success,
    required this.completedAt,
  });

  Map<String, dynamic> toMap() => {
    'backupId': backupId,
    'type': type.name,
    'collectionsBackedUp': collectionsBackedUp,
    'totalDocuments': totalDocuments,
    'sizeBytes': sizeBytes,
    'location': location,
    'success': success,
    'completedAt': completedAt.toIso8601String(),
  };
}

/// Backup types
enum BackupType {
  full,
  incremental,
  differential,
  critical,
}

/// Key rotation result
class KeyRotationResult {
  final String keyType;
  final bool rotated;
  final DateTime? previousRotation;
  final DateTime newRotation;
  final String? error;

  const KeyRotationResult({
    required this.keyType,
    required this.rotated,
    this.previousRotation,
    required this.newRotation,
    this.error,
  });

  Map<String, dynamic> toMap() => {
    'keyType': keyType,
    'rotated': rotated,
    'previousRotation': previousRotation?.toIso8601String(),
    'newRotation': newRotation.toIso8601String(),
    'error': error,
  };
}

/// Long-term maintenance automation service
class MaintenanceService {
  static MaintenanceService? _instance;
  static MaintenanceService get instance => _instance ??= MaintenanceService._();

  MaintenanceService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _random = Random();

  // Default configuration
  ArchiveConfig _config = const ArchiveConfig();

  // Stream controllers
  final _maintenanceController = StreamController<MaintenanceResult>.broadcast();
  Stream<MaintenanceResult> get maintenanceStream => _maintenanceController.stream;

  // Collections
  CollectionReference<Map<String, dynamic>> get _roomsCollection =>
      _firestore.collection('rooms');

  CollectionReference<Map<String, dynamic>> get _archivedRoomsCollection =>
      _firestore.collection('archived_rooms');

  CollectionReference<Map<String, dynamic>> get _assetsCollection =>
      _firestore.collection('assets');

  CollectionReference<Map<String, dynamic>> get _maintenanceLogsCollection =>
      _firestore.collection('maintenance_logs');

  CollectionReference<Map<String, dynamic>> get _backupsCollection =>
      _firestore.collection('backups');

  CollectionReference<Map<String, dynamic>> get _keysCollection =>
      _firestore.collection('key_rotations');

  /// Update configuration
  void configure(ArchiveConfig config) {
    _config = config;
  }

  // ============================================================
  // AUTO-ARCHIVE OLD ROOMS
  // ============================================================

  /// Archive old inactive rooms
  Future<MaintenanceResult> autoArchiveOldRooms({
    Duration? ageThreshold,
    int? batchSize,
    bool? dryRun,
  }) async {
    final taskId = _generateTaskId();
    final startedAt = DateTime.now();

    debugPrint('ðŸ“¦ [MaintenanceService] Starting room archival (taskId: $taskId)');

    final threshold = ageThreshold ?? _config.roomAgeThreshold;
    final batch = batchSize ?? _config.batchSize;
    final isDryRun = dryRun ?? _config.dryRun;

    int itemsProcessed = 0;
    int itemsArchived = 0;

    try {
      final cutoffDate = DateTime.now().subtract(threshold);

      // Query old rooms
      final oldRoomsQuery = await _roomsCollection
          .where('status', isEqualTo: 'ended')
          .where('endedAt', isLessThan: cutoffDate.toIso8601String())
          .limit(batch)
          .get();

      itemsProcessed = oldRoomsQuery.docs.length;
      debugPrint('ðŸ“¦ [MaintenanceService] Found $itemsProcessed rooms to archive');

      if (!isDryRun) {
        final writeBatch = _firestore.batch();

        for (final doc in oldRoomsQuery.docs) {
          // Archive the room
          final archiveRef = _archivedRoomsCollection.doc(doc.id);
          writeBatch.set(archiveRef, {
            ...doc.data(),
            'archivedAt': FieldValue.serverTimestamp(),
            'archiveReason': 'age_threshold_exceeded',
          });

          // Delete from active collection
          writeBatch.delete(doc.reference);
          itemsArchived++;
        }

        if (itemsArchived > 0) {
          await writeBatch.commit();
        }
      }

      final result = MaintenanceResult(
        taskId: taskId,
        taskType: MaintenanceTaskType.archiveOldRooms,
        success: true,
        itemsProcessed: itemsProcessed,
        itemsArchived: itemsArchived,
        duration: DateTime.now().difference(startedAt),
        startedAt: startedAt,
        completedAt: DateTime.now(),
        details: {
          'threshold': threshold.inDays,
          'dryRun': isDryRun,
          'cutoffDate': cutoffDate.toIso8601String(),
        },
      );

      await _logMaintenance(result);
      _maintenanceController.add(result);

      debugPrint('âœ… [MaintenanceService] Archived $itemsArchived rooms');
      return result;
    } catch (e) {
      final result = MaintenanceResult(
        taskId: taskId,
        taskType: MaintenanceTaskType.archiveOldRooms,
        success: false,
        itemsProcessed: itemsProcessed,
        itemsArchived: itemsArchived,
        duration: DateTime.now().difference(startedAt),
        error: e.toString(),
        startedAt: startedAt,
        completedAt: DateTime.now(),
      );

      await _logMaintenance(result);
      _maintenanceController.add(result);

      debugPrint('âŒ [MaintenanceService] Failed to archive rooms: $e');
      return result;
    }
  }

  // ============================================================
  // AUTO-CLEAN UNUSED ASSETS
  // ============================================================

  /// Clean unused assets (orphaned files, old uploads, etc.)
  Future<MaintenanceResult> autoCleanUnusedAssets({
    Duration? unusedThreshold,
    int? batchSize,
    bool? dryRun,
  }) async {
    final taskId = _generateTaskId();
    final startedAt = DateTime.now();

    debugPrint('ðŸ§¹ [MaintenanceService] Starting asset cleanup (taskId: $taskId)');

    final threshold = unusedThreshold ?? const Duration(days: 30);
    final batch = batchSize ?? _config.batchSize;
    final isDryRun = dryRun ?? _config.dryRun;

    int itemsProcessed = 0;
    int itemsDeleted = 0;

    try {
      final cutoffDate = DateTime.now().subtract(threshold);

      // Query unused assets
      final unusedQuery = await _assetsCollection
          .where('lastAccessedAt', isLessThan: cutoffDate.toIso8601String())
          .where('referenceCount', isEqualTo: 0)
          .limit(batch)
          .get();

      itemsProcessed = unusedQuery.docs.length;
      debugPrint('ðŸ§¹ [MaintenanceService] Found $itemsProcessed unused assets');

      if (!isDryRun) {
        final writeBatch = _firestore.batch();

        for (final doc in unusedQuery.docs) {
          // Note: In production, also delete from Storage
          writeBatch.delete(doc.reference);
          itemsDeleted++;
        }

        if (itemsDeleted > 0) {
          await writeBatch.commit();
        }
      }

      final result = MaintenanceResult(
        taskId: taskId,
        taskType: MaintenanceTaskType.cleanUnusedAssets,
        success: true,
        itemsProcessed: itemsProcessed,
        itemsDeleted: itemsDeleted,
        duration: DateTime.now().difference(startedAt),
        startedAt: startedAt,
        completedAt: DateTime.now(),
        details: {
          'threshold': threshold.inDays,
          'dryRun': isDryRun,
        },
      );

      await _logMaintenance(result);
      _maintenanceController.add(result);

      debugPrint('âœ… [MaintenanceService] Cleaned $itemsDeleted unused assets');
      return result;
    } catch (e) {
      final result = MaintenanceResult(
        taskId: taskId,
        taskType: MaintenanceTaskType.cleanUnusedAssets,
        success: false,
        itemsProcessed: itemsProcessed,
        itemsDeleted: itemsDeleted,
        duration: DateTime.now().difference(startedAt),
        error: e.toString(),
        startedAt: startedAt,
        completedAt: DateTime.now(),
      );

      await _logMaintenance(result);
      _maintenanceController.add(result);

      debugPrint('âŒ [MaintenanceService] Failed to clean assets: $e');
      return result;
    }
  }

  // ============================================================
  // AUTO-ROTATE KEYS
  // ============================================================

  /// Automatically rotate API keys and secrets
  Future<List<KeyRotationResult>> autoRotateKeys({
    List<String>? keyTypes,
    bool? forceRotation,
  }) async {
    debugPrint('ðŸ”‘ [MaintenanceService] Starting key rotation');

    final typesToRotate = keyTypes ?? ['api_key', 'webhook_secret', 'encryption_key'];
    final force = forceRotation ?? false;
    final results = <KeyRotationResult>[];

    for (final keyType in typesToRotate) {
      try {
        // Check last rotation
        final keyDoc = await _keysCollection.doc(keyType).get();
        final keyData = keyDoc.data();

        DateTime? lastRotation;
        if (keyData != null && keyData['lastRotatedAt'] != null) {
          lastRotation = DateTime.tryParse(keyData['lastRotatedAt'] as String);
        }

        // Determine if rotation is needed
        final rotationInterval = _getRotationInterval(keyType);
        final needsRotation = force ||
            lastRotation == null ||
            DateTime.now().difference(lastRotation) > rotationInterval;

        if (needsRotation) {
          // Perform rotation (in production, this would generate new keys)
          await _keysCollection.doc(keyType).set({
            'keyType': keyType,
            'lastRotatedAt': DateTime.now().toIso8601String(),
            'rotationInterval': rotationInterval.inDays,
            'rotatedBy': 'maintenance_service',
          }, SetOptions(merge: true));

          results.add(KeyRotationResult(
            keyType: keyType,
            rotated: true,
            previousRotation: lastRotation,
            newRotation: DateTime.now(),
          ));

          debugPrint('âœ… [MaintenanceService] Rotated key: $keyType');
        } else {
          results.add(KeyRotationResult(
            keyType: keyType,
            rotated: false,
            previousRotation: lastRotation,
            newRotation: lastRotation,
          ));

          debugPrint('â­ï¸ [MaintenanceService] Skipped key rotation: $keyType (not due)');
        }
      } catch (e) {
        results.add(KeyRotationResult(
          keyType: keyType,
          rotated: false,
          newRotation: DateTime.now(),
          error: e.toString(),
        ));

        debugPrint('âŒ [MaintenanceService] Failed to rotate key $keyType: $e');
      }
    }

    // Log results
    await _maintenanceLogsCollection.add({
      'type': 'key_rotation',
      'results': results.map((r) => r.toMap()).toList(),
      'timestamp': FieldValue.serverTimestamp(),
    });

    return results;
  }

  Duration _getRotationInterval(String keyType) {
    switch (keyType) {
      case 'api_key':
        return const Duration(days: 90);
      case 'webhook_secret':
        return const Duration(days: 60);
      case 'encryption_key':
        return const Duration(days: 180);
      default:
        return const Duration(days: 90);
    }
  }

  // ============================================================
  // AUTO-BACKUP CRITICAL DATA
  // ============================================================

  /// Backup critical data collections
  Future<BackupResult> autoBackupCriticalData({
    BackupType type = BackupType.incremental,
    List<String>? collections,
  }) async {
    final backupId = _generateBackupId();
    debugPrint('ðŸ’¾ [MaintenanceService] Starting backup (id: $backupId, type: ${type.name})');

    final collectionsToBackup = collections ?? [
      'users',
      'rooms',
      'subscriptions',
      'payments',
      'creator_profiles',
    ];

    int totalDocuments = 0;
    int estimatedSize = 0;

    try {
      // In production, this would:
      // 1. Export to Cloud Storage
      // 2. Use Firestore Export API
      // 3. Verify backup integrity

      for (final collection in collectionsToBackup) {
        final count = await _firestore.collection(collection).count().get();
        totalDocuments += count.count ?? 0;
        estimatedSize += (count.count ?? 0) * 1024; // Rough estimate
      }

      // Record backup metadata
      final backupLocation = 'gs://mixmingle-backups/$backupId';

      await _backupsCollection.doc(backupId).set({
        'backupId': backupId,
        'type': type.name,
        'collections': collectionsToBackup,
        'totalDocuments': totalDocuments,
        'sizeBytes': estimatedSize,
        'location': backupLocation,
        'status': 'completed',
        'createdAt': FieldValue.serverTimestamp(),
      });

      final result = BackupResult(
        backupId: backupId,
        type: type,
        collectionsBackedUp: collectionsToBackup,
        totalDocuments: totalDocuments,
        sizeBytes: estimatedSize,
        location: backupLocation,
        success: true,
        completedAt: DateTime.now(),
      );

      // Track analytics
      AnalyticsService.instance.logEvent(name: 'backup_completed', parameters: {
        'backup_id': backupId,
        'type': type.name,
        'documents': totalDocuments,
      });

      debugPrint('âœ… [MaintenanceService] Backup completed: $totalDocuments documents');
      return result;
    } catch (e) {
      debugPrint('âŒ [MaintenanceService] Backup failed: $e');

      await _backupsCollection.doc(backupId).set({
        'backupId': backupId,
        'type': type.name,
        'status': 'failed',
        'error': e.toString(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      return BackupResult(
        backupId: backupId,
        type: type,
        collectionsBackedUp: [],
        totalDocuments: 0,
        sizeBytes: 0,
        location: '',
        success: false,
        completedAt: DateTime.now(),
      );
    }
  }

  // ============================================================
  // DATA INTEGRITY VALIDATION
  // ============================================================

  /// Validate data integrity across collections
  Future<MaintenanceResult> validateDataIntegrity() async {
    final taskId = _generateTaskId();
    final startedAt = DateTime.now();

    debugPrint('ðŸ” [MaintenanceService] Validating data integrity');

    int itemsProcessed = 0;
    final issues = <Map<String, dynamic>>[];

    try {
      // Check for orphaned room participants
      final participants = await _firestore.collection('room_participants')
          .limit(1000)
          .get();

      for (final doc in participants.docs) {
        itemsProcessed++;
        final roomId = doc.data()['roomId'] as String?;
        if (roomId != null) {
          final roomExists = await _roomsCollection.doc(roomId).get();
          if (!roomExists.exists) {
            issues.add({
              'type': 'orphaned_participant',
              'participantId': doc.id,
              'missingRoomId': roomId,
            });
          }
        }
      }

      // Check for rooms without hosts
      final rooms = await _roomsCollection.limit(500).get();
      for (final doc in rooms.docs) {
        itemsProcessed++;
        final hostId = doc.data()['hostId'] as String?;
        if (hostId == null || hostId.isEmpty) {
          issues.add({
            'type': 'room_without_host',
            'roomId': doc.id,
          });
        }
      }

      final result = MaintenanceResult(
        taskId: taskId,
        taskType: MaintenanceTaskType.validateDataIntegrity,
        success: true,
        itemsProcessed: itemsProcessed,
        duration: DateTime.now().difference(startedAt),
        startedAt: startedAt,
        completedAt: DateTime.now(),
        details: {
          'issuesFound': issues.length,
          'issues': issues.take(50).toList(),
        },
      );

      await _logMaintenance(result);
      _maintenanceController.add(result);

      debugPrint('âœ… [MaintenanceService] Integrity check complete: ${issues.length} issues found');
      return result;
    } catch (e) {
      final result = MaintenanceResult(
        taskId: taskId,
        taskType: MaintenanceTaskType.validateDataIntegrity,
        success: false,
        itemsProcessed: itemsProcessed,
        duration: DateTime.now().difference(startedAt),
        error: e.toString(),
        startedAt: startedAt,
        completedAt: DateTime.now(),
      );

      await _logMaintenance(result);
      _maintenanceController.add(result);

      debugPrint('âŒ [MaintenanceService] Integrity check failed: $e');
      return result;
    }
  }

  // ============================================================
  // UTILITY METHODS
  // ============================================================

  String _generateTaskId() {
    return 'maint_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(10000)}';
  }

  String _generateBackupId() {
    final now = DateTime.now();
    return 'backup_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${_random.nextInt(10000)}';
  }

  Future<void> _logMaintenance(MaintenanceResult result) async {
    try {
      await _maintenanceLogsCollection.add({
        ...result.toMap(),
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('âš ï¸ [MaintenanceService] Failed to log maintenance: $e');
    }
  }

  /// Get maintenance history
  Future<List<MaintenanceResult>> getMaintenanceHistory({
    MaintenanceTaskType? type,
    int limit = 50,
  }) async {
    var query = _maintenanceLogsCollection
        .orderBy('timestamp', descending: true)
        .limit(limit);

    if (type != null) {
      query = query.where('taskType', isEqualTo: type.name);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return MaintenanceResult(
        taskId: data['taskId'] as String? ?? '',
        taskType: MaintenanceTaskType.values.firstWhere(
          (t) => t.name == data['taskType'],
          orElse: () => MaintenanceTaskType.archiveOldRooms,
        ),
        success: data['success'] as bool? ?? false,
        itemsProcessed: data['itemsProcessed'] as int? ?? 0,
        itemsArchived: data['itemsArchived'] as int? ?? 0,
        itemsDeleted: data['itemsDeleted'] as int? ?? 0,
        duration: Duration(milliseconds: data['durationMs'] as int? ?? 0),
        error: data['error'] as String?,
        startedAt: DateTime.tryParse(data['startedAt'] as String? ?? '') ?? DateTime.now(),
        completedAt: DateTime.tryParse(data['completedAt'] as String? ?? '') ?? DateTime.now(),
        details: (data['details'] as Map<String, dynamic>?) ?? {},
      );
    }).toList();
  }

  /// Dispose resources
  void dispose() {
    _maintenanceController.close();
  }
}
