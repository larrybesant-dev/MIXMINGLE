/// Age Verified Guard
/// Protects routes that require 18+ age verification.
/// If the signed-in user's Firestore document has ageVerified != true,
/// their session is terminated and they are redirected to the age gate.
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_routes.dart';
import '../../../shared/providers/auth_providers.dart';

class AgeVerifiedGuard extends ConsumerWidget {
  final Widget child;

  const AgeVerifiedGuard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      // ── Show child only when ageVerified is confirmed ────────────
      data: (user) {
        if (user == null) {
          // No auth user — let the auth gate handle redirection.
          return const SizedBox.shrink();
        }
        if (user.ageVerified != true) {
          // Age not verified: force sign-out then send to age gate.
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await FirebaseAuth.instance.signOut();
            if (context.mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.ageGate,
                (_) => false,
              );
            }
          });
          return const Scaffold(
            backgroundColor: Color(0xFF0A0C14),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return child;
      },
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF0A0C14),
        body: Center(child: CircularProgressIndicator()),
      ),
      // On Firestore error, allow access — don't hard-block on network issues.
      error: (_, __) => child,
    );
  }
}
