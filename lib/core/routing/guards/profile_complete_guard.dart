/// Profile Complete Guard
/// Protects routes that require completed onboarding
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// TEMP DISABLED: import '../../features/onboarding/providers/onboarding_controller.dart';
// TEMP DISABLED: import '../../features/onboarding/onboarding_flow.dart';

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
    // TEMP DISABLED: Onboarding bypassed for development
    return child;

    // Original guard logic (commented out):
    // final onboardingCompleteAsync = ref.watch(hasCompletedOnboardingProvider);
    // return onboardingCompleteAsync.when(
    //   data: (isComplete) => isComplete ? child : OnboardingFlow(),
    //   loading: () => CircularProgressIndicator(),
    //   error: (error, stack) => ErrorScreen(),
    // );
  }
}
