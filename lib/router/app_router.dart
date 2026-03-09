/// lib/router/app_router.dart
///
/// MixVy centralized router.
/// Registers EVERY screen in the app. Plug into MaterialApp via:
///
///   MaterialApp(
///     initialRoute: AppRoutes.ageGate,
///     onGenerateRoute: AppRouter.onGenerateRoute,
///   )
///
/// Navigation:
///   Navigator.pushNamed(context, AppRoutes.home);
///   Navigator.pushNamed(context, AppRoutes.room, arguments: roomId);
///   Navigator.pushNamed(context, AppRoutes.profile, arguments: userId);
///
/// Note: This file is the authoritative screen registry for routing QA.
/// When you add/rename/remove a screen, update AppRoutes and this file.
library;


import 'package:flutter/material.dart';
import 'package:mixmingle/core/routing/app_routes.dart';
// Auth / Onboarding
import 'package:mixmingle/features/auth/screens/age_gate_page.dart';
import 'package:mixmingle/features/auth/screens/neon_login_page.dart';
import 'package:mixmingle/features/auth/screens/neon_signup_page.dart';
import 'package:mixmingle/features/auth/forgot_password_page.dart';
import 'package:mixmingle/features/landing/landing_page.dart';
// Core
import 'package:mixmingle/features/home/home_page_electric.dart';
import 'package:mixmingle/features/discovery/pages/discovery_page.dart';
// Profile / Social
import 'package:mixmingle/features/profile/pages/user_profile_page.dart';
import 'package:mixmingle/features/edit_profile/edit_profile_page.dart';
import 'package:mixmingle/features/profile/screens/followers_list_page.dart';
import 'package:mixmingle/features/profile/screens/following_list_page.dart';
import 'package:mixmingle/features/friends/friend_list_page.dart';
// Chat / Messaging
import 'package:mixmingle/features/chat/screens/chats_list_page.dart';
import 'package:mixmingle/features/chat/screens/chat_conversation_page.dart';
import 'package:mixmingle/features/chat/screens/message_requests_page.dart';
// Rooms / Live
import 'package:mixmingle/features/room/screens/rooms_list_page.dart';
import 'package:mixmingle/features/room/screens/voice_room_page.dart';
import 'package:mixmingle/features/room/screens/create_room_page_complete.dart';
// Settings
import 'package:mixmingle/features/settings/settings_page.dart';
import 'package:mixmingle/features/settings/account_settings_page.dart';
import 'package:mixmingle/features/settings/privacy_settings_page.dart';
import 'package:mixmingle/features/settings/notification_settings_page.dart';
import 'package:mixmingle/features/settings/blocked_users_page.dart';
// Notifications
import 'package:mixmingle/features/notifications/notification_center_page.dart';
// Events
import 'package:mixmingle/features/events/screens/events_list_page.dart';
import 'package:mixmingle/features/events/screens/event_details_page.dart';
// Payments
import 'package:mixmingle/features/payments/screens/coin_purchase_page.dart';
// Admin
import 'package:mixmingle/features/admin/admin_dashboard_page.dart';

class AppRouter {
	static Route<dynamic> onGenerateRoute(RouteSettings settings) {
		switch (settings.name) {
			// Auth / Onboarding
			case AppRoutes.ageGate:
				return MaterialPageRoute(builder: (_) => const AgeGatePage());
			case AppRoutes.login:
				return MaterialPageRoute(builder: (_) => const NeonLoginPage());
			case AppRoutes.signup:
				return MaterialPageRoute(builder: (_) => const NeonSignupPage());
			case AppRoutes.forgotPassword:
				return MaterialPageRoute(builder: (_) => const ForgotPasswordPage());
			case AppRoutes.landing:
				return MaterialPageRoute(builder: (_) => const LandingPage());

			// Core
			case AppRoutes.home:
				return MaterialPageRoute(builder: (_) => const HomePageElectric());
			case AppRoutes.discovery:
				return MaterialPageRoute(builder: (_) => const DiscoveryPage());

			// Profile / Social
			case AppRoutes.userProfile:
				{
					final args = settings.arguments;
					if (args is String) {
						return MaterialPageRoute(builder: (_) => UserProfilePage(userId: args));
					}
					return _errorRoute('Missing userId for UserProfilePage');
				}
			case AppRoutes.editProfile:
				return MaterialPageRoute(builder: (_) => const EditProfilePage());
			case AppRoutes.followers:
				{
					final args = settings.arguments;
					if (args is Map && args['userId'] != null && args['displayName'] != null) {
						return MaterialPageRoute(
							builder: (_) => FollowersListPage(userId: args['userId'], displayName: args['displayName']),
						);
					}
					return _errorRoute('Missing userId/displayName for FollowersListPage');
				}
			case AppRoutes.following:
				{
					final args = settings.arguments;
					if (args is Map && args['userId'] != null && args['displayName'] != null) {
						return MaterialPageRoute(
							builder: (_) => FollowingListPage(userId: args['userId'], displayName: args['displayName']),
						);
					}
					return _errorRoute('Missing userId/displayName for FollowingListPage');
				}
			case AppRoutes.friends:
				return MaterialPageRoute(builder: (_) => const FriendListPage());

			// Chat / Messaging
			case AppRoutes.chats:
				return MaterialPageRoute(builder: (_) => const ChatsListPage());
			case AppRoutes.chat:
				{
					final args = settings.arguments;
					if (args is String) {
						return MaterialPageRoute(builder: (_) => ChatConversationPage(chatId: args));
					}
					return _errorRoute('Missing chatId for ChatConversationPage');
				}
			case AppRoutes.messageRequests:
				return MaterialPageRoute(builder: (_) => const MessageRequestsPage());

			// Rooms / Live
			case AppRoutes.rooms:
				return MaterialPageRoute(builder: (_) => const RoomsListPage());
			case AppRoutes.room:
				{
					final args = settings.arguments;
					if (args is Map && args['room'] != null) {
						return MaterialPageRoute(builder: (_) => VoiceRoomPage(room: args['room']));
					}
					return _errorRoute('Missing room for VoiceRoomPage');
				}
			case AppRoutes.createRoom:
				return MaterialPageRoute(builder: (_) => const CreateRoomPageComplete());

			// Settings
			case AppRoutes.settings:
				return MaterialPageRoute(builder: (_) => const SettingsPage());
			case AppRoutes.accountSettings:
				return MaterialPageRoute(builder: (_) => const AccountSettingsPage());
			case AppRoutes.privacySettings:
				return MaterialPageRoute(builder: (_) => const PrivacySettingsPage());
			case AppRoutes.notificationSettings:
				return MaterialPageRoute(builder: (_) => const NotificationSettingsPage());
			case AppRoutes.blockedUsers:
				return MaterialPageRoute(builder: (_) => const BlockedUsersPage());

			// Notifications
			case AppRoutes.notifications:
				return MaterialPageRoute(builder: (_) => const NotificationCenterPage());

			// Events
			case AppRoutes.events:
				return MaterialPageRoute(builder: (_) => const EventsPage());
			case AppRoutes.eventDetails:
				{
					final args = settings.arguments;
					if (args is String) {
						return MaterialPageRoute(builder: (_) => EventDetailsPage(eventId: args));
					}
					return _errorRoute('Missing eventId for EventDetailsPage');
				}

			// Payments
			case AppRoutes.coins:
				return MaterialPageRoute(builder: (_) => const CoinPurchasePage());

			// Admin
			case AppRoutes.adminDashboard:
				return MaterialPageRoute(builder: (_) => const AdminDashboardPage());

			// Dev / QA (fallback to error route if not implemented)
			default:
				return _errorRoute('Route not found: \'${settings.name}\'');
		}
	}

	static Route<dynamic> _errorRoute(String message) {
		return MaterialPageRoute(
			builder: (_) => Scaffold(
				appBar: AppBar(title: const Text('Routing Error')),
				body: Center(child: Text(message)),
			),
		);
	}
}

// ── Route inventory (all mapped screens) ─────────────────────────────────────
// Auth / Onboarding
//   AgeGatePage          → AppRoutes.ageGate        (/age-gate)
//   NeonLoginPage        → AppRoutes.login           (/login)
//   NeonSignupPage       → AppRoutes.signup          (/signup)
//   ForgotPasswordPage   → AppRoutes.forgotPassword  (/forgot-password)
//   LandingPage          → AppRoutes.landing         (/)
//
// Core
//   HomePageElectric     → AppRoutes.home            (/home)
//   DiscoveryPage        → AppRoutes.discovery       (/discovery)
//
// Profile / Social
//   UserProfilePage      → AppRoutes.userProfile     (/profile) + userId arg
//   EditProfilePage      → AppRoutes.editProfile     (/profile/edit)
//   FollowersListPage    → AppRoutes.followers       (/followers)
//   FollowingListPage    → AppRoutes.following       (/following)
//   FriendListPage       → AppRoutes.friends         (/friends)
//                          AppRoutes.friendRequests  (/profile/friend-requests)
//
// Chat / Messaging
//   ChatsListPage        → AppRoutes.chats / chatList  (/chats)
//   ChatConversationPage → AppRoutes.chat              (/chat) + chatId arg
//   MessageRequestsPage  → AppRoutes.messageRequests   (/message-requests)
//
// Rooms / Live
//   RoomsListPage        → AppRoutes.rooms           (/rooms)
//   VoiceRoomPage        → AppRoutes.room            (/room)  + roomId arg
//                          AppRoutes.liveRoom        (/room/live) + roomId arg
//   CreateRoomPageComplete → AppRoutes.createRoom    (/rooms/create)
//
// Settings
//   SettingsPage         → AppRoutes.settings        (/settings)
//   AccountSettingsPage  → AppRoutes.accountSettings (/settings/account)
//   PrivacySettingsPage  → AppRoutes.privacySettings (/settings/privacy)
//   NotificationSettingsPage → AppRoutes.notificationSettings (/settings/notifications)
//   BlockedUsersPage     → AppRoutes.blockedUsers    (/blocked-users)
//
// Notifications
//   NotificationCenterPage → AppRoutes.notifications (/notifications)
//
// Events
//   EventsPage           → AppRoutes.events          (/events)
//   EventDetailsPage     → AppRoutes.eventDetails    (/events/details) + eventId arg
//
// Payments
//   CoinPurchasePage     → AppRoutes.coins           (/coins)
//
// Admin
//   AdminDashboardPage   → AppRoutes.adminDashboard  (/admin/dashboard)
//
// Dev / QA
//   RouteTestPage        → AppRoutes.routeTest       (/dev/routes)
//   ProviderDebugPage    → AppRoutes.providerDebug   (/dev/providers)
