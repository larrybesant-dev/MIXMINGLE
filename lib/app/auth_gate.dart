import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_providers.dart';
import 'package:mixmingle/core/routing/app_routes.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);

<<<<<<< HEAD
    return auth.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Not signed in')),
=======
          // Initialize presence service for authenticated user (non-blocking)
          Future.microtask(() async {
            try {
              final presenceService = ref.read(presenceServiceProvider);
              await presenceService.initializePresence();
              await presenceService.goOnline();
              debugPrint('âœ… Presence initialized for user ${user.uid}');
            } catch (e) {
              debugPrint('âš ï¸ Presence initialization failed: $e');
              // App continues - presence is optional for rendering
            }
          });

          // Temporarily disable email verification requirement for development
          // if (user.emailVerified) {
          // Check if user has completed profile
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get(),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (profileSnapshot.hasData && profileSnapshot.data!.exists) {
                final profileData =
                    profileSnapshot.data!.data() as Map<String, dynamic>?;
                // Check if profile has required fields (displayName at minimum)
                if (profileData != null && profileData['displayName'] != null) {
                  return child; // Profile complete, show protected content
                }
              }

              // Profile incomplete, redirect to profile creation
              return const CreateProfilePage();
            },
>>>>>>> origin/develop
          );
        }
        // User is authenticated — redirect to the home screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.home,
            (_) => false,
          );
        });
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const Scaffold(
        body: Center(child: Text('Auth error')),
      ),
    );
  }
}
