/// Internal Alpha Service
///
/// Manages internal alpha testing program including tester invitations,
/// build distribution, feedback collection, and reporting.
library;

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/analytics/analytics_service.dart';
import 'feedback_service.dart';

/// Service for managing internal alpha testing
class InternalAlphaService {
  static InternalAlphaService? _instance;
  static InternalAlphaService get instance =>
      _instance ??= InternalAlphaService._();

  InternalAlphaService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AnalyticsService _analytics = AnalyticsService.instance;
  final FeedbackService _feedbackService = FeedbackService.instance;

  // Collections
  static const String _testersCollection = 'alpha_testers';
  static const String _buildsCollection = 'alpha_builds';
  static const String _reportsCollection = 'alpha_reports';

  // Limits
  static const int maxInternalTesters = 50;

  // ============================================================
  // TESTER MANAGEMENT
  // ============================================================

  /// Invite internal testers to the alpha program
  Future<InviteResult> inviteInternalTesters({
    required List<String> emails,
    String? invitedBy,
    String? customMessage,
  }) async {
    try {
      debugPrint('📧 [Alpha] Inviting ${emails.length} internal testers...');

      final existingCount = await _getActiveTesterCount();
      if (existingCount + emails.length > maxInternalTesters) {
        return InviteResult(
          success: false,
          invited: [],
          failed: emails,
          error: 'Would exceed maximum of $maxInternalTesters internal testers',
        );
      }

      final invited = <String>[];
      final failed = <String>[];
      final batch = _firestore.batch();

      for (final email in emails) {
        try {
          final normalizedEmail = email.toLowerCase().trim();

          // Check if already invited
          final existing = await _firestore
              .collection(_testersCollection)
              .where('email', isEqualTo: normalizedEmail)
              .get();

          if (existing.docs.isNotEmpty) {
            failed.add(email);
            continue;
          }

          // Create invitation
          final docRef = _firestore.collection(_testersCollection).doc();
          batch.set(docRef, {
            'id': docRef.id,
            'email': normalizedEmail,
            'status': TesterStatus.invited.name,
            'invitedBy': invitedBy,
            'customMessage': customMessage,
            'invitedAt': FieldValue.serverTimestamp(),
            'lastActiveAt': null,
            'feedbackCount': 0,
            'sessionsCount': 0,
            'deviceInfo': null,
          });

          invited.add(email);
        } catch (e) {
          failed.add(email);
          debugPrint('❌ [Alpha] Failed to invite $email: $e');
        }
      }

      await batch.commit();

      // Track analytics
      await _analytics.logEvent(
        name: 'alpha_testers_invited',
        parameters: {
          'count': invited.length,
          'invited_by': invitedBy ?? 'system',
        },
      );

      debugPrint('✅ [Alpha] Invited ${invited.length} testers');

      return InviteResult(
        success: true,
        invited: invited,
        failed: failed,
      );
    } catch (e) {
      debugPrint('❌ [Alpha] Failed to invite testers: $e');
      return InviteResult(
        success: false,
        invited: [],
        failed: emails,
        error: e.toString(),
      );
    }
  }

  /// Get all internal testers
  Future<List<AlphaTester>> getTesters({
    TesterStatus? status,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore.collection(_testersCollection);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      query = query.orderBy('invitedAt', descending: true).limit(limit);

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => AlphaTester.fromMap(doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('❌ [Alpha] Failed to get testers: $e');
      return [];
    }
  }

  /// Activate a tester (when they accept invitation)
  Future<bool> activateTester(String email) async {
    try {
      final query = await _firestore
          .collection(_testersCollection)
          .where('email', isEqualTo: email.toLowerCase())
          .get();

      if (query.docs.isEmpty) return false;

      await query.docs.first.reference.update({
        'status': TesterStatus.active.name,
        'activatedAt': FieldValue.serverTimestamp(),
        'lastActiveAt': FieldValue.serverTimestamp(),
      });

      await _analytics.logEvent(
        name: 'alpha_tester_activated',
        parameters: {'email': email},
      );

      debugPrint('✅ [Alpha] Tester activated: $email');
      return true;
    } catch (e) {
      debugPrint('❌ [Alpha] Failed to activate tester: $e');
      return false;
    }
  }

  /// Record tester activity
  Future<void> recordActivity(String email, {Map<String, dynamic>? deviceInfo}) async {
    try {
      final query = await _firestore
          .collection(_testersCollection)
          .where('email', isEqualTo: email.toLowerCase())
          .get();

      if (query.docs.isEmpty) return;

      final update = <String, dynamic>{
        'lastActiveAt': FieldValue.serverTimestamp(),
        'sessionsCount': FieldValue.increment(1),
      };

      if (deviceInfo != null) {
        update['deviceInfo'] = deviceInfo;
      }

      await query.docs.first.reference.update(update);
    } catch (e) {
      debugPrint('⚠️ [Alpha] Failed to record activity: $e');
    }
  }

  // ============================================================
  // BUILD DISTRIBUTION
  // ============================================================

  /// Distribute a new build to internal testers
  Future<DistributeResult> distributeBuild({
    required String version,
    required int buildNumber,
    required String platform,
    String? releaseNotes,
    List<String>? targetTesters, // null means all active testers
  }) async {
    try {
      debugPrint('📦 [Alpha] Distributing build $version ($buildNumber)...');

      // Create build record
      final buildRef = _firestore.collection(_buildsCollection).doc();
      final buildData = {
        'id': buildRef.id,
        'version': version,
        'buildNumber': buildNumber,
        'platform': platform,
        'releaseNotes': releaseNotes,
        'distributedAt': FieldValue.serverTimestamp(),
        'distributedTo': targetTesters ?? [],
        'downloadCount': 0,
        'feedbackCount': 0,
        'status': 'distributed',
      };

      await buildRef.set(buildData);

      // Get target testers
      List<AlphaTester> testers;
      if (targetTesters != null) {
        testers = await Future.wait(
          targetTesters.map((email) => _getTester(email)),
        ).then((list) => list.whereType<AlphaTester>().toList());
      } else {
        testers = await getTesters(status: TesterStatus.active);
      }

      // Notify testers (would integrate with push notifications)
      for (final tester in testers) {
        await _notifyTester(tester, buildData);
      }

      await _analytics.logEvent(
        name: 'alpha_build_distributed',
        parameters: {
          'version': version,
          'build_number': buildNumber,
          'tester_count': testers.length,
        },
      );

      debugPrint('✅ [Alpha] Build distributed to ${testers.length} testers');

      return DistributeResult(
        success: true,
        buildId: buildRef.id,
        notifiedCount: testers.length,
      );
    } catch (e) {
      debugPrint('❌ [Alpha] Failed to distribute build: $e');
      return DistributeResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Record that a tester downloaded a build
  Future<void> recordDownload(String buildId, String testerEmail) async {
    try {
      await _firestore.collection(_buildsCollection).doc(buildId).update({
        'downloadCount': FieldValue.increment(1),
        'downloads': FieldValue.arrayUnion([testerEmail]),
      });
    } catch (e) {
      debugPrint('⚠️ [Alpha] Failed to record download: $e');
    }
  }

  // ============================================================
  // FEEDBACK COLLECTION
  // ============================================================

  /// Collect feedback from internal tester
  Future<FeedbackSubmissionResult> collectInternalFeedback({
    required String userId,
    required String testerEmail,
    required String message,
    required FeedbackCategory category,
    FeedbackPriority priority = FeedbackPriority.medium,
    String? buildId,
    List<String>? attachmentUrls,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Submit through feedback service with alpha metadata
      final result = await _feedbackService.submitFeedback(
        userId: userId,
        message: message,
        category: category,
        priority: priority,
        attachmentUrls: attachmentUrls,
        metadata: {
          ...?metadata,
          'source': 'internal_alpha',
          'testerEmail': testerEmail,
          'buildId': buildId,
        },
      );

      if (result.success) {
        // Update tester feedback count
        await _updateTesterFeedbackCount(testerEmail);

        // Update build feedback count
        if (buildId != null) {
          await _firestore.collection(_buildsCollection).doc(buildId).update({
            'feedbackCount': FieldValue.increment(1),
          });
        }
      }

      return result;
    } catch (e) {
      debugPrint('❌ [Alpha] Failed to collect feedback: $e');
      return FeedbackSubmissionResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  // ============================================================
  // REPORTING
  // ============================================================

  /// Generate internal alpha report
  Future<InternalReport> generateInternalReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      debugPrint('📊 [Alpha] Generating internal report...');

      final start = startDate ?? DateTime.now().subtract(const Duration(days: 7));
      final end = endDate ?? DateTime.now();

      // Get testers stats
      final allTesters = await getTesters();
      final activeTesters = allTesters.where((t) => t.status == TesterStatus.active).toList();
      final inactiveTesters = allTesters.where((t) =>
        t.status == TesterStatus.active &&
        (t.lastActiveAt == null ||
         t.lastActiveAt!.isBefore(DateTime.now().subtract(const Duration(days: 3))))
      ).toList();

      // Get feedback stats
      final feedbackQuery = await _firestore
          .collection('feedback')
          .where('metadata.source', isEqualTo: 'internal_alpha')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      final feedbackByCategory = <FeedbackCategory, int>{};
      final feedbackByPriority = <FeedbackPriority, int>{};

      for (final doc in feedbackQuery.docs) {
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

      // Get builds
      final buildsQuery = await _firestore
          .collection(_buildsCollection)
          .where('distributedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .orderBy('distributedAt', descending: true)
          .get();

      final builds = buildsQuery.docs.map((doc) {
        final data = doc.data();
        return AlphaBuild(
          id: data['id'],
          version: data['version'],
          buildNumber: data['buildNumber'],
          platform: data['platform'],
          distributedAt: (data['distributedAt'] as Timestamp).toDate(),
          downloadCount: data['downloadCount'] ?? 0,
          feedbackCount: data['feedbackCount'] ?? 0,
        );
      }).toList();

      // Calculate adoption rate
      final latestBuild = builds.isNotEmpty ? builds.first : null;
      final adoptionRate = latestBuild != null && activeTesters.isNotEmpty
          ? (latestBuild.downloadCount / activeTesters.length * 100)
              .clamp(0, 100)
              .toDouble()
          : 0.0;

      // Top issues
      final criticalFeedback = feedbackQuery.docs
          .where((doc) => doc.data()['priority'] == 'critical')
          .map((doc) => doc.data()['message'] as String)
          .take(5)
          .toList();

      final report = InternalReport(
        generatedAt: DateTime.now(),
        periodStart: start,
        periodEnd: end,
        totalTesters: allTesters.length,
        activeTesters: activeTesters.length,
        inactiveTesters: inactiveTesters.length,
        totalFeedback: feedbackQuery.docs.length,
        feedbackByCategory: feedbackByCategory,
        feedbackByPriority: feedbackByPriority,
        builds: builds,
        latestBuildAdoption: adoptionRate,
        topIssues: criticalFeedback,
      );

      // Save report
      await _firestore.collection(_reportsCollection).add({
        'type': 'internal_alpha',
        'generatedAt': FieldValue.serverTimestamp(),
        'periodStart': Timestamp.fromDate(start),
        'periodEnd': Timestamp.fromDate(end),
        'data': report.toMap(),
      });

      debugPrint('✅ [Alpha] Report generated');

      return report;
    } catch (e) {
      debugPrint('❌ [Alpha] Failed to generate report: $e');
      rethrow;
    }
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  Future<int> _getActiveTesterCount() async {
    final snapshot = await _firestore
        .collection(_testersCollection)
        .where('status', whereIn: [TesterStatus.invited.name, TesterStatus.active.name])
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<AlphaTester?> _getTester(String email) async {
    final query = await _firestore
        .collection(_testersCollection)
        .where('email', isEqualTo: email.toLowerCase())
        .get();

    if (query.docs.isEmpty) return null;
    return AlphaTester.fromMap(query.docs.first.data());
  }

  Future<void> _notifyTester(AlphaTester tester, Map<String, dynamic> buildData) async {
    // Would integrate with NotificationService to send push/email
    debugPrint('📬 [Alpha] Would notify ${tester.email} about build ${buildData['version']}');
  }

  Future<void> _updateTesterFeedbackCount(String email) async {
    final query = await _firestore
        .collection(_testersCollection)
        .where('email', isEqualTo: email.toLowerCase())
        .get();

    if (query.docs.isNotEmpty) {
      await query.docs.first.reference.update({
        'feedbackCount': FieldValue.increment(1),
        'lastFeedbackAt': FieldValue.serverTimestamp(),
      });
    }
  }
}

// ============================================================
// ENUMS
// ============================================================

enum TesterStatus {
  invited,
  active,
  inactive,
  removed,
}

// ============================================================
// DATA CLASSES
// ============================================================

class AlphaTester {
  final String id;
  final String email;
  final TesterStatus status;
  final DateTime? invitedAt;
  final DateTime? activatedAt;
  final DateTime? lastActiveAt;
  final int feedbackCount;
  final int sessionsCount;
  final Map<String, dynamic>? deviceInfo;

  const AlphaTester({
    required this.id,
    required this.email,
    required this.status,
    this.invitedAt,
    this.activatedAt,
    this.lastActiveAt,
    this.feedbackCount = 0,
    this.sessionsCount = 0,
    this.deviceInfo,
  });

  factory AlphaTester.fromMap(Map<String, dynamic> map) {
    return AlphaTester(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      status: TesterStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => TesterStatus.invited,
      ),
      invitedAt: (map['invitedAt'] as Timestamp?)?.toDate(),
      activatedAt: (map['activatedAt'] as Timestamp?)?.toDate(),
      lastActiveAt: (map['lastActiveAt'] as Timestamp?)?.toDate(),
      feedbackCount: map['feedbackCount'] ?? 0,
      sessionsCount: map['sessionsCount'] ?? 0,
      deviceInfo: map['deviceInfo'],
    );
  }
}

class AlphaBuild {
  final String id;
  final String version;
  final int buildNumber;
  final String platform;
  final DateTime distributedAt;
  final int downloadCount;
  final int feedbackCount;

  const AlphaBuild({
    required this.id,
    required this.version,
    required this.buildNumber,
    required this.platform,
    required this.distributedAt,
    this.downloadCount = 0,
    this.feedbackCount = 0,
  });
}

class InviteResult {
  final bool success;
  final List<String> invited;
  final List<String> failed;
  final String? error;

  const InviteResult({
    required this.success,
    required this.invited,
    required this.failed,
    this.error,
  });
}

class DistributeResult {
  final bool success;
  final String? buildId;
  final int? notifiedCount;
  final String? error;

  const DistributeResult({
    required this.success,
    this.buildId,
    this.notifiedCount,
    this.error,
  });
}

class InternalReport {
  final DateTime generatedAt;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int totalTesters;
  final int activeTesters;
  final int inactiveTesters;
  final int totalFeedback;
  final Map<FeedbackCategory, int> feedbackByCategory;
  final Map<FeedbackPriority, int> feedbackByPriority;
  final List<AlphaBuild> builds;
  final double latestBuildAdoption;
  final List<String> topIssues;

  const InternalReport({
    required this.generatedAt,
    required this.periodStart,
    required this.periodEnd,
    required this.totalTesters,
    required this.activeTesters,
    required this.inactiveTesters,
    required this.totalFeedback,
    required this.feedbackByCategory,
    required this.feedbackByPriority,
    required this.builds,
    required this.latestBuildAdoption,
    required this.topIssues,
  });

  Map<String, dynamic> toMap() {
    return {
      'generatedAt': generatedAt.toIso8601String(),
      'periodStart': periodStart.toIso8601String(),
      'periodEnd': periodEnd.toIso8601String(),
      'totalTesters': totalTesters,
      'activeTesters': activeTesters,
      'inactiveTesters': inactiveTesters,
      'totalFeedback': totalFeedback,
      'feedbackByCategory': feedbackByCategory.map((k, v) => MapEntry(k.name, v)),
      'feedbackByPriority': feedbackByPriority.map((k, v) => MapEntry(k.name, v)),
      'latestBuildAdoption': latestBuildAdoption,
      'topIssues': topIssues,
    };
  }
}
