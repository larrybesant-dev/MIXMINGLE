/// Profile Complete Guard
/// Protects routes that require completed onboarding
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/all_providers.dart';
import 'package:mixmingle/core/routing/app_routes.dart';
// Removed unused auto_route and missing onboarding_route imports

/// Guard widget that checks if user has completed onboarding
/// If not complete, shows OnboardingFlow
/// ProfileCompleteGuard checks onboarding completion and redirects if needed
class ProfileCompleteGuard {
  static Future<void> check(BuildContext context, WidgetRef ref) async {
    final onboardingComplete = ref.read(hasCompletedOnboardingProvider);
    if (onboardingComplete == true) {
      // Proceed as normal
      return;
    } else {
      // Redirect to onboarding
      Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
    }
  }
}
