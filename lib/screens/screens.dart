/// Screens barrel file - Re-exports all main screens for easy importing
///
/// This provides a centralized import point matching scaffold conventions:
/// ```dart
/// import 'package:mixmingle/screens/screens.dart';
/// ```
///
/// Note: The actual implementations reside in lib/features/
/// This barrel file provides convenient re-exports.
library;

// ============================================================
// AUTH SCREENS
// ============================================================
export '../features/auth/screens/neon_login_page.dart';
export '../features/auth/screens/neon_signup_page.dart';
export '../features/auth/screens/neon_splash_page.dart';
export '../features/auth/forgot_password_page.dart';

// ============================================================
// HOME SCREENS
// ============================================================
export '../features/home/screens/home_page_electric.dart';

// ============================================================
// PROFILE SCREENS
// ============================================================
export '../features/profile/screens/profile_page.dart';
export '../features/profile/screens/user_profile_page.dart';
export '../features/profile/screens/edit_profile_page.dart';

// ============================================================
// ROOM SCREENS
// ============================================================
export '../features/room/room_page.dart';
export '../features/room/screens/voice_room_page.dart';

// ============================================================
// CHAT SCREENS
// ============================================================
export '../features/chat/screens/chat_page.dart';
export '../features/messages/messages_page.dart';

// ============================================================
// SOCIAL FEED SCREENS
// ============================================================
export '../features/feed/social_feed_page.dart';
export '../features/feed/create_post_dialog.dart';

// ============================================================
// SPEED DATING SCREENS (TEMP DISABLED)
// ============================================================
// export '../features/speed_dating/screens/speed_dating_lobby_page.dart';
// export '../features/speed_dating/screens/speed_dating_call_page.dart';
// export '../features/speed_dating/screens/speed_dating_decision_page.dart';

// ============================================================
// MATCHING SCREENS
// ============================================================
export '../features/app/screens/matches_page.dart';

// ============================================================
// EVENTS SCREENS
// ============================================================
export '../features/events/screens/events_page.dart';
export '../features/events/screens/event_details_page.dart';
export '../features/events/screens/create_event_page.dart';

// ============================================================
// GO LIVE / BROADCASTING SCREENS
// ============================================================
export '../features/go_live/go_live_page.dart';

// ============================================================
// SETTINGS SCREENS
// ============================================================
export '../features/settings/settings_page.dart';

// ============================================================
// PAYMENTS / WALLET SCREENS
// ============================================================
export '../features/payments/screens/coin_store_screen.dart';
export '../features/payments/screens/wallet_page.dart';
export '../features/withdrawal/withdrawal_page.dart';

// ============================================================
// ONBOARDING SCREENS (TEMP DISABLED)
// ============================================================
// export '../features/onboarding/screens/onboarding_page.dart';
export '../features/landing/landing_page.dart';

// ============================================================
// LEADERBOARDS & ACHIEVEMENTS
// ============================================================
export '../features/leaderboards/leaderboards_page.dart';
export '../features/achievements/achievements_page.dart';

// ============================================================
// NOTIFICATIONS
// ============================================================
export '../features/notifications/screens/notifications_page.dart';

// ============================================================
// ADMIN / MODERATION SCREENS
// ============================================================
export '../features/admin/admin_dashboard_page.dart';
export '../features/moderation/screens/moderator_dashboard_page.dart';

// ============================================================
// LEGAL SCREENS
// ============================================================
export '../features/legal/privacy_policy_page.dart';
export '../features/legal/terms_of_service_page.dart';


