import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_providers.dart';

final profileCompletionProvider = Provider<bool>((ref) {
  final currentUserProfile = ref.watch(currentUserProfileProvider).value;

  if (currentUserProfile == null) return false;

  final hasBasicInfo = currentUserProfile.displayName != null &&
      currentUserProfile.displayName!.isNotEmpty &&
      currentUserProfile.age != null &&
      currentUserProfile.age! >= 18 &&
      currentUserProfile.gender != null;

  final hasInterests = currentUserProfile.interests != null && currentUserProfile.interests!.length >= 3;

  return hasBasicInfo && hasInterests;
});

final needsOnboardingProvider = Provider<bool>((ref) {
  final currentUserProfile = ref.watch(currentUserProfileProvider).value;
  final isProfileComplete = ref.watch(profileCompletionProvider);

  return currentUserProfile != null && !isProfileComplete;
});
