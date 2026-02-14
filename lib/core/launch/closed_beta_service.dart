/// Closed Beta Service
///
/// Manages closed beta testing program including cohort management,
/// beta updates distribution, feedback collection, and weekly summaries.
library;

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/analytics/analytics_service.dart';
import 'feedback_service.dart';

/// Service for managing closed beta testing
class ClosedBetaService {
  static ClosedBetaService? _instance;
  static ClosedBetaService get instance =>
      _instance ??= ClosedBetaService._();

  ClosedBetaService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AnalyticsService _analytics = AnalyticsService.instance;
  final FeedbackService _feedbackService = FeedbackService.instance;

  // Collections
  static const String _cohortsCollection = 'beta_cohorts';
  static const String _testersCollection = 'beta_testers';
  static const String _updatesCollection = 'beta_updates';
  static const String _summariesCollection = 'beta_summaries';

  // Limits
  static const int maxBetaTesters = 500;
  static const int maxCohortSize = 100;

  // ============================================================
  // COHORT MANAGEMENT
  // ============================================================

  /// Manage beta cohort - create, update, or archive
  Future<CohortResult> manageBetaCohort({
    required CohortAction action,
    String? cohortId,
    String? name,
    String? description,
    List<String>? featureFlags,
    int? maxSize,
    CohortType? cohortType,
  }) async {
    try {
      switch (action) {
        case CohortAction.create:
          return await _createCohort(
            name: name!,
            description: description,
            featureFlags: featureFlags,
            maxSize: maxSize ?? maxCohortSize,
            cohortType: cohortType ?? CohortType.general,
          );

        case CohortAction.update:
          return await _updateCohort(
            cohortId: cohortId!,
            name: name,
            description: description,
            featureFlags: featureFlags,
            maxSize: maxSize,
          );

        case CohortAction.archive:
          return await _archiveCohort(cohortId!);

        case CohortAction.activate:
          return await _activateCohort(cohortId!);
      }
    } catch (e) {
      debugPrint('❌ [Beta] Cohort management failed: $e');
      return CohortResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<CohortResult> _createCohort({
    required String name,
    String? description,
    List<String>? featureFlags,
    required int maxSize,
    required CohortType cohortType,
  }) async {
    debugPrint('📦 [Beta] Creating cohort: $name');

    final cohortRef = _firestore.collection(_cohortsCollection).doc();
    final cohortData = {
      'id': cohortRef.id,
      'name': name,
      'description': description,
      'featureFlags': featureFlags ?? [],
      'maxSize': maxSize,
      'currentSize': 0,
      'cohortType': cohortType.name,
      'status': CohortStatus.active.name,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await cohortRef.set(cohortData);

    await _analytics.logEvent(
      name: 'beta_cohort_created',
      parameters: {
        'cohort_id': cohortRef.id,
        'name': name,
        'type': cohortType.name,
      },
    );

    debugPrint('✅ [Beta] Cohort created: ${cohortRef.id}');

    return CohortResult(
      success: true,
      cohortId: cohortRef.id,
      message: 'Cohort created successfully',
    );
  }

  Future<CohortResult> _updateCohort({
    required String cohortId,
    String? name,
    String? description,
    List<String>? featureFlags,
    int? maxSize,
  }) async {
    debugPrint('📝 [Beta] Updating cohort: $cohortId');

    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (featureFlags != null) updates['featureFlags'] = featureFlags;
    if (maxSize != null) updates['maxSize'] = maxSize;

    await _firestore.collection(_cohortsCollection).doc(cohortId).update(updates);

    return CohortResult(
      success: true,
      cohortId: cohortId,
      message: 'Cohort updated successfully',
    );
  }

  Future<CohortResult> _archiveCohort(String cohortId) async {
    debugPrint('📁 [Beta] Archiving cohort: $cohortId');

    await _firestore.collection(_cohortsCollection).doc(cohortId).update({
      'status': CohortStatus.archived.name,
      'archivedAt': FieldValue.serverTimestamp(),
    });

    return CohortResult(
      success: true,
      cohortId: cohortId,
      message: 'Cohort archived',
    );
  }

  Future<CohortResult> _activateCohort(String cohortId) async {
    debugPrint('✅ [Beta] Activating cohort: $cohortId');

    await _firestore.collection(_cohortsCollection).doc(cohortId).update({
      'status': CohortStatus.active.name,
      'activatedAt': FieldValue.serverTimestamp(),
    });

    return CohortResult(
      success: true,
      cohortId: cohortId,
      message: 'Cohort activated',
    );
  }

  /// Get all cohorts
  Future<List<BetaCohort>> getCohorts({CohortStatus? status}) async {
    try {
      Query query = _firestore.collection(_cohortsCollection);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      final snapshot = await query.orderBy('createdAt', descending: true).get();
      return snapshot.docs
          .map((doc) => BetaCohort.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ [Beta] Failed to get cohorts: $e');
      return [];
    }
  }

  /// Add testers to a cohort
  Future<AddTesterResult> addTestersToCohort({
    required String cohortId,
    required List<String> userIds,
  }) async {
    try {
      debugPrint('👥 [Beta] Adding ${userIds.length} testers to cohort $cohortId');

      // Get cohort info
      final cohortDoc = await _firestore.collection(_cohortsCollection).doc(cohortId).get();
      if (!cohortDoc.exists) {
        return AddTesterResult(
          success: false,
          error: 'Cohort not found',
        );
      }

      final cohortData = cohortDoc.data()!;
      final currentSize = cohortData['currentSize'] ?? 0;
      final maxSize = cohortData['maxSize'] ?? maxCohortSize;

      if (currentSize + userIds.length > maxSize) {
        return AddTesterResult(
          success: false,
          error: 'Would exceed cohort limit of $maxSize',
        );
      }

      final added = <String>[];
      final failed = <String>[];
      final batch = _firestore.batch();

      for (final userId in userIds) {
        try {
          // Check if already in any cohort
          final existing = await _firestore
              .collection(_testersCollection)
              .doc(userId)
              .get();

          if (existing.exists) {
            failed.add(userId);
            continue;
          }

          final testerRef = _firestore.collection(_testersCollection).doc(userId);
          batch.set(testerRef, {
            'userId': userId,
            'cohortId': cohortId,
            'joinedAt': FieldValue.serverTimestamp(),
            'status': BetaTesterStatus.active.name,
            'feedbackCount': 0,
            'sessionsCount': 0,
            'lastActiveAt': null,
          });

          added.add(userId);
        } catch (e) {
          failed.add(userId);
        }
      }

      // Update cohort size
      batch.update(cohortDoc.reference, {
        'currentSize': FieldValue.increment(added.length),
      });

      await batch.commit();

      await _analytics.logEvent(
        name: 'beta_testers_added',
        parameters: {
          'cohort_id': cohortId,
          'count': added.length,
        },
      );

      return AddTesterResult(
        success: true,
        added: added,
        failed: failed,
      );
    } catch (e) {
      debugPrint('❌ [Beta] Failed to add testers: $e');
      return AddTesterResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  // ============================================================
  // BETA UPDATES
  // ============================================================

  /// Send beta update announcement
  Future<UpdateResult> sendBetaUpdates({
    required String title,
    required String body,
    String? version,
    List<String>? targetCohorts, // null means all active cohorts
    List<String>? highlights,
    String? downloadUrl,
  }) async {
    try {
      debugPrint('📢 [Beta] Sending update: $title');

      // Create update record
      final updateRef = _firestore.collection(_updatesCollection).doc();
      final updateData = {
        'id': updateRef.id,
        'title': title,
        'body': body,
        'version': version,
        'targetCohorts': targetCohorts,
        'highlights': highlights ?? [],
        'downloadUrl': downloadUrl,
        'sentAt': FieldValue.serverTimestamp(),
        'readCount': 0,
        'feedbackCount': 0,
      };

      await updateRef.set(updateData);

      // Get target testers
      List<String> testerIds = [];
      if (targetCohorts != null) {
        for (final cohortId in targetCohorts) {
          final testers = await _firestore
              .collection(_testersCollection)
              .where('cohortId', isEqualTo: cohortId)
              .where('status', isEqualTo: BetaTesterStatus.active.name)
              .get();
          testerIds.addAll(testers.docs.map((d) => d.id));
        }
      } else {
        final testers = await _firestore
            .collection(_testersCollection)
            .where('status', isEqualTo: BetaTesterStatus.active.name)
            .get();
        testerIds = testers.docs.map((d) => d.id).toList();
      }

      // Would integrate with push notifications
      debugPrint('📬 [Beta] Would notify ${testerIds.length} testers');

      await _analytics.logEvent(
        name: 'beta_update_sent',
        parameters: {
          'title': title,
          'version': version ?? 'unknown',
          'tester_count': testerIds.length,
        },
      );

      return UpdateResult(
        success: true,
        updateId: updateRef.id,
        notifiedCount: testerIds.length,
      );
    } catch (e) {
      debugPrint('❌ [Beta] Failed to send update: $e');
      return UpdateResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  // ============================================================
  // FEEDBACK COLLECTION
  // ============================================================

  /// Collect beta feedback
  Future<FeedbackSubmissionResult> collectBetaFeedback({
    required String userId,
    required String message,
    required FeedbackCategory category,
    FeedbackPriority priority = FeedbackPriority.medium,
    String? cohortId,
    String? updateId,
    String? screenName,
    List<String>? attachmentUrls,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Get tester's cohort if not provided
      String? actualCohortId = cohortId;
      if (actualCohortId == null) {
        final testerDoc = await _firestore
            .collection(_testersCollection)
            .doc(userId)
            .get();
        if (testerDoc.exists) {
          actualCohortId = testerDoc.data()?['cohortId'];
        }
      }

      // Submit through feedback service with beta metadata
      final result = await _feedbackService.submitFeedback(
        userId: userId,
        message: message,
        category: category,
        priority: priority,
        screenName: screenName,
        attachmentUrls: attachmentUrls,
        metadata: {
          ...?metadata,
          'source': 'closed_beta',
          'cohortId': actualCohortId,
          'updateId': updateId,
        },
      );

      if (result.success) {
        // Update tester feedback count
        await _firestore.collection(_testersCollection).doc(userId).update({
          'feedbackCount': FieldValue.increment(1),
          'lastFeedbackAt': FieldValue.serverTimestamp(),
        });

        // Update update feedback count
        if (updateId != null) {
          await _firestore.collection(_updatesCollection).doc(updateId).update({
            'feedbackCount': FieldValue.increment(1),
          });
        }
      }

      return result;
    } catch (e) {
      debugPrint('❌ [Beta] Failed to collect feedback: $e');
      return FeedbackSubmissionResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  // ============================================================
  // WEEKLY SUMMARY
  // ============================================================

  /// Generate weekly beta summary
  Future<WeeklyBetaSummary> generateWeeklyBetaSummary({
    DateTime? weekStart,
  }) async {
    try {
      debugPrint('📊 [Beta] Generating weekly summary...');

      final start = weekStart ??
          DateTime.now().subtract(Duration(days: DateTime.now().weekday));
      final end = start.add(const Duration(days: 7));

      // Get cohort stats
      final cohorts = await getCohorts(status: CohortStatus.active);
      final cohortStats = <String, CohortWeeklyStats>{};

      for (final cohort in cohorts) {
        final testers = await _firestore
            .collection(_testersCollection)
            .where('cohortId', isEqualTo: cohort.id)
            .get();

        final activeTesters = testers.docs.where((doc) {
          final lastActive = doc.data()['lastActiveAt'] as Timestamp?;
          return lastActive != null && lastActive.toDate().isAfter(start);
        }).length;

        final feedback = await _firestore
            .collection('feedback')
            .where('metadata.cohortId', isEqualTo: cohort.id)
            .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
            .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
            .get();

        cohortStats[cohort.id] = CohortWeeklyStats(
          cohortId: cohort.id,
          cohortName: cohort.name,
          totalTesters: testers.docs.length,
          activeTesters: activeTesters,
          feedbackCount: feedback.docs.length,
          engagementRate: testers.docs.isNotEmpty
              ? (activeTesters / testers.docs.length * 100)
              : 0.0,
        );
      }

      // Get overall feedback stats
      final allFeedback = await _firestore
          .collection('feedback')
          .where('metadata.source', isEqualTo: 'closed_beta')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      final feedbackByCategory = <FeedbackCategory, int>{};
      final feedbackByPriority = <FeedbackPriority, int>{};

      for (final doc in allFeedback.docs) {
        final data = doc.data();
        final category = FeedbackCategory.values.firstWhere(
          (c) => c.name == data['category'],
          orElse: () => FeedbackCategory.other,
        );
        final priority = FeedbackPriority.values.firstWhere(
          (p) => p.name == data['priority'],
          orElse: () => FeedbackPriority.medium,
        );

        feedbackByCategory[category] = (feedbackByCategory[category] ?? 0) + 1;
        feedbackByPriority[priority] = (feedbackByPriority[priority] ?? 0) + 1;
      }

      // Get updates sent this week
      final updatesQuery = await _firestore
          .collection(_updatesCollection)
          .where('sentAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('sentAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      // Top issues (critical/high priority)
      final topIssues = allFeedback.docs
          .where((doc) => ['critical', 'high'].contains(doc.data()['priority']))
          .map((doc) => doc.data()['message'] as String)
          .take(10)
          .toList();

      final summary = WeeklyBetaSummary(
        weekStart: start,
        weekEnd: end,
        generatedAt: DateTime.now(),
        totalActiveCohorts: cohorts.length,
        cohortStats: cohortStats,
        totalFeedback: allFeedback.docs.length,
        feedbackByCategory: feedbackByCategory,
        feedbackByPriority: feedbackByPriority,
        updatesCount: updatesQuery.docs.length,
        topIssues: topIssues,
      );

      // Save summary
      await _firestore.collection(_summariesCollection).add({
        'type': 'weekly',
        'weekStart': Timestamp.fromDate(start),
        'weekEnd': Timestamp.fromDate(end),
        'generatedAt': FieldValue.serverTimestamp(),
        'data': summary.toMap(),
      });

      debugPrint('✅ [Beta] Weekly summary generated');

      return summary;
    } catch (e) {
      debugPrint('❌ [Beta] Failed to generate summary: $e');
      rethrow;
    }
  }

  /// Get tester info
  Future<BetaTester?> getTester(String userId) async {
    try {
      final doc = await _firestore.collection(_testersCollection).doc(userId).get();
      if (!doc.exists) return null;
      return BetaTester.fromMap(doc.data()!);
    } catch (e) {
      debugPrint('❌ [Beta] Failed to get tester: $e');
      return null;
    }
  }

  /// Record tester activity
  Future<void> recordActivity(String userId) async {
    try {
      await _firestore.collection(_testersCollection).doc(userId).update({
        'lastActiveAt': FieldValue.serverTimestamp(),
        'sessionsCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('⚠️ [Beta] Failed to record activity: $e');
    }
  }
}

// ============================================================
// ENUMS
// ============================================================

enum CohortAction {
  create,
  update,
  archive,
  activate,
}

enum CohortType {
  general,
  powerUsers,
  creators,
  newUsers,
  international,
  accessibility,
}

enum CohortStatus {
  active,
  paused,
  archived,
}

enum BetaTesterStatus {
  active,
  inactive,
  removed,
}

// ============================================================
// DATA CLASSES
// ============================================================

class BetaCohort {
  final String id;
  final String name;
  final String? description;
  final List<String> featureFlags;
  final int maxSize;
  final int currentSize;
  final CohortType cohortType;
  final CohortStatus status;
  final DateTime? createdAt;

  const BetaCohort({
    required this.id,
    required this.name,
    this.description,
    required this.featureFlags,
    required this.maxSize,
    required this.currentSize,
    required this.cohortType,
    required this.status,
    this.createdAt,
  });

  factory BetaCohort.fromMap(Map<String, dynamic> map) {
    return BetaCohort(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      featureFlags: List<String>.from(map['featureFlags'] ?? []),
      maxSize: map['maxSize'] ?? 100,
      currentSize: map['currentSize'] ?? 0,
      cohortType: CohortType.values.firstWhere(
        (t) => t.name == map['cohortType'],
        orElse: () => CohortType.general,
      ),
      status: CohortStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => CohortStatus.active,
      ),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

class BetaTester {
  final String userId;
  final String cohortId;
  final BetaTesterStatus status;
  final DateTime? joinedAt;
  final DateTime? lastActiveAt;
  final int feedbackCount;
  final int sessionsCount;

  const BetaTester({
    required this.userId,
    required this.cohortId,
    required this.status,
    this.joinedAt,
    this.lastActiveAt,
    this.feedbackCount = 0,
    this.sessionsCount = 0,
  });

  factory BetaTester.fromMap(Map<String, dynamic> map) {
    return BetaTester(
      userId: map['userId'] ?? '',
      cohortId: map['cohortId'] ?? '',
      status: BetaTesterStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => BetaTesterStatus.active,
      ),
      joinedAt: (map['joinedAt'] as Timestamp?)?.toDate(),
      lastActiveAt: (map['lastActiveAt'] as Timestamp?)?.toDate(),
      feedbackCount: map['feedbackCount'] ?? 0,
      sessionsCount: map['sessionsCount'] ?? 0,
    );
  }
}

class CohortResult {
  final bool success;
  final String? cohortId;
  final String? message;
  final String? error;

  const CohortResult({
    required this.success,
    this.cohortId,
    this.message,
    this.error,
  });
}

class AddTesterResult {
  final bool success;
  final List<String> added;
  final List<String> failed;
  final String? error;

  const AddTesterResult({
    required this.success,
    this.added = const [],
    this.failed = const [],
    this.error,
  });
}

class UpdateResult {
  final bool success;
  final String? updateId;
  final int? notifiedCount;
  final String? error;

  const UpdateResult({
    required this.success,
    this.updateId,
    this.notifiedCount,
    this.error,
  });
}

class CohortWeeklyStats {
  final String cohortId;
  final String cohortName;
  final int totalTesters;
  final int activeTesters;
  final int feedbackCount;
  final double engagementRate;

  const CohortWeeklyStats({
    required this.cohortId,
    required this.cohortName,
    required this.totalTesters,
    required this.activeTesters,
    required this.feedbackCount,
    required this.engagementRate,
  });

  Map<String, dynamic> toMap() {
    return {
      'cohortId': cohortId,
      'cohortName': cohortName,
      'totalTesters': totalTesters,
      'activeTesters': activeTesters,
      'feedbackCount': feedbackCount,
      'engagementRate': engagementRate,
    };
  }
}

class WeeklyBetaSummary {
  final DateTime weekStart;
  final DateTime weekEnd;
  final DateTime generatedAt;
  final int totalActiveCohorts;
  final Map<String, CohortWeeklyStats> cohortStats;
  final int totalFeedback;
  final Map<FeedbackCategory, int> feedbackByCategory;
  final Map<FeedbackPriority, int> feedbackByPriority;
  final int updatesCount;
  final List<String> topIssues;

  const WeeklyBetaSummary({
    required this.weekStart,
    required this.weekEnd,
    required this.generatedAt,
    required this.totalActiveCohorts,
    required this.cohortStats,
    required this.totalFeedback,
    required this.feedbackByCategory,
    required this.feedbackByPriority,
    required this.updatesCount,
    required this.topIssues,
  });

  Map<String, dynamic> toMap() {
    return {
      'weekStart': weekStart.toIso8601String(),
      'weekEnd': weekEnd.toIso8601String(),
      'generatedAt': generatedAt.toIso8601String(),
      'totalActiveCohorts': totalActiveCohorts,
      'cohortStats': cohortStats.map((k, v) => MapEntry(k, v.toMap())),
      'totalFeedback': totalFeedback,
      'feedbackByCategory': feedbackByCategory.map((k, v) => MapEntry(k.name, v)),
      'feedbackByPriority': feedbackByPriority.map((k, v) => MapEntry(k.name, v)),
      'updatesCount': updatesCount,
      'topIssues': topIssues,
    };
  }
}
