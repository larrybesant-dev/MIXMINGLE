import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

/// Guard that ensures the current user has the `admin` Firebase custom claim.
/// Shows an "Access Denied" screen with a back button for non-admins.
class AdminGuard extends StatelessWidget {
  final Widget child;

  const AdminGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<fb_auth.IdTokenResult?>(
      future: fb_auth.FirebaseAuth.instance.currentUser?.getIdTokenResult(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF080C14),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final claims = snapshot.data?.claims ?? {};
        final isAdmin = claims['admin'] == true;

        if (!isAdmin) {
          return Scaffold(
            backgroundColor: const Color(0xFF080C14),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline,
                      color: Color(0xFFFF4C4C), size: 64),
                  const SizedBox(height: 24),
                  const Text(
                    'Access Denied',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Admin access required.',
                    style: TextStyle(color: Color(0xFF888888), fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1F2E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          );
        }

        return child;
      },
    );
  }
}
