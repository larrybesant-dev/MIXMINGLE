/// Creator Payout Report
///
/// Generates weekly and monthly payout reports for creators.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../analytics/analytics_service.dart';

/// Weekly payout report
class WeeklyPayoutReport {
  final String reportId;
  final String creatorId;
  final DateTime weekStart;
  final DateTime weekEnd;
  final double totalEarnings;
  final double totalPlatformFees;
  final double netEarnings;
  final double payoutAmount;
  final Map<String, double> earningsBySource;
  final int transactionCount;
  final String status;
  final DateTime generatedAt;

  const WeeklyPayoutReport({
    required this.reportId,
    required this.creatorId,
    required this.weekStart,
    required this.weekEnd,
    required this.totalEarnings,
    required this.totalPlatformFees,
    required this.netEarnings,
    required this.payoutAmount,
    required this.earningsBySource,
    required this.transactionCount,
    required this.status,
    required this.generatedAt,
  });

  Map<String, dynamic> toMap() => {
    'reportId': reportId,
    'creatorId': creatorId,
    'weekStart': weekStart.toIso8601String(),
    'weekEnd': weekEnd.toIso8601String(),
    'totalEarnings': totalEarnings,
    'totalPlatformFees': totalPlatformFees,
    'netEarnings': netEarnings,
    'payoutAmount': payoutAmount,
    'earningsBySource': earningsBySource,
    'transactionCount': transactionCount,
    'status': status,
    'generatedAt': generatedAt.toIso8601String(),
  };

  factory WeeklyPayoutReport.fromMap(Map<String, dynamic> map) {
    return WeeklyPayoutReport(
      reportId: map['reportId'] as String,
      creatorId: map['creatorId'] as String,
      weekStart: DateTime.parse(map['weekStart'] as String),
      weekEnd: DateTime.parse(map['weekEnd'] as String),
      totalEarnings: (map['totalEarnings'] as num).toDouble(),
      totalPlatformFees: (map['totalPlatformFees'] as num).toDouble(),
      netEarnings: (map['netEarnings'] as num).toDouble(),
      payoutAmount: (map['payoutAmount'] as num).toDouble(),
      earningsBySource: Map<String, double>.from(
        (map['earningsBySource'] as Map).map(
          (k, v) => MapEntry(k as String, (v as num).toDouble()),
        ),
      ),
      transactionCount: map['transactionCount'] as int,
      status: map['status'] as String,
      generatedAt: DateTime.parse(map['generatedAt'] as String),
    );
  }
}

/// Monthly creator summary
class MonthlyCreatorSummary {
  final String reportId;
  final String creatorId;
  final int year;
  final int month;
  final double totalEarnings;
  final double netEarnings;
  final double totalPayouts;
  final double pendingBalance;
  final Map<String, double> earningsBySource;
  final Map<String, dynamic> metrics;
  final String currentTier;
  final bool tierChanged;
  final String? previousTier;
  final int followerChange;
  final double engagementScore;
  final DateTime generatedAt;

  const MonthlyCreatorSummary({
    required this.reportId,
    required this.creatorId,
    required this.year,
    required this.month,
    required this.totalEarnings,
    required this.netEarnings,
    required this.totalPayouts,
    required this.pendingBalance,
    required this.earningsBySource,
    required this.metrics,
    required this.currentTier,
    required this.tierChanged,
    this.previousTier,
    required this.followerChange,
    required this.engagementScore,
    required this.generatedAt,
  });

  String get monthName {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  Map<String, dynamic> toMap() => {
    'reportId': reportId,
    'creatorId': creatorId,
    'year': year,
    'month': month,
    'totalEarnings': totalEarnings,
    'netEarnings': netEarnings,
    'totalPayouts': totalPayouts,
    'pendingBalance': pendingBalance,
    'earningsBySource': earningsBySource,
    'metrics': metrics,
    'currentTier': currentTier,
    'tierChanged': tierChanged,
    'previousTier': previousTier,
    'followerChange': followerChange,
    'engagementScore': engagementScore,
    'generatedAt': generatedAt.toIso8601String(),
  };

  factory MonthlyCreatorSummary.fromMap(Map<String, dynamic> map) {
    return MonthlyCreatorSummary(
      reportId: map['reportId'] as String,
      creatorId: map['creatorId'] as String,
      year: map['year'] as int,
      month: map['month'] as int,
      totalEarnings: (map['totalEarnings'] as num).toDouble(),
      netEarnings: (map['netEarnings'] as num).toDouble(),
      totalPayouts: (map['totalPayouts'] as num).toDouble(),
      pendingBalance: (map['pendingBalance'] as num).toDouble(),
      earningsBySource: Map<String, double>.from(
        (map['earningsBySource'] as Map).map(
          (k, v) => MapEntry(k as String, (v as num).toDouble()),
        ),
      ),
      metrics: Map<String, dynamic>.from(map['metrics'] ?? {}),
      currentTier: map['currentTier'] as String,
      tierChanged: map['tierChanged'] as bool,
      previousTier: map['previousTier'] as String?,
      followerChange: map['followerChange'] as int,
      engagementScore: (map['engagementScore'] as num).toDouble(),
      generatedAt: DateTime.parse(map['generatedAt'] as String),
    );
  }
}

/// Service for generating creator payout reports
class CreatorPayoutReport {
  static CreatorPayoutReport? _instance;
  static CreatorPayoutReport get instance => _instance ??= CreatorPayoutReport._();

  CreatorPayoutReport._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  CollectionReference<Map<String, dynamic>> get _weeklyReportsCollection =>
      _firestore.collection('weekly_payout_reports');

  CollectionReference<Map<String, dynamic>> get _monthlyReportsCollection =>
      _firestore.collection('monthly_creator_summaries');

  CollectionReference<Map<String, dynamic>> get _earningsCollection =>
      _firestore.collection('creator_earnings');

  CollectionReference<Map<String, dynamic>> get _payoutsCollection =>
      _firestore.collection('creator_payouts');

  CollectionReference<Map<String, dynamic>> get _creatorsCollection =>
      _firestore.collection('creators');

  /// Generate weekly payout report for a creator
  Future<WeeklyPayoutReport> generateWeeklyPayoutReport({
    required String creatorId,
    DateTime? weekEndDate,
  }) async {
    final weekEnd = weekEndDate ?? _getLastSunday();
    final weekStart = weekEnd.subtract(const Duration(days: 6));

    // Get earnings for the week
    final earningsSnapshot = await _earningsCollection
        .where('creatorId', isEqualTo: creatorId)
        .where('timestamp', isGreaterThanOrEqualTo: weekStart.toIso8601String())
        .where('timestamp', isLessThanOrEqualTo: weekEnd.toIso8601String())
        .get();

    double totalEarnings = 0;
    double totalPlatformFees = 0;
    double netEarnings = 0;
    final earningsBySource = <String, double>{};

    for (final doc in earningsSnapshot.docs) {
      final data = doc.data();
      final amount = (data['amount'] as num).toDouble();
      final platformFee = (data['platformFee'] as num).toDouble();
      final net = (data['netAmount'] as num).toDouble();
      final source = data['source'] as String;

      totalEarnings += amount;
      totalPlatformFees += platformFee;
      netEarnings += net;
      earningsBySource[source] = (earningsBySource[source] ?? 0) + net;
    }

    // Get payouts for the week
    final payoutsSnapshot = await _payoutsCollection
        .where('creatorId', isEqualTo: creatorId)
        .where('status', isEqualTo: 'completed')
        .where('requestedAt', isGreaterThanOrEqualTo: weekStart.toIso8601String())
        .where('requestedAt', isLessThanOrEqualTo: weekEnd.toIso8601String())
        .get();

    double payoutAmount = 0;
    for (final doc in payoutsSnapshot.docs) {
      payoutAmount += (doc.data()['amount'] as num).toDouble();
    }

    // Generate report
    final reportId = '${creatorId}_${weekEnd.toIso8601String().substring(0, 10)}';
    final report = WeeklyPayoutReport(
      reportId: reportId,
      creatorId: creatorId,
      weekStart: weekStart,
      weekEnd: weekEnd,
      totalEarnings: totalEarnings,
      totalPlatformFees: totalPlatformFees,
      netEarnings: netEarnings,
      payoutAmount: payoutAmount,
      earningsBySource: earningsBySource,
      transactionCount: earningsSnapshot.docs.length,
      status: 'generated',
      generatedAt: DateTime.now(),
    );

    // Save report
    await _weeklyReportsCollection.doc(reportId).set(report.toMap());

    AnalyticsService.instance.logEvent(
      name: 'weekly_report_generated',
      parameters: {
        'creator_id': creatorId,
        'total_earnings': totalEarnings,
        'net_earnings': netEarnings,
      },
    );

    return report;
  }

  /// Generate monthly creator summary
  Future<MonthlyCreatorSummary> generateMonthlyCreatorSummary({
    required String creatorId,
    int? year,
    int? month,
  }) async {
    final now = DateTime.now();
    final targetYear = year ?? now.year;
    final targetMonth = month ?? now.month;

    final monthStart = DateTime(targetYear, targetMonth, 1);
    final monthEnd = DateTime(targetYear, targetMonth + 1, 0, 23, 59, 59);

    // Get creator data
    final creatorDoc = await _creatorsCollection.doc(creatorId).get();
    final creatorData = creatorDoc.data() ?? {};

    // Get earnings for the month
    final earningsSnapshot = await _earningsCollection
        .where('creatorId', isEqualTo: creatorId)
        .where('timestamp', isGreaterThanOrEqualTo: monthStart.toIso8601String())
        .where('timestamp', isLessThanOrEqualTo: monthEnd.toIso8601String())
        .get();

    double totalEarnings = 0;
    double netEarnings = 0;
    final earningsBySource = <String, double>{};

    for (final doc in earningsSnapshot.docs) {
      final data = doc.data();
      final amount = (data['amount'] as num).toDouble();
      final net = (data['netAmount'] as num).toDouble();
      final source = data['source'] as String;

      totalEarnings += amount;
      netEarnings += net;
      earningsBySource[source] = (earningsBySource[source] ?? 0) + net;
    }

    // Get payouts for the month
    final payoutsSnapshot = await _payoutsCollection
        .where('creatorId', isEqualTo: creatorId)
        .where('status', isEqualTo: 'completed')
        .where('requestedAt', isGreaterThanOrEqualTo: monthStart.toIso8601String())
        .where('requestedAt', isLessThanOrEqualTo: monthEnd.toIso8601String())
        .get();

    double totalPayouts = 0;
    for (final doc in payoutsSnapshot.docs) {
      totalPayouts += (doc.data()['amount'] as num).toDouble();
    }

    // Calculate metrics
    final currentFollowers = (creatorData['followerCount'] as int?) ?? 0;
    final previousFollowers = (creatorData['previousMonthFollowers'] as int?) ?? currentFollowers;
    final followerChange = currentFollowers - previousFollowers;

    // Get engagement metrics
    final roomsHosted = await _getMonthlyRoomsHosted(creatorId, monthStart, monthEnd);
    final avgParticipants = await _getAvgParticipants(creatorId, monthStart, monthEnd);
    final totalMinutesStreamed = await _getTotalMinutesStreamed(creatorId, monthStart, monthEnd);

    final engagementScore = _calculateEngagementScore(
      roomsHosted: roomsHosted,
      avgParticipants: avgParticipants,
      totalMinutes: totalMinutesStreamed,
      earnings: netEarnings,
    );

    // Check tier changes
    final currentTier = creatorData['tier'] as String? ?? 'starter';
    final tierChangedAt = creatorData['tierChangedAt'] as Timestamp?;
    final tierChanged = tierChangedAt != null &&
        tierChangedAt.toDate().isAfter(monthStart) &&
        tierChangedAt.toDate().isBefore(monthEnd);
    final previousTier = tierChanged ? (creatorData['previousTier'] as String?) : null;

    // Generate summary
    final reportId = '${creatorId}_${targetYear}_$targetMonth';
    final summary = MonthlyCreatorSummary(
      reportId: reportId,
      creatorId: creatorId,
      year: targetYear,
      month: targetMonth,
      totalEarnings: totalEarnings,
      netEarnings: netEarnings,
      totalPayouts: totalPayouts,
      pendingBalance: (creatorData['pendingBalance'] as num?)?.toDouble() ?? 0,
      earningsBySource: earningsBySource,
      metrics: {
        'roomsHosted': roomsHosted,
        'avgParticipants': avgParticipants,
        'totalMinutesStreamed': totalMinutesStreamed,
        'transactionCount': earningsSnapshot.docs.length,
      },
      currentTier: currentTier,
      tierChanged: tierChanged,
      previousTier: previousTier,
      followerChange: followerChange,
      engagementScore: engagementScore,
      generatedAt: DateTime.now(),
    );

    // Save summary
    await _monthlyReportsCollection.doc(reportId).set(summary.toMap());

    // Update creator's previous month data for next month's comparison
    await _creatorsCollection.doc(creatorId).update({
      'previousMonthEarnings': netEarnings,
      'previousMonthFollowers': currentFollowers,
    });

    AnalyticsService.instance.logEvent(
      name: 'monthly_summary_generated',
      parameters: {
        'creator_id': creatorId,
        'year': targetYear,
        'month': targetMonth,
        'net_earnings': netEarnings,
      },
    );

    return summary;
  }

  /// Get weekly reports for a creator
  Future<List<WeeklyPayoutReport>> getWeeklyReports({
    required String creatorId,
    int limit = 12,
  }) async {
    final snapshot = await _weeklyReportsCollection
        .where('creatorId', isEqualTo: creatorId)
        .orderBy('weekEnd', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => WeeklyPayoutReport.fromMap(doc.data()))
        .toList();
  }

  /// Get monthly summaries for a creator
  Future<List<MonthlyCreatorSummary>> getMonthlySummaries({
    required String creatorId,
    int limit = 12,
  }) async {
    final snapshot = await _monthlyReportsCollection
        .where('creatorId', isEqualTo: creatorId)
        .orderBy('year', descending: true)
        .orderBy('month', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => MonthlyCreatorSummary.fromMap(doc.data()))
        .toList();
  }

  /// Generate reports for all active creators
  Future<Map<String, dynamic>> generateAllCreatorReports({
    bool weekly = true,
    bool monthly = false,
  }) async {
    int weeklyGenerated = 0;
    int monthlyGenerated = 0;
    final errors = <String>[];

    // Get all active creators
    final creatorsSnapshot = await _creatorsCollection
        .where('status', isEqualTo: 'active')
        .get();

    for (final doc in creatorsSnapshot.docs) {
      try {
        if (weekly) {
          await generateWeeklyPayoutReport(creatorId: doc.id);
          weeklyGenerated++;
        }
        if (monthly) {
          await generateMonthlyCreatorSummary(creatorId: doc.id);
          monthlyGenerated++;
        }
      } catch (e) {
        errors.add('${doc.id}: $e');
      }
    }

    AnalyticsService.instance.logEvent(
      name: 'bulk_reports_generated',
      parameters: {
        'weekly_count': weeklyGenerated,
        'monthly_count': monthlyGenerated,
        'error_count': errors.length,
      },
    );

    return {
      'weeklyGenerated': weeklyGenerated,
      'monthlyGenerated': monthlyGenerated,
      'errors': errors,
    };
  }

  // Private helper methods

  DateTime _getLastSunday() {
    final now = DateTime.now();
    final daysToSubtract = now.weekday == DateTime.sunday ? 0 : now.weekday;
    return DateTime(now.year, now.month, now.day - daysToSubtract);
  }

  Future<int> _getMonthlyRoomsHosted(
    String creatorId,
    DateTime start,
    DateTime end,
  ) async {
    final snapshot = await _firestore
        .collection('rooms')
        .where('hostId', isEqualTo: creatorId)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  Future<double> _getAvgParticipants(
    String creatorId,
    DateTime start,
    DateTime end,
  ) async {
    final snapshot = await _firestore
        .collection('rooms')
        .where('hostId', isEqualTo: creatorId)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    if (snapshot.docs.isEmpty) return 0;

    int totalParticipants = 0;
    for (final doc in snapshot.docs) {
      totalParticipants += (doc.data()['maxParticipants'] as int?) ?? 0;
    }

    return totalParticipants / snapshot.docs.length;
  }

  Future<int> _getTotalMinutesStreamed(
    String creatorId,
    DateTime start,
    DateTime end,
  ) async {
    final snapshot = await _firestore
        .collection('stream_sessions')
        .where('creatorId', isEqualTo: creatorId)
        .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    int totalMinutes = 0;
    for (final doc in snapshot.docs) {
      final duration = (doc.data()['durationMinutes'] as int?) ?? 0;
      totalMinutes += duration;
    }

    return totalMinutes;
  }

  double _calculateEngagementScore({
    required int roomsHosted,
    required double avgParticipants,
    required int totalMinutes,
    required double earnings,
  }) {
    // Weighted engagement score calculation
    double score = 0;

    // Room frequency (up to 30 points)
    score += (roomsHosted / 30 * 30).clamp(0, 30);

    // Average participants (up to 25 points)
    score += (avgParticipants / 20 * 25).clamp(0, 25);

    // Streaming time (up to 25 points) - target 40 hours/month
    score += (totalMinutes / 2400 * 25).clamp(0, 25);

    // Earnings performance (up to 20 points)
    score += (earnings / 500 * 20).clamp(0, 20);

    return (score / 100).clamp(0, 1);
  }
}

/// Widget for displaying payout report summary
class PayoutReportCard extends StatelessWidget {
  final WeeklyPayoutReport report;

  const PayoutReportCard({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Week of ${_formatDate(report.weekStart)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Chip(
                  label: Text(report.status),
                  backgroundColor: report.status == 'generated'
                      ? Colors.green.shade100
                      : Colors.orange.shade100,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetric(context, 'Gross', '\$${report.totalEarnings.toStringAsFixed(2)}'),
                _buildMetric(context, 'Net', '\$${report.netEarnings.toStringAsFixed(2)}'),
                _buildMetric(context, 'Paid Out', '\$${report.payoutAmount.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${report.transactionCount} transactions',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
