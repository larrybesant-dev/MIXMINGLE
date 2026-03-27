
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mixvy/features/auth/controllers/auth_controller.dart';
import 'package:mixvy/core/services/first_run_service.dart';
import 'package:mixvy/features/onboarding/onboarding_screen.dart';

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
      final loggedIn = authState.uid != null;
      final isLoggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/register';
      final isOnboarding = state.matchedLocation == '/onboarding';
      final isFirstRun = await FirstRunService.isFirstRun();

      if (isFirstRun && !isOnboarding) return '/onboarding';
      if (!isFirstRun && isOnboarding) return loggedIn ? '/' : '/login';
      if (!loggedIn && !isLoggingIn) return '/login';
      if (loggedIn && isLoggingIn) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
      GoRoute(path: '/payments', builder: (context, state) => const PaymentsScreen()),
    ],
  );
});
