/// Launch Service
///
/// Manages launch phases including internal alpha, closed beta,
/// open beta, and production release.
library;

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/analytics/analytics_service.dart';

/// Service for managing app launch phases
class LaunchService {
  static LaunchService? _instance;
  static LaunchService get instance => _instance ??= LaunchService._();

  LaunchService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AnalyticsService _analytics = AnalyticsService.instance;

  // Firestore paths
  static const String _configDoc = 'app_config/launch';
  static const String _betaUsersCollection = 'beta_users';

  // Cached launch phase
  LaunchPhase? _cachedPhase;
  DateTime? _phaseCacheTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  // ============================================================
  // LAUNCH PHASE MANAGEMENT
  // ============================================================

  /// Get current launch phase
  Future<LaunchPhase> getCurrentPhase() async {
    try {
      // Check cache
      if (_cachedPhase != null &&
          _phaseCacheTime != null &&
          DateTime.now().difference(_phaseCacheTime!) < _cacheDuration) {
        return _cachedPhase!;
      }

      final doc = await _firestore.doc(_configDoc).get();
      final data = doc.data();

      if (data == null) {
        _cachedPhase = LaunchPhase.production;
      } else {
        _cachedPhase = LaunchPhase.fromString(data['phase'] ?? 'production');
      }

      _phaseCacheTime = DateTime.now();
      return _cachedPhase!;
    } catch (e) {
      debugPrint('âŒ [Launch] Failed to get phase: $e');
      return LaunchPhase.production;
    }
  }

  /// Start internal alpha phase
  Future<LaunchPhaseResult> startInternalAlpha({
    required List<String> allowedEmails,
    String? feedbackFormUrl,
  }) async {
    try {
      await _firestore.doc(_configDoc).set({
        'phase': 'internal_alpha',
        'startedAt': FieldValue.serverTimestamp(),
        'allowedEmails': allowedEmails,
        'feedbackFormUrl': feedbackFormUrl,
        'maxUsers': 50,
        'features': {
          'voiceRooms': true,
          'videoRooms': false,
          'payments': false,
          'referrals': false,
        },
      });

      _cachedPhase = LaunchPhase.internalAlpha;
      _phaseCacheTime = DateTime.now();

      await _analytics.logEvent(
        name: 'launch_phase_changed',
        parameters: {'phase': 'internal_alpha'},
      );

      debugPrint('âœ… [Launch] Internal alpha started');

      return const LaunchPhaseResult(
        success: true,
        phase: LaunchPhase.internalAlpha,
        message: 'Internal alpha phase started',
      );
    } catch (e) {
      debugPrint('âŒ [Launch] Failed to start internal alpha: $e');
      return LaunchPhaseResult(
        success: false,
        phase: LaunchPhase.internalAlpha,
        error: e.toString(),
      );
    }
  }

  /// Start closed beta phase
  Future<LaunchPhaseResult> startClosedBeta({
    int maxUsers = 500,
    bool requireInviteCode = true,
    String? feedbackFormUrl,
  }) async {
    try {
      await _firestore.doc(_configDoc).set({
        'phase': 'closed_beta',
        'startedAt': FieldValue.serverTimestamp(),
        'maxUsers': maxUsers,
        'requireInviteCode': requireInviteCode,
        'feedbackFormUrl': feedbackFormUrl,
        'features': {
          'voiceRooms': true,
          'videoRooms': true,
          'payments': false,
          'referrals': true,
        },
      });

      _cachedPhase = LaunchPhase.closedBeta;
      _phaseCacheTime = DateTime.now();

      await _analytics.logEvent(
        name: 'launch_phase_changed',
        parameters: {'phase': 'closed_beta', 'max_users': maxUsers},
      );

      debugPrint('âœ… [Launch] Closed beta started');

      return LaunchPhaseResult(
        success: true,
        phase: LaunchPhase.closedBeta,
        message: 'Closed beta phase started with $maxUsers max users',
      );
    } catch (e) {
      debugPrint('âŒ [Launch] Failed to start closed beta: $e');
      return LaunchPhaseResult(
        success: false,
        phase: LaunchPhase.closedBeta,
        error: e.toString(),
      );
    }
  }

  /// Start open beta phase
  Future<LaunchPhaseResult> startOpenBeta({
    String? feedbackFormUrl,
    bool enablePayments = true,
  }) async {
    try {
      await _firestore.doc(_configDoc).set({
        'phase': 'open_beta',
        'startedAt': FieldValue.serverTimestamp(),
        'feedbackFormUrl': feedbackFormUrl,
        'features': {
          'voiceRooms': true,
          'videoRooms': true,
          'payments': enablePayments,
          'referrals': true,
          'spotlight': true,
        },
      });

      _cachedPhase = LaunchPhase.openBeta;
      _phaseCacheTime = DateTime.now();

      await _analytics.logEvent(
        name: 'launch_phase_changed',
        parameters: {'phase': 'open_beta'},
      );

      debugPrint('âœ… [Launch] Open beta started');

      return const LaunchPhaseResult(
        success: true,
        phase: LaunchPhase.openBeta,
        message: 'Open beta phase started',
      );
    } catch (e) {
      debugPrint('âŒ [Launch] Failed to start open beta: $e');
      return LaunchPhaseResult(
        success: false,
        phase: LaunchPhase.openBeta,
        error: e.toString(),
      );
    }
  }

  /// Go to production
  Future<LaunchPhaseResult> goToProduction() async {
    try {
      await _firestore.doc(_configDoc).set({
        'phase': 'production',
        'launchedAt': FieldValue.serverTimestamp(),
        'features': {
          'voiceRooms': true,
          'videoRooms': true,
          'payments': true,
          'referrals': true,
          'spotlight': true,
          'events': true,
        },
      });

      _cachedPhase = LaunchPhase.production;
      _phaseCacheTime = DateTime.now();

      await _analytics.logEvent(
        name: 'app_launched_production',
        parameters: {},
      );

      debugPrint('ðŸš€ [Launch] Production launched!');

      return const LaunchPhaseResult(
        success: true,
        phase: LaunchPhase.production,
        message: 'Congratulations! App is now in production!',
      );
    } catch (e) {
      debugPrint('âŒ [Launch] Failed to go to production: $e');
      return LaunchPhaseResult(
        success: false,
        phase: LaunchPhase.production,
        error: e.toString(),
      );
    }
  }

  // ============================================================
  // BETA USER MANAGEMENT
  // ============================================================

  /// Check if user is allowed in current phase
  Future<bool> isUserAllowed(String userId, String email) async {
    try {
      final phase = await getCurrentPhase();

      switch (phase) {
        case LaunchPhase.internalAlpha:
          return await _isInternalAlphaUser(email);
        case LaunchPhase.closedBeta:
          return await _isClosedBetaUser(userId);
        case LaunchPhase.openBeta:
        case LaunchPhase.production:
          return true;
      }
    } catch (e) {
      debugPrint('âŒ [Launch] Failed to check user access: $e');
      return false;
    }
  }

  Future<bool> _isInternalAlphaUser(String email) async {
    final doc = await _firestore.doc(_configDoc).get();
    final allowedEmails = List<String>.from(doc.data()?['allowedEmails'] ?? []);
    return allowedEmails.contains(email.toLowerCase());
  }

  Future<bool> _isClosedBetaUser(String userId) async {
    final betaDoc = await _firestore
        .collection(_betaUsersCollection)
        .doc(userId)
        .get();
    return betaDoc.exists;
  }

  /// Add user to beta
  Future<void> addBetaUser(String userId, String email, {String? inviteCode}) async {
    try {
      await _firestore.collection(_betaUsersCollection).doc(userId).set({
        'email': email,
        'inviteCode': inviteCode,
        'joinedAt': FieldValue.serverTimestamp(),
        'feedbackCount': 0,
      });

      await _analytics.logEvent(
        name: 'beta_user_added',
        parameters: {'user_id': userId},
      );
    } catch (e) {
      debugPrint('âŒ [Launch] Failed to add beta user: $e');
    }
  }

  /// Get beta user count
  Future<int> getBetaUserCount() async {
    try {
      final snapshot = await _firestore
          .collection(_betaUsersCollection)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('âŒ [Launch] Failed to get beta count: $e');
      return 0;
    }
  }

  // ============================================================
  // FEATURE FLAGS
  // ============================================================

  /// Check if a feature is enabled in current phase
  Future<bool> isFeatureEnabled(String featureName) async {
    try {
      final doc = await _firestore.doc(_configDoc).get();
      final features = doc.data()?['features'] as Map<String, dynamic>? ?? {};
      return features[featureName] ?? false;
    } catch (e) {
      debugPrint('âŒ [Launch] Failed to check feature: $e');
      return false;
    }
  }

  /// Get all feature flags
  Future<Map<String, bool>> getFeatureFlags() async {
    try {
      final doc = await _firestore.doc(_configDoc).get();
      final features = doc.data()?['features'] as Map<String, dynamic>? ?? {};
      return features.map((key, value) => MapEntry(key, value as bool));
    } catch (e) {
      debugPrint('âŒ [Launch] Failed to get features: $e');
      return {};
    }
  }

  // ============================================================
  // LAUNCH STATUS
  // ============================================================

  /// Get launch status
  Future<LaunchStatus> getLaunchStatus() async {
    try {
      final phase = await getCurrentPhase();
      final doc = await _firestore.doc(_configDoc).get();
      final data = doc.data() ?? {};

      final betaCount = await getBetaUserCount();
      final features = await getFeatureFlags();

      return LaunchStatus(
        phase: phase,
        startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
        betaUserCount: betaCount,
        maxBetaUsers: data['maxUsers'] as int?,
        feedbackFormUrl: data['feedbackFormUrl'] as String?,
        enabledFeatures: features,
      );
    } catch (e) {
      debugPrint('âŒ [Launch] Failed to get status: $e');
      return const LaunchStatus(phase: LaunchPhase.production);
    }
  }

  /// Clear phase cache
  void clearCache() {
    _cachedPhase = null;
    _phaseCacheTime = null;
  }
}

// ============================================================
// ENUMS
// ============================================================

enum LaunchPhase {
  internalAlpha,
  closedBeta,
  openBeta,
  production;

  static LaunchPhase fromString(String value) {
    switch (value) {
      case 'internal_alpha':
        return LaunchPhase.internalAlpha;
      case 'closed_beta':
        return LaunchPhase.closedBeta;
      case 'open_beta':
        return LaunchPhase.openBeta;
      case 'production':
      default:
        return LaunchPhase.production;
    }
  }

  String get displayName {
    switch (this) {
      case LaunchPhase.internalAlpha:
        return 'Internal Alpha';
      case LaunchPhase.closedBeta:
        return 'Closed Beta';
      case LaunchPhase.openBeta:
        return 'Open Beta';
      case LaunchPhase.production:
        return 'Production';
    }
  }

  String get badge {
    switch (this) {
      case LaunchPhase.internalAlpha:
        return 'ðŸ”¬ Alpha';
      case LaunchPhase.closedBeta:
        return 'ðŸ§ª Beta';
      case LaunchPhase.openBeta:
        return 'ðŸš€ Open Beta';
      case LaunchPhase.production:
        return '';
    }
  }
}

// ============================================================
// DATA CLASSES
// ============================================================

class LaunchPhaseResult {
  final bool success;
  final LaunchPhase phase;
  final String? message;
  final String? error;

  const LaunchPhaseResult({
    required this.success,
    required this.phase,
    this.message,
    this.error,
  });
}

class LaunchStatus {
  final LaunchPhase phase;
  final DateTime? startedAt;
  final int betaUserCount;
  final int? maxBetaUsers;
  final String? feedbackFormUrl;
  final Map<String, bool> enabledFeatures;

  const LaunchStatus({
    required this.phase,
    this.startedAt,
    this.betaUserCount = 0,
    this.maxBetaUsers,
    this.feedbackFormUrl,
    this.enabledFeatures = const {},
  });

  bool get isBeta =>
      phase == LaunchPhase.internalAlpha ||
      phase == LaunchPhase.closedBeta ||
      phase == LaunchPhase.openBeta;

  double? get betaCapacityPercent {
    if (maxBetaUsers == null || maxBetaUsers == 0) return null;
    return betaUserCount / maxBetaUsers!;
  }
}
