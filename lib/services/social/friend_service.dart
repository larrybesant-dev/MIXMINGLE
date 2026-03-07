import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Status of a friendship between the current user and another user.
enum FriendRequestStatus { none, sent, received, friends }

/// All friend-request and friendship Firestore operations.
///
/// Firestore structure:
///   users/{uid}/friend_requests/{fromUid}  — incoming requests
///   users/{uid}/sent_requests/{toUid}      — outgoing requests
///   users/{uid}/friends/{friendUid}         — confirmed friends (bidirectional)
///   users/{uid}/blocked/{blockedUid}        — blocked users
class FriendService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid {
    final u = _auth.currentUser;
    if (u == null) throw Exception('Not authenticated');
    return u.uid;
  }

  // ── Send friend request ───────────────────────────────────────────────────

  Future<void> sendFriendRequest(String toUserId) async {
    if (toUserId == _uid) return;
    final batch = _db.batch();
    batch.set(
      _db.collection('users').doc(_uid).collection('sent_requests').doc(toUserId),
      {
        'to': toUserId,
        'from': _uid,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      },
    );
    batch.set(
      _db.collection('users').doc(toUserId).collection('friend_requests').doc(_uid),
      {
        'from': _uid,
        'to': toUserId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      },
    );
    await batch.commit();
    debugPrint('[FriendService] Sent friend request to $toUserId');
  }

  // ── Cancel sent request ───────────────────────────────────────────────────

  Future<void> cancelFriendRequest(String toUserId) async {
    final batch = _db.batch();
    batch.delete(_db.collection('users').doc(_uid).collection('sent_requests').doc(toUserId));
    batch.delete(_db.collection('users').doc(toUserId).collection('friend_requests').doc(_uid));
    await batch.commit();
  }

  // ── Accept incoming request ───────────────────────────────────────────────

  Future<void> acceptFriendRequest(String fromUserId) async {
    final batch = _db.batch();
    final now = FieldValue.serverTimestamp();
    // Bidirectional friendship
    batch.set(
      _db.collection('users').doc(_uid).collection('friends').doc(fromUserId),
      {'friendId': fromUserId, 'since': now},
    );
    batch.set(
      _db.collection('users').doc(fromUserId).collection('friends').doc(_uid),
      {'friendId': _uid, 'since': now},
    );
    // Remove request documents
    batch.delete(_db.collection('users').doc(_uid).collection('friend_requests').doc(fromUserId));
    batch.delete(_db.collection('users').doc(fromUserId).collection('sent_requests').doc(_uid));
    await batch.commit();
    debugPrint('[FriendService] Accepted friend request from $fromUserId');
  }

  // ── Reject incoming request ───────────────────────────────────────────────

  Future<void> rejectFriendRequest(String fromUserId) async {
    final batch = _db.batch();
    batch.delete(_db.collection('users').doc(_uid).collection('friend_requests').doc(fromUserId));
    batch.delete(_db.collection('users').doc(fromUserId).collection('sent_requests').doc(_uid));
    await batch.commit();
  }

  // ── Remove friend ─────────────────────────────────────────────────────────

  Future<void> removeFriend(String friendId) async {
    final batch = _db.batch();
    batch.delete(_db.collection('users').doc(_uid).collection('friends').doc(friendId));
    batch.delete(_db.collection('users').doc(friendId).collection('friends').doc(_uid));
    await batch.commit();
  }

  // ── Block / Unblock ───────────────────────────────────────────────────────

  Future<void> blockUser(String targetId) async {
    final batch = _db.batch();
    batch.set(
      _db.collection('users').doc(_uid).collection('blocked').doc(targetId),
      {'blockedAt': FieldValue.serverTimestamp(), 'blockedId': targetId},
    );
    // Also remove any existing friendship
    batch.delete(_db.collection('users').doc(_uid).collection('friends').doc(targetId));
    batch.delete(_db.collection('users').doc(targetId).collection('friends').doc(_uid));
    batch.delete(_db.collection('users').doc(_uid).collection('friend_requests').doc(targetId));
    batch.delete(_db.collection('users').doc(targetId).collection('friend_requests').doc(_uid));
    await batch.commit();
  }

  Future<void> unblockUser(String targetId) async {
    await _db.collection('users').doc(_uid).collection('blocked').doc(targetId).delete();
  }

  // ── Streams ───────────────────────────────────────────────────────────────

  /// Real-time friendship status with a specific user.
  Stream<FriendRequestStatus> watchFriendStatus(String otherUserId) {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('friends')
        .doc(otherUserId)
        .snapshots()
        .asyncMap((doc) async {
      if (doc.exists) return FriendRequestStatus.friends;

      final sent = await _db
          .collection('users')
          .doc(_uid)
          .collection('sent_requests')
          .doc(otherUserId)
          .get();
      if (sent.exists) return FriendRequestStatus.sent;

      final received = await _db
          .collection('users')
          .doc(_uid)
          .collection('friend_requests')
          .doc(otherUserId)
          .get();
      if (received.exists) return FriendRequestStatus.received;

      return FriendRequestStatus.none;
    });
  }

  /// Incoming friend requests ordered newest-first.
  Stream<List<Map<String, dynamic>>> watchIncomingRequests() {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('friend_requests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => <String, dynamic>{...d.data(), 'id': d.id}).toList());
  }

  /// Confirmed friend IDs.
  Stream<List<String>> watchFriendIds() {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('friends')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toList());
  }

  /// Whether the current user is blocked by [userId].
  Future<bool> isBlockedBy(String userId) async {
    final doc = await _db
        .collection('users')
        .doc(userId)
        .collection('blocked')
        .doc(_uid)
        .get();
    return doc.exists;
  }
}
