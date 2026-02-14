/// Feedback Service
///
/// Handles user feedback collection, categorization, and reporting
/// during beta phases to improve the app.
library;

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/analytics/analytics_service.dart';

/// Service for managing user feedback
class FeedbackService {
  static FeedbackService? _instance;
  static FeedbackService get instance => _instance ??= FeedbackService._();

  FeedbackService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AnalyticsService _analytics = AnalyticsService.instance;

  // Collections
  static const String _feedbackCollection = 'feedback';
  static const String _reportsCollection = 'feedback_reports';

  // ============================================================
  // FEEDBACK SUBMISSION
  // ============================================================

  /// Submit user feedback
  Future<FeedbackSubmissionResult> submitFeedback({
    required String userId,
    required String message,
    required FeedbackCategory category,
    FeedbackPriority priority = FeedbackPriority.medium,
    String? screenName,
    String? deviceInfo,
    List<String>? attachmentUrls,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final feedbackId = _firestore.collection(_feedbackCollection).doc().id;

      final feedbackData = {
        'id': feedbackId,
        'userId': userId,
        'message': message,
        'category': category.name,
        'priority': priority.name,
        'screenName': screenName,
        'deviceInfo': deviceInfo,
        'attachmentUrls': attachmentUrls ?? [],
        'metadata': metadata ?? {},
        'status': FeedbackStatus.pending.name,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection(_feedbackCollection)
          .doc(feedbackId)
          .set(feedbackData);

      // Update user's feedback count
      await _firestore.collection('beta_users').doc(userId).update({
        'feedbackCount': FieldValue.increment(1),
        'lastFeedbackAt': FieldValue.serverTimestamp(),
      });

      // Track analytics
      await _analytics.logEvent(
        name: 'feedback_submitted',
        parameters: {
          'user_id': userId,
          'category': category.name,
          'priority': priority.name,
        },
      );

      debugPrint('✅ [Feedback] Submitted: $feedbackId');

      return FeedbackSubmissionResult(
        success: true,
        feedbackId: feedbackId,
        message: 'Thank you for your feedback!',
      );
    } catch (e) {
      debugPrint('❌ [Feedback] Failed to submit: $e');
      return FeedbackSubmissionResult(
        success: false,
        error: 'Failed to submit feedback. Please try again.',
      );
    }
  }

  // ============================================================
  // FEEDBACK CATEGORIZATION
  // ============================================================

  /// Categorize feedback automatically based on keywords
  FeedbackCategory categorizeFeedback(String message) {
    final lowerMessage = message.toLowerCase();

    // Bug-related keywords
    final bugKeywords = [
      'bug', 'crash', 'error', 'broken', 'not working', 'doesn\'t work',
      'issue', 'problem', 'fail', 'stuck', 'freeze', 'glitch',
    ];

    // Feature request keywords
    final featureKeywords = [
      'add', 'feature', 'would be nice', 'suggestion', 'wish', 'want',
      'could you', 'please add', 'idea', 'improve', 'enhancement',
    ];

    // UI/UX keywords
    final uiKeywords = [
      'ui', 'ux', 'design', 'layout', 'button', 'screen', 'look',
      'color', 'font', 'confusing', 'hard to find', 'ugly', 'beautiful',
    ];

    // Performance keywords
    final performanceKeywords = [
      'slow', 'lag', 'performance', 'battery', 'memory', 'loading',
      'speed', 'fast', 'optimize', 'heavy',
    ];

    // Content keywords
    final contentKeywords = [
      'content', 'user', 'inappropriate', 'spam', 'fake', 'report',
      'offensive', 'harassment', 'abuse',
    ];

    for (final keyword in bugKeywords) {
      if (lowerMessage.contains(keyword)) {
        return FeedbackCategory.bug;
      }
    }

    for (final keyword in featureKeywords) {
      if (lowerMessage.contains(keyword)) {
        return FeedbackCategory.featureRequest;
      }
    }

    for (final keyword in uiKeywords) {
      if (lowerMessage.contains(keyword)) {
        return FeedbackCategory.uiUx;
      }
    }

    for (final keyword in performanceKeywords) {
      if (lowerMessage.contains(keyword)) {
        return FeedbackCategory.performance;
      }
    }

    for (final keyword in contentKeywords) {
      if (lowerMessage.contains(keyword)) {
        return FeedbackCategory.content;
      }
    }

    return FeedbackCategory.general;
  }

  /// Auto-detect priority based on message urgency
  FeedbackPriority detectPriority(String message) {
    final lowerMessage = message.toLowerCase();

    final criticalKeywords = [
      'crash', 'data loss', 'security', 'urgent', 'critical',
      'can\'t login', 'payment', 'money', 'lost',
    ];

    final highKeywords = [
      'blocked', 'can\'t use', 'broken', 'serious', 'important',
      'need fix', 'asap',
    ];

    for (final keyword in criticalKeywords) {
      if (lowerMessage.contains(keyword)) {
        return FeedbackPriority.critical;
      }
    }

    for (final keyword in highKeywords) {
      if (lowerMessage.contains(keyword)) {
        return FeedbackPriority.high;
      }
    }

    return FeedbackPriority.medium;
  }

  // ============================================================
  // FEEDBACK REPORTS
  // ============================================================

  /// Generate weekly feedback report
  Future<FeedbackReport> generateWeeklyFeedbackReport() async {
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday));
      final weekStartTimestamp = Timestamp.fromDate(
        DateTime(weekStart.year, weekStart.month, weekStart.day),
      );

      // Get all feedback from this week
      final feedbackQuery = await _firestore
          .collection(_feedbackCollection)
          .where('createdAt', isGreaterThanOrEqualTo: weekStartTimestamp)
          .get();

      final feedbackList = feedbackQuery.docs.map((doc) => doc.data()).toList();

      // Categorize feedback
      final categoryCount = <FeedbackCategory, int>{};
      final priorityCount = <FeedbackPriority, int>{};
      final statusCount = <FeedbackStatus, int>{};

      for (final feedback in feedbackList) {
        final category = FeedbackCategory.values.firstWhere(
          (c) => c.name == feedback['category'],
          orElse: () => FeedbackCategory.general,
        );
        final priority = FeedbackPriority.values.firstWhere(
          (p) => p.name == feedback['priority'],
          orElse: () => FeedbackPriority.medium,
        );
        final status = FeedbackStatus.values.firstWhere(
          (s) => s.name == feedback['status'],
          orElse: () => FeedbackStatus.pending,
        );

        categoryCount[category] = (categoryCount[category] ?? 0) + 1;
        priorityCount[priority] = (priorityCount[priority] ?? 0) + 1;
        statusCount[status] = (statusCount[status] ?? 0) + 1;
      }

      // Calculate resolution rate
      final resolved = statusCount[FeedbackStatus.resolved] ?? 0;
      final total = feedbackList.length;
      final resolutionRate = total > 0 ? resolved / total : 0.0;

      // Get top issues (most common)
      final topIssues = _extractTopIssues(feedbackList, 5);

      final report = FeedbackReport(
        periodStart: DateTime(weekStart.year, weekStart.month, weekStart.day),
        periodEnd: now,
        totalFeedback: total,
        categoryBreakdown: categoryCount,
        priorityBreakdown: priorityCount,
        statusBreakdown: statusCount,
        resolutionRate: resolutionRate,
        topIssues: topIssues,
      );

      // Store report
      await _firestore.collection(_reportsCollection).add({
        ...report.toMap(),
        'generatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ [Feedback] Weekly report generated: $total items');

      return report;
    } catch (e) {
      debugPrint('❌ [Feedback] Failed to generate report: $e');
      return FeedbackReport(
        periodStart: DateTime.now().subtract(const Duration(days: 7)),
        periodEnd: DateTime.now(),
        totalFeedback: 0,
        categoryBreakdown: {},
        priorityBreakdown: {},
        statusBreakdown: {},
        resolutionRate: 0,
        topIssues: [],
      );
    }
  }

  /// Extract top issues from feedback
  List<String> _extractTopIssues(
    List<Map<String, dynamic>> feedbackList,
    int count,
  ) {
    // Simple word frequency analysis
    final wordCount = <String, int>{};
    final stopWords = {
      'the', 'a', 'an', 'is', 'it', 'to', 'and', 'of', 'in', 'for',
      'on', 'with', 'this', 'that', 'i', 'my', 'me', 'when', 'can',
    };

    for (final feedback in feedbackList) {
      final message = (feedback['message'] as String? ?? '').toLowerCase();
      final words = message.split(RegExp(r'\s+'));

      for (final word in words) {
        final cleanWord = word.replaceAll(RegExp(r'[^\w]'), '');
        if (cleanWord.length > 3 && !stopWords.contains(cleanWord)) {
          wordCount[cleanWord] = (wordCount[cleanWord] ?? 0) + 1;
        }
      }
    }

    // Sort by frequency and return top issues
    final sortedWords = wordCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedWords.take(count).map((e) => e.key).toList();
  }

  // ============================================================
  // FEEDBACK MANAGEMENT
  // ============================================================

  /// Get user's feedback history
  Future<List<FeedbackItem>> getUserFeedback(String userId) async {
    try {
      final query = await _firestore
          .collection(_feedbackCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        return FeedbackItem(
          id: doc.id,
          message: data['message'] ?? '',
          category: FeedbackCategory.values.firstWhere(
            (c) => c.name == data['category'],
            orElse: () => FeedbackCategory.general,
          ),
          priority: FeedbackPriority.values.firstWhere(
            (p) => p.name == data['priority'],
            orElse: () => FeedbackPriority.medium,
          ),
          status: FeedbackStatus.values.firstWhere(
            (s) => s.name == data['status'],
            orElse: () => FeedbackStatus.pending,
          ),
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          response: data['response'] as String?,
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ [Feedback] Failed to get user feedback: $e');
      return [];
    }
  }

  /// Update feedback status (admin)
  Future<void> updateFeedbackStatus(
    String feedbackId,
    FeedbackStatus status, {
    String? response,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (response != null) {
        updateData['response'] = response;
        updateData['respondedAt'] = FieldValue.serverTimestamp();
      }

      await _firestore
          .collection(_feedbackCollection)
          .doc(feedbackId)
          .update(updateData);

      debugPrint('✅ [Feedback] Status updated: $feedbackId -> ${status.name}');
    } catch (e) {
      debugPrint('❌ [Feedback] Failed to update status: $e');
    }
  }

  /// Get feedback statistics
  Future<FeedbackStats> getFeedbackStats() async {
    try {
      final allFeedback = await _firestore
          .collection(_feedbackCollection)
          .get();

      int pending = 0;
      int inProgress = 0;
      int resolved = 0;

      for (final doc in allFeedback.docs) {
        final status = doc.data()['status'] ?? 'pending';
        switch (status) {
          case 'pending':
            pending++;
            break;
          case 'in_progress':
            inProgress++;
            break;
          case 'resolved':
            resolved++;
            break;
        }
      }

      return FeedbackStats(
        total: allFeedback.docs.length,
        pending: pending,
        inProgress: inProgress,
        resolved: resolved,
      );
    } catch (e) {
      debugPrint('❌ [Feedback] Failed to get stats: $e');
      return const FeedbackStats();
    }
  }
}

// ============================================================
// ENUMS
// ============================================================

enum FeedbackCategory {
  bug,
  featureRequest,
  uiUx,
  usability,    // Added for beta feedback form
  suggestion,   // Added for beta feedback form
  performance,
  content,
  general,
  other;

  String get displayName {
    switch (this) {
      case FeedbackCategory.bug:
        return 'Bug Report';
      case FeedbackCategory.featureRequest:
        return 'Feature Request';
      case FeedbackCategory.uiUx:
        return 'UI/UX';
      case FeedbackCategory.usability:
        return 'Usability';
      case FeedbackCategory.suggestion:
        return 'Suggestion';
      case FeedbackCategory.performance:
        return 'Performance';
      case FeedbackCategory.content:
        return 'Content Issue';
      case FeedbackCategory.general:
        return 'General';
      case FeedbackCategory.other:
        return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case FeedbackCategory.bug:
        return '🐛';
      case FeedbackCategory.featureRequest:
        return '💡';
      case FeedbackCategory.uiUx:
        return '🎨';
      case FeedbackCategory.usability:
        return '👆';
      case FeedbackCategory.suggestion:
        return '✨';
      case FeedbackCategory.performance:
        return '⚡';
      case FeedbackCategory.content:
        return '📝';
      case FeedbackCategory.general:
        return '💬';
      case FeedbackCategory.other:
        return '📌';
    }
  }
}

enum FeedbackPriority {
  low,
  medium,
  high,
  critical;

  String get displayName {
    switch (this) {
      case FeedbackPriority.low:
        return 'Low';
      case FeedbackPriority.medium:
        return 'Medium';
      case FeedbackPriority.high:
        return 'High';
      case FeedbackPriority.critical:
        return 'Critical';
    }
  }

  String get color {
    switch (this) {
      case FeedbackPriority.low:
        return '#4CAF50'; // Green
      case FeedbackPriority.medium:
        return '#FFC107'; // Amber
      case FeedbackPriority.high:
        return '#FF9800'; // Orange
      case FeedbackPriority.critical:
        return '#F44336'; // Red
    }
  }
}

enum FeedbackStatus {
  pending,
  inProgress,
  resolved,
  closed,
  wontFix;

  String get displayName {
    switch (this) {
      case FeedbackStatus.pending:
        return 'Pending';
      case FeedbackStatus.inProgress:
        return 'In Progress';
      case FeedbackStatus.resolved:
        return 'Resolved';
      case FeedbackStatus.closed:
        return 'Closed';
      case FeedbackStatus.wontFix:
        return 'Won\'t Fix';
    }
  }
}

// ============================================================
// DATA CLASSES
// ============================================================

class FeedbackSubmissionResult {
  final bool success;
  final String? feedbackId;
  final String? message;
  final String? error;

  const FeedbackSubmissionResult({
    required this.success,
    this.feedbackId,
    this.message,
    this.error,
  });
}

class FeedbackItem {
  final String id;
  final String message;
  final FeedbackCategory category;
  final FeedbackPriority priority;
  final FeedbackStatus status;
  final DateTime createdAt;
  final String? response;

  const FeedbackItem({
    required this.id,
    required this.message,
    required this.category,
    required this.priority,
    required this.status,
    required this.createdAt,
    this.response,
  });
}

class FeedbackReport {
  final DateTime periodStart;
  final DateTime periodEnd;
  final int totalFeedback;
  final Map<FeedbackCategory, int> categoryBreakdown;
  final Map<FeedbackPriority, int> priorityBreakdown;
  final Map<FeedbackStatus, int> statusBreakdown;
  final double resolutionRate;
  final List<String> topIssues;

  const FeedbackReport({
    required this.periodStart,
    required this.periodEnd,
    required this.totalFeedback,
    required this.categoryBreakdown,
    required this.priorityBreakdown,
    required this.statusBreakdown,
    required this.resolutionRate,
    required this.topIssues,
  });

  Map<String, dynamic> toMap() {
    return {
      'periodStart': Timestamp.fromDate(periodStart),
      'periodEnd': Timestamp.fromDate(periodEnd),
      'totalFeedback': totalFeedback,
      'categoryBreakdown': categoryBreakdown.map((k, v) => MapEntry(k.name, v)),
      'priorityBreakdown': priorityBreakdown.map((k, v) => MapEntry(k.name, v)),
      'statusBreakdown': statusBreakdown.map((k, v) => MapEntry(k.name, v)),
      'resolutionRate': resolutionRate,
      'topIssues': topIssues,
    };
  }
}

class FeedbackStats {
  final int total;
  final int pending;
  final int inProgress;
  final int resolved;

  const FeedbackStats({
    this.total = 0,
    this.pending = 0,
    this.inProgress = 0,
    this.resolved = 0,
  });

  double get resolutionRate => total > 0 ? resolved / total : 0;
}
