
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mixvy/features/auth/controllers/auth_controller.dart';
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

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final isLoggedIn = authState.uid != null;
      final isAuthRoute =
        state.matchedLocation == '/login' ||
        state.matchedLocation == '/register' ||
        state.matchedLocation == '/splash';
      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }
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
});
