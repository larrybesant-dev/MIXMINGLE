// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mixmingle/shared/widgets/club_background.dart';
import 'package:mixmingle/shared/widgets/neon_button.dart';
import 'package:mixmingle/app_routes.dart';
import 'package:mixmingle/providers/profile_completion_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final needsOnboarding = ref.watch(needsOnboardingProvider);

    // Redirect to onboarding if profile is incomplete
    if (needsOnboarding) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.onboarding,
          (route) => false,
        );
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = FirebaseAuth.instance.currentUser;
    return ClubBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (!context.mounted) return;
                Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
              },
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Welcome, ${user?.email ?? 'User'}',
                style: const TextStyle(fontSize: 18),
              ),
              NeonButton(
                label: 'Profile',
                onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
              ),
              NeonButton(
                label: 'Matches',
                onPressed: () => Navigator.pushNamed(context, AppRoutes.matches),
              ),
              NeonButton(
                label: 'Chats',
                onPressed: () => Navigator.pushNamed(context, AppRoutes.chats),
              ),
              NeonButton(
                label: 'Create Room',
                onPressed: () => Navigator.pushNamed(context, AppRoutes.createRoom),
              ),
              NeonButton(
                label: 'Discover Rooms',
                onPressed: () => Navigator.pushNamed(context, AppRoutes.discoverRooms),
              ),
              NeonButton(
                label: 'Settings',
                onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
