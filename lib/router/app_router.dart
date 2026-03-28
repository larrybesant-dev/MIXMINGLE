
import 'dart:developer' as developer;

import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mixvy/features/auth/controllers/auth_controller.dart';
import 'package:mixvy/core/services/first_run_service.dart';
import 'package:mixvy/core/services/profile_gate_service.dart';
import 'package:mixvy/features/onboarding/onboarding_screen.dart';
import 'package:mixvy/features/feed/screens/discovery_feed_screen.dart';
import 'package:mixvy/features/profile/user_profile_screen.dart';
import 'package:mixvy/presentation/screens/friend_list_screen.dart';
import 'package:mixvy/presentation/screens/live_room_screen.dart';
import 'package:mixvy/presentation/screens/notifications_screen.dart';
import 'package:mixvy/presentation/screens/settings_screen.dart';
import 'package:mixvy/features/speed_dating/screens/speed_dating_screen.dart';

import '../features/auth/register_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/payments/payments_screen.dart';


// Supabase logic removed.

import 'package:mixvy/features/auth/screens/login_screen.dart';
import '../features/dashboard/dashboard_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      try {
        final loggedIn = authState.uid != null;
        final isLoggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/register';
        final isOnboarding = state.matchedLocation == '/onboarding';
        final isProfile = state.matchedLocation == '/profile';
        final isFirstRun = await FirstRunService.isFirstRun();

        if (isFirstRun && !isOnboarding) return '/onboarding';
        if (!isFirstRun && isOnboarding) return loggedIn ? '/' : '/login';
        if (!loggedIn && !isLoggingIn) return '/login';
        if (loggedIn) {
          final profileComplete = await ProfileGateService.isProfileComplete(authState.uid!);
          if (!profileComplete && !isProfile) return '/profile';
          if (profileComplete && isProfile && !isFirstRun) return '/';
        }
        if (loggedIn && isLoggingIn) return '/';
        return null;
      } catch (error, stackTrace) {
        developer.log(
          'Router redirect failed for ${state.matchedLocation}',
          name: 'AppRouter',
          error: error,
          stackTrace: stackTrace,
        );
        return null;
      }
    },
    routes: [
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
      GoRoute(path: '/discover', builder: (context, state) => const DiscoveryFeedScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
      GoRoute(
        path: '/profile/:userId',
        builder: (context, state) => UserProfileScreen(
          userId: state.pathParameters['userId']!,
        ),
      ),
      GoRoute(path: '/payments', builder: (context, state) => const PaymentsScreen()),
      GoRoute(path: '/speed-dating', builder: (context, state) => const SpeedDatingScreen()),
      GoRoute(path: '/friends', builder: (context, state) => const FriendListScreen()),
      GoRoute(
        path: '/room/:roomId',
        builder: (context, state) => LiveRoomScreen(
          roomId: state.pathParameters['roomId']!,
        ),
      ),
      GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
    ],
  );
});
