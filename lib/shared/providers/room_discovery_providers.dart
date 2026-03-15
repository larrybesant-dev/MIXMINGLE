// lib/shared/providers/room_discovery_providers.dart
// Phase 10: Stream-based room discovery providers.
// All providers use Firestore snapshot streams — no polling, no Stream.periodic.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/room/room_discovery_service.dart';
import '../models/room.dart';

final roomDiscoveryServiceProvider =
    Provider<RoomDiscoveryService>((ref) => RoomDiscoveryService());

/// Live stream of trending rooms (most viewers, public & active).
final trendingRoomsProvider = StreamProvider<List<Room>>((ref) {
  return ref.watch(roomDiscoveryServiceProvider).getTrendingRoomsStream();
});

<<<<<<< HEAD
/// Live stream of newest rooms (public, ordered by createdAt desc).
final newRoomsProvider = StreamProvider<List<Room>>((ref) {
  return ref.watch(roomDiscoveryServiceProvider).getNewRoomsStream();
=======
final activeRoomsProvider = FutureProvider<List<DocumentSnapshot>>((ref) async {
  final service = ref.read(roomDiscoveryServiceProvider);
  return service.getRoomsByCategory('active');
>>>>>>> origin/develop
});

/// Live stream of recommended rooms personalised for [userId].
final recommendedRoomsProvider =
    StreamProvider.family<List<Room>, String>((ref, userId) {
  return ref
      .watch(roomDiscoveryServiceProvider)
      .getRecommendedRoomsStream(userId);
});

