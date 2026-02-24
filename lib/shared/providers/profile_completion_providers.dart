import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_providers.dart';

final profileCompletionProvider = Provider<bool>((ref) {
  final currentUserProfile = ref.watch(currentUserProfileProvider).value;

  if (currentUserProfile == null) return false;

  // Only require a displayName to be considered complete.
  // Age, gender, and interests are optional — users can fill them in later.
  final hasDisplayName = currentUserProfile.displayName != null &&
      currentUserProfile.displayName!.isNotEmpty;

  return hasDisplayName;
});

final needsOnboardingProvider = Provider<bool>((ref) {
  // Always return false — onboarding redirect is disabled.
  // Remove this override to re-enable the onboarding gate.
  return false;
});
