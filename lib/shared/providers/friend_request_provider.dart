import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/social/friend_service.dart';
import 'auth_providers.dart';

// ── Service provider ──────────────────────────────────────────────────────────

final friendServiceProvider = Provider<FriendService>((ref) => FriendService());

// ── Friend status with a specific user ───────────────────────────────────────

final friendStatusProvider =
    StreamProvider.family<FriendRequestStatus, String>((ref, userId) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value(FriendRequestStatus.none);
  return ref.read(friendServiceProvider).watchFriendStatus(userId);
});

// ── Incoming friend requests ──────────────────────────────────────────────────

final incomingFriendRequestsProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value([]);
  return ref.read(friendServiceProvider).watchIncomingRequests();
});

/// Count for badge indicators on nav bar / friend list tab.
final pendingFriendRequestCountProvider = Provider<int>((ref) {
  return ref.watch(incomingFriendRequestsProvider).maybeWhen(
    data: (reqs) => reqs.length,
    orElse: () => 0,
  );
});

// ── Friend IDs stream ──────────────────────────────────────────────────────────

final friendIdsProvider = StreamProvider<List<String>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value([]);
  return ref.read(friendServiceProvider).watchFriendIds();
});
