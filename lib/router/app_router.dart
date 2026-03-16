import 'package:go_router/go_router.dart';

import '../presentation/screens/splash_screen.dart';
import '../presentation/screens/login_screen.dart';
import '../presentation/screens/register_screen.dart';
import '../presentation/screens/home_feed_screen.dart';
import '../presentation/screens/friend_list_screen.dart';
import '../presentation/screens/friend_requests_screen.dart';
import '../presentation/screens/chat_list_screen.dart';
import '../presentation/screens/chat_screen.dart';
import '../presentation/screens/create_room_screen.dart';
import '../presentation/screens/room_screen.dart';
import '../presentation/screens/room_members_screen.dart';
import '../presentation/screens/user_profile_screen.dart';
import '../presentation/screens/edit_profile_screen.dart';
import '../presentation/screens/notifications_screen.dart';
import '../presentation/screens/settings_screen.dart';
import '../presentation/screens/payments_screen.dart';
import '../presentation/screens/referral_screen.dart';
import '../presentation/screens/moderation_screen.dart';
import '../presentation/screens/admin_dashboard_screen.dart';
import '../presentation/screens/search_screen.dart';
import '../presentation/screens/invite_friends_screen.dart';
import '../presentation/screens/live_room_screen.dart';
import '../presentation/screens/room_history_screen.dart';
import '../presentation/screens/event_screen.dart';
import '../presentation/screens/membership_screen.dart';

final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(path: '/home', builder: (context, state) => const HomeFeedScreen()),
    GoRoute(
      path: '/friends',
      builder: (context, state) => const FriendListScreen(),
    ),
    GoRoute(
      path: '/friend-requests',
      builder: (context, state) => const FriendRequestsScreen(),
    ),
    GoRoute(
      path: '/chats',
      builder: (context, state) => const ChatListScreen(),
    ),
    GoRoute(
      path: '/chat/:roomId',
      builder: (context, state) => const ChatScreen(),
    ),
    GoRoute(
      path: '/room/create',
      builder: (context, state) => const CreateRoomScreen(),
    ),
    GoRoute(
      path: '/room/:roomId',
      builder: (context, state) => const RoomScreen(),
    ),
    GoRoute(
      path: '/room/members/:roomId',
      builder: (context, state) => const RoomMembersScreen(),
    ),
    GoRoute(
      path: '/profile/:userId',
      builder: (context, state) => const UserProfileScreen(),
    ),
    GoRoute(
      path: '/profile/edit',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/payments',
      builder: (context, state) => const PaymentsScreen(),
    ),
    GoRoute(
      path: '/referral',
      builder: (context, state) => const ReferralScreen(),
    ),
    GoRoute(
      path: '/moderation',
      builder: (context, state) => const ModerationScreen(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(path: '/search', builder: (context, state) => const SearchScreen()),
    GoRoute(
      path: '/invite',
      builder: (context, state) => const InviteFriendsScreen(),
    ),
    GoRoute(
      path: '/live/:roomId',
      builder: (context, state) => const LiveRoomScreen(),
    ),
    GoRoute(
      path: '/room/history',
      builder: (context, state) => const RoomHistoryScreen(),
    ),
    GoRoute(
      path: '/event/:eventId',
      builder: (context, state) => const EventScreen(),
    ),
    GoRoute(
      path: '/membership',
      builder: (context, state) => const MembershipScreen(),
    ),
  ],
);
