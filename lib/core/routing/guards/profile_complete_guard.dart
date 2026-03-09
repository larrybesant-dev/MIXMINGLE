/// Profile Complete Guard
/// Protects routes that require completed onboarding
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/all_providers.dart';
import 'package:auto_route/auto_route.dart';
import '../../features/onboarding/routes/onboarding_route.dart';

/// Guard widget that checks if user has completed onboarding
/// If not complete, shows OnboardingFlow
class ProfileCompleteGuard extends AutoRouteGuard {
  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    final context = resolver.context;
    final ref = ProviderScope.containerOf(context);

    final onboardingAsync = ref.read(hasCompletedOnboardingProvider);

    onboardingAsync.when(
      data: (isComplete) {
        if (isComplete == true) {
          resolver.next(true);
        } else {
          router.replace(const OnboardingRoute());
        }
      },
      loading: () {
        resolver.next(false);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );
      },
      error: (e, st) {
        resolver.next(false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading onboarding status')),
        );
      },
    );
  }
}
