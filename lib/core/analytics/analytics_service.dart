/// Analytics Service
///
/// Centralized analytics tracking using Firebase Analytics.
/// Provides methods for logging events, setting user properties,
/// and tracking funnels throughout the app.
library;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'analytics_events.dart';

/// Singleton service for analytics tracking
class AnalyticsService {
  static AnalyticsService? _instance;
  static AnalyticsService get instance => _instance ??= AnalyticsService._();

  AnalyticsService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Get the analytics observer for navigation tracking
  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // ============================================================
  // CORE METHODS
  // ============================================================

  /// Log a custom event with optional parameters
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters,
      );
      debugPrint('ðŸ“Š [Analytics] Event logged: $name');
    } catch (e) {
      debugPrint('âŒ [Analytics] Failed to log event $name: $e');
    }
  }

  /// Set the current user ID for analytics
  Future<void> setUserId(String? userId) async {
    try {
      await _analytics.setUserId(id: userId);
      debugPrint('ðŸ“Š [Analytics] User ID set: ${userId ?? 'null'}');
    } catch (e) {
      debugPrint('âŒ [Analytics] Failed to set user ID: $e');
    }
  }

  /// Set user properties for segmentation
  Future<void> setUserProperties({
    String? tier,
    String? platform,
    String? version,
  }) async {
    try {
      if (tier != null) {
        await _analytics.setUserProperty(
          name: AnalyticsUserProperties.membershipTier,
          value: tier,
        );
      }
      if (platform != null) {
        await _analytics.setUserProperty(
          name: AnalyticsUserProperties.platform,
          value: platform,
        );
      }
      if (version != null) {
        await _analytics.setUserProperty(
          name: AnalyticsUserProperties.appVersion,
          value: version,
        );
      }
      debugPrint('ðŸ“Š [Analytics] User properties set');
    } catch (e) {
      debugPrint('âŒ [Analytics] Failed to set user properties: $e');
    }
  }

  /// Set a single user property
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
      debugPrint('ðŸ“Š [Analytics] User property set: $name = $value');
    } catch (e) {
      debugPrint('âŒ [Analytics] Failed to set user property: $e');
    }
  }

  /// Log screen view for navigation tracking
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
      debugPrint('ðŸ“Š [Analytics] Screen view: $screenName');
    } catch (e) {
      debugPrint('âŒ [Analytics] Failed to log screen view: $e');
    }
  }

  // ============================================================
  // ONBOARDING EVENTS
  // ============================================================

  Future<void> logOnboardingStarted() async {
    await logEvent(name: AnalyticsEvents.onboardingStarted);
  }

  Future<void> logOnboardingCompleted() async {
    await logEvent(name: AnalyticsEvents.onboardingCompleted);
  }

  Future<void> logOnboardingSkipped({int? step}) async {
    await logEvent(
      name: AnalyticsEvents.onboardingSkipped,
      parameters: step != null ? {AnalyticsParams.step: step} : null,
    );
  }

  Future<void> logOnboardingStepViewed(int step) async {
    await logEvent(
      name: AnalyticsEvents.onboardingStepViewed,
      parameters: {AnalyticsParams.step: step},
    );
  }

  // ============================================================
  // AUTH EVENTS
  // ============================================================

  Future<void> logLoginSuccess({required String method}) async {
    await logEvent(
      name: AnalyticsEvents.loginSuccess,
      parameters: {AnalyticsParams.authMethod: method},
    );
  }

  Future<void> logLoginFailed({required String method, String? error}) async {
    await logEvent(
      name: AnalyticsEvents.loginFailed,
      parameters: {
        AnalyticsParams.authMethod: method,
        if (error != null) AnalyticsParams.errorMessage: error,
      },
    );
  }

  Future<void> logLogout() async {
    await logEvent(name: AnalyticsEvents.logout);
  }

  Future<void> logSignupCompleted({required String method}) async {
    await logEvent(
      name: AnalyticsEvents.signupCompleted,
      parameters: {AnalyticsParams.authMethod: method},
    );
  }

  // ============================================================
  // MEMBERSHIP EVENTS
  // ============================================================

  Future<void> logMembershipUpgraded({
    required String fromTier,
    required String toTier,
    required String productId,
    double? price,
  }) async {
    await logEvent(
      name: AnalyticsEvents.membershipUpgraded,
      parameters: {
        'from_tier': fromTier,
        'to_tier': toTier,
        AnalyticsParams.productId: productId,
        if (price != null) AnalyticsParams.price: price,
      },
    );
  }

  Future<void> logMembershipDowngraded({
    required String fromTier,
    required String toTier,
  }) async {
    await logEvent(
      name: AnalyticsEvents.membershipDowngraded,
      parameters: {
        'from_tier': fromTier,
        'to_tier': toTier,
      },
    );
  }

  Future<void> logMembershipRenewed({required String tier}) async {
    await logEvent(
      name: AnalyticsEvents.membershipRenewed,
      parameters: {AnalyticsParams.membershipTier: tier},
    );
  }

  Future<void> logVipRoomAttempt({required String currentTier}) async {
    await logEvent(
      name: AnalyticsEvents.vipRoomAttempt,
      parameters: {AnalyticsParams.membershipTier: currentTier},
    );
  }

  /// Log any membership tier change
  Future<void> logMembershipChanged({
    required String tier,
    required String previousTier,
  }) async {
    await logEvent(
      name: 'membership_changed',
      parameters: {
        'tier': tier,
        'previous_tier': previousTier,
      },
    );
  }

  /// Log VIP conversion funnel step
  Future<void> logVipConversionFunnelStep({
    required String step,
    String? tier,
  }) async {
    await logEvent(
      name: 'vip_conversion_funnel',
      parameters: {
        'step': step,
        if (tier != null) 'tier': tier,
      },
    );
  }

  // ============================================================
  // COIN EVENTS
  // ============================================================

  Future<void> logCoinStoreOpened() async {
    await logEvent(name: AnalyticsEvents.coinStoreOpened);
  }

  Future<void> logCoinPurchaseStarted({
    required String packageId,
    required int coinAmount,
    required double price,
  }) async {
    await logEvent(
      name: AnalyticsEvents.coinPurchaseStarted,
      parameters: {
        AnalyticsParams.productId: packageId,
        AnalyticsParams.coinAmount: coinAmount,
        AnalyticsParams.price: price,
      },
    );
  }

  Future<void> logCoinPurchaseCompleted({
    required String packageId,
    required int coinAmount,
    required double price,
  }) async {
    await logEvent(
      name: AnalyticsEvents.coinPurchaseCompleted,
      parameters: {
        AnalyticsParams.productId: packageId,
        AnalyticsParams.coinAmount: coinAmount,
        AnalyticsParams.price: price,
      },
    );
  }

  Future<void> logCoinPurchaseFailed({
    required String packageId,
    required String error,
  }) async {
    await logEvent(
      name: AnalyticsEvents.coinPurchaseFailed,
      parameters: {
        AnalyticsParams.productId: packageId,
        AnalyticsParams.errorMessage: error,
      },
    );
  }

  Future<void> logCoinsSpentGift({
    required int amount,
    required String recipientId,
  }) async {
    await logEvent(
      name: AnalyticsEvents.coinsSpentGift,
      parameters: {
        AnalyticsParams.coinAmount: amount,
        AnalyticsParams.targetUserId: recipientId,
      },
    );
  }

  Future<void> logCoinsSpentSpotlight({required int amount}) async {
    await logEvent(
      name: AnalyticsEvents.coinsSpentSpotlight,
      parameters: {AnalyticsParams.coinAmount: amount},
    );
  }

  // ============================================================
  // ROOM EVENTS
  // ============================================================

  Future<void> logRoomJoinStarted({
    required String roomId,
    String? roomType,
  }) async {
    await logEvent(
      name: AnalyticsEvents.roomJoinStarted,
      parameters: {
        AnalyticsParams.roomId: roomId,
        if (roomType != null) AnalyticsParams.roomType: roomType,
      },
    );
  }

  Future<void> logRoomJoinSuccess({
    required String roomId,
    String? roomType,
    int? participantCount,
    int? loadTimeMs,
  }) async {
    await logEvent(
      name: AnalyticsEvents.roomJoinSuccess,
      parameters: {
        AnalyticsParams.roomId: roomId,
        if (roomType != null) AnalyticsParams.roomType: roomType,
        if (participantCount != null)
          AnalyticsParams.participantCount: participantCount,
        if (loadTimeMs != null) AnalyticsParams.loadTime: loadTimeMs,
      },
    );
  }

  Future<void> logRoomJoinFailed({
    required String roomId,
    required String error,
  }) async {
    await logEvent(
      name: AnalyticsEvents.roomJoinFailed,
      parameters: {
        AnalyticsParams.roomId: roomId,
        AnalyticsParams.errorMessage: error,
      },
    );
  }

  Future<void> logRoomLeave({
    required String roomId,
    int? durationSeconds,
  }) async {
    await logEvent(
      name: AnalyticsEvents.roomLeave,
      parameters: {
        AnalyticsParams.roomId: roomId,
        if (durationSeconds != null) AnalyticsParams.duration: durationSeconds,
      },
    );
  }

  Future<void> logCameraEnabled({required String roomId}) async {
    await logEvent(
      name: AnalyticsEvents.cameraEnabled,
      parameters: {AnalyticsParams.roomId: roomId},
    );
  }

  Future<void> logCameraDisabled({required String roomId}) async {
    await logEvent(
      name: AnalyticsEvents.cameraDisabled,
      parameters: {AnalyticsParams.roomId: roomId},
    );
  }

  Future<void> logMicEnabled({required String roomId}) async {
    await logEvent(
      name: AnalyticsEvents.micEnabled,
      parameters: {AnalyticsParams.roomId: roomId},
    );
  }

  Future<void> logMicDisabled({required String roomId}) async {
    await logEvent(
      name: AnalyticsEvents.micDisabled,
      parameters: {AnalyticsParams.roomId: roomId},
    );
  }

  // ============================================================
  // MODERATION EVENTS
  // ============================================================

  Future<void> logReportSubmitted({
    required String reportedUserId,
    required String reason,
    String? roomId,
  }) async {
    await logEvent(
      name: AnalyticsEvents.reportSubmitted,
      parameters: {
        AnalyticsParams.reportedUserId: reportedUserId,
        AnalyticsParams.reportReason: reason,
        if (roomId != null) AnalyticsParams.roomId: roomId,
      },
    );
  }

  Future<void> logUserBlocked({required String blockedUserId}) async {
    await logEvent(
      name: AnalyticsEvents.userBlocked,
      parameters: {AnalyticsParams.targetUserId: blockedUserId},
    );
  }

  Future<void> logUserUnblocked({required String unblockedUserId}) async {
    await logEvent(
      name: AnalyticsEvents.userUnblocked,
      parameters: {AnalyticsParams.targetUserId: unblockedUserId},
    );
  }

  Future<void> logHostActionTaken({
    required String action,
    required String targetUserId,
    required String roomId,
  }) async {
    await logEvent(
      name: AnalyticsEvents.hostActionTaken,
      parameters: {
        AnalyticsParams.actionType: action,
        AnalyticsParams.targetUserId: targetUserId,
        AnalyticsParams.roomId: roomId,
      },
    );
  }

  Future<void> logAdminReportReviewed({
    required String reportId,
    required String action,
  }) async {
    await logEvent(
      name: AnalyticsEvents.adminReportReviewed,
      parameters: {
        'report_id': reportId,
        AnalyticsParams.actionType: action,
      },
    );
  }

  Future<void> logAdminUserBanned({required String bannedUserId}) async {
    await logEvent(
      name: AnalyticsEvents.adminUserBanned,
      parameters: {AnalyticsParams.targetUserId: bannedUserId},
    );
  }

  // ============================================================
  // ENGAGEMENT EVENTS
  // ============================================================

  Future<void> logMessageSent({
    required String roomId,
    String? messageType,
  }) async {
    await logEvent(
      name: AnalyticsEvents.messageSent,
      parameters: {
        AnalyticsParams.roomId: roomId,
        if (messageType != null) AnalyticsParams.messageType: messageType,
      },
    );
  }

  Future<void> logFirstMessageSent({required String roomId}) async {
    await logEvent(
      name: AnalyticsEvents.firstMessageSent,
      parameters: {AnalyticsParams.roomId: roomId},
    );
  }

  Future<void> logReactionSent({
    required String roomId,
    required String reactionType,
  }) async {
    await logEvent(
      name: AnalyticsEvents.reactionSent,
      parameters: {
        AnalyticsParams.roomId: roomId,
        AnalyticsParams.reactionType: reactionType,
      },
    );
  }

  Future<void> logSpotlightActivated({
    required String roomId,
    required String targetUserId,
  }) async {
    await logEvent(
      name: AnalyticsEvents.spotlightActivated,
      parameters: {
        AnalyticsParams.roomId: roomId,
        AnalyticsParams.targetUserId: targetUserId,
      },
    );
  }

  Future<void> logWindowOpened({required String windowType}) async {
    await logEvent(
      name: AnalyticsEvents.windowOpened,
      parameters: {AnalyticsParams.windowType: windowType},
    );
  }

  Future<void> logWindowClosed({required String windowType}) async {
    await logEvent(
      name: AnalyticsEvents.windowClosed,
      parameters: {AnalyticsParams.windowType: windowType},
    );
  }

  // ============================================================
  // FUNNEL TRACKING
  // ============================================================

  /// Log a funnel step for conversion tracking
  Future<void> logFunnelStep({
    required String funnelName,
    required int step,
    required String stepName,
    bool success = true,
  }) async {
    await logEvent(
      name: 'funnel_step',
      parameters: {
        AnalyticsParams.funnelName: funnelName,
        AnalyticsParams.step: step,
        'step_name': stepName,
        AnalyticsParams.success: success ? 1 : 0,
      },
    );
  }

  /// Log new user activation funnel
  Future<void> logNewUserActivationStep({
    required int step,
    required String stepName,
  }) async {
    await logFunnelStep(
      funnelName: 'new_user_activation',
      step: step,
      stepName: stepName,
    );
  }

  /// Log monetization funnel
  Future<void> logMonetizationFunnelStep({
    required int step,
    required String stepName,
  }) async {
    await logFunnelStep(
      funnelName: 'monetization',
      step: step,
      stepName: stepName,
    );
  }

  /// Log VIP conversion funnel
  Future<void> logVipConversionStep({
    required int step,
    required String stepName,
  }) async {
    await logFunnelStep(
      funnelName: 'vip_conversion',
      step: step,
      stepName: stepName,
    );
  }

  // ============================================================
  // ERROR TRACKING
  // ============================================================

  Future<void> logError({
    required String errorType,
    required String message,
    String? stackTrace,
  }) async {
    await logEvent(
      name: AnalyticsEvents.errorOccurred,
      parameters: {
        'error_type': errorType,
        AnalyticsParams.errorMessage: message,
        if (stackTrace != null) 'stack_trace': stackTrace.substring(0, 100),
      },
    );
  }

  // ============================================================
  // TYPED HELPERS (Phase 7)
  // ============================================================

  /// Simple named funnel milestone helper: logFunnelMilestone('first_room_join')
  Future<void> logFunnelMilestone(String name, {Map<String, Object>? params}) async {
    await logEvent(name: name, parameters: params);
  }

  /// Generic engagement event wrapper
  Future<void> logEngagement(
    String name, {
    Map<String, Object>? params,
  }) async {
    await logEvent(name: name, parameters: params);
  }

  /// Typed ad event helper
  Future<void> logAdEvent({
    required String type,
    required String adId,
    required String advertiserId,
    required String placement,
    Map<String, Object>? extra,
  }) async {
    await logEvent(
      name: type,
      parameters: {
        AnalyticsParams.adId: adId,
        AnalyticsParams.advertiserId: advertiserId,
        AnalyticsParams.placement: placement,
        ...?extra,
      },
    );
  }

  // ============================================================
  // AD ANALYTICS
  // ============================================================

  Future<void> logAdImpression({
    required String adId,
    required String advertiserId,
    required String placement,
  }) async {
    await logAdEvent(
      type: AnalyticsEvents.adImpression,
      adId: adId,
      advertiserId: advertiserId,
      placement: placement,
    );
  }

  Future<void> logAdClick({
    required String adId,
    required String advertiserId,
    required String placement,
  }) async {
    await logAdEvent(
      type: AnalyticsEvents.adClick,
      adId: adId,
      advertiserId: advertiserId,
      placement: placement,
    );
  }

  Future<void> logAdSkipped({
    required String adId,
    required String advertiserId,
    required String placement,
  }) async {
    await logAdEvent(
      type: AnalyticsEvents.adSkipped,
      adId: adId,
      advertiserId: advertiserId,
      placement: placement,
    );
  }

  // ============================================================
  // FEED ENGAGEMENT
  // ============================================================

  Future<void> logFeedPostLiked({required String postId}) async {
    await logEvent(
      name: AnalyticsEvents.feedPostLiked,
      parameters: {AnalyticsParams.postId: postId},
    );
  }

  Future<void> logFeedPostViewed({required String postId}) async {
    await logEvent(
      name: AnalyticsEvents.feedPostViewed,
      parameters: {AnalyticsParams.postId: postId},
    );
  }

  Future<void> logFeedPostCommented({required String postId}) async {
    await logEvent(
      name: AnalyticsEvents.feedPostCommented,
      parameters: {AnalyticsParams.postId: postId},
    );
  }

  // ============================================================
  // MATCH / INBOX ENGAGEMENT
  // ============================================================

  Future<void> logMatchTileOpened({required String matchId}) async {
    await logEvent(
      name: AnalyticsEvents.matchTileOpened,
      parameters: {AnalyticsParams.matchId: matchId},
    );
  }

  Future<void> logMatchMessageButtonTapped({required String matchId}) async {
    await logEvent(
      name: AnalyticsEvents.matchMessageButtonTapped,
      parameters: {AnalyticsParams.matchId: matchId},
    );
  }

  // ============================================================
  // SOCIAL / FRIENDS
  // ============================================================

  Future<void> logFriendRequestSent({required String targetUserId}) async {
    await logEvent(
      name: AnalyticsEvents.friendRequestSent,
      parameters: {AnalyticsParams.targetUserId: targetUserId},
    );
  }

  Future<void> logFriendRequestAccepted({required String targetUserId}) async {
    await logEvent(
      name: AnalyticsEvents.friendRequestAccepted,
      parameters: {AnalyticsParams.targetUserId: targetUserId},
    );
  }

  // ============================================================
  // DISCOVER ENGAGEMENT
  // ============================================================

  Future<void> logDiscoverUserViewed({required String userId}) async {
    await logEvent(
      name: AnalyticsEvents.discoverUserViewed,
      parameters: {AnalyticsParams.targetUserId: userId},
    );
  }

  Future<void> logDiscoverUserLiked({required String userId}) async {
    await logEvent(
      name: AnalyticsEvents.discoverUserLiked,
      parameters: {AnalyticsParams.targetUserId: userId},
    );
  }

  Future<void> logDiscoverUserSuperliked({required String userId}) async {
    await logEvent(
      name: AnalyticsEvents.discoverUserSuperliked,
      parameters: {AnalyticsParams.targetUserId: userId},
    );
  }

  // ============================================================
  // SPEED DATING
  // ============================================================

  Future<void> logSpeedDatingRoundStarted({required String sessionId}) async {
    await logEvent(
      name: AnalyticsEvents.speedDatingRoundStarted,
      parameters: {'session_id': sessionId},
    );
  }

  Future<void> logSpeedDatingMatchCreated({
    required String sessionId,
    required String partnerId,
  }) async {
    await logEvent(
      name: AnalyticsEvents.speedDatingMatchCreated,
      parameters: {
        'session_id': sessionId,
        AnalyticsParams.targetUserId: partnerId,
      },
    );
  }

  // ============================================================
  // CHAT
  // ============================================================

  Future<void> logChatMessageSent({required String chatId}) async {
    await logEvent(
      name: AnalyticsEvents.chatMessageSent,
      parameters: {AnalyticsParams.chatId: chatId},
    );
  }

  Future<void> logChatReactionAdded({required String chatId}) async {
    await logEvent(
      name: AnalyticsEvents.chatReactionAdded,
      parameters: {AnalyticsParams.chatId: chatId},
    );
  }

  // ============================================================
  // ERROR & RETRY ANALYTICS
  // ============================================================

  Future<void> logFirestoreWriteError({String? context}) async {
    await logEvent(
      name: AnalyticsEvents.errorFirestoreWrite,
      parameters: {if (context != null) 'context': context},
    );
  }

  Future<void> logFirestoreReadError({String? context}) async {
    await logEvent(
      name: AnalyticsEvents.errorFirestoreRead,
      parameters: {if (context != null) 'context': context},
    );
  }

  Future<void> logNetworkError({String? context}) async {
    await logEvent(
      name: AnalyticsEvents.networkError,
      parameters: {if (context != null) 'context': context},
    );
  }

  Future<void> logRetryTapped({required String screen}) async {
    await logEvent(
      name: AnalyticsEvents.retryTapped,
      parameters: {'screen': screen},
    );
  }

  Future<void> logOfflineModeEntered() async {
    await logEvent(name: AnalyticsEvents.offlineModeEntered);
  }

  Future<void> logOfflineModeExited() async {
    await logEvent(name: AnalyticsEvents.offlineModeExited);
  }

  // ============================================================
  // FIRST-TIME / FUNNEL MILESTONES
  // ============================================================

  Future<void> logFirstRoomJoin({required String roomId}) async {
    await logEvent(
      name: AnalyticsEvents.firstRoomJoin,
      parameters: {AnalyticsParams.roomId: roomId},
    );
  }

  Future<void> logFirstChatSent({required String chatId}) async {
    await logEvent(
      name: AnalyticsEvents.firstChatSent,
      parameters: {AnalyticsParams.chatId: chatId},
    );
  }

  Future<void> logFirstMatch({required String matchId}) async {
    await logEvent(
      name: AnalyticsEvents.firstMatch,
      parameters: {AnalyticsParams.matchId: matchId},
    );
  }

  Future<void> logFirstFriendAdded({required String userId}) async {
    await logEvent(
      name: AnalyticsEvents.firstFriendAdded,
      parameters: {AnalyticsParams.targetUserId: userId},
    );
  }

  Future<void> logActivationCompleted() async {
    await logEvent(name: AnalyticsEvents.activationCompleted);
  }

  // ============================================================
  // ONCE-ONLY FUNNEL MILESTONES (guarded by SharedPreferences)
  // ============================================================

  static const _kPrefFirstRoomJoin = 'analytics_first_room_join_done';
  static const _kPrefFirstChatSent = 'analytics_first_chat_sent_done';
  static const _kPrefFirstFriendAdded = 'analytics_first_friend_added_done';
  static const _kPrefActivation = 'analytics_activation_completed_done';

  /// Fire first_room_join exactly once per install.
  Future<void> logFirstRoomJoinOnce({required String roomId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_kPrefFirstRoomJoin) == true) return;
      await prefs.setBool(_kPrefFirstRoomJoin, true);
      await logFirstRoomJoin(roomId: roomId);
      await _checkActivationOnce(prefs);
    } catch (e) {
      debugPrint('[Analytics] logFirstRoomJoinOnce error: $e');
    }
  }

  /// Fire first_chat_sent exactly once per install.
  Future<void> logFirstChatSentOnce({required String chatId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_kPrefFirstChatSent) == true) return;
      await prefs.setBool(_kPrefFirstChatSent, true);
      await logFirstChatSent(chatId: chatId);
      await _checkActivationOnce(prefs);
    } catch (e) {
      debugPrint('[Analytics] logFirstChatSentOnce error: $e');
    }
  }

  /// Fire first_friend_added exactly once per install.
  Future<void> logFirstFriendAddedOnce({required String userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_kPrefFirstFriendAdded) == true) return;
      await prefs.setBool(_kPrefFirstFriendAdded, true);
      await logFirstFriendAdded(userId: userId);
    } catch (e) {
      debugPrint('[Analytics] logFirstFriendAddedOnce error: $e');
    }
  }

  /// Auto-fire activation_completed when onboarding + first_room + first_chat all done.
  Future<void> _checkActivationOnce(SharedPreferences prefs) async {
    if (prefs.getBool(_kPrefActivation) == true) return;
    final roomDone = prefs.getBool(_kPrefFirstRoomJoin) == true;
    final chatDone = prefs.getBool(_kPrefFirstChatSent) == true;
    if (roomDone && chatDone) {
      await prefs.setBool(_kPrefActivation, true);
      await logActivationCompleted();
    }
  }
}
