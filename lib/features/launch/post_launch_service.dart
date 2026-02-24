/// Post-Launch Service
///
/// Manages feedback collection, categorization, prioritization,
/// and reporting after public launch.
library;

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/analytics/analytics_service.dart';

/// Service for managing post-launch feedback and iteration
class PostLaunchService {
  static PostLaunchService? _instance;
  static PostLaunchService get instance => _instance ??= PostLaunchService._();

  PostLaunchService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AnalyticsService _analytics = AnalyticsService.instance;

  // Collections
  static const String _feedbackCollection = 'post_launch_feedback';
  static const String _issuesCollection = 'post_launch_issues';
  static const String _reportsCollection = 'post_launch_reports';

  // ============================================================
  // FEEDBACK COLLECTION
  // ============================================================

  /// Collect user feedback post-launch
  Future<FeedbackSubmissionResult> collectUserFeedback({
    required String userId,
    required String feedbackText,
    required FeedbackType type,
    FeedbackRating? rating,
    String? screenshotUrl,
    Map<String, dynamic>? metadata,
  }) async {
    debugPrint('ðŸ“ [PostLaunch] Collecting feedback from user: $userId');

    try {
      final feedbackId = 'fb_${DateTime.now().millisecondsSinceEpoch}_$userId';

      final feedback = UserFeedback(
        id: feedbackId,
        userId: userId,
        feedbackText: feedbackText,
        type: type,
        rating: rating,
        screenshotUrl: screenshotUrl,
        metadata: metadata ?? {},
        submittedAt: DateTime.now(),
        status: FeedbackStatus.pending,
        category: null, // Will be set during categorization
        priority: null, // Will be set during prioritization
      );

      await _firestore.collection(_feedbackCollection).doc(feedbackId).set({
        ...feedback.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _analytics.logEvent(
        name: 'post_launch_feedback_submitted',
        parameters: {
          'type': type.name,
          'has_rating': rating != null,
          'has_screenshot': screenshotUrl != null,
        },
      );

      debugPrint('âœ… [PostLaunch] Feedback submitted: $feedbackId');

      return FeedbackSubmissionResult(
        success: true,
        feedbackId: feedbackId,
        message: 'Thank you for your feedback!',
      );
    } catch (e) {
      debugPrint('âŒ [PostLaunch] Failed to submit feedback: $e');
      return const FeedbackSubmissionResult(
        success: false,
        feedbackId: null,
        message: 'Failed to submit feedback. Please try again.',
      );
    }
  }

  /// Get all feedback for processing
  Future<List<UserFeedback>> getAllFeedback({
    FeedbackStatus? status,
    FeedbackType? type,
    int limit = 100,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection(_feedbackCollection)
          .orderBy('createdAt', descending: true);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }
      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }

      final snapshot = await query.limit(limit).get();

      return snapshot.docs.map((doc) => UserFeedback.fromMap(doc.data())).toList();
    } catch (e) {
      debugPrint('âŒ [PostLaunch] Failed to get feedback: $e');
      return [];
    }
  }

  // ============================================================
  // FEEDBACK CATEGORIZATION
  // ============================================================

  /// Categorize feedback by topic
  Future<CategorizationResult> categorizeFeedback({
    required String feedbackId,
    required FeedbackCategory category,
    List<String>? tags,
    String? notes,
  }) async {
    debugPrint('ðŸ·ï¸ [PostLaunch] Categorizing feedback: $feedbackId');

    try {
      await _firestore.collection(_feedbackCollection).doc(feedbackId).update({
        'category': category.name,
        'tags': tags ?? [],
        'categorizationNotes': notes,
        'categorizedAt': FieldValue.serverTimestamp(),
        'status': FeedbackStatus.categorized.name,
      });

      await _analytics.logEvent(
        name: 'feedback_categorized',
        parameters: {
          'category': category.name,
          'feedback_id': feedbackId,
        },
      );

      debugPrint('âœ… [PostLaunch] Feedback categorized');

      return CategorizationResult(
        success: true,
        feedbackId: feedbackId,
        category: category,
      );
    } catch (e) {
      debugPrint('âŒ [PostLaunch] Failed to categorize: $e');
      return CategorizationResult(
        success: false,
        feedbackId: feedbackId,
        category: null,
      );
    }
  }

  /// Auto-categorize feedback based on keywords
  Future<FeedbackCategory> suggestCategory(String feedbackText) async {
    final text = feedbackText.toLowerCase();

    // Bug indicators
    final bugKeywords = ['bug', 'crash', 'error', 'broken', 'not working', 'issue', 'problem', 'fail'];
    if (bugKeywords.any((k) => text.contains(k))) {
      return FeedbackCategory.bug;
    }

    // Feature request indicators
    final featureKeywords = ['feature', 'add', 'would be nice', 'please add', 'wish', 'want', 'suggestion'];
    if (featureKeywords.any((k) => text.contains(k))) {
      return FeedbackCategory.featureRequest;
    }

    // Performance indicators
    final perfKeywords = ['slow', 'lag', 'performance', 'battery', 'freeze', 'loading'];
    if (perfKeywords.any((k) => text.contains(k))) {
      return FeedbackCategory.performance;
    }

    // UI/UX indicators
    final uiKeywords = ['design', 'ui', 'ux', 'layout', 'looks', 'confusing', 'hard to'];
    if (uiKeywords.any((k) => text.contains(k))) {
      return FeedbackCategory.uiux;
    }

    // Video/Audio indicators
    final mediaKeywords = ['video', 'audio', 'camera', 'microphone', 'sound', 'quality'];
    if (mediaKeywords.any((k) => text.contains(k))) {
      return FeedbackCategory.videoAudio;
    }

    // Payment indicators
    final paymentKeywords = ['payment', 'purchase', 'subscription', 'vip', 'charge', 'refund'];
    if (paymentKeywords.any((k) => text.contains(k))) {
      return FeedbackCategory.payment;
    }

    return FeedbackCategory.general;
  }

  // ============================================================
  // FEEDBACK PRIORITIZATION
  // ============================================================

  /// Prioritize fixes based on impact and frequency
  Future<PrioritizationResult> prioritizeFixes() async {
    debugPrint('ðŸŽ¯ [PostLaunch] Prioritizing fixes...');

    try {
      // Get all categorized feedback
      final feedback = await getAllFeedback(status: FeedbackStatus.categorized);

      // Group by category and count
      final categoryCount = <FeedbackCategory, int>{};
      final categoryImpact = <FeedbackCategory, double>{};

      for (final fb in feedback) {
        if (fb.category != null) {
          categoryCount[fb.category!] = (categoryCount[fb.category!] ?? 0) + 1;

          // Calculate impact score based on rating
          double impact = 1.0;
          if (fb.rating != null) {
            impact = (5 - fb.rating!.index).toDouble(); // Lower rating = higher impact
          }
          categoryImpact[fb.category!] = (categoryImpact[fb.category!] ?? 0) + impact;
        }
      }

      // Create prioritized issues
      final issues = <PrioritizedIssue>[];

      for (final category in categoryCount.keys) {
        final count = categoryCount[category]!;
        final totalImpact = categoryImpact[category]!;
        final avgImpact = totalImpact / count;

        // Priority score: (count * 0.4) + (avgImpact * 0.6)
        final priorityScore = (count * 0.4) + (avgImpact * 0.6 * 20);

        final priority = _scoreToPriority(priorityScore);

        final issue = PrioritizedIssue(
          category: category,
          feedbackCount: count,
          averageImpact: avgImpact,
          priorityScore: priorityScore,
          priority: priority,
          relatedFeedbackIds: feedback
              .where((f) => f.category == category)
              .map((f) => f.id)
              .toList(),
        );

        issues.add(issue);

        // Update feedback with priority
        for (final fb in feedback.where((f) => f.category == category)) {
          await _firestore.collection(_feedbackCollection).doc(fb.id).update({
            'priority': priority.name,
            'priorityScore': priorityScore,
            'status': FeedbackStatus.prioritized.name,
          });
        }
      }

      // Sort by priority score
      issues.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));

      // Save issue tracking
      for (final issue in issues) {
        await _firestore.collection(_issuesCollection).doc(issue.category.name).set({
          ...issue.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      debugPrint('âœ… [PostLaunch] ${issues.length} issues prioritized');

      return PrioritizationResult(
        success: true,
        totalFeedback: feedback.length,
        issues: issues,
      );
    } catch (e) {
      debugPrint('âŒ [PostLaunch] Failed to prioritize: $e');
      return const PrioritizationResult(
        success: false,
        totalFeedback: 0,
        issues: [],
      );
    }
  }

  Priority _scoreToPriority(double score) {
    if (score >= 30) return Priority.critical;
    if (score >= 20) return Priority.high;
    if (score >= 10) return Priority.medium;
    return Priority.low;
  }

  // ============================================================
  // POST-LAUNCH REPORT
  // ============================================================

  /// Generate comprehensive post-launch report
  Future<PostLaunchReport> generatePostLaunchReport({
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    debugPrint('ðŸ“Š [PostLaunch] Generating report...');

    final end = endDate ?? DateTime.now();

    try {
      // Get all feedback in date range
      final feedbackQuery = await _firestore
          .collection(_feedbackCollection)
          .where('submittedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('submittedAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      final allFeedback = feedbackQuery.docs
          .map((doc) => UserFeedback.fromMap(doc.data()))
          .toList();

      // Calculate statistics
      final totalFeedback = allFeedback.length;

      // Breakdown by type
      final typeBreakdown = <FeedbackType, int>{};
      for (final fb in allFeedback) {
        typeBreakdown[fb.type] = (typeBreakdown[fb.type] ?? 0) + 1;
      }

      // Breakdown by category
      final categoryBreakdown = <FeedbackCategory, int>{};
      for (final fb in allFeedback.where((f) => f.category != null)) {
        categoryBreakdown[fb.category!] = (categoryBreakdown[fb.category!] ?? 0) + 1;
      }

      // Breakdown by status
      final statusBreakdown = <FeedbackStatus, int>{};
      for (final fb in allFeedback) {
        statusBreakdown[fb.status] = (statusBreakdown[fb.status] ?? 0) + 1;
      }

      // Average rating
      final ratedFeedback = allFeedback.where((f) => f.rating != null).toList();
      final avgRating = ratedFeedback.isNotEmpty
          ? ratedFeedback.map((f) => f.rating!.index + 1).reduce((a, b) => a + b) /
              ratedFeedback.length
          : 0.0;

      // Get prioritized issues
      final issues = await _getPrioritizedIssues();

      // Top issues (critical and high priority)
      final topIssues = issues.where((i) =>
          i.priority == Priority.critical || i.priority == Priority.high).toList();

      // Sentiment analysis
      final positiveFeedback = allFeedback.where(
          (f) => f.rating != null && f.rating!.index >= 3).length;
      final negativeFeedback = allFeedback.where(
          (f) => f.rating != null && f.rating!.index <= 1).length;

      final sentimentScore = ratedFeedback.isNotEmpty
          ? (positiveFeedback - negativeFeedback) / ratedFeedback.length * 100
          : 0.0;

      // Trend over time
      final dailyTrend = <DateTime, int>{};
      for (final fb in allFeedback) {
        final day = DateTime(fb.submittedAt.year, fb.submittedAt.month, fb.submittedAt.day);
        dailyTrend[day] = (dailyTrend[day] ?? 0) + 1;
      }

      final report = PostLaunchReport(
        id: 'plr_${DateTime.now().millisecondsSinceEpoch}',
        generatedAt: DateTime.now(),
        periodStart: startDate,
        periodEnd: end,
        totalFeedback: totalFeedback,
        typeBreakdown: typeBreakdown,
        categoryBreakdown: categoryBreakdown,
        statusBreakdown: statusBreakdown,
        averageRating: avgRating,
        sentimentScore: sentimentScore,
        topIssues: topIssues,
        dailyTrend: dailyTrend,
        recommendations: _generateRecommendations(topIssues, sentimentScore),
      );

      // Save report
      await _firestore.collection(_reportsCollection).doc(report.id).set({
        ...report.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _analytics.logEvent(
        name: 'post_launch_report_generated',
        parameters: {
          'total_feedback': totalFeedback,
          'period_days': end.difference(startDate).inDays,
        },
      );

      debugPrint('âœ… [PostLaunch] Report generated: ${report.id}');

      return report;
    } catch (e) {
      debugPrint('âŒ [PostLaunch] Failed to generate report: $e');
      return PostLaunchReport(
        id: 'error',
        generatedAt: DateTime.now(),
        periodStart: startDate,
        periodEnd: end,
        totalFeedback: 0,
        typeBreakdown: {},
        categoryBreakdown: {},
        statusBreakdown: {},
        averageRating: 0,
        sentimentScore: 0,
        topIssues: [],
        dailyTrend: {},
        recommendations: ['Error generating report'],
      );
    }
  }

  Future<List<PrioritizedIssue>> _getPrioritizedIssues() async {
    try {
      final snapshot = await _firestore
          .collection(_issuesCollection)
          .orderBy('priorityScore', descending: true)
          .get();

      return snapshot.docs.map((doc) => PrioritizedIssue.fromMap(doc.data())).toList();
    } catch (e) {
      return [];
    }
  }

  List<String> _generateRecommendations(List<PrioritizedIssue> topIssues, double sentiment) {
    final recommendations = <String>[];

    // Based on sentiment
    if (sentiment < -20) {
      recommendations.add('ðŸš¨ User sentiment is significantly negative. Focus on addressing critical bugs and UX issues.');
    } else if (sentiment < 0) {
      recommendations.add('âš ï¸ User sentiment is slightly negative. Consider enhancing communication about known issues.');
    } else if (sentiment > 30) {
      recommendations.add('âœ¨ User sentiment is very positive! Consider highlighting testimonials in marketing.');
    }

    // Based on top issues
    for (final issue in topIssues.take(3)) {
      switch (issue.category) {
        case FeedbackCategory.bug:
          recommendations.add('ðŸ› Critical: ${issue.feedbackCount} bug reports. Schedule emergency bug fix sprint.');
          break;
        case FeedbackCategory.performance:
          recommendations.add('âš¡ Performance issues reported by ${issue.feedbackCount} users. Profile and optimize.');
          break;
        case FeedbackCategory.videoAudio:
          recommendations.add('ðŸŽ¥ Video/Audio issues affecting ${issue.feedbackCount} users. Review media stack.');
          break;
        case FeedbackCategory.uiux:
          recommendations.add('ðŸŽ¨ UI/UX concerns from ${issue.feedbackCount} users. Schedule design review.');
          break;
        case FeedbackCategory.featureRequest:
          recommendations.add('ðŸ’¡ ${issue.feedbackCount} feature requests. Consider for product roadmap.');
          break;
        case FeedbackCategory.payment:
          recommendations.add('ðŸ’³ Payment issues from ${issue.feedbackCount} users. Priority fix required.');
          break;
        case FeedbackCategory.general:
        case FeedbackCategory.other:
          break;
      }
    }

    if (recommendations.isEmpty) {
      recommendations.add('âœ… No critical issues detected. Continue monitoring and iterating.');
    }

    return recommendations;
  }

  // ============================================================
  // FEEDBACK STATUS UPDATE
  // ============================================================

  /// Update feedback status (e.g., when resolved)
  Future<bool> updateFeedbackStatus({
    required String feedbackId,
    required FeedbackStatus newStatus,
    String? resolution,
  }) async {
    try {
      await _firestore.collection(_feedbackCollection).doc(feedbackId).update({
        'status': newStatus.name,
        'resolution': resolution,
        'resolvedAt': newStatus == FeedbackStatus.resolved
            ? FieldValue.serverTimestamp()
            : null,
      });

      await _analytics.logEvent(
        name: 'feedback_status_updated',
        parameters: {
          'feedback_id': feedbackId,
          'new_status': newStatus.name,
        },
      );

      return true;
    } catch (e) {
      debugPrint('âŒ [PostLaunch] Failed to update status: $e');
      return false;
    }
  }
}

// ============================================================
// ENUMS
// ============================================================

enum FeedbackType {
  bug,
  featureRequest,
  improvement,
  complaint,
  praise,
  question,
  other,
}

enum FeedbackRating {
  terrible, // 1
  poor,     // 2
  okay,     // 3
  good,     // 4
  excellent, // 5
}

enum FeedbackStatus {
  pending,
  categorized,
  prioritized,
  inProgress,
  resolved,
  closed,
  duplicate,
}

enum FeedbackCategory {
  bug,
  featureRequest,
  performance,
  uiux,
  videoAudio,
  payment,
  general,
  other,
}

enum Priority {
  critical,
  high,
  medium,
  low,
}

// ============================================================
// DATA CLASSES
// ============================================================

class UserFeedback {
  final String id;
  final String userId;
  final String feedbackText;
  final FeedbackType type;
  final FeedbackRating? rating;
  final String? screenshotUrl;
  final Map<String, dynamic> metadata;
  final DateTime submittedAt;
  final FeedbackStatus status;
  final FeedbackCategory? category;
  final Priority? priority;

  const UserFeedback({
    required this.id,
    required this.userId,
    required this.feedbackText,
    required this.type,
    this.rating,
    this.screenshotUrl,
    required this.metadata,
    required this.submittedAt,
    required this.status,
    this.category,
    this.priority,
  });

  factory UserFeedback.fromMap(Map<String, dynamic> map) {
    return UserFeedback(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      feedbackText: map['feedbackText'] ?? '',
      type: FeedbackType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => FeedbackType.other,
      ),
      rating: map['rating'] != null
          ? FeedbackRating.values.firstWhere(
              (r) => r.name == map['rating'],
              orElse: () => FeedbackRating.okay,
            )
          : null,
      screenshotUrl: map['screenshotUrl'],
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      submittedAt: map['submittedAt'] is Timestamp
          ? (map['submittedAt'] as Timestamp).toDate()
          : DateTime.parse(map['submittedAt'] ?? DateTime.now().toIso8601String()),
      status: FeedbackStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => FeedbackStatus.pending,
      ),
      category: map['category'] != null
          ? FeedbackCategory.values.firstWhere(
              (c) => c.name == map['category'],
              orElse: () => FeedbackCategory.general,
            )
          : null,
      priority: map['priority'] != null
          ? Priority.values.firstWhere(
              (p) => p.name == map['priority'],
              orElse: () => Priority.low,
            )
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'feedbackText': feedbackText,
    'type': type.name,
    'rating': rating?.name,
    'screenshotUrl': screenshotUrl,
    'metadata': metadata,
    'submittedAt': submittedAt.toIso8601String(),
    'status': status.name,
    'category': category?.name,
    'priority': priority?.name,
  };
}

class FeedbackSubmissionResult {
  final bool success;
  final String? feedbackId;
  final String message;

  const FeedbackSubmissionResult({
    required this.success,
    this.feedbackId,
    required this.message,
  });
}

class CategorizationResult {
  final bool success;
  final String feedbackId;
  final FeedbackCategory? category;

  const CategorizationResult({
    required this.success,
    required this.feedbackId,
    required this.category,
  });
}

class PrioritizedIssue {
  final FeedbackCategory category;
  final int feedbackCount;
  final double averageImpact;
  final double priorityScore;
  final Priority priority;
  final List<String> relatedFeedbackIds;

  const PrioritizedIssue({
    required this.category,
    required this.feedbackCount,
    required this.averageImpact,
    required this.priorityScore,
    required this.priority,
    required this.relatedFeedbackIds,
  });

  factory PrioritizedIssue.fromMap(Map<String, dynamic> map) {
    return PrioritizedIssue(
      category: FeedbackCategory.values.firstWhere(
        (c) => c.name == map['category'],
        orElse: () => FeedbackCategory.general,
      ),
      feedbackCount: map['feedbackCount'] ?? 0,
      averageImpact: (map['averageImpact'] ?? 0).toDouble(),
      priorityScore: (map['priorityScore'] ?? 0).toDouble(),
      priority: Priority.values.firstWhere(
        (p) => p.name == map['priority'],
        orElse: () => Priority.low,
      ),
      relatedFeedbackIds: List<String>.from(map['relatedFeedbackIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
    'category': category.name,
    'feedbackCount': feedbackCount,
    'averageImpact': averageImpact,
    'priorityScore': priorityScore,
    'priority': priority.name,
    'relatedFeedbackIds': relatedFeedbackIds,
  };
}

class PrioritizationResult {
  final bool success;
  final int totalFeedback;
  final List<PrioritizedIssue> issues;

  const PrioritizationResult({
    required this.success,
    required this.totalFeedback,
    required this.issues,
  });
}

class PostLaunchReport {
  final String id;
  final DateTime generatedAt;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int totalFeedback;
  final Map<FeedbackType, int> typeBreakdown;
  final Map<FeedbackCategory, int> categoryBreakdown;
  final Map<FeedbackStatus, int> statusBreakdown;
  final double averageRating;
  final double sentimentScore;
  final List<PrioritizedIssue> topIssues;
  final Map<DateTime, int> dailyTrend;
  final List<String> recommendations;

  const PostLaunchReport({
    required this.id,
    required this.generatedAt,
    required this.periodStart,
    required this.periodEnd,
    required this.totalFeedback,
    required this.typeBreakdown,
    required this.categoryBreakdown,
    required this.statusBreakdown,
    required this.averageRating,
    required this.sentimentScore,
    required this.topIssues,
    required this.dailyTrend,
    required this.recommendations,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'generatedAt': generatedAt.toIso8601String(),
    'periodStart': periodStart.toIso8601String(),
    'periodEnd': periodEnd.toIso8601String(),
    'totalFeedback': totalFeedback,
    'typeBreakdown': typeBreakdown.map((k, v) => MapEntry(k.name, v)),
    'categoryBreakdown': categoryBreakdown.map((k, v) => MapEntry(k.name, v)),
    'statusBreakdown': statusBreakdown.map((k, v) => MapEntry(k.name, v)),
    'averageRating': averageRating,
    'sentimentScore': sentimentScore,
    'topIssues': topIssues.map((i) => i.toMap()).toList(),
    'dailyTrend': dailyTrend.map((k, v) => MapEntry(k.toIso8601String(), v)),
    'recommendations': recommendations,
  };
}
