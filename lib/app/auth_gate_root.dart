import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_providers.dart';
import '../providers/all_providers.dart';
import '../shared/widgets/loading_widgets.dart';

class AuthGateRoot extends ConsumerWidget {
  const AuthGateRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authStateProvider).value;
    final profileAsync = ref.watch(currentUserProfileProvider);

    if (authUser == null) {
      return const NeonLoginPage();
    }

    return profileAsync.when(
      loading: () => const FullScreenLoader(message: 'Loading profile...'),
      error: (_, __) => const FullScreenLoader(message: 'Profile error'),
      data: (profile) {
        if (profile == null) {
          // Profile not created yet, show signup
          return const NeonSignupPage();
        }
        // --- Navigation logic ---
        if (!profile.ageVerified) {
          // Call ref.invalidate(currentUserProfileProvider) after age verification to force reload
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushNamed(context, AppRoutes.ageGate);
          });
          return const FullScreenLoader(message: 'Redirecting to age verification...');
        }
        if (!profile.onboardingComplete) {
          // Call ref.invalidate(currentUserProfileProvider) after onboarding to force reload
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushNamed(context, AppRoutes.onboarding);
          });
          return const FullScreenLoader(message: 'Redirecting to onboarding...');
        }
        // Profile is fully loaded and user is ready, show home
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushNamed(context, AppRoutes.home);
        });
        return const FullScreenLoader(message: 'Redirecting to home...');
      },
    );
  }
}
