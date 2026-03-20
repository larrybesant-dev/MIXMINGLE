
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../features/auth/register_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/profile/edit_profile_screen.dart';
import '../features/payments/payments_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/chat/chat_list_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/events/events_screen.dart';
import '../features/events/create_event_screen.dart';
import '../features/events/event_detail_screen.dart';
// Add more feature imports as needed

// final supabase = Supabase.instance.client;

import 'package:flutter/material.dart';
import 'package:mixvy/features/auth/screens/login_screen.dart';
import '../features/home/home_screen.dart';

class AppRouter {
  static Route<dynamic> generate(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/home':
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case '/profile':
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      default:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
  }
}
final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null;

    final isAuthRoute =
      state.matchedLocation == '/login' ||
      state.matchedLocation == '/register' ||
      state.matchedLocation == '/splash';

    // 🚫 Not logged in → force login
    if (!isLoggedIn && !isAuthRoute) {
      return '/login';
    }

    // ✅ Logged in → block auth screens
    if (isLoggedIn && isAuthRoute) {
      return '/home';
    }

    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
    GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
    GoRoute(path: '/profile/edit', builder: (context, state) => const EditProfileScreen()),
    GoRoute(path: '/payments', builder: (context, state) => const PaymentsScreen()),
    GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
    GoRoute(path: '/chats', builder: (context, state) => const ChatListScreen()),
    GoRoute(path: '/chat/:roomId', builder: (context, state) => const ChatScreen()),
    GoRoute(path: '/events', builder: (context, state) => const EventsScreen()),
    GoRoute(path: '/events/create', builder: (context, state) => const CreateEventScreen()),
    GoRoute(path: '/events/detail/:eventId', builder: (context, state) => const EventDetailScreen()),
    // Add more routes as needed
  ],
);
