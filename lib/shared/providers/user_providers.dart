import '../../models/user_profile.dart';
import '../../services/user/profile_service.dart';
/// User profile by ID provider
final userProfileProvider = FutureProvider.family<UserProfile?, String>((ref, userId) async {
  final profileService = ref.watch(profileServiceProvider);
  return await profileService.getUserProfile(userId);
});
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/user/profile_service.dart';
import '../../services/social/presence_service.dart';
import '../models/user_presence.dart';
import '../../providers/all_providers.dart';

/// Service providers
final profileServiceProvider = Provider<ProfileService>((ref) => ProfileService());

final presenceServiceProvider = Provider<PresenceService>((ref) => PresenceService());

// Use currentUserProfileProvider from lib/providers/all_providers.dart

/// User profile by ID provider

/// User presence provider - Phase 2 Hardened
/// Uses error handling and prevents infinite retry loops
final userPresenceProvider = StreamProvider.family<UserPresence?, String>((ref, userId) {
  final presenceService = ref.watch(presenceServiceProvider);

  // Get stream with built-in error handling and retry guards
  return presenceService.getUserPresence(userId).handleError((error, stackTrace) {
    debugPrint('âŒ userPresenceProvider error for $userId: $error');
    return null; // Return null on error instead of propagating
  });
});

/// User search controller

final userSearchControllerProvider = NotifierProvider<UserSearchController, AsyncValue<List<UserProfile>>>(() {
  return UserSearchController();
});

class UserSearchController extends Notifier<AsyncValue<List<UserProfile>>> {
  @override
  AsyncValue<List<UserProfile>> build() {
    return const AsyncValue.data([]);
  }

  Future<void> searchUsers(String query) async {
    // TODO: Implement search logic
  }

  Future<void> filterByInterests(List<String> interests) async {
    // TODO: Implement filter logic
  }
}

final blockedUsersProvider = StreamProvider<List<String>>((ref) async* {
  final currentUser = ref.watch(currentUserProfileProvider).value;
  if (currentUser == null) {
    yield [];
    return;
  }
  yield [];
});

final userFollowersProvider = StreamProvider.family<List<UserProfile>, String>((ref, userId) async* {
  yield [];
});

final userFollowingProvider = StreamProvider.family<List<UserProfile>, String>((ref, userId) async* {
  yield [];
});

/// User statistics provider
final userStatisticsProvider = StreamProvider.family<Map<String, dynamic>, String>((ref, userId) async* {
  // This would aggregate various user stats
  // For now, return empty map
  yield {};
});

/// Blocked users provider
// Duplicate provider declarations removed. Only one valid declaration for each remains above.
// Usage in UI:
// final controller = PaginationController<UserProfile>(
//   queryBuilder: () => FirebaseFirestore.instance.collection('users').limit(20),
//   fromDocument: (doc) => UserProfile.fromFirestore(doc),
// );
// await controller.loadInitial();
// await controller.loadMore();
