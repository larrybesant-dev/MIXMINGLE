/// Onboarding Optimization Service
///
/// Provides optimization tracking for the onboarding funnel,
/// auto-join welcome room functionality, and first interaction nudges.
library;

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/analytics/analytics_service.dart';
import 'welcome_room_service.dart';

/// Service for optimizing onboarding flow and tracking funnel metrics
class OnboardingOptimizationService {
  static OnboardingOptimizationService? _instance;
  static OnboardingOptimizationService get instance =>
      _instance ??= OnboardingOptimizationService._();

  OnboardingOptimizationService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AnalyticsService _analytics = AnalyticsService.instance;
  final WelcomeRoomService _welcomeRoom = WelcomeRoomService.instance;

  // Prefs keys
  static const String _onboardingStartTimeKey = 'onboarding_start_time';
  static const String _firstInteractionCompletedKey = 'first_interaction_completed';
  static const String _welcomeRoomJoinedKey = 'welcome_room_joined';

  /// Track onboarding start
  /// Call this when user begins the onboarding flow
  Future<void> trackOnboardingStart(String? userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final startTime = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt(_onboardingStartTimeKey, startTime);

      // Log analytics event
      await _analytics.logEvent(
        name: 'onboarding_funnel_start',
        parameters: {
          'user_id': userId ?? 'anonymous',
          'timestamp': startTime,
        },
      );

      // Log to Firestore for funnel analysis
      if (userId != null) {
        await _firestore.collection('analytics_events').add({
          'event': 'onboarding_start',
          'userId': userId,
          'timestamp': FieldValue.serverTimestamp(),
          'platform': defaultTargetPlatform.name,
        });
      }

      debugPrint('ðŸš€ [Onboarding] Funnel start tracked');
    } catch (e) {
      debugPrint('âŒ [Onboarding] Failed to track start: $e');
    }
  }

  /// Track onboarding complete with duration metrics
  /// Call this when user finishes all onboarding steps
  Future<void> trackOnboardingComplete(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final startTime = prefs.getInt(_onboardingStartTimeKey);
      final endTime = DateTime.now().millisecondsSinceEpoch;

      int? durationSeconds;
      if (startTime != null) {
        durationSeconds = ((endTime - startTime) / 1000).round();
      }

      // Log analytics event
      await _analytics.logEvent(
        name: 'onboarding_funnel_complete',
        parameters: {
          'user_id': userId,
          'duration_seconds': durationSeconds ?? 0,
          'timestamp': endTime,
        },
      );

      // Log to Firestore
      await _firestore.collection('analytics_events').add({
        'event': 'onboarding_complete',
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'durationSeconds': durationSeconds,
        'platform': defaultTargetPlatform.name,
      });

      // Update user document
      await _firestore.collection('users').doc(userId).update({
        'onboardingCompletedAt': FieldValue.serverTimestamp(),
        'onboardingDurationSeconds': durationSeconds,
      });

      debugPrint('âœ… [Onboarding] Funnel complete tracked (${durationSeconds}s)');
    } catch (e) {
      debugPrint('âŒ [Onboarding] Failed to track complete: $e');
    }
  }

  /// Auto-join welcome room after onboarding completion
  /// Returns the room ID if successful, null otherwise
  Future<String?> autoJoinWelcomeRoom(String userId, String userName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alreadyJoined = prefs.getBool(_welcomeRoomJoinedKey) ?? false;

      if (alreadyJoined) {
        debugPrint('â„¹ï¸ [Onboarding] Welcome room already joined');
        return null;
      }

      // Join the welcome room
      final roomId = await _welcomeRoom.joinWelcomeRoom(userId, userName);

      if (roomId != null) {
        await prefs.setBool(_welcomeRoomJoinedKey, true);

        // Track the auto-join event
        await _analytics.logEvent(
          name: 'welcome_room_auto_joined',
          parameters: {
            'user_id': userId,
            'room_id': roomId,
          },
        );

        debugPrint('âœ… [Onboarding] Auto-joined welcome room: $roomId');
      }

      return roomId;
    } catch (e) {
      debugPrint('âŒ [Onboarding] Failed to auto-join welcome room: $e');
      return null;
    }
  }

  /// Nudge user for first interaction
  /// Returns true if nudge should be shown
  Future<bool> shouldNudgeFirstInteraction(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final completed = prefs.getBool(_firstInteractionCompletedKey) ?? false;

      if (completed) {
        return false;
      }

      // Check if user has had any interactions
      final interactionsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('interactions')
          .limit(1)
          .get();

      return interactionsSnapshot.docs.isEmpty;
    } catch (e) {
      debugPrint('âŒ [Onboarding] Error checking first interaction: $e');
      return false;
    }
  }

  /// Nudge user to complete first interaction
  /// Returns the nudge message and action
  Future<FirstInteractionNudge?> nudgeFirstInteraction(String userId) async {
    try {
      final shouldNudge = await shouldNudgeFirstInteraction(userId);

      if (!shouldNudge) {
        return null;
      }

      // Track nudge shown
      await _analytics.logEvent(
        name: 'first_interaction_nudge_shown',
        parameters: {'user_id': userId},
      );

      return const FirstInteractionNudge(
        title: 'Say Hello! ðŸ‘‹',
        message: 'Join a room and start chatting to make your first connection!',
        actionLabel: 'Find a Room',
        actionRoute: '/discover',
      );
    } catch (e) {
      debugPrint('âŒ [Onboarding] Failed to create nudge: $e');
      return null;
    }
  }

  /// Mark first interaction as completed
  Future<void> markFirstInteractionComplete(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_firstInteractionCompletedKey, true);

      await _analytics.logEvent(
        name: 'first_interaction_completed',
        parameters: {'user_id': userId},
      );

      debugPrint('âœ… [Onboarding] First interaction marked complete');
    } catch (e) {
      debugPrint('âŒ [Onboarding] Failed to mark first interaction: $e');
    }
  }

  /// Get onboarding funnel metrics for a user
  Future<OnboardingMetrics?> getOnboardingMetrics(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      final data = doc.data();

      if (data == null) return null;

      return OnboardingMetrics(
        completedAt: (data['onboardingCompletedAt'] as Timestamp?)?.toDate(),
        durationSeconds: data['onboardingDurationSeconds'] as int?,
        welcomeRoomJoined: data['welcomeRoomJoined'] as bool? ?? false,
        firstInteractionCompleted: data['firstInteractionCompleted'] as bool? ?? false,
      );
    } catch (e) {
      debugPrint('âŒ [Onboarding] Failed to get metrics: $e');
      return null;
    }
  }

  /// Track onboarding step with timing
  Future<void> trackOnboardingStep({
    required String userId,
    required int stepIndex,
    required String stepName,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'onboarding_step_viewed',
        parameters: {
          'user_id': userId,
          'step_index': stepIndex,
          'step_name': stepName,
        },
      );

      await _firestore.collection('analytics_events').add({
        'event': 'onboarding_step',
        'userId': userId,
        'stepIndex': stepIndex,
        'stepName': stepName,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('âŒ [Onboarding] Failed to track step: $e');
    }
  }

  /// Reset onboarding optimization flags (for testing)
  Future<void> resetOptimizationFlags() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_onboardingStartTimeKey);
      await prefs.remove(_firstInteractionCompletedKey);
      await prefs.remove(_welcomeRoomJoinedKey);
      debugPrint('ðŸ”„ [Onboarding] Optimization flags reset');
    } catch (e) {
      debugPrint('âŒ [Onboarding] Failed to reset flags: $e');
    }
  }
}

/// Data class for first interaction nudge
class FirstInteractionNudge {
  final String title;
  final String message;
  final String actionLabel;
  final String actionRoute;

  const FirstInteractionNudge({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.actionRoute,
  });
}

/// Data class for onboarding metrics
class OnboardingMetrics {
  final DateTime? completedAt;
  final int? durationSeconds;
  final bool welcomeRoomJoined;
  final bool firstInteractionCompleted;

  const OnboardingMetrics({
    this.completedAt,
    this.durationSeconds,
    required this.welcomeRoomJoined,
    required this.firstInteractionCompleted,
  });

  bool get isOnboardingComplete => completedAt != null;

  double? get completionRate {
    int completed = 0;
    const int total = 3;

    if (isOnboardingComplete) completed++;
    if (welcomeRoomJoined) completed++;
    if (firstInteractionCompleted) completed++;

    return completed / total;
  }
}
