// lib/core/routing/app_routes.dart
// Centralized route management for MixMingle

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Landing & Auth
import '../../features/landing/landing_page.dart';
import '../../features/auth/screens/age_gate_page.dart';
import '../../features/auth/screens/neon_login_page.dart';
import '../../features/auth/screens/neon_signup_page.dart';
import '../../features/auth/forgot_password_page.dart';

// Home
import '../../features/home/home_page_electric.dart';

// Rooms
import '../../features/room/screens/rooms_list_page.dart';
import '../../features/room/screens/voice_room_page.dart';
import '../../features/room/providers/room_providers.dart';
import '../../shared/widgets/club_background.dart';

// Chat
import '../../features/chat/screens/chats_list_page.dart';
import '../../features/chat/screens/chat_conversation_page.dart';
import '../../features/chat/screens/message_requests_page.dart';

// Discovery
import '../../features/discovery/discovery_page.dart';

// Profile & Social
import '../../features/profile/screens/following_list_page.dart';
import '../../features/profile/screens/report_user_page.dart';
import '../../features/profile/screens/edit_profile_page.dart';
import '../../features/profile/screens/user_profile_page.dart';
import '../../features/friends/friend_list_page.dart';

// Settings
import '../../features/settings/screens/settings_page.dart';
import '../../features/settings/account_settings_page.dart';
import '../../features/settings/privacy_settings_page.dart';
import '../../features/settings/notification_settings_page.dart';
import '../../features/settings/blocked_users_page.dart';

// Admin
import '../../features/admin/admin_dashboard_page.dart';

// Notifications
import '../../features/notifications/notification_center_page.dart';

// Payments / Coins
import '../../features/payments/screens/coin_purchase_page.dart';

// Events
import '../../features/events/screens/events_page.dart';
import '../../features/events/screens/event_details_page.dart';

// Create Room
import '../../features/room/screens/create_room_page_complete.dart';

// Auth providers (for profile/me route)
import '../../shared/providers/auth_providers.dart';

// Guards
import '../routing/guards/age_verified_guard.dart';
import '../routing/guards/profile_complete_guard.dart';

/// App Routes
class AppRoutes {
  static const String landing             = '/';
  static const String login               = '/login';
  static const String signup              = '/signup';
  static const String forgotPassword      = '/forgot-password';
  static const String ageGate             = '/age-gate';
  static const String onboarding          = '/onboarding';
  static const String home                = '/home';
  static const String rooms               = '/rooms';
  static const String room                = '/room';
  static const String chats               = '/chats';
  static const String chat                = '/chat';
  static const String editProfile         = '/profile/edit';
  static const String userProfile         = '/profile';
  static const String profile             = '/profile/me';
  static const String profileMedia        = '/profile/media';
  static const String discovery           = '/discovery';
  static const String followers           = '/followers';
  static const String following           = '/following';
  static const String suggested           = '/suggested';
  static const String suggestedUsers      = '/suggested-users';
  static const String trendingUsers       = '/trending-users';
  static const String activeNow           = '/active-now';
  static const String matches             = '/matches';
  static const String matchDiscovery      = '/match/discovery';
  static const String matchPreferences    = '/match/preferences';
  static const String events              = '/events';
  static const String eventDetails        = '/events/details';
  static const String discoverRooms       = '/discover/rooms';
  static const String discoverRoomsLive   = '/discover/rooms/live';
  static const String createRoom          = '/rooms/create';
  static const String notifications       = '/notifications';
  static const String settings            = '/settings';
  static const String settingsRoute       = '/settings';
  static const String accountSettings     = '/settings/account';
  static const String privacySettings     = '/settings/privacy';
  static const String notificationSettings = '/settings/notifications';
  static const String coins               = '/coins';
  static const String membershipUpgrade   = '/membership/upgrade';
  static const String reportUser          = '/report/user';
  static const String blockedUsers        = '/blocked-users';
  static const String adminDashboard      = '/admin/dashboard';
  static const String friends              = '/friends';
  static const String messageRequests      = '/message-requests';

  static Route<dynamic> onGenerateRoute(RouteSettings routeSettings) {
    debugPrint('Navigating to: ${routeSettings.name}');

    switch (routeSettings.name) {
      case landing:
        return MaterialPageRoute(builder: (_) => const LandingPage());
      case login:
        return MaterialPageRoute(builder: (_) => const NeonLoginPage());
      case signup:
        return MaterialPageRoute(builder: (_) => const NeonSignupPage());
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordPage());
      case ageGate:
        return MaterialPageRoute(builder: (_) => const AgeGatePage());
      case home:
        return MaterialPageRoute(
          builder: (_) => const AgeVerifiedGuard(
            child: ProfileCompleteGuard(child: HomePageElectric()),
          ),
        );
      case rooms:
        return MaterialPageRoute(
          builder: (_) => const AgeVerifiedGuard(
            child: ProfileCompleteGuard(child: RoomsListPage()),
          ),
        );
      case room:
        final roomId = routeSettings.arguments as String?;
        if (roomId == null) return _errorRoute('Room ID required');
        return MaterialPageRoute(
          builder: (_) => AgeVerifiedGuard(
            child: ProfileCompleteGuard(
              child: _RoomLoaderPage(roomId: roomId),
            ),
          ),
        );
      case chats:
        return MaterialPageRoute(
          builder: (_) => const AgeVerifiedGuard(
            child: ProfileCompleteGuard(child: ChatsListPage()),
          ),
        );
      case chat:
        final chatId = routeSettings.arguments as String?;
        if (chatId == null) return _errorRoute('Chat ID required');
        return MaterialPageRoute(
          builder: (_) => AgeVerifiedGuard(
            child: ProfileCompleteGuard(child: ChatConversationPage(chatId: chatId)),
          ),
        );
      case following:
        final userId = routeSettings.arguments as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => FollowingListPage(userId: userId, displayName: ''),
        );
      case friends:
        return MaterialPageRoute(
          builder: (_) => const AgeVerifiedGuard(
            child: ProfileCompleteGuard(child: FriendListPage()),
          ),
        );
      case reportUser:
        final args = routeSettings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ReportUserPage(
            userId: args?['userId'] as String? ?? '',
            displayName: args?['displayName'] as String?,
          ),
        );
      case messageRequests:
        return MaterialPageRoute(
          builder: (_) => const AgeVerifiedGuard(
            child: ProfileCompleteGuard(child: MessageRequestsPage()),
          ),
        );
      case discovery:
        return MaterialPageRoute(
          builder: (_) => const AgeVerifiedGuard(
            child: ProfileCompleteGuard(child: DiscoveryPage()),
          ),
        );
      case settings:
        return MaterialPageRoute(
          builder: (_) => const AgeVerifiedGuard(
            child: ProfileCompleteGuard(child: SettingsPage()),
          ),
        );
      case accountSettings:
        return MaterialPageRoute(
          builder: (_) => const AgeVerifiedGuard(
            child: ProfileCompleteGuard(child: AccountSettingsPage()),
          ),
        );
      case privacySettings:
        return MaterialPageRoute(
          builder: (_) => const AgeVerifiedGuard(
            child: ProfileCompleteGuard(child: PrivacySettingsPage()),
          ),
        );
      case notificationSettings:
        return MaterialPageRoute(
          builder: (_) => const AgeVerifiedGuard(
            child: ProfileCompleteGuard(child: NotificationSettingsPage()),
          ),
        );
      case blockedUsers:
        return MaterialPageRoute(
          builder: (_) => const AgeVerifiedGuard(
            child: ProfileCompleteGuard(child: BlockedUsersPage()),
          ),
        );
      case adminDashboard:
        return MaterialPageRoute(
          builder: (_) => const AgeVerifiedGuard(
            child: ProfileCompleteGuard(child: AdminDashboardPage()),
          ),
        );
      case notifications:
        return MaterialPageRoute(
          builder: (_) => const AgeVerifiedGuard(
            child: ProfileCompleteGuard(child: NotificationCenterPage()),
          ),
        );
      case coins:
        return MaterialPageRoute(
          builder: (_) => const AgeVerifiedGuard(
            child: ProfileCompleteGuard(child: CoinPurchasePage()),
          ),
        );
      case createRoom:
        return MaterialPageRoute(
          builder: (_) => const AgeVerifiedGuard(
            child: ProfileCompleteGuard(child: CreateRoomPageComplete()),
          ),
        );
      case events:
        return MaterialPageRoute(
          builder: (_) => const AgeVerifiedGuard(
            child: ProfileCompleteGuard(child: EventsPage()),
          ),
        );
      case eventDetails:
        final eventId = routeSettings.arguments as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => AgeVerifiedGuard(
            child: ProfileCompleteGuard(
              child: EventDetailsPage(eventId: eventId),
            ),
          ),
        );
      case profile:
        return MaterialPageRoute(
          builder: (_) => const AgeVerifiedGuard(
            child: ProfileCompleteGuard(child: _CurrentUserProfilePage()),
          ),
        );
      case editProfile:
        return MaterialPageRoute(
          builder: (_) => const AgeVerifiedGuard(
            child: ProfileCompleteGuard(child: EditProfilePage()),
          ),
        );
      case userProfile:
        final userId = routeSettings.arguments as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => AgeVerifiedGuard(
            child: ProfileCompleteGuard(
              child: UserProfilePage(userId: userId),
            ),
          ),
        );
      default:
        return _errorRoute('No route defined for ${routeSettings.name}');
    }
  }

  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text(message)),
      ),
    );
  }
}

/// Loads a Room from Firestore by ID then hands off to VoiceRoomPage.
/// Used by the /room route so callers only need to pass arguments: roomId.
class _RoomLoaderPage extends ConsumerWidget {
  final String roomId;
  const _RoomLoaderPage({required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsync = ref.watch(roomByIdProvider(roomId));
    return roomAsync.when(
      loading: () => const ClubBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Room')),
        body: Center(child: Text('Could not load room: $e')),
      ),
      data: (room) {
        if (room == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Room')),
            body: const Center(child: Text('Room not found.')),
          );
        }
        return VoiceRoomPage(room: room);
      },
    );
  }
}

/// Redirects /profile/me to the current user's UserProfilePage.
class _CurrentUserProfilePage extends ConsumerWidget {
  const _CurrentUserProfilePage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authStateProvider).asData?.value?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return UserProfilePage(userId: uid);
  }
}
