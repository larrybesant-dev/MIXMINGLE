
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mixvy/features/auth/controllers/auth_controller.dart';

import '../features/auth/register_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/payments/payments_screen.dart';
import 'package:mixvy/features/auth/screens/login_screen.dart';
import '../features/dashboard/dashboard_screen.dart';

// Supabase logic removed.

import 'package:mixvy/features/auth/screens/login_screen.dart';
import '../features/dashboard/dashboard_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final loggedIn = authState.uid != null;
      final isLoggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/register';
      if (!loggedIn && !isLoggingIn) return '/login';
      if (loggedIn && isLoggingIn) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
      GoRoute(path: '/payments', builder: (context, state) => const PaymentsScreen()),
    ],
  );
});
