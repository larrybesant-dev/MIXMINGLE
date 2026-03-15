import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/social/social_graph_service.dart';
import '../../services/social/social_feed_service.dart';
import '../models/user_profile.dart';
import '../models/user_presence.dart';
import '../models/post.dart';
import 'user_providers.dart'; // For profileServiceProvider + presenceServiceProvider

// Service providers
final socialGraphServiceProvider =
    Provider<SocialGraphService>((ref) => SocialGraphService());

// Followers list provider (stream of user IDs)
final followersIdsProvider =
    StreamProvider.family<List<String>, String>((ref, userId) {
  final service = ref.watch(socialGraphServiceProvider);
  return service.watchFollowers(userId);
});

// Following list provider (stream of user IDs)
final followingIdsProvider =
    StreamProvider.family<List<String>, String>((ref, userId) {
  final service = ref.watch(socialGraphServiceProvider);
  return service.watchFollowing(userId);
});

// Mutual friends list provider (stream of user IDs)
final mutualFriendsIdsProvider =
    StreamProvider.family<List<String>, String>((ref, userId) {
  final service = ref.watch(socialGraphServiceProvider);
  return service.watchMutualFriends(userId);
});

// Is following provider (stream of bool)
final isFollowingProvider =
    StreamProvider.family<bool, String>((ref, targetUserId) {
  final service = ref.watch(socialGraphServiceProvider);
  return service.watchIsFollowing(targetUserId);
});

// Follower profiles provider (FutureProvider for simplicity)
final followerProfilesProvider =
    FutureProvider.family<List<UserProfile>, String>((ref, userId) async {
  final service = ref.watch(socialGraphServiceProvider);
  final profileService = ref.watch(profileServiceProvider);

  final ids = await service.getFollowers(userId);
  final profiles = <UserProfile>[];

  for (final id in ids) {
    try {
      final profile = await profileService.getUserProfile(id);
      if (profile != null) {
        profiles.add(profile);
      }
    } catch (e) {
      // Skip profiles that fail to load
      continue;
    }
  }

  return profiles;
});

// Following profiles provider
final followingProfilesProvider =
    FutureProvider.family<List<UserProfile>, String>((ref, userId) async {
  final service = ref.watch(socialGraphServiceProvider);
  final profileService = ref.watch(profileServiceProvider);

  final ids = await service.getFollowing(userId);
  final profiles = <UserProfile>[];

  for (final id in ids) {
    try {
      final profile = await profileService.getUserProfile(id);
      if (profile != null) {
        profiles.add(profile);
      }
    } catch (e) {
      // Skip profiles that fail to load
      continue;
    }
  }

  return profiles;
});

// Mutual friends profiles provider
final mutualFriendsProfilesProvider =
    FutureProvider.family<List<UserProfile>, String>((ref, userId) async {
  final service = ref.watch(socialGraphServiceProvider);
  final profileService = ref.watch(profileServiceProvider);

  final ids = await service.getMutualFriends(userId);
  final profiles = <UserProfile>[];

  for (final id in ids) {
    try {
      final profile = await profileService.getUserProfile(id);
      if (profile != null) {
        profiles.add(profile);
      }
    } catch (e) {
      // Skip profiles that fail to load
      continue;
    }
  }

  return profiles;
});

// suggestedUsersProvider lives in discovery_providers.dart (StreamProvider)
// import 'package:mixmingle/shared/providers/discovery_providers.dart'

<<<<<<< HEAD
// Presence provider — moved to user_providers.dart to avoid duplicate symbol.
// Use userPresenceProvider(uid) from user_providers.dart (exported via all_providers.dart).
=======
// Presence provider (using existing presence service)
final userPresenceProvider =
    StreamProvider.family<UserPresence?, String>((ref, userId) {
  final service = ref.watch(presenceServiceProvider);
  return service.getUserPresence(userId);
});
>>>>>>> origin/develop

// Follower/following counts
final followerCountProvider =
    FutureProvider.family<int, String>((ref, userId) async {
  final service = ref.watch(socialGraphServiceProvider);
  return service.getFollowerCount(userId);
});

final followingCountProvider =
    FutureProvider.family<int, String>((ref, userId) async {
  final service = ref.watch(socialGraphServiceProvider);
  return service.getFollowingCount(userId);
});

// Follow action provider (for UI interactions)
final followActionProvider =
    FutureProvider.family<void, ({String userId, bool follow})>(
        (ref, params) async {
  final service = ref.watch(socialGraphServiceProvider);

  if (params.follow) {
    await service.followUser(params.userId);
  } else {
    await service.unfollowUser(params.userId);
  }

  // Invalidate related providers to refresh UI
  ref.invalidate(isFollowingProvider(params.userId));
  ref.invalidate(followerCountProvider(params.userId));
});
<<<<<<< HEAD

// Following feed provider — posts from users the current user follows + own posts.
// Uses the users/{uid}/following subcollection.
final followingFeedProvider = StreamProvider.family<List<Post>, String>((ref, userId) {
  final feedService = ref.watch(socialFeedServiceProvider);
  return feedService.getFollowingFeedStream(userId);
});

// Social feed service provider
final socialFeedServiceProvider = Provider<SocialFeedService>((ref) => SocialFeedService.instance);

// ─────────────────────────────────────────────────────────────────────────────
// MUTUAL FOLLOWERS  (people who follow profileUser that currentUser also follows)
// ─────────────────────────────────────────────────────────────────────────────

/// Returns profiles of users who follow [profileUserId] that [currentUserId] also follows.
/// Capped at 10 results. Use as: `mutualFollowersProvider((currentUserId: id, profileUserId: pid))`
final mutualFollowersProvider =
    FutureProvider.family<List<UserProfile>, ({String currentUserId, String profileUserId})>(
        (ref, params) async {
  final service = ref.watch(socialGraphServiceProvider);
  final profileService = ref.watch(profileServiceProvider);

  final profileUserFollowers = await service.getFollowers(params.profileUserId);
  if (profileUserFollowers.isEmpty) return [];

  final currentUserFollowing = await service.getFollowing(params.currentUserId);
  if (currentUserFollowing.isEmpty) return [];

  final mutualIds = profileUserFollowers
      .where((id) => currentUserFollowing.contains(id))
      .take(10)
      .toList();
  if (mutualIds.isEmpty) return [];

  final profiles = <UserProfile>[];
  for (final id in mutualIds) {
    try {
      final p = await profileService.getUserProfile(id);
      if (p != null) profiles.add(p);
    } catch (_) {}
  }
  return profiles;
});

// ─────────────────────────────────────────────────────────────────────────────
// PRESENCE PROVIDERS
// ─────────────────────────────────────────────────────────────────────────────

/// Last-active timestamp provider — real-time stream of when userId was last seen.
final lastActiveProvider = StreamProvider.family<DateTime?, String>((ref, userId) {
  final presenceService = ref.watch(presenceServiceProvider);
  return presenceService.getUserPresence(userId).map((p) => p?.lastUpdate);
});

/// Active friends provider — list of followed users who are currently online or away,
/// respecting the 10-minute stale threshold.
/// Returns at most 30 users (Firestore whereIn limit).
final activeFriendsProvider = StreamProvider<List<UserPresence>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value([]);

  final followingAsync = ref.watch(followingIdsProvider(uid));
  final ids = followingAsync.value ?? [];
  if (ids.isEmpty) return Stream.value([]);

  // Firestore whereIn supports up to 30 values
  final queryIds = ids.take(30).toList();

  return FirebaseFirestore.instance
      .collection('presence')
      .where(FieldPath.documentId, whereIn: queryIds)
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => UserPresence.fromMap(doc.id, doc.data()))
          .where((p) =>
              !p.isStale &&
              (p.state == PresenceState.online || p.state == PresenceState.away))
          .toList());
});

=======
>>>>>>> origin/develop
