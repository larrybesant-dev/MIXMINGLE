// lib/shared/providers/discovery_providers.dart
//
// Four Riverpod StreamProviders for the Discovery System.
// All providers use Firestore snapshot streams — no polling, no Stream.periodic.
//
// Providers:
//   discoveryServiceProvider  – singleton DiscoveryService
//   suggestedUsersProvider    – users not yet followed, ranked by popularity
//   trendingUsersProvider     – top users by follower count
//   activeNowUsersProvider    – users currently online or away (presence-backed)
//   discoverableRoomsProvider – public active rooms by viewer count

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/social/discovery_service.dart';
import '../../models/user_profile.dart';
import '../models/room.dart';

// ── Service ──────────────────────────────────────────────────────────────────

final discoveryServiceProvider =
    Provider<DiscoveryService>((ref) => DiscoveryService());

// ── User Discovery ───────────────────────────────────────────────────────────

/// Stream of suggested users for the current user.
/// Excludes users already followed, ranked by follower count.
/// Refreshes automatically on each Firestore snapshot update.
final suggestedUsersProvider = StreamProvider<List<UserProfile>>((ref) {
  return ref.watch(discoveryServiceProvider).streamSuggestedUsers();
});

/// Stream of the top 20 users ranked by follower count descending.
final trendingUsersProvider = StreamProvider<List<UserProfile>>((ref) {
  return ref.watch(discoveryServiceProvider).streamTrendingUsers();
});

/// Stream of users who are currently online or away across the platform.
/// Backed by the `presence` Firestore collection.
final activeNowUsersProvider = StreamProvider<List<UserProfile>>((ref) {
  return ref.watch(discoveryServiceProvider).streamActiveNowUsers();
});

// ── Room Discovery ───────────────────────────────────────────────────────────

/// Stream of public, active rooms ordered by viewer count descending.
final discoverableRoomsProvider = StreamProvider<List<Room>>((ref) {
  return ref.watch(discoveryServiceProvider).streamDiscoverableRooms();
});
