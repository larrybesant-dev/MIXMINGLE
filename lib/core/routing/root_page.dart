import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mixmingle/core/routing/app_routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/all_providers.dart';
import 'package:mixmingle/models/user_profile.dart';
// ...existing code...

void handleRouting(BuildContext context, UserProfile? profile) {
  final authUser = FirebaseAuth.instance.currentUser;

  if (authUser == null) {
    Navigator.pushReplacementNamed(context, AppRoutes.login);
    return;
  }

  if (profile == null) {
    // Wait for provider to finish loading
    return;
  }

  if (!profile.onboardingComplete) {
    Navigator.pushReplacementNamed(context, AppRoutes.signup);
    return;
  }
  if (profile.ageVerified != true) {
    Navigator.pushReplacementNamed(context, AppRoutes.ageGate);
    return;
  }
  Navigator.pushReplacementNamed(context, AppRoutes.home);
}

class RootPage extends ConsumerWidget {
  const RootPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return profileAsync.when(
      data: (profile) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          handleRouting(context, profile);
        });
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Scaffold(
        body: Center(child: Text('Error loading profile: $e')),
      ),
    );
  }
}
