/// Onboarding Controller - Stub for compilation
/// TODO: Implement full onboarding state management
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to check if user has verified their age
final hasVerifiedAgeProvider = Provider<bool>((ref) {
  // TODO: Check actual age verification status from Firestore or local storage
  return false;
});

/// Provider to check if user has completed onboarding
final hasCompletedOnboardingProvider = Provider<bool>((ref) {
  // TODO: Check actual onboarding completion status
  return false;
});

/// Onboarding state controller
class OnboardingController extends StateNotifier<OnboardingState> {
  OnboardingController() : super(OnboardingState());

  void completeAgeVerification() {
    // TODO: Implement
  }

  void completeOnboarding() {
    // TODO: Implement
  }
}

/// Onboarding state model
class OnboardingState {
  final bool ageVerified;
  final bool onboardingComplete;

  OnboardingState({
    this.ageVerified = false,
    this.onboardingComplete = false,
  });
}

final onboardingControllerProvider = StateNotifierProvider<OnboardingController, OnboardingState>(
  (ref) => OnboardingController(),
);
