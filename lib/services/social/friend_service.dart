<<<<<<< HEAD
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

  /// Confirmed friend IDs for the current user.
  Stream<List<String>> watchFriendIds() {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('friends')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toList());
  }

  /// Confirmed friend IDs for any [userId] (used when viewing another profile).
  Stream<List<String>> watchFriendIdsOf(String userId) {
    return _db
        .collection('users')
        .doc(userId)
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

  /// Streams whether the current user has blocked [targetId].
  Stream<bool> watchBlockedStatus(String targetId) {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('blocked')
        .doc(targetId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  /// Fetches friend IDs for any user (for mutual-friends calculation).
  Future<List<String>> getFriendIds(String userId) async {
    final snap = await _db
        .collection('users')
        .doc(userId)
        .collection('friends')
        .get();
    return snap.docs.map((d) => d.id).toList();
=======
// lib/services/social/friend_service.dart
//
// Full Firestore-backed Friend System
//
// Firestore layout:
//   /friendRequests/{requestId}        — top-level for cross-user queries
//   /users/{uid}/friendRequests/{requestId}  — per-user inbox / outbox
//   /users/{uid}/friends/{friendUid}   — accepted friend list
// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../shared/models/friend_request.dart';

class FriendService {
  FriendService._();
  static final FriendService instance = FriendService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? '';

  // ── Private helpers ────────────────────────────────────────────────────────

  DocumentReference _globalReqRef(String requestId) =>
      _db.collection('friendRequests').doc(requestId);

  CollectionReference _userReqCol(String uid) =>
      _db.collection('users').doc(uid).collection('friendRequests');

  CollectionReference _friendsCol(String uid) =>
      _db.collection('users').doc(uid).collection('friends');

  // ── Send ───────────────────────────────────────────────────────────────────

  /// Sends a friend request TO [receiverId].
  /// No-ops if a pending request already exists in either direction.
  Future<void> sendFriendRequest({
    required String receiverId,
    String? receiverName,
    String? receiverAvatarUrl,
  }) async {
    if (_uid.isEmpty || _uid == receiverId) return;

    // De-duplicate guard —  check existing pending in both directions
    final existing = await _db
        .collection('friendRequests')
        .where('senderId', isEqualTo: _uid)
        .where('receiverId', isEqualTo: receiverId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return;

    final alreadyFriend = await _friendsCol(_uid).doc(receiverId).get();
    if (alreadyFriend.exists) return;

    final me = _auth.currentUser;
    final newRef = _db.collection('friendRequests').doc();

    final payload = FriendRequest(
      requestId: newRef.id,
      senderId: _uid,
      receiverId: receiverId,
      status: FriendRequestStatus.pending,
      timestamp: DateTime.now(),
      senderName: me?.displayName,
      senderAvatarUrl: me?.photoURL,
      receiverName: receiverName,
      receiverAvatarUrl: receiverAvatarUrl,
    ).toMap();

    final batch = _db.batch();
    // Global doc
    batch.set(newRef, payload);
    // Sender's outbox
    batch.set(_userReqCol(_uid).doc(newRef.id), payload);
    // Receiver's inbox
    batch.set(_userReqCol(receiverId).doc(newRef.id), payload);

    await batch.commit();
    debugPrint('[FriendService] sendFriendRequest → $receiverId (${newRef.id})');
  }

  // ── Cancel ─────────────────────────────────────────────────────────────────

  Future<void> cancelFriendRequest(String requestId,
      {required String receiverId}) async {
    final batch = _db.batch();
    batch.delete(_globalReqRef(requestId));
    batch.delete(_userReqCol(_uid).doc(requestId));
    batch.delete(_userReqCol(receiverId).doc(requestId));
    await batch.commit();
    debugPrint('[FriendService] cancelled request $requestId');
  }

  // ── Accept ─────────────────────────────────────────────────────────────────

  Future<void> acceptFriendRequest(String requestId,
      {required String senderId}) async {
    final me = _auth.currentUser;
    final now = FieldValue.serverTimestamp();
    final batch = _db.batch();

    // Update status on all copies
    final update = {'status': 'accepted', 'acceptedAt': now};
    batch.update(_globalReqRef(requestId), update);
    batch.update(_userReqCol(_uid).doc(requestId), update);
    batch.update(_userReqCol(senderId).doc(requestId), update);

    // Add bidirectional friend entries
    batch.set(_friendsCol(_uid).doc(senderId), {
      'since': now,
      'displayName': null, // UI can update from user profile
      'avatarUrl': null,
    });
    batch.set(_friendsCol(senderId).doc(_uid), {
      'since': now,
      'displayName': me?.displayName,
      'avatarUrl': me?.photoURL,
    });

    await batch.commit();
    debugPrint('[FriendService] accepted request $requestId from $senderId');
  }

  // ── Decline ────────────────────────────────────────────────────────────────

  Future<void> declineFriendRequest(String requestId,
      {required String senderId}) async {
    final update = {'status': 'declined', 'declinedAt': FieldValue.serverTimestamp()};
    final batch = _db.batch();
    batch.update(_globalReqRef(requestId), update);
    batch.update(_userReqCol(_uid).doc(requestId), update);
    batch.update(_userReqCol(senderId).doc(requestId), update);
    await batch.commit();
    debugPrint('[FriendService] declined request $requestId');
  }

  // ── Unfriend ───────────────────────────────────────────────────────────────

  Future<void> unfriend(String targetUid) async {
    final batch = _db.batch();
    batch.delete(_friendsCol(_uid).doc(targetUid));
    batch.delete(_friendsCol(targetUid).doc(_uid));
    await batch.commit();
    debugPrint('[FriendService] unfriended $targetUid');
  }

  // ── Auto-friend (e.g. speed dating mutual match) ───────────────────────────

  /// Silently auto-friends two users without going through request flow.
  Future<void> autoFriend(String userAUid, String userBUid) async {
    final now = FieldValue.serverTimestamp();
    final batch = _db.batch();
    batch.set(_friendsCol(userAUid).doc(userBUid), {'since': now});
    batch.set(_friendsCol(userBUid).doc(userAUid), {'since': now});
    await batch.commit();
    debugPrint('[FriendService] auto-friended $userAUid ↔ $userBUid');
  }

  // ── State helpers ──────────────────────────────────────────────────────────

  Future<bool> isFriend(String targetUid) async {
    if (_uid.isEmpty) return false;
    final snap = await _friendsCol(_uid).doc(targetUid).get();
    return snap.exists;
  }

  Future<bool> isPending(String targetUid) async {
    if (_uid.isEmpty) return false;
    final snap = await _db
        .collection('friendRequests')
        .where('senderId', isEqualTo: _uid)
        .where('receiverId', isEqualTo: targetUid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<bool> hasIncomingRequest(String targetUid) async {
    if (_uid.isEmpty) return false;
    final snap = await _db
        .collection('friendRequests')
        .where('senderId', isEqualTo: targetUid)
        .where('receiverId', isEqualTo: _uid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// Returns the requestId if a pending request TO [targetUid] exists,
  /// else null.
  Future<String?> pendingRequestId(String targetUid) async {
    if (_uid.isEmpty) return null;
    final snap = await _db
        .collection('friendRequests')
        .where('senderId', isEqualTo: _uid)
        .where('receiverId', isEqualTo: targetUid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    return snap.docs.isNotEmpty ? snap.docs.first.id : null;
  }

  Future<String?> incomingRequestId(String targetUid) async {
    if (_uid.isEmpty) return null;
    final snap = await _db
        .collection('friendRequests')
        .where('senderId', isEqualTo: targetUid)
        .where('receiverId', isEqualTo: _uid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    return snap.docs.isNotEmpty ? snap.docs.first.id : null;
  }

  // ── Streams ────────────────────────────────────────────────────────────────

  /// Real-time stream of current user's **incoming** pending requests.
  Stream<List<FriendRequest>> streamIncomingRequests() {
    if (_uid.isEmpty) return Stream.value([]);
    return _db
        .collection('friendRequests')
        .where('receiverId', isEqualTo: _uid)
        .where('status', isEqualTo: 'pending')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => FriendRequest.fromDoc(d)).toList());
  }

  /// Real-time stream of current user's **sent** pending requests.
  Stream<List<FriendRequest>> streamSentRequests() {
    if (_uid.isEmpty) return Stream.value([]);
    return _db
        .collection('friendRequests')
        .where('senderId', isEqualTo: _uid)
        .where('status', isEqualTo: 'pending')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => FriendRequest.fromDoc(d)).toList());
  }

  /// Real-time stream of current user's friends.
  Stream<List<FriendEntry>> streamFriends([String? uid]) {
    final targetUid = uid ?? _uid;
    if (targetUid.isEmpty) return Stream.value([]);
    return _friendsCol(targetUid)
        .orderBy('since', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => FriendEntry.fromDoc(d)).toList());
  }

  /// Live count of incoming pending friend requests (for badge).
  Stream<int> streamPendingCount() {
    if (_uid.isEmpty) return Stream.value(0);
    return _db
        .collection('friendRequests')
        .where('receiverId', isEqualTo: _uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs.length);
>>>>>>> origin/develop
  }
}
