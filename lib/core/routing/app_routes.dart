/// App Router
/// Centralized route management for Mix & Mingle
library;

import 'package:flutter/material.dart';

// Landing & Auth
import '../../features/landing/landing_page.dart';
import '../../features/auth/screens/neon_login_page.dart';
import '../../features/auth/screens/neon_signup_page.dart';
import '../../features/auth/forgot_password_page.dart';

// Onboarding
import '../../features/onboarding/age_gate_page.dart';
import '../../features/onboarding/onboarding_flow.dart';

// Home & Main Navigation
import '../../features/home/home_page_electric.dart';

// Speed Dating
import '../../features/speed_dating/screens/speed_dating_lobby_page.dart';
import '../../features/speed_dating/screens/speed_dating_session_page.dart';

// Rooms
import '../../features/rooms/screens/rooms_list_page.dart';

// Chat
import '../../features/chat/screens/chats_list_page.dart';
import '../../features/chat/screens/chat_conversation_page.dart';

// Profile & Social Graph
import '../../features/profile/screens/edit_profile_page.dart';
import '../../features/profile/screens/user_profile_page.dart';
import '../../features/profile/screens/user_discovery_page_new.dart';
import '../../features/profile/screens/followers_list_page.dart';
import '../../features/profile/screens/following_list_page.dart';
import '../../features/profile/screens/suggested_users_page.dart';

// Monetization
import '../../features/payments/screens/coin_store_screen.dart';
import '../../features/payments/screens/membership_upgrade_screen.dart';

// Moderation & Admin
import '../../features/moderation/screens/report_user_screen.dart';
import '../../features/moderation/screens/blocked_users_screen.dart';
import '../../features/admin/admin_dashboard_page.dart';

// Guards
import '../routing/guards/age_verified_guard.dart';
import '../routing/guards/profile_complete_guard.dart';
import 'package:mix_and_mingle/shared/models/user_profile.dart';

/// App Routes
class AppRoutes {
  // Public routes (no auth required)
  static const String landing = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';

  // Onboarding
  static const String ageGate = '/age-gate';
  static const String onboarding = '/onboarding';

  // Protected routes (require auth)
  static const String home = '/home';

  // Speed Dating - DISABLED (feature removed)
  // static const String speedDatingLobby = '/speed-dating';
  // static const String speedDatingSession = '/speed-dating/session';

  // Rooms
  static const String rooms = '/rooms';
  static const String room = '/room';

  // Chat
  static const String chats = '/chats';
  static const String chat = '/chat';

  // Profile & Social Graph
  static const String editProfile = '/profile/edit';
  static const String userProfile = '/profile';
  static const String discovery = '/discovery';
  static const String followers = '/followers';
  static const String following = '/following';
  static const String suggested = '/suggested';

  // Monetization
  static const String coins = '/coins';
  static const String membershipUpgrade = '/membership/upgrade';

  // Moderation
  static const String reportUser = '/report/user';
  static const String blockedUsers = '/blocked-users';

  // Admin
  static const String adminDashboard = '/admin/dashboard';

  // Settings
  static const String settings = '/settings';

  /// Generate route
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    debugPrint('🧭 Navigating to: ${settings.name}');

    switch (settings.name) {
      // Public routes
      case landing:
        return MaterialPageRoute(builder: (_) => const LandingPage());

      case login:
        return MaterialPageRoute(builder: (_) => const NeonLoginPage());

      case signup:
        return MaterialPageRoute(builder: (_) => const NeonSignupPage());

      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordPage());

      // Onboarding
      case ageGate:
        return MaterialPageRoute(builder: (_) => const AgeGatePage());

      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingFlow());

      // Protected routes with guards
      case home:
        return MaterialPageRoute(
          builder: (_) => const AgeVerifiedGuard(
            child: ProfileCompleteGuard(
              child: HomePageElectric(),
            ),
          ),
        );

      // Speed Dating
      case speedDatingLobby:
        return MaterialPageRoute(
          builder: (_) => const AgeVerifiedGuard(
            child: ProfileCompleteGuard(
              child: SpeedDatingLobbyPage(),
            ),
          ),
        );

      case speedDatingSession:
        final sessionId = settings.arguments as String?;
        if (sessionId == null) {
          return _errorRoute('Session ID required');
        }
        return MaterialPageRoute(
          builder: (_) => AgeVerifiedGuard(
            child: ProfileCompleteGuard(
              child: SpeedDatingSessionPage(sessionId: sessionId),
            ),
          ),
        );

      // Rooms
      case rooms:
        return MaterialPageRoute(
          builder: (_) => const AgeVerifiedGuard(
            child: ProfileCompleteGuard(
              child: RoomsListPage(),
            ),
          ),
        );

      case room:
        final roomId = settings.arguments as String?;
        if (roomId == null) {
          return _errorRoute('Room ID required');
        }
        // TODO: Create RoomPage widget
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Room: $roomId\n(Coming soon)'),
            ),
          ),
        );

      // Chat
      case chats:
        return MaterialPageRoute(
          builder: (_) => const AgeVerifiedGuard(
            child: ProfileCompleteGuard(
              child: ChatsListPage(),
            ),
          ),
        );

      case chat:
        final chatId = settings.arguments as String?;
        if (chatId == null) {
          return _errorRoute('Chat ID required');
        }
        return MaterialPageRoute(
          builder: (_) => AgeVerifiedGuard(
            child: ProfileCompleteGuard(
              child: ChatConversationPage(chatId: chatId),
            ),
          ),
        );

      // Profile
      case editProfile:
        return MaterialPageRoute(
          builder: (_) => const AgeVerifiedGuard(
            child: EditProfilePage(),
          ),
        );

      case userProfile:
        final userId = settings.arguments as String?;
        if (userId == null) {
          return _errorRoute('User ID required');
        }
        return MaterialPageRoute(
          builder: (_) => AgeVerifiedGuard(
            child: UserProfilePage(userId: userId),
          ),
        );

      case discovery:
        return MaterialPageRoute(
          builder: (_) => const AgeVerifiedGuard(
            child: ProfileCompleteGuard(
              child: UserDiscoveryPage(),
            ),
          ),
        );

      // Social Graph
      case followers:
        final args = settings.arguments as Map<String, dynamic>?;
        final userId = args?['userId'] as String?;
        final displayName = args?['displayName'] as String?;
        if (userId == null || displayName == null) {
          return _errorRoute('User ID and display name required');
        }
        return MaterialPageRoute(
          builder: (_) => AgeVerifiedGuard(
            child: FollowersListPage(
              userId: userId,
              displayName: displayName,
            ),
          ),
        );

      case following:
        final args = settings.arguments as Map<String, dynamic>?;
        final userId = args?['userId'] as String?;
        final displayName = args?['displayName'] as String?;
        if (userId == null || displayName == null) {
          return _errorRoute('User ID and display name required');
        }
        return MaterialPageRoute(
          builder: (_) => AgeVerifiedGuard(
            child: FollowingListPage(
              userId: userId,
              displayName: displayName,
            ),
          ),
        );

      case suggested:
        return MaterialPageRoute(
          builder: (_) => const AgeVerifiedGuard(
            child: ProfileCompleteGuard(
              child: SuggestedUsersPage(),
            ),
          ),
        );

      // Monetization
      case coins:
        return MaterialPageRoute(
          builder: (_) => const AgeVerifiedGuard(
            child: CoinStoreScreen(),
          ),
        );

      case membershipUpgrade:
        return MaterialPageRoute(
          builder: (_) => const AgeVerifiedGuard(
            child: MembershipUpgradeScreen(),
          ),
        );

      // Moderation
      case reportUser:
        final args = settings.arguments as Map<String, dynamic>?;
        final reportedUserId = args?['userId'] as String?;
        final reportedUserName = args?['userName'] as String?;
        if (reportedUserId == null) {
          return _errorRoute('Reported user ID required');
        }
        return MaterialPageRoute(
          builder: (_) => AgeVerifiedGuard(
            child: ReportUserScreen(
              reportedUserId: reportedUserId,
              reportedUserName: reportedUserName ?? 'User',
            ),
          ),
        );

      case blockedUsers:
        return MaterialPageRoute(
          builder: (_) => const AgeVerifiedGuard(
            child: BlockedUsersScreen(),
          ),
        );

      // Admin
      case adminDashboard:
        return MaterialPageRoute(
          builder: (_) => const AgeVerifiedGuard(
            child: AdminDashboardPage(),
          ),
        );

      // Settings
      case settings:
        // TODO: Create SettingsPage
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('Settings\n(Coming soon)'),
            ),
          ),
        );

      // Unknown route
      default:
        return _errorRoute('Route not found: ${settings.name}');
    }
  }

  /// Error route
  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error',
                style: Theme.of(_).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(message),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(_).pushReplacementNamed(landing),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
