/// Analytics Events Constants
///
/// All analytics event names and parameter keys used throughout the app.
/// Consistent naming ensures clean analytics data and easy reporting.
library;

/// Event names for analytics tracking
class AnalyticsEvents {
  AnalyticsEvents._();

  // ============================================================
  // ONBOARDING EVENTS
  // ============================================================
  static const String onboardingStarted = 'onboarding_started';
  static const String onboardingCompleted = 'onboarding_completed';
  static const String onboardingSkipped = 'onboarding_skipped';
  static const String onboardingStepViewed = 'onboarding_step_viewed';

  // ============================================================
  // AUTH EVENTS
  // ============================================================
  static const String loginStarted = 'login_started';
  static const String loginSuccess = 'login_success';
  static const String loginFailed = 'login_failed';
  static const String logout = 'logout';
  static const String signupStarted = 'signup_started';
  static const String signupCompleted = 'signup_completed';
  static const String signupFailed = 'signup_failed';
  static const String passwordReset = 'password_reset';

  // ============================================================
  // MEMBERSHIP EVENTS
  // ============================================================
  static const String membershipUpgradeStarted = 'membership_upgrade_started';
  static const String membershipUpgraded = 'membership_upgraded';
  static const String membershipDowngraded = 'membership_downgraded';
  static const String membershipRenewed = 'membership_renewed';
  static const String membershipCancelled = 'membership_cancelled';
  static const String vipRoomAttempt = 'vip_room_attempt';

  // ============================================================
  // COIN EVENTS
  // ============================================================
  static const String coinStoreOpened = 'coin_store_opened';
  static const String coinPurchaseStarted = 'coin_purchase_started';
  static const String coinPurchaseCompleted = 'coin_purchase_completed';
  static const String coinPurchaseFailed = 'coin_purchase_failed';
  static const String coinsSpentGift = 'coins_spent_gift';
  static const String coinsSpentSpotlight = 'coins_spent_spotlight';
  static const String coinsReceived = 'coins_received';

  // ============================================================
  // ROOM EVENTS
  // ============================================================
  static const String roomJoinStarted = 'room_join_started';
  static const String roomJoinSuccess = 'room_join_success';
  static const String roomJoinFailed = 'room_join_failed';
  static const String roomLeave = 'room_leave';
  static const String roomCreated = 'room_created';
  static const String roomDeleted = 'room_deleted';
  static const String cameraEnabled = 'camera_enabled';
  static const String cameraDisabled = 'camera_disabled';
  static const String micEnabled = 'mic_enabled';
  static const String micDisabled = 'mic_disabled';
  static const String screenShareStarted = 'screen_share_started';
  static const String screenShareStopped = 'screen_share_stopped';

  // ============================================================
  // MODERATION EVENTS
  // ============================================================
  static const String reportSubmitted = 'report_submitted';
  static const String userBlocked = 'user_blocked';
  static const String userUnblocked = 'user_unblocked';
  static const String hostActionTaken = 'host_action_taken';
  static const String adminReportReviewed = 'admin_report_reviewed';
  static const String adminUserBanned = 'admin_user_banned';
  static const String userKicked = 'user_kicked';
  static const String userMuted = 'user_muted';
  static const String userWarned = 'user_warned';

  // ============================================================
  // ENGAGEMENT EVENTS
  // ============================================================
  static const String messageSent = 'message_sent';
  static const String reactionSent = 'reaction_sent';
  static const String spotlightActivated = 'spotlight_activated';
  static const String windowOpened = 'window_opened';
  static const String windowClosed = 'window_closed';
  static const String profileViewed = 'profile_viewed';
  static const String followUser = 'follow_user';
  static const String unfollowUser = 'unfollow_user';
  static const String firstMessageSent = 'first_message_sent';

  // ============================================================
  // UI/NAVIGATION EVENTS
  // ============================================================
  static const String screenView = 'screen_view';
  static const String tabSelected = 'tab_selected';
  static const String panelOpened = 'panel_opened';
  static const String panelClosed = 'panel_closed';
  static const String settingsOpened = 'settings_opened';
  static const String settingsChanged = 'settings_changed';

  // ============================================================
  // ERROR EVENTS
  // ============================================================
  static const String errorOccurred = 'error_occurred';
  static const String networkError = 'network_error';
  static const String permissionDenied = 'permission_denied';
}

/// Parameter keys for analytics events
class AnalyticsParams {
  AnalyticsParams._();

  // User params
  static const String userId = 'user_id';
  static const String membershipTier = 'membership_tier';
  static const String platform = 'platform';
  static const String appVersion = 'app_version';

  // Room params
  static const String roomId = 'room_id';
  static const String roomType = 'room_type';
  static const String roomName = 'room_name';
  static const String participantCount = 'participant_count';
  static const String duration = 'duration';

  // Auth params
  static const String authMethod = 'auth_method';
  static const String errorCode = 'error_code';
  static const String errorMessage = 'error_message';

  // Purchase params
  static const String productId = 'product_id';
  static const String price = 'price';
  static const String currency = 'currency';
  static const String coinAmount = 'coin_amount';
  static const String packageName = 'package_name';

  // Moderation params
  static const String reportReason = 'report_reason';
  static const String reportedUserId = 'reported_user_id';
  static const String actionType = 'action_type';
  static const String targetUserId = 'target_user_id';

  // Engagement params
  static const String messageType = 'message_type';
  static const String reactionType = 'reaction_type';
  static const String windowType = 'window_type';

  // Funnel params
  static const String step = 'step';
  static const String funnelName = 'funnel_name';
  static const String success = 'success';

  // Performance params
  static const String loadTime = 'load_time';
  static const String latency = 'latency';
  static const String frameDropRate = 'frame_drop_rate';
}

/// User properties for analytics
class AnalyticsUserProperties {
  AnalyticsUserProperties._();

  static const String membershipTier = 'membership_tier';
  static const String platform = 'platform';
  static const String appVersion = 'app_version';
  static const String accountCreatedDate = 'account_created_date';
  static const String totalRoomsJoined = 'total_rooms_joined';
  static const String totalCoinsSpent = 'total_coins_spent';
  static const String isVip = 'is_vip';
}
