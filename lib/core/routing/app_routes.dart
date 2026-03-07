// lib/core/routing/app_routes.dart
// Centralized route management for MixMingle

import 'package:flutter/material.dart';

// Landing & Auth
import '../../features/landing/landing_page.dart';
import '../../features/auth/screens/neon_login_page.dart';
import '../../features/auth/screens/neon_signup_page.dart';
import '../../features/auth/forgot_password_page.dart';

// Home
import '../../features/home/home_page_electric.dart';

// Rooms
import '../../features/room/screens/rooms_list_page.dart';

// Chat
import '../../features/chat/screens/chats_list_page.dart';
import '../../features/chat/screens/chat_conversation_page.dart';

// Profile & Social
import '../../features/profile/screens/following_list_page.dart';

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

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    debugPrint('Navigating to: ${settings.name}');

    switch (settings.name) {
      case landing:
        return MaterialPageRoute(builder: (_) => const LandingPage());
      case login:
        return MaterialPageRoute(builder: (_) => const NeonLoginPage());
      case signup:
        return MaterialPageRoute(builder: (_) => const NeonSignupPage());
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordPage());
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
        final roomId = settings.arguments as String?;
        if (roomId == null) return _errorRoute('Room ID required');
        return MaterialPageRoute(
          builder: (_) => Scaffold(body: Center(child: Text('Room: $roomId'))),
        );
      case chats:
        return MaterialPageRoute(
          builder: (_) => const AgeVerifiedGuard(
            child: ProfileCompleteGuard(child: ChatsListPage()),
          ),
        );
      case chat:
        final chatId = settings.arguments as String?;
        if (chatId == null) return _errorRoute('Chat ID required');
        return MaterialPageRoute(
          builder: (_) => AgeVerifiedGuard(
            child: ProfileCompleteGuard(child: ChatConversationPage(chatId: chatId)),
          ),
        );
      case following:
        final userId = settings.arguments as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => FollowingListPage(userId: userId, displayName: ''),
        );
      default:
        return _errorRoute('No route defined for ${settings.name}');
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
