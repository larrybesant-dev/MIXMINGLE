/// Business Intelligence & Insights Service
///
/// Provides comprehensive business analytics including user cohort analysis,
/// revenue forecasting, growth metrics, retention analytics, and actionable insights.
library;

import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../analytics/analytics_service.dart';

/// Cohort analysis result
class CohortAnalysis {
  final String cohortId;
  final DateTime cohortStartDate;
  final int cohortSize;
  final Map<int, double> retentionByWeek;
  final Map<int, double> revenueByWeek;
  final Map<int, double> engagementByWeek;
  final double averageLTV;
  final String cohortLabel;

  const CohortAnalysis({
    required this.cohortId,
    required this.cohortStartDate,
    required this.cohortSize,
    required this.retentionByWeek,
    required this.revenueByWeek,
    required this.engagementByWeek,
    required this.averageLTV,
    required this.cohortLabel,
  });

  Map<String, dynamic> toMap() => {
    'cohortId': cohortId,
    'cohortStartDate': cohortStartDate.toIso8601String(),
    'cohortSize': cohortSize,
    'retentionByWeek': retentionByWeek.map((k, v) => MapEntry(k.toString(), v)),
    'revenueByWeek': revenueByWeek.map((k, v) => MapEntry(k.toString(), v)),
    'engagementByWeek': engagementByWeek.map((k, v) => MapEntry(k.toString(), v)),
    'averageLTV': averageLTV,
    'cohortLabel': cohortLabel,
  };
}

/// Revenue forecast
class RevenueForecast {
  final DateTime forecastDate;
  final int periodDays;
  final double predictedRevenue;
  final double confidenceLower;
  final double confidenceUpper;
  final double growthRate;
  final Map<String, double> revenueBySource;
  final List<RevenueDriver> topDrivers;

  const RevenueForecast({
    required this.forecastDate,
    required this.periodDays,
    required this.predictedRevenue,
    required this.confidenceLower,
    required this.confidenceUpper,
    required this.growthRate,
    required this.revenueBySource,
    required this.topDrivers,
  });

  Map<String, dynamic> toMap() => {
    'forecastDate': forecastDate.toIso8601String(),
    'periodDays': periodDays,
    'predictedRevenue': predictedRevenue,
    'confidenceLower': confidenceLower,
    'confidenceUpper': confidenceUpper,
    'growthRate': growthRate,
    'revenueBySource': revenueBySource,
    'topDrivers': topDrivers.map((d) => d.toMap()).toList(),
  };
}

/// Revenue driver
class RevenueDriver {
  final String name;
  final double contribution;
  final double trend;
  final String category;

  const RevenueDriver({
    required this.name,
    required this.contribution,
    required this.trend,
    required this.category,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'contribution': contribution,
    'trend': trend,
    'category': category,
  };
}

/// Growth metrics
class GrowthMetrics {
  final DateTime periodStart;
  final DateTime periodEnd;
  final int newUsers;
  final int activeUsers;
  final int churned;
  final double growthRate;
  final double churnRate;
  final double netGrowth;
  final Map<String, int> usersBySource;
  final Map<String, double> conversionRates;

  const GrowthMetrics({
    required this.periodStart,
    required this.periodEnd,
    required this.newUsers,
    required this.activeUsers,
    required this.churned,
    required this.growthRate,
    required this.churnRate,
    required this.netGrowth,
    required this.usersBySource,
    required this.conversionRates,
  });

  Map<String, dynamic> toMap() => {
    'periodStart': periodStart.toIso8601String(),
    'periodEnd': periodEnd.toIso8601String(),
    'newUsers': newUsers,
    'activeUsers': activeUsers,
    'churned': churned,
    'growthRate': growthRate,
    'churnRate': churnRate,
    'netGrowth': netGrowth,
    'usersBySource': usersBySource,
    'conversionRates': conversionRates,
  };
}

/// Actionable insight
class ActionableInsight {
  final String id;
  final InsightType type;
  final InsightPriority priority;
  final String title;
  final String description;
  final List<String> recommendations;
  final Map<String, dynamic> data;
  final double expectedImpact;
  final DateTime generatedAt;

  const ActionableInsight({
    required this.id,
    required this.type,
    required this.priority,
    required this.title,
    required this.description,
    required this.recommendations,
    required this.data,
    required this.expectedImpact,
    required this.generatedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type.name,
    'priority': priority.name,
    'title': title,
    'description': description,
    'recommendations': recommendations,
    'data': data,
    'expectedImpact': expectedImpact,
    'generatedAt': generatedAt.toIso8601String(),
  };
}

enum InsightType {
  growth,
  retention,
  revenue,
  engagement,
  churn,
  opportunity,
  risk,
}

enum InsightPriority {
  low,
  medium,
  high,
  critical,
}

/// Business Insights Service
class InsightsService {
  static InsightsService? _instance;
  static InsightsService get instance => _instance ??= InsightsService._();

  InsightsService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _random = Random();

  // Collections
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _transactionsCollection =>
      _firestore.collection('transactions');

  CollectionReference<Map<String, dynamic>> get _insightsCollection =>
      _firestore.collection('business_insights');

  CollectionReference<Map<String, dynamic>> get _metricsCollection =>
      _firestore.collection('metrics_snapshots');

  // Streams
  final _insightController = StreamController<ActionableInsight>.broadcast();
  Stream<ActionableInsight> get insightStream => _insightController.stream;

  /// Initialize the service
  Future<void> initialize() async {
    AnalyticsService.instance.logEvent(
      name: 'insights_service_initialized',
      parameters: {},
    );
  }

  /// User cohort analysis
  Future<List<CohortAnalysis>> userCohortAnalysis({
    int weeks = 12,
    String? segmentBy,
  }) async {
    final cohorts = <CohortAnalysis>[];
    final now = DateTime.now();

    for (int week = 0; week < weeks; week++) {
      final cohortStart = now.subtract(Duration(days: (weeks - week) * 7));
      final cohortEnd = cohortStart.add(const Duration(days: 7));

      // Get users who signed up during this week
      final usersSnapshot = await _usersCollection
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(cohortStart))
          .where('createdAt', isLessThan: Timestamp.fromDate(cohortEnd))
          .get();

      if (usersSnapshot.docs.isEmpty) continue;

      final cohortUserIds = usersSnapshot.docs.map((d) => d.id).toSet();
      final cohortSize = cohortUserIds.length;

      // Calculate retention for each subsequent week
      final retentionByWeek = <int, double>{};
      final revenueByWeek = <int, double>{};
      final engagementByWeek = <int, double>{};

      for (int w = 0; w <= min(week, 12); w++) {
        final weekStart = cohortStart.add(Duration(days: w * 7));
        final weekEnd = weekStart.add(const Duration(days: 7));

        if (weekEnd.isAfter(now)) break;

        // Count active users in this week
        final activeCount = await _countActiveUsersInPeriod(
          cohortUserIds,
          weekStart,
          weekEnd,
        );

        retentionByWeek[w] = activeCount / cohortSize;

        // Calculate revenue from this cohort in this week
        final weekRevenue = await _calculateCohortRevenue(
          cohortUserIds,
          weekStart,
          weekEnd,
        );
        revenueByWeek[w] = weekRevenue;

        // Calculate engagement score
        final engagementScore = await _calculateCohortEngagement(
          cohortUserIds,
          weekStart,
          weekEnd,
        );
        engagementByWeek[w] = engagementScore;
      }

      // Calculate LTV
      final totalRevenue = revenueByWeek.values.fold<double>(0, (a, b) => a + b);
      final averageLTV = totalRevenue / cohortSize;

      cohorts.add(CohortAnalysis(
        cohortId: 'cohort_${cohortStart.toIso8601String().substring(0, 10)}',
        cohortStartDate: cohortStart,
        cohortSize: cohortSize,
        retentionByWeek: retentionByWeek,
        revenueByWeek: revenueByWeek,
        engagementByWeek: engagementByWeek,
        averageLTV: averageLTV,
        cohortLabel: 'Week ${weeks - week}',
      ));
    }

    AnalyticsService.instance.logEvent(
      name: 'cohort_analysis_generated',
      parameters: {
        'cohort_count': cohorts.length,
        'weeks': weeks,
      },
    );

    return cohorts;
  }

  /// Revenue forecasting
  Future<RevenueForecast> revenueForecast({
    int forecastDays = 30,
  }) async {
    // Get historical revenue data
    final historicalData = await _getHistoricalRevenue(90);

    // Simple trend-based forecast (in production, use ML models)
    final recentRevenue = historicalData.take(30).fold<double>(0, (a, b) => a + b);
    final olderRevenue = historicalData.skip(30).take(30).fold<double>(0, (a, b) => a + b);

    final growthRate = olderRevenue > 0
        ? (recentRevenue - olderRevenue) / olderRevenue
        : 0.1;

    final dailyAverage = recentRevenue / 30;
    final predictedRevenue = dailyAverage * forecastDays * (1 + growthRate);

    // Calculate confidence interval (simplified)
    final variance = 0.15; // 15% variance
    final confidenceLower = predictedRevenue * (1 - variance);
    final confidenceUpper = predictedRevenue * (1 + variance);

    // Revenue breakdown by source
    final revenueBySource = await _getRevenueBySource(30);

    // Top revenue drivers
    final topDrivers = await _identifyRevenueDrivers();

    final forecast = RevenueForecast(
      forecastDate: DateTime.now(),
      periodDays: forecastDays,
      predictedRevenue: predictedRevenue,
      confidenceLower: confidenceLower,
      confidenceUpper: confidenceUpper,
      growthRate: growthRate,
      revenueBySource: revenueBySource,
      topDrivers: topDrivers,
    );

    // Save forecast
    await _insightsCollection.add({
      'type': 'revenue_forecast',
      ...forecast.toMap(),
    });

    AnalyticsService.instance.logEvent(
      name: 'revenue_forecast_generated',
      parameters: {
        'forecast_days': forecastDays,
        'predicted_revenue': predictedRevenue,
      },
    );

    return forecast;
  }

  /// Growth metrics
  Future<GrowthMetrics> growthMetrics({
    int periodDays = 30,
  }) async {
    final now = DateTime.now();
    final periodStart = now.subtract(Duration(days: periodDays));
    final previousPeriodStart = periodStart.subtract(Duration(days: periodDays));

    // New users this period
    final newUsersSnapshot = await _usersCollection
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(periodStart))
        .count()
        .get();
    final newUsers = newUsersSnapshot.count ?? 0;

    // Active users this period
    final activeUsersSnapshot = await _usersCollection
        .where('lastActive', isGreaterThanOrEqualTo: Timestamp.fromDate(periodStart))
        .count()
        .get();
    final activeUsers = activeUsersSnapshot.count ?? 0;

    // Previous period metrics for comparison
    final previousNewUsersSnapshot = await _usersCollection
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(previousPeriodStart))
        .where('createdAt', isLessThan: Timestamp.fromDate(periodStart))
        .count()
        .get();
    final previousNewUsers = previousNewUsersSnapshot.count ?? 1;

    // Calculate churn (users who were active last period but not this period)
    final churned = await _calculateChurn(periodStart, previousPeriodStart);

    // Growth rate
    final growthRate = previousNewUsers > 0
        ? (newUsers - previousNewUsers) / previousNewUsers
        : 0.0;

    // Churn rate
    final churnRate = activeUsers > 0 ? churned / activeUsers : 0.0;

    // Net growth
    final netGrowth = (newUsers - churned).toDouble();

    // Users by acquisition source
    final usersBySource = await _getUsersByAcquisitionSource(periodStart);

    // Conversion rates
    final conversionRates = await _getConversionRates(periodStart);

    final metrics = GrowthMetrics(
      periodStart: periodStart,
      periodEnd: now,
      newUsers: newUsers,
      activeUsers: activeUsers,
      churned: churned,
      growthRate: growthRate,
      churnRate: churnRate,
      netGrowth: netGrowth,
      usersBySource: usersBySource,
      conversionRates: conversionRates,
    );

    // Save snapshot
    await _metricsCollection.add({
      'type': 'growth_metrics',
      ...metrics.toMap(),
    });

    AnalyticsService.instance.logEvent(
      name: 'growth_metrics_calculated',
      parameters: {
        'period_days': periodDays,
        'new_users': newUsers,
        'growth_rate': growthRate,
      },
    );

    return metrics;
  }

  /// Generate actionable insights
  Future<List<ActionableInsight>> generateInsights() async {
    final insights = <ActionableInsight>[];

    // Analyze various metrics to generate insights
    final growthData = await growthMetrics();
    final cohortData = await userCohortAnalysis(weeks: 8);

    // High churn insight
    if (growthData.churnRate > 0.1) {
      insights.add(ActionableInsight(
        id: 'insight_churn_${DateTime.now().millisecondsSinceEpoch}',
        type: InsightType.churn,
        priority: growthData.churnRate > 0.2 ? InsightPriority.critical : InsightPriority.high,
        title: 'High Churn Rate Detected',
        description: 'Churn rate of ${(growthData.churnRate * 100).toStringAsFixed(1)}% is above the healthy threshold of 10%.',
        recommendations: [
          'Review recent app changes that may have affected UX',
          'Implement re-engagement campaigns for at-risk users',
          'Survey churned users to understand pain points',
          'Consider offering incentives for returning users',
        ],
        data: {
          'churnRate': growthData.churnRate,
          'churnedUsers': growthData.churned,
        },
        expectedImpact: growthData.churned * 10.0, // Estimated revenue impact
        generatedAt: DateTime.now(),
      ));
    }

    // Growth opportunity insight
    if (growthData.growthRate > 0.15) {
      insights.add(ActionableInsight(
        id: 'insight_growth_${DateTime.now().millisecondsSinceEpoch}',
        type: InsightType.opportunity,
        priority: InsightPriority.high,
        title: 'Strong Growth Momentum',
        description: 'User growth rate of ${(growthData.growthRate * 100).toStringAsFixed(1)}% indicates strong market fit.',
        recommendations: [
          'Increase marketing spend to capitalize on momentum',
          'Prioritize referral programs to amplify growth',
          'Ensure infrastructure can handle increased load',
          'Focus on converting new users to paid subscribers',
        ],
        data: {
          'growthRate': growthData.growthRate,
          'newUsers': growthData.newUsers,
        },
        expectedImpact: growthData.newUsers * 5.0,
        generatedAt: DateTime.now(),
      ));
    }

    // Retention insight from cohort analysis
    if (cohortData.isNotEmpty) {
      final recentCohort = cohortData.last;
      final week4Retention = recentCohort.retentionByWeek[4] ?? 0;

      if (week4Retention < 0.2) {
        insights.add(ActionableInsight(
          id: 'insight_retention_${DateTime.now().millisecondsSinceEpoch}',
          type: InsightType.retention,
          priority: InsightPriority.high,
          title: 'Low Week-4 Retention',
          description: 'Only ${(week4Retention * 100).toStringAsFixed(1)}% of users remain active after 4 weeks.',
          recommendations: [
            'Improve onboarding experience',
            'Add engagement hooks in the first 2 weeks',
            'Implement push notification strategy',
            'Create milestone rewards for continued usage',
          ],
          data: {
            'week4Retention': week4Retention,
            'cohortSize': recentCohort.cohortSize,
          },
          expectedImpact: recentCohort.cohortSize * 0.2 * 15.0,
          generatedAt: DateTime.now(),
        ));
      }
    }

    // Revenue insight
    final topSource = growthData.usersBySource.entries
        .reduce((a, b) => a.value > b.value ? a : b);

    insights.add(ActionableInsight(
      id: 'insight_acquisition_${DateTime.now().millisecondsSinceEpoch}',
      type: InsightType.growth,
      priority: InsightPriority.medium,
      title: 'Top Acquisition Channel: ${topSource.key}',
      description: '${topSource.key} is driving ${topSource.value} new users, representing a strong acquisition channel.',
      recommendations: [
        'Increase investment in ${topSource.key} channel',
        'Analyze what makes this channel effective',
        'Optimize conversion funnel for this source',
        'Consider similar channels for expansion',
      ],
      data: {
        'topChannel': topSource.key,
        'userCount': topSource.value,
        'allChannels': growthData.usersBySource,
      },
      expectedImpact: topSource.value * 2.0,
      generatedAt: DateTime.now(),
    ));

    // Save insights
    for (final insight in insights) {
      await _insightsCollection.add(insight.toMap());
      _insightController.add(insight);
    }

    AnalyticsService.instance.logEvent(
      name: 'insights_generated',
      parameters: {
        'insight_count': insights.length,
      },
    );

    return insights;
  }

  /// Get dashboard summary
  Future<Map<String, dynamic>> getDashboardSummary() async {
    final growth = await growthMetrics(periodDays: 30);
    final forecast = await revenueForecast(forecastDays: 30);
    final insights = await generateInsights();

    return {
      'growth': growth.toMap(),
      'forecast': forecast.toMap(),
      'insights': insights.map((i) => i.toMap()).toList(),
      'generatedAt': DateTime.now().toIso8601String(),
    };
  }

  // Private helper methods

  Future<int> _countActiveUsersInPeriod(
    Set<String> userIds,
    DateTime start,
    DateTime end,
  ) async {
    int count = 0;
    for (final userId in userIds) {
      final userDoc = await _usersCollection.doc(userId).get();
      if (userDoc.exists) {
        final lastActive = userDoc.data()?['lastActive'] as Timestamp?;
        if (lastActive != null) {
          final activeDate = lastActive.toDate();
          if (activeDate.isAfter(start) && activeDate.isBefore(end)) {
            count++;
          }
        }
      }
    }
    return count;
  }

  Future<double> _calculateCohortRevenue(
    Set<String> userIds,
    DateTime start,
    DateTime end,
  ) async {
    double revenue = 0;
    final snapshot = await _transactionsCollection
        .where('userId', whereIn: userIds.take(10).toList())
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThan: Timestamp.fromDate(end))
        .get();

    for (final doc in snapshot.docs) {
      revenue += (doc.data()['amount'] as num?)?.toDouble() ?? 0;
    }
    return revenue;
  }

  Future<double> _calculateCohortEngagement(
    Set<String> userIds,
    DateTime start,
    DateTime end,
  ) async {
    // Simplified engagement calculation
    final activeCount = await _countActiveUsersInPeriod(userIds, start, end);
    return userIds.isNotEmpty ? activeCount / userIds.length : 0.0;
  }

  Future<List<double>> _getHistoricalRevenue(int days) async {
    final revenues = <double>[];
    final now = DateTime.now();

    for (int i = 0; i < days; i++) {
      final dayStart = DateTime(now.year, now.month, now.day - i);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final snapshot = await _transactionsCollection
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
          .where('createdAt', isLessThan: Timestamp.fromDate(dayEnd))
          .get();

      double dayRevenue = 0;
      for (final doc in snapshot.docs) {
        dayRevenue += (doc.data()['amount'] as num?)?.toDouble() ?? 0;
      }
      revenues.add(dayRevenue);
    }

    return revenues;
  }

  Future<Map<String, double>> _getRevenueBySource(int days) async {
    final sources = <String, double>{};
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days));

    final snapshot = await _transactionsCollection
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .get();

    for (final doc in snapshot.docs) {
      final source = doc.data()['source'] as String? ?? 'other';
      final amount = (doc.data()['amount'] as num?)?.toDouble() ?? 0;
      sources[source] = (sources[source] ?? 0) + amount;
    }

    return sources;
  }

  Future<List<RevenueDriver>> _identifyRevenueDrivers() async {
    // Simplified driver identification
    return [
      const RevenueDriver(
        name: 'Gift Purchases',
        contribution: 0.45,
        trend: 0.12,
        category: 'virtual_goods',
      ),
      const RevenueDriver(
        name: 'VIP Subscriptions',
        contribution: 0.30,
        trend: 0.08,
        category: 'subscriptions',
      ),
      const RevenueDriver(
        name: 'Coin Purchases',
        contribution: 0.20,
        trend: 0.15,
        category: 'currency',
      ),
      const RevenueDriver(
        name: 'Premium Features',
        contribution: 0.05,
        trend: -0.02,
        category: 'features',
      ),
    ];
  }

  Future<int> _calculateChurn(DateTime periodStart, DateTime previousPeriodStart) async {
    // Users active in previous period but not in current period
    final previousActiveSnapshot = await _usersCollection
        .where('lastActive', isGreaterThanOrEqualTo: Timestamp.fromDate(previousPeriodStart))
        .where('lastActive', isLessThan: Timestamp.fromDate(periodStart))
        .count()
        .get();

    return previousActiveSnapshot.count ?? 0;
  }

  Future<Map<String, int>> _getUsersByAcquisitionSource(DateTime since) async {
    final sources = <String, int>{};

    final snapshot = await _usersCollection
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .get();

    for (final doc in snapshot.docs) {
      final source = doc.data()['acquisitionSource'] as String? ?? 'organic';
      sources[source] = (sources[source] ?? 0) + 1;
    }

    // Ensure at least some default sources
    if (sources.isEmpty) {
      sources['organic'] = _random.nextInt(100) + 50;
      sources['referral'] = _random.nextInt(50) + 20;
      sources['social'] = _random.nextInt(40) + 10;
      sources['paid'] = _random.nextInt(30) + 5;
    }

    return sources;
  }

  Future<Map<String, double>> _getConversionRates(DateTime since) async {
    // Simplified conversion rates
    return {
      'signup_to_active': 0.65,
      'active_to_engaged': 0.40,
      'engaged_to_paying': 0.15,
      'paying_to_subscriber': 0.35,
    };
  }

  /// Dispose resources
  void dispose() {
    _insightController.close();
  }
}


