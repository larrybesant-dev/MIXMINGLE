// lib/shared/providers/friend_providers.dart
//
// Riverpod providers for the Friend System.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/social/friend_service.dart';
import '../../shared/models/friend_request.dart';

// ── Service ────────────────────────────────────────────────────────────────────

final friendServiceProvider = Provider<FriendService>((ref) {
  return FriendService.instance;
});

// ── Streams ────────────────────────────────────────────────────────────────────

/// Incoming pending requests (real-time).
final incomingFriendRequestsProvider =
    StreamProvider<List<FriendRequest>>((ref) {
  final service = ref.watch(friendServiceProvider);
  return service.streamIncomingRequests();
});

/// Sent pending requests (real-time).
final sentFriendRequestsProvider =
    StreamProvider<List<FriendRequest>>((ref) {
  final service = ref.watch(friendServiceProvider);
  return service.streamSentRequests();
});

/// Friends list for current user.
final myFriendsProvider = StreamProvider<List<FriendEntry>>((ref) {
  final service = ref.watch(friendServiceProvider);
  return service.streamFriends();
});

/// Friends list for any user uid.
final friendsOfUserProvider =
    StreamProvider.family<List<FriendEntry>, String>((ref, uid) {
  final service = ref.watch(friendServiceProvider);
  return service.streamFriends(uid);
});

/// Live badge count for incoming requests.
final pendingFriendRequestCountProvider = StreamProvider<int>((ref) {
  final service = ref.watch(friendServiceProvider);
  return service.streamPendingCount();
});

// ── Relationship state for a specific target user ──────────────────────────────

enum FriendRelationship { none, pendingSent, pendingReceived, friends }

/// Resolves current user's relationship to [targetUid] — drives FriendRequestButton.
final friendRelationshipProvider =
    FutureProvider.family<FriendRelationship, String>((ref, targetUid) async {
  final currentUid = FirebaseAuth.instance.currentUser?.uid;
  if (currentUid == null || currentUid == targetUid) {
    return FriendRelationship.none;
  }
  final service = ref.read(friendServiceProvider);
  if (await service.isFriend(targetUid)) return FriendRelationship.friends;
  if (await service.isPending(targetUid)) return FriendRelationship.pendingSent;
  if (await service.hasIncomingRequest(targetUid)) {
    return FriendRelationship.pendingReceived;
  }
  return FriendRelationship.none;
});

// ── Actions ────────────────────────────────────────────────────────────────────

final sendFriendRequestProvider =
    FutureProvider.family<void, Map<String, String?>>((ref, params) async {
  await ref.read(friendServiceProvider).sendFriendRequest(
        receiverId: params['receiverId']!,
        receiverName: params['receiverName'],
        receiverAvatarUrl: params['receiverAvatarUrl'],
      );
  // Invalidate so UI refreshes
  ref.invalidate(friendRelationshipProvider(params['receiverId']!));
  ref.invalidate(pendingFriendRequestCountProvider);
});

final cancelFriendRequestProvider =
    FutureProvider.family<void, Map<String, String>>((ref, params) async {
  await ref.read(friendServiceProvider).cancelFriendRequest(
        params['requestId']!,
        receiverId: params['receiverId']!,
      );
  ref.invalidate(friendRelationshipProvider(params['receiverId']!));
  ref.invalidate(pendingFriendRequestCountProvider);
  ref.invalidate(sentFriendRequestsProvider);
});

final acceptFriendRequestProvider =
    FutureProvider.family<void, Map<String, String>>((ref, params) async {
  await ref.read(friendServiceProvider).acceptFriendRequest(
        params['requestId']!,
        senderId: params['senderId']!,
      );
  ref.invalidate(friendRelationshipProvider(params['senderId']!));
  ref.invalidate(pendingFriendRequestCountProvider);
  ref.invalidate(incomingFriendRequestsProvider);
  ref.invalidate(myFriendsProvider);
});

final declineFriendRequestProvider =
    FutureProvider.family<void, Map<String, String>>((ref, params) async {
  await ref.read(friendServiceProvider).declineFriendRequest(
        params['requestId']!,
        senderId: params['senderId']!,
      );
  ref.invalidate(pendingFriendRequestCountProvider);
  ref.invalidate(incomingFriendRequestsProvider);
});

final unfriendProvider =
    FutureProvider.family<void, String>((ref, targetUid) async {
  await ref.read(friendServiceProvider).unfriend(targetUid);
  ref.invalidate(friendRelationshipProvider(targetUid));
  ref.invalidate(myFriendsProvider);
});
