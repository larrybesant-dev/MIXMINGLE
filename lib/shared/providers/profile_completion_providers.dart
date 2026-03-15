import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_providers.dart';
import 'profile_controller.dart' hide currentUserProfileProvider;

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
<<<<<<< HEAD

/// 0–100 profile richness score based on five pillars:
/// avatar (20) + bio (20) + photos (15) + interests (15) + location (15) + music (15)
final profileCompletenessScoreProvider = Provider.family<int, String>((ref, userId) {
  final p = ref.watch(userProfileProvider(userId)).value;
  if (p == null) return 0;
  int score = 0;
  if ((p.photoUrl ?? '').isNotEmpty) score += 20;
  if ((p.bio ?? '').isNotEmpty) score += 20;
  if (p.galleryPhotos?.isNotEmpty ?? false) score += 15;
  if (p.interests?.isNotEmpty ?? false) score += 15;
  if ((p.location ?? '').isNotEmpty) score += 15;
  if ((p.musicTastes?.isNotEmpty ?? false) || (p.musicGenres?.isNotEmpty ?? false)) score += 15;
  return score;
});

=======
>>>>>>> origin/develop
