/// Profile Complete Guard
/// Protects routes that require completed onboarding
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/onboarding/providers/onboarding_controller.dart';
import '../../features/onboarding/onboarding_flow.dart';

/// Guard widget that checks if user has completed onboarding
/// If not complete, shows OnboardingFlow
class ProfileCompleteGuard extends ConsumerWidget {
  final Widget child;

  const ProfileCompleteGuard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingCompleteAsync = ref.watch(hasCompletedOnboardingProvider);

    return onboardingCompleteAsync.when(
      data: (isComplete) {
        if (isComplete) {
          return child;
        }

        // Not complete - show onboarding flow
        return const OnboardingFlow();
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
                'Error checking profile status',
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
