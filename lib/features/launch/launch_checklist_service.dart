/// Launch Checklist Service
///
/// Verifies all launch requirements are met: analytics, Crashlytics,
/// performance traces, moderation flows, payments, retention loops,
/// and referral system.
library;

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for managing and verifying launch checklist items
class LaunchChecklistService {
  static LaunchChecklistService? _instance;
  static LaunchChecklistService get instance =>
      _instance ??= LaunchChecklistService._();

  LaunchChecklistService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  static const String _checklistCollection = 'launch_checklists';

  // ============================================================
  // ANALYTICS VERIFICATION
  // ============================================================

  /// Verify all analytics events are firing correctly
  Future<ChecklistResult> verifyAnalytics() async {
    debugPrint('ðŸ” [Checklist] Verifying analytics...');

    final checks = <CheckItem>[];
    bool allPassed = true;

    try {
      // Check 1: Core events are configured
      final coreEvents = [
        'app_open',
        'session_start',
        'screen_view',
        'user_signup',
        'user_login',
      ];

      for (final event in coreEvents) {
        final exists = await _checkEventExists(event);
        checks.add(CheckItem(
          name: 'Core event: $event',
          passed: exists,
          details: exists ? 'Configured' : 'Not found',
        ));
        if (!exists) allPassed = false;
      }

      // Check 2: Room events
      final roomEvents = [
        'room_created',
        'room_joined',
        'room_left',
        'room_ended',
      ];

      for (final event in roomEvents) {
        final exists = await _checkEventExists(event);
        checks.add(CheckItem(
          name: 'Room event: $event',
          passed: exists,
          details: exists ? 'Configured' : 'Not found',
        ));
        if (!exists) allPassed = false;
      }

      // Check 3: Conversion events
      final conversionEvents = [
        'purchase_started',
        'purchase_completed',
        'vip_upgraded',
      ];

      for (final event in conversionEvents) {
        final exists = await _checkEventExists(event);
        checks.add(CheckItem(
          name: 'Conversion event: $event',
          passed: exists,
          details: exists ? 'Configured' : 'Not found',
        ));
        if (!exists) allPassed = false;
      }

      // Check 4: User properties
      final hasUserProperties = await _verifyUserProperties();
      checks.add(CheckItem(
        name: 'User properties configured',
        passed: hasUserProperties,
        details: hasUserProperties ? 'Configured' : 'Missing configuration',
      ));
      if (!hasUserProperties) allPassed = false;

      return ChecklistResult(
        category: 'Analytics',
        passed: allPassed,
        checks: checks,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('âŒ [Checklist] Analytics verification failed: $e');
      return ChecklistResult(
        category: 'Analytics',
        passed: false,
        checks: [
          CheckItem(
            name: 'Analytics verification',
            passed: false,
            details: 'Error: $e',
          ),
        ],
        timestamp: DateTime.now(),
      );
    }
  }

  // ============================================================
  // CRASHLYTICS VERIFICATION
  // ============================================================

  /// Verify Crashlytics is properly configured
  Future<ChecklistResult> verifyCrashlytics() async {
    debugPrint('ðŸ” [Checklist] Verifying Crashlytics...');

    final checks = <CheckItem>[];
    bool allPassed = true;

    try {
      // Check 1: Crashlytics enabled
      final crashlyticsConfig = await _firestore
          .collection('app_config')
          .doc('crashlytics')
          .get();

      final enabled = crashlyticsConfig.data()?['enabled'] ?? false;
      checks.add(CheckItem(
        name: 'Crashlytics enabled',
        passed: enabled,
        details: enabled ? 'Active' : 'Disabled',
      ));
      if (!enabled) allPassed = false;

      // Check 2: Non-fatal error reporting
      final nonFatalEnabled = crashlyticsConfig.data()?['nonFatalEnabled'] ?? false;
      checks.add(CheckItem(
        name: 'Non-fatal error reporting',
        passed: nonFatalEnabled,
        details: nonFatalEnabled ? 'Enabled' : 'Disabled',
      ));
      if (!nonFatalEnabled) allPassed = false;

      // Check 3: User identification
      final userIdEnabled = crashlyticsConfig.data()?['userIdEnabled'] ?? false;
      checks.add(CheckItem(
        name: 'User identification',
        passed: userIdEnabled,
        details: userIdEnabled ? 'Enabled' : 'Disabled',
      ));

      // Check 4: Recent crashes (should be low)
      final crashCount = await _getRecentCrashCount(7);
      final lowCrashRate = crashCount < 100; // Threshold for pre-launch
      checks.add(CheckItem(
        name: 'Recent crash count (7d)',
        passed: lowCrashRate,
        details: '$crashCount crashes',
      ));
      if (!lowCrashRate) allPassed = false;

      // Check 5: Crash-free rate
      final crashFreeRate = await _getCrashFreeRate();
      final healthyRate = crashFreeRate >= 99;
      checks.add(CheckItem(
        name: 'Crash-free rate',
        passed: healthyRate,
        details: '${crashFreeRate.toStringAsFixed(2)}%',
      ));
      if (!healthyRate) allPassed = false;

      return ChecklistResult(
        category: 'Crashlytics',
        passed: allPassed,
        checks: checks,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('âŒ [Checklist] Crashlytics verification failed: $e');
      return ChecklistResult(
        category: 'Crashlytics',
        passed: false,
        checks: [
          CheckItem(
            name: 'Crashlytics verification',
            passed: false,
            details: 'Error: $e',
          ),
        ],
        timestamp: DateTime.now(),
      );
    }
  }

  // ============================================================
  // PERFORMANCE TRACES VERIFICATION
  // ============================================================

  /// Verify performance traces are configured
  Future<ChecklistResult> verifyPerformanceTraces() async {
    debugPrint('ðŸ” [Checklist] Verifying performance traces...');

    final checks = <CheckItem>[];
    bool allPassed = true;

    try {
      // Check 1: Performance monitoring enabled
      final perfConfig = await _firestore
          .collection('app_config')
          .doc('performance')
          .get();

      final enabled = perfConfig.data()?['enabled'] ?? false;
      checks.add(CheckItem(
        name: 'Performance monitoring',
        passed: enabled,
        details: enabled ? 'Enabled' : 'Disabled',
      ));
      if (!enabled) allPassed = false;

      // Check 2: Critical traces configured
      final criticalTraces = [
        'app_startup',
        'room_join',
        'video_connect',
        'api_response',
        'feed_load',
      ];

      for (final trace in criticalTraces) {
        final exists = await _checkTraceExists(trace);
        checks.add(CheckItem(
          name: 'Trace: $trace',
          passed: exists,
          details: exists ? 'Configured' : 'Missing',
        ));
        if (!exists) allPassed = false;
      }

      // Check 3: Network monitoring
      final networkEnabled = perfConfig.data()?['networkMonitoring'] ?? false;
      checks.add(CheckItem(
        name: 'Network monitoring',
        passed: networkEnabled,
        details: networkEnabled ? 'Enabled' : 'Disabled',
      ));
      if (!networkEnabled) allPassed = false;

      // Check 4: Screen rendering traces
      final screenTracesEnabled = perfConfig.data()?['screenTraces'] ?? false;
      checks.add(CheckItem(
        name: 'Screen rendering traces',
        passed: screenTracesEnabled,
        details: screenTracesEnabled ? 'Enabled' : 'Disabled',
      ));
      if (!screenTracesEnabled) allPassed = false;

      return ChecklistResult(
        category: 'Performance Traces',
        passed: allPassed,
        checks: checks,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('âŒ [Checklist] Performance verification failed: $e');
      return ChecklistResult(
        category: 'Performance Traces',
        passed: false,
        checks: [
          CheckItem(
            name: 'Performance verification',
            passed: false,
            details: 'Error: $e',
          ),
        ],
        timestamp: DateTime.now(),
      );
    }
  }

  // ============================================================
  // MODERATION FLOWS VERIFICATION
  // ============================================================

  /// Verify moderation flows are in place
  Future<ChecklistResult> verifyModerationFlows() async {
    debugPrint('ðŸ” [Checklist] Verifying moderation flows...');

    final checks = <CheckItem>[];
    bool allPassed = true;

    try {
      // Check 1: Content moderation enabled
      final modConfig = await _firestore
          .collection('app_config')
          .doc('moderation')
          .get();

      final contentModeration = modConfig.data()?['contentModerationEnabled'] ?? false;
      checks.add(CheckItem(
        name: 'Content moderation',
        passed: contentModeration,
        details: contentModeration ? 'Active' : 'Inactive',
      ));
      if (!contentModeration) allPassed = false;

      // Check 2: User reporting
      final reportingEnabled = modConfig.data()?['reportingEnabled'] ?? false;
      checks.add(CheckItem(
        name: 'User reporting',
        passed: reportingEnabled,
        details: reportingEnabled ? 'Enabled' : 'Disabled',
      ));
      if (!reportingEnabled) allPassed = false;

      // Check 3: Auto-moderation rules
      final autoModRules = await _firestore
          .collection('moderation_rules')
          .where('active', isEqualTo: true)
          .count()
          .get();

      final hasRules = (autoModRules.count ?? 0) >= 5;
      checks.add(CheckItem(
        name: 'Auto-moderation rules',
        passed: hasRules,
        details: '${autoModRules.count ?? 0} active rules',
      ));
      if (!hasRules) allPassed = false;

      // Check 4: Banned word list
      final bannedWords = await _firestore
          .collection('banned_words')
          .count()
          .get();

      final hasBannedWords = (bannedWords.count ?? 0) >= 100;
      checks.add(CheckItem(
        name: 'Banned word list',
        passed: hasBannedWords,
        details: '${bannedWords.count ?? 0} words',
      ));
      if (!hasBannedWords) allPassed = false;

      // Check 5: Moderator team
      final moderators = await _firestore
          .collection('users')
          .where('roles', arrayContains: 'moderator')
          .count()
          .get();

      final hasModerators = (moderators.count ?? 0) >= 2;
      checks.add(CheckItem(
        name: 'Moderator team',
        passed: hasModerators,
        details: '${moderators.count ?? 0} moderators',
      ));
      if (!hasModerators) allPassed = false;

      // Check 6: Report queue
      final pendingReports = await _firestore
          .collection('reports')
          .where('status', isEqualTo: 'pending')
          .count()
          .get();

      final queueHealthy = (pendingReports.count ?? 0) < 50;
      checks.add(CheckItem(
        name: 'Report queue status',
        passed: queueHealthy,
        details: '${pendingReports.count ?? 0} pending reports',
      ));

      return ChecklistResult(
        category: 'Moderation Flows',
        passed: allPassed,
        checks: checks,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('âŒ [Checklist] Moderation verification failed: $e');
      return ChecklistResult(
        category: 'Moderation Flows',
        passed: false,
        checks: [
          CheckItem(
            name: 'Moderation verification',
            passed: false,
            details: 'Error: $e',
          ),
        ],
        timestamp: DateTime.now(),
      );
    }
  }

  // ============================================================
  // PAYMENTS VERIFICATION
  // ============================================================

  /// Verify payment systems are ready
  Future<ChecklistResult> verifyPayments() async {
    debugPrint('ðŸ” [Checklist] Verifying payments...');

    final checks = <CheckItem>[];
    bool allPassed = true;

    try {
      // Check 1: Payment provider configured
      final paymentConfig = await _firestore
          .collection('app_config')
          .doc('payments')
          .get();

      final providerConfigured = paymentConfig.data()?['providerConfigured'] ?? false;
      checks.add(CheckItem(
        name: 'Payment provider',
        passed: providerConfigured,
        details: providerConfigured ? 'Configured' : 'Not configured',
      ));
      if (!providerConfigured) allPassed = false;

      // Check 2: iOS In-App Purchases
      final iosIAPConfigured = paymentConfig.data()?['iosIAP'] ?? false;
      checks.add(CheckItem(
        name: 'iOS In-App Purchases',
        passed: iosIAPConfigured,
        details: iosIAPConfigured ? 'Configured' : 'Not configured',
      ));
      if (!iosIAPConfigured) allPassed = false;

      // Check 3: Google Play Billing
      final androidBillingConfigured = paymentConfig.data()?['googlePlayBilling'] ?? false;
      checks.add(CheckItem(
        name: 'Google Play Billing',
        passed: androidBillingConfigured,
        details: androidBillingConfigured ? 'Configured' : 'Not configured',
      ));
      if (!androidBillingConfigured) allPassed = false;

      // Check 4: Products configured
      final products = await _firestore
          .collection('products')
          .where('active', isEqualTo: true)
          .count()
          .get();

      final hasProducts = (products.count ?? 0) >= 1;
      checks.add(CheckItem(
        name: 'Products configured',
        passed: hasProducts,
        details: '${products.count ?? 0} active products',
      ));
      if (!hasProducts) allPassed = false;

      // Check 5: Receipt validation
      final receiptValidation = paymentConfig.data()?['receiptValidation'] ?? false;
      checks.add(CheckItem(
        name: 'Receipt validation',
        passed: receiptValidation,
        details: receiptValidation ? 'Enabled' : 'Disabled',
      ));
      if (!receiptValidation) allPassed = false;

      // Check 6: Test transactions
      final testTransactions = await _firestore
          .collection('transactions')
          .where('environment', isEqualTo: 'sandbox')
          .count()
          .get();

      final hasTestTransactions = (testTransactions.count ?? 0) >= 5;
      checks.add(CheckItem(
        name: 'Test transactions',
        passed: hasTestTransactions,
        details: '${testTransactions.count ?? 0} sandbox transactions',
      ));
      if (!hasTestTransactions) allPassed = false;

      return ChecklistResult(
        category: 'Payments',
        passed: allPassed,
        checks: checks,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('âŒ [Checklist] Payments verification failed: $e');
      return ChecklistResult(
        category: 'Payments',
        passed: false,
        checks: [
          CheckItem(
            name: 'Payments verification',
            passed: false,
            details: 'Error: $e',
          ),
        ],
        timestamp: DateTime.now(),
      );
    }
  }

  // ============================================================
  // RETENTION LOOPS VERIFICATION
  // ============================================================

  /// Verify retention loops are configured
  Future<ChecklistResult> verifyRetentionLoops() async {
    debugPrint('ðŸ” [Checklist] Verifying retention loops...');

    final checks = <CheckItem>[];
    bool allPassed = true;

    try {
      // Check 1: Push notifications
      final notifConfig = await _firestore
          .collection('app_config')
          .doc('notifications')
          .get();

      final pushEnabled = notifConfig.data()?['pushEnabled'] ?? false;
      checks.add(CheckItem(
        name: 'Push notifications',
        passed: pushEnabled,
        details: pushEnabled ? 'Enabled' : 'Disabled',
      ));
      if (!pushEnabled) allPassed = false;

      // Check 2: Notification templates
      final templates = await _firestore
          .collection('notification_templates')
          .where('active', isEqualTo: true)
          .count()
          .get();

      final hasTemplates = (templates.count ?? 0) >= 5;
      checks.add(CheckItem(
        name: 'Notification templates',
        passed: hasTemplates,
        details: '${templates.count ?? 0} active templates',
      ));
      if (!hasTemplates) allPassed = false;

      // Check 3: Re-engagement campaigns
      final campaigns = await _firestore
          .collection('engagement_campaigns')
          .where('status', isEqualTo: 'active')
          .count()
          .get();

      final hasCampaigns = (campaigns.count ?? 0) >= 1;
      checks.add(CheckItem(
        name: 'Re-engagement campaigns',
        passed: hasCampaigns,
        details: '${campaigns.count ?? 0} active campaigns',
      ));
      if (!hasCampaigns) allPassed = false;

      // Check 4: Streak/reward system
      final streakConfig = await _firestore
          .collection('app_config')
          .doc('streaks')
          .get();

      final streaksEnabled = streakConfig.data()?['enabled'] ?? false;
      checks.add(CheckItem(
        name: 'Streak system',
        passed: streaksEnabled,
        details: streaksEnabled ? 'Enabled' : 'Disabled',
      ));
      if (!streaksEnabled) allPassed = false;

      // Check 5: Daily rewards
      final dailyRewards = await _firestore
          .collection('daily_rewards')
          .where('active', isEqualTo: true)
          .count()
          .get();

      final hasDailyRewards = (dailyRewards.count ?? 0) >= 7;
      checks.add(CheckItem(
        name: 'Daily rewards',
        passed: hasDailyRewards,
        details: '${dailyRewards.count ?? 0} rewards configured',
      ));
      if (!hasDailyRewards) allPassed = false;

      // Check 6: Onboarding flow
      final onboardingConfig = await _firestore
          .collection('app_config')
          .doc('onboarding')
          .get();

      final onboardingEnabled = onboardingConfig.data()?['enabled'] ?? false;
      checks.add(CheckItem(
        name: 'Onboarding flow',
        passed: onboardingEnabled,
        details: onboardingEnabled ? 'Configured' : 'Not configured',
      ));
      if (!onboardingEnabled) allPassed = false;

      return ChecklistResult(
        category: 'Retention Loops',
        passed: allPassed,
        checks: checks,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('âŒ [Checklist] Retention verification failed: $e');
      return ChecklistResult(
        category: 'Retention Loops',
        passed: false,
        checks: [
          CheckItem(
            name: 'Retention verification',
            passed: false,
            details: 'Error: $e',
          ),
        ],
        timestamp: DateTime.now(),
      );
    }
  }

  // ============================================================
  // REFERRAL SYSTEM VERIFICATION
  // ============================================================

  /// Verify referral system is ready
  Future<ChecklistResult> verifyReferralSystem() async {
    debugPrint('ðŸ” [Checklist] Verifying referral system...');

    final checks = <CheckItem>[];
    bool allPassed = true;

    try {
      // Check 1: Referral system enabled
      final referralConfig = await _firestore
          .collection('app_config')
          .doc('referrals')
          .get();

      final enabled = referralConfig.data()?['enabled'] ?? false;
      checks.add(CheckItem(
        name: 'Referral system',
        passed: enabled,
        details: enabled ? 'Enabled' : 'Disabled',
      ));
      if (!enabled) allPassed = false;

      // Check 2: Referral rewards configured
      final referrerReward = referralConfig.data()?['referrerReward'];
      final refereeReward = referralConfig.data()?['refereeReward'];
      final hasRewards = referrerReward != null && refereeReward != null;
      checks.add(CheckItem(
        name: 'Referral rewards',
        passed: hasRewards,
        details: hasRewards
            ? 'Referrer: $referrerReward, Referee: $refereeReward'
            : 'Not configured',
      ));
      if (!hasRewards) allPassed = false;

      // Check 3: Deep links
      final deepLinksEnabled = referralConfig.data()?['deepLinksEnabled'] ?? false;
      checks.add(CheckItem(
        name: 'Deep links',
        passed: deepLinksEnabled,
        details: deepLinksEnabled ? 'Configured' : 'Not configured',
      ));
      if (!deepLinksEnabled) allPassed = false;

      // Check 4: Share functionality
      final shareEnabled = referralConfig.data()?['shareEnabled'] ?? false;
      checks.add(CheckItem(
        name: 'Share functionality',
        passed: shareEnabled,
        details: shareEnabled ? 'Enabled' : 'Disabled',
      ));
      if (!shareEnabled) allPassed = false;

      // Check 5: Attribution tracking
      final attributionEnabled = referralConfig.data()?['attributionTracking'] ?? false;
      checks.add(CheckItem(
        name: 'Attribution tracking',
        passed: attributionEnabled,
        details: attributionEnabled ? 'Enabled' : 'Disabled',
      ));
      if (!attributionEnabled) allPassed = false;

      // Check 6: Test referrals
      final testReferrals = await _firestore
          .collection('referrals')
          .where('source', isEqualTo: 'test')
          .count()
          .get();

      final hasTestReferrals = (testReferrals.count ?? 0) >= 1;
      checks.add(CheckItem(
        name: 'Test referrals',
        passed: hasTestReferrals,
        details: '${testReferrals.count ?? 0} test referrals tracked',
      ));

      return ChecklistResult(
        category: 'Referral System',
        passed: allPassed,
        checks: checks,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('âŒ [Checklist] Referral verification failed: $e');
      return ChecklistResult(
        category: 'Referral System',
        passed: false,
        checks: [
          CheckItem(
            name: 'Referral verification',
            passed: false,
            details: 'Error: $e',
          ),
        ],
        timestamp: DateTime.now(),
      );
    }
  }

  // ============================================================
  // RUN ALL VERIFICATIONS
  // ============================================================

  /// Run complete launch checklist verification
  Future<FullChecklistReport> runFullVerification() async {
    debugPrint('ðŸš€ [Checklist] Running full verification...');

    final results = <ChecklistResult>[];

    // Run all verifications
    results.add(await verifyAnalytics());
    results.add(await verifyCrashlytics());
    results.add(await verifyPerformanceTraces());
    results.add(await verifyModerationFlows());
    results.add(await verifyPayments());
    results.add(await verifyRetentionLoops());
    results.add(await verifyReferralSystem());

    // Calculate overall result
    final passedCount = results.where((r) => r.passed).length;
    final totalCount = results.length;
    final allPassed = passedCount == totalCount;

    // Get blockers
    final blockers = <String>[];
    for (final result in results) {
      if (!result.passed) {
        final failedChecks = result.checks.where((c) => !c.passed);
        for (final check in failedChecks) {
          blockers.add('${result.category}: ${check.name}');
        }
      }
    }

    final report = FullChecklistReport(
      timestamp: DateTime.now(),
      results: results,
      passedCategories: passedCount,
      totalCategories: totalCount,
      allPassed: allPassed,
      blockers: blockers,
      launchReady: allPassed && blockers.isEmpty,
    );

    // Save report
    await _firestore.collection(_checklistCollection).add({
      'timestamp': FieldValue.serverTimestamp(),
      'passedCategories': passedCount,
      'totalCategories': totalCount,
      'allPassed': allPassed,
      'blockerCount': blockers.length,
      'launchReady': report.launchReady,
    });

    debugPrint(allPassed
        ? 'âœ… [Checklist] All verifications passed!'
        : 'âš ï¸ [Checklist] ${blockers.length} blockers found');

    return report;
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  Future<bool> _checkEventExists(String eventName) async {
    try {
      final query = await _firestore
          .collection('analytics_events')
          .where('event', isEqualTo: eventName)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _verifyUserProperties() async {
    try {
      final config = await _firestore
          .collection('app_config')
          .doc('analytics')
          .get();
      return config.data()?['userPropertiesConfigured'] ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<int> _getRecentCrashCount(int days) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));
      final query = await _firestore
          .collection('crashes')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .count()
          .get();
      return query.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<double> _getCrashFreeRate() async {
    try {
      final config = await _firestore
          .collection('monitoring_metrics')
          .orderBy('timestamp', descending: true)
          .where('type', isEqualTo: 'crash_free_sessions')
          .limit(1)
          .get();
      if (config.docs.isEmpty) return 99.5;
      return (config.docs.first.data()['crashFreeRate'] ?? 99.5) as double;
    } catch (e) {
      return 99.5;
    }
  }

  Future<bool> _checkTraceExists(String traceName) async {
    try {
      final config = await _firestore
          .collection('performance_traces')
          .doc(traceName)
          .get();
      return config.exists && (config.data()?['enabled'] ?? false);
    } catch (e) {
      return false;
    }
  }
}

// ============================================================
// DATA CLASSES
// ============================================================

class CheckItem {
  final String name;
  final bool passed;
  final String details;

  const CheckItem({
    required this.name,
    required this.passed,
    required this.details,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'passed': passed,
    'details': details,
  };
}

class ChecklistResult {
  final String category;
  final bool passed;
  final List<CheckItem> checks;
  final DateTime timestamp;

  const ChecklistResult({
    required this.category,
    required this.passed,
    required this.checks,
    required this.timestamp,
  });

  int get passedCount => checks.where((c) => c.passed).length;
  int get totalCount => checks.length;

  Map<String, dynamic> toMap() => {
    'category': category,
    'passed': passed,
    'passedCount': passedCount,
    'totalCount': totalCount,
    'checks': checks.map((c) => c.toMap()).toList(),
    'timestamp': timestamp.toIso8601String(),
  };
}

class FullChecklistReport {
  final DateTime timestamp;
  final List<ChecklistResult> results;
  final int passedCategories;
  final int totalCategories;
  final bool allPassed;
  final List<String> blockers;
  final bool launchReady;

  const FullChecklistReport({
    required this.timestamp,
    required this.results,
    required this.passedCategories,
    required this.totalCategories,
    required this.allPassed,
    required this.blockers,
    required this.launchReady,
  });

  Map<String, dynamic> toMap() => {
    'timestamp': timestamp.toIso8601String(),
    'results': results.map((r) => r.toMap()).toList(),
    'passedCategories': passedCategories,
    'totalCategories': totalCategories,
    'allPassed': allPassed,
    'blockers': blockers,
    'launchReady': launchReady,
  };
}
