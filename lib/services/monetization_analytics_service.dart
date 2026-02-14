import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Analytics time periods
enum AnalyticsPeriod {
  day,
  week,
  month,
  quarter,
  year,
  allTime,
}

/// Revenue categories
enum RevenueCategory {
  subscriptions,
  coinPurchases,
  gifts,
  premiumFeatures,
  advertisements,
}

/// User engagement metrics
class UserEngagementMetrics {
  final int totalUsers;
  final int activeUsers;
  final int newUsers;
  final double averageSessionDuration;
  final int totalMessages;
  final int totalRoomsCreated;
  final int totalVoiceMinutes;
  final Map<String, int> platformUsage;

  const UserEngagementMetrics({
    required this.totalUsers,
    required this.activeUsers,
    required this.newUsers,
    required this.averageSessionDuration,
    required this.totalMessages,
    required this.totalRoomsCreated,
    required this.totalVoiceMinutes,
    required this.platformUsage,
  });

  factory UserEngagementMetrics.fromMap(Map<String, dynamic> map) {
    return UserEngagementMetrics(
      totalUsers: map['totalUsers'] ?? 0,
      activeUsers: map['activeUsers'] ?? 0,
      newUsers: map['newUsers'] ?? 0,
      averageSessionDuration: (map['averageSessionDuration'] ?? 0).toDouble(),
      totalMessages: map['totalMessages'] ?? 0,
      totalRoomsCreated: map['totalRoomsCreated'] ?? 0,
      totalVoiceMinutes: map['totalVoiceMinutes'] ?? 0,
      platformUsage: Map<String, int>.from(map['platformUsage'] ?? {}),
    );
  }
}

/// Revenue metrics
class RevenueMetrics {
  final double totalRevenue;
  final double monthlyRecurringRevenue;
  final Map<RevenueCategory, double> revenueByCategory;
  final Map<String, double> revenueBySubscriptionTier;
  final double averageRevenuePerUser;
  final int payingUsers;
  final double churnRate;

  const RevenueMetrics({
    required this.totalRevenue,
    required this.monthlyRecurringRevenue,
    required this.revenueByCategory,
    required this.revenueBySubscriptionTier,
    required this.averageRevenuePerUser,
    required this.payingUsers,
    required this.churnRate,
  });

  factory RevenueMetrics.fromMap(Map<String, dynamic> map) {
    return RevenueMetrics(
      totalRevenue: (map['totalRevenue'] ?? 0).toDouble(),
      monthlyRecurringRevenue: (map['monthlyRecurringRevenue'] ?? 0).toDouble(),
      revenueByCategory: Map<RevenueCategory, double>.from(
        (map['revenueByCategory'] ?? {}).map(
          (key, value) => MapEntry(
            RevenueCategory.values.firstWhere(
              (e) => e.name == key,
              orElse: () => RevenueCategory.subscriptions,
            ),
            (value ?? 0).toDouble(),
          ),
        ),
      ),
      revenueBySubscriptionTier: Map<String, double>.from(
        (map['revenueBySubscriptionTier'] ?? {}).map(
          (key, value) => MapEntry(key, (value ?? 0).toDouble()),
        ),
      ),
      averageRevenuePerUser: (map['averageRevenuePerUser'] ?? 0).toDouble(),
      payingUsers: map['payingUsers'] ?? 0,
      churnRate: (map['churnRate'] ?? 0).toDouble(),
    );
  }
}

/// Monetization analytics service
class MonetizationAnalyticsService {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'us-central1');

  /// Get user engagement metrics
  Future<UserEngagementMetrics> getUserEngagementMetrics(AnalyticsPeriod period) async {
    try {
      final result = await _functions.httpsCallable('getUserEngagementMetrics').call({
        'period': period.name,
      });

      return UserEngagementMetrics.fromMap(result.data ?? {});
    } catch (e) {
      debugPrint('Error getting user engagement metrics: $e');
      return UserEngagementMetrics(
        totalUsers: 0,
        activeUsers: 0,
        newUsers: 0,
        averageSessionDuration: 0,
        totalMessages: 0,
        totalRoomsCreated: 0,
        totalVoiceMinutes: 0,
        platformUsage: {},
      );
    }
  }

  /// Get revenue metrics
  Future<RevenueMetrics> getRevenueMetrics(AnalyticsPeriod period) async {
    try {
      final result = await _functions.httpsCallable('getRevenueMetrics').call({
        'period': period.name,
      });

      return RevenueMetrics.fromMap(result.data ?? {});
    } catch (e) {
      debugPrint('Error getting revenue metrics: $e');
      return RevenueMetrics(
        totalRevenue: 0,
        monthlyRecurringRevenue: 0,
        revenueByCategory: {},
        revenueBySubscriptionTier: {},
        averageRevenuePerUser: 0,
        payingUsers: 0,
        churnRate: 0,
      );
    }
  }

  /// Get coin economy analytics
  Future<Map<String, dynamic>> getCoinEconomyAnalytics(AnalyticsPeriod period) async {
    try {
      final result = await _functions.httpsCallable('getCoinEconomyAnalytics').call({
        'period': period.name,
      });

      return result.data ?? {};
    } catch (e) {
      debugPrint('Error getting coin economy analytics: $e');
      return {};
    }
  }

  /// Get gift analytics
  Future<Map<String, dynamic>> getGiftAnalytics(AnalyticsPeriod period) async {
    try {
      final result = await _functions.httpsCallable('getGiftAnalytics').call({
        'period': period.name,
      });

      return result.data ?? {};
    } catch (e) {
      debugPrint('Error getting gift analytics: $e');
      return {};
    }
  }

  /// Get subscription analytics
  Future<Map<String, dynamic>> getSubscriptionAnalytics(AnalyticsPeriod period) async {
    try {
      final result = await _functions.httpsCallable('getSubscriptionAnalytics').call({
        'period': period.name,
      });

      return result.data ?? {};
    } catch (e) {
      debugPrint('Error getting subscription analytics: $e');
      return {};
    }
  }

  /// Get top spenders
  Future<List<Map<String, dynamic>>> getTopSpenders({
    AnalyticsPeriod period = AnalyticsPeriod.month,
    int limit = 10,
  }) async {
    try {
      final result = await _functions.httpsCallable('getTopSpenders').call({
        'period': period.name,
        'limit': limit,
      });

      return List<Map<String, dynamic>>.from(result.data ?? []);
    } catch (e) {
      debugPrint('Error getting top spenders: $e');
      return [];
    }
  }

  /// Get conversion funnel data
  Future<Map<String, dynamic>> getConversionFunnel(AnalyticsPeriod period) async {
    try {
      final result = await _functions.httpsCallable('getConversionFunnel').call({
        'period': period.name,
      });

      return result.data ?? {};
    } catch (e) {
      debugPrint('Error getting conversion funnel: $e');
      return {};
    }
  }

  /// Get cohort analysis
  Future<List<Map<String, dynamic>>> getCohortAnalysis({
    AnalyticsPeriod period = AnalyticsPeriod.month,
    int numCohorts = 6,
  }) async {
    try {
      final result = await _functions.httpsCallable('getCohortAnalysis').call({
        'period': period.name,
        'numCohorts': numCohorts,
      });

      return List<Map<String, dynamic>>.from(result.data ?? []);
    } catch (e) {
      debugPrint('Error getting cohort analysis: $e');
      return [];
    }
  }

  /// Get real-time metrics (last 24 hours)
  Future<Map<String, dynamic>> getRealtimeMetrics() async {
    try {
      final result = await _functions.httpsCallable('getRealtimeMetrics').call();
      return result.data ?? {};
    } catch (e) {
      debugPrint('Error getting realtime metrics: $e');
      return {};
    }
  }

  /// Export analytics data
  Future<String> exportAnalyticsData({
    required AnalyticsPeriod period,
    required List<String> metrics,
    String format = 'csv', // 'csv' or 'json'
  }) async {
    try {
      final result = await _functions.httpsCallable('exportAnalyticsData').call({
        'period': period.name,
        'metrics': metrics,
        'format': format,
      });

      return result.data['downloadUrl'] ?? '';
    } catch (e) {
      debugPrint('Error exporting analytics data: $e');
      return '';
    }
  }

  /// Get predictive analytics (revenue forecasting)
  Future<Map<String, dynamic>> getPredictiveAnalytics({
    int forecastDays = 30,
  }) async {
    try {
      final result = await _functions.httpsCallable('getPredictiveAnalytics').call({
        'forecastDays': forecastDays,
      });

      return result.data ?? {};
    } catch (e) {
      debugPrint('Error getting predictive analytics: $e');
      return {};
    }
  }

  /// Get A/B test results
  Future<List<Map<String, dynamic>>> getABTestResults({
    String? testName,
    AnalyticsPeriod period = AnalyticsPeriod.week,
  }) async {
    try {
      final result = await _functions.httpsCallable('getABTestResults').call({
        'testName': testName,
        'period': period.name,
      });

      return List<Map<String, dynamic>>.from(result.data ?? []);
    } catch (e) {
      debugPrint('Error getting A/B test results: $e');
      return [];
    }
  }

  /// Track custom event
  Future<void> trackCustomEvent({
    required String eventName,
    required String userId,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      await _functions.httpsCallable('trackCustomEvent').call({
        'eventName': eventName,
        'userId': userId,
        'parameters': parameters ?? {},
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error tracking custom event: $e');
    }
  }

  /// Get user behavior insights
  Future<Map<String, dynamic>> getUserBehaviorInsights(String userId) async {
    try {
      final result = await _functions.httpsCallable('getUserBehaviorInsights').call({
        'userId': userId,
      });

      return result.data ?? {};
    } catch (e) {
      debugPrint('Error getting user behavior insights: $e');
      return {};
    }
  }

  /// Generate monetization report
  Future<Map<String, dynamic>> generateMonetizationReport(AnalyticsPeriod period) async {
    try {
      final [
        engagement,
        revenue,
        coinEconomy,
        gifts,
        subscriptions,
      ] = await Future.wait([
        getUserEngagementMetrics(period),
        getRevenueMetrics(period),
        getCoinEconomyAnalytics(period),
        getGiftAnalytics(period),
        getSubscriptionAnalytics(period),
      ]);

      return {
        'period': period.name,
        'generatedAt': DateTime.now().toIso8601String(),
        'engagement': engagement,
        'revenue': revenue,
        'coinEconomy': coinEconomy,
        'gifts': gifts,
        'subscriptions': subscriptions,
        'keyInsights': _generateKeyInsights({
          'engagement': engagement,
          'revenue': revenue,
          'coinEconomy': coinEconomy,
          'gifts': gifts,
          'subscriptions': subscriptions,
        }),
      };
    } catch (e) {
      debugPrint('Error generating monetization report: $e');
      return {};
    }
  }

  List<String> _generateKeyInsights(Map<String, dynamic> data) {
    final insights = <String>[];

    final revenue = data['revenue'] as RevenueMetrics?;
    final engagement = data['engagement'] as UserEngagementMetrics?;

    if (revenue != null) {
      if (revenue.averageRevenuePerUser > 0) {
        insights.add('Average revenue per user: \$${revenue.averageRevenuePerUser.toStringAsFixed(2)}');
      }

      if (revenue.churnRate > 0) {
        insights.add('Monthly churn rate: ${(revenue.churnRate * 100).toStringAsFixed(1)}%');
      }

      final topCategory = revenue.revenueByCategory.entries.reduce((a, b) => a.value > b.value ? a : b);
      insights.add('Top revenue source: ${topCategory.key.name} (\$${topCategory.value.toStringAsFixed(2)})');
    }

    if (engagement != null) {
      final engagementRate = engagement.totalUsers > 0 ? (engagement.activeUsers / engagement.totalUsers * 100) : 0;
      insights.add('User engagement rate: ${engagementRate.toStringAsFixed(1)}%');

      if (engagement.averageSessionDuration > 0) {
        insights.add('Average session duration: ${engagement.averageSessionDuration.toStringAsFixed(1)} minutes');
      }
    }

    return insights;
  }
}

/// Riverpod providers
final monetizationAnalyticsServiceProvider = Provider<MonetizationAnalyticsService>((ref) {
  return MonetizationAnalyticsService();
});

final userEngagementMetricsProvider =
    FutureProvider.family<UserEngagementMetrics, AnalyticsPeriod>((ref, period) async {
  final service = ref.watch(monetizationAnalyticsServiceProvider);
  return service.getUserEngagementMetrics(period);
});

final revenueMetricsProvider = FutureProvider.family<RevenueMetrics, AnalyticsPeriod>((ref, period) async {
  final service = ref.watch(monetizationAnalyticsServiceProvider);
  return service.getRevenueMetrics(period);
});

final coinEconomyAnalyticsProvider = FutureProvider.family<Map<String, dynamic>, AnalyticsPeriod>((ref, period) async {
  final service = ref.watch(monetizationAnalyticsServiceProvider);
  return service.getCoinEconomyAnalytics(period);
});

final giftAnalyticsProvider = FutureProvider.family<Map<String, dynamic>, AnalyticsPeriod>((ref, period) async {
  final service = ref.watch(monetizationAnalyticsServiceProvider);
  return service.getGiftAnalytics(period);
});

final subscriptionAnalyticsProvider = FutureProvider.family<Map<String, dynamic>, AnalyticsPeriod>((ref, period) async {
  final service = ref.watch(monetizationAnalyticsServiceProvider);
  return service.getSubscriptionAnalytics(period);
});

final topSpendersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(monetizationAnalyticsServiceProvider);
  return service.getTopSpenders();
});

final conversionFunnelProvider = FutureProvider.family<Map<String, dynamic>, AnalyticsPeriod>((ref, period) async {
  final service = ref.watch(monetizationAnalyticsServiceProvider);
  return service.getConversionFunnel(period);
});

final cohortAnalysisProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(monetizationAnalyticsServiceProvider);
  return service.getCohortAnalysis();
});

final realtimeMetricsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(monetizationAnalyticsServiceProvider);
  return service.getRealtimeMetrics();
});

final predictiveAnalyticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(monetizationAnalyticsServiceProvider);
  return service.getPredictiveAnalytics();
});

final monetizationReportProvider = FutureProvider.family<Map<String, dynamic>, AnalyticsPeriod>((ref, period) async {
  final service = ref.watch(monetizationAnalyticsServiceProvider);
  return service.generateMonetizationReport(period);
});
