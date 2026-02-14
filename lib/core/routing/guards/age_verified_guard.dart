/// Age Verified Guard
/// Protects routes that require 18+ age verification
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/onboarding/providers/onboarding_controller.dart';
import '../../features/onboarding/screens/age_gate_page.dart';

/// Guard widget that checks if user has verified their age (18+)
/// If not verified, shows AgeGatePage
class AgeVerifiedGuard extends ConsumerWidget {
  final Widget child;

  const AgeVerifiedGuard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ageVerifiedAsync = ref.watch(hasVerifiedAgeProvider);

    return ageVerifiedAsync.when(
      data: (isVerified) {
        if (isVerified) {
          return child;
        }

        // Not verified - show age gate
        return AgeGatePage(
          onConfirm: () {
            // After confirmation, the provider will auto-refresh
            // and show the child widget
          },
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error checking age verification',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
