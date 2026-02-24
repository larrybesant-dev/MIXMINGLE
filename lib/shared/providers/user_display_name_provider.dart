
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import 'user_providers.dart';

/// Cached display name provider with efficient fallback handling
///
/// This provider reduces Firestore reads by:
/// - Caching user profile lookups via Riverpod's built-in caching
/// - Providing fast, consistent name resolution across the app
/// - Handling null/error cases with sensible fallbacks
///
/// Usage:
/// ```dart
/// final displayName = ref.watch(userDisplayNameProvider(userId));
/// ```
final userDisplayNameProvider = FutureProvider.family<String, String>((ref, userId) async {
  if (userId.isEmpty) {
    return 'Unknown User';
  }

  try {
    // Watch the userProfileProvider which already has caching via StreamProvider
    final profileAsync = await ref.watch(userProfileProvider(userId).future);
    final profile = profileAsync;

    // Fallback chain: displayName -> username -> 'Unknown User'
    if (profile?.displayName != null && profile!.displayName!.isNotEmpty) {
      return profile.displayName!;
    }

    if (profile?.username != null && profile!.username!.isNotEmpty) {
      return profile.username!;
    }

    return 'Unknown User';
  } catch (e) {
    // If fetch fails, return graceful fallback
    return 'Unknown User';
  }
});

/// Batch display name provider for efficiently loading multiple names at once
///
/// Useful for participant lists, message threads, etc.
///
/// Usage:
/// ```dart
/// final names = ref.watch(batchUserDisplayNamesProvider(userIds));
/// ```
final batchUserDisplayNamesProvider = FutureProvider.family<Map<String, String>, List<String>>((ref, userIds) async {
  final names = <String, String>{};

  // Fetch all names in parallel
  final futures = userIds.map((userId) async {
    final name = await ref.watch(userDisplayNameProvider(userId).future);
    return MapEntry(userId, name);
  });

  final results = await Future.wait(futures);

  for (final entry in results) {
    names[entry.key] = entry.value;
  }

  return names;
});

/// Quick synchronous display name getter for when profile is already loaded
///
/// Returns null if profile not yet loaded, caller should use async provider
String? getCachedDisplayName(UserProfile? profile) {
  if (profile == null) return null;

  if (profile.displayName != null && profile.displayName!.isNotEmpty) {
    return profile.displayName;
  }

  if (profile.username != null && profile.username!.isNotEmpty) {
    return profile.username;
  }

  return 'Unknown User';
}

/// Display name with avatar initial helper
///
/// Returns first character of display name, uppercased
String getDisplayNameInitial(String displayName) {
  if (displayName.isEmpty || displayName == 'Unknown User') {
    return '?';
  }
  return displayName[0].toUpperCase();
}


