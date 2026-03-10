import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/all_providers.dart';
import '../core/routing/app_routes.dart';
import '../shared/widgets/loading_widgets.dart';
import '../features/auth/screens/neon_login_page.dart';
import '../features/auth/screens/neon_signup_page.dart';

class AuthGateRoot extends ConsumerWidget {
  const AuthGateRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authStateProvider).value;
    final profileAsync = ref.watch(currentUserProfileProvider);
    // Prevent duplicate navigation
    bool navigated = false;

    if (authUser == null) {
      debugPrint('[AuthGateRoot] No auth user, showing login page');
      return const NeonLoginPage();
    }

    return profileAsync.when(
      loading: () {
        debugPrint('[AuthGateRoot] Profile loading...');
        return const FullScreenLoader(message: 'Loading MixMingle...');
      },
      error: (e, st) {
        debugPrint('[AuthGateRoot] Profile error: $e');
        return const FullScreenLoader(message: 'Profile error');
      },
      data: (profile) {
        if (profile == null) {
          debugPrint('[AuthGateRoot] Profile is null, showing signup page');
          return const NeonSignupPage();
        }
        if (profile.ageVerified == false) {
          debugPrint('[AuthGateRoot] Age not verified, redirecting to age gate');
          if (!navigated) {
            navigated = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushNamed(context, AppRoutes.ageGate);
            });
          }
          return const FullScreenLoader(message: 'Redirecting to age verification...');
        }
        if (profile.onboardingComplete == false) {
          debugPrint('[AuthGateRoot] Onboarding not complete, redirecting to onboarding');
          if (!navigated) {
            navigated = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushNamed(context, AppRoutes.onboarding);
            });
          }
          return const FullScreenLoader(message: 'Redirecting to onboarding...');
        }
        debugPrint('[AuthGateRoot] Profile ready, redirecting to home');
        if (!navigated) {
          navigated = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushNamed(context, AppRoutes.home);
          });
        }
        return const FullScreenLoader(message: 'Redirecting to MixVy home...');
      },
    );
  }
}
