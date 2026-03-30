import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/moderation_service.dart';

class FollowService {
  FollowService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    ModerationService? moderationService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _moderationService = moderationService ?? ModerationService(firestore: firestore ?? FirebaseFirestore.instance, auth: auth ?? FirebaseAuth.instance);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final ModerationService _moderationService;

  String _asString(dynamic value, {String fallback = ''}) {
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return fallback;
  }

  bool _asBool(dynamic value, {bool fallback = false}) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') {
        return true;
      }
      if (normalized == 'false' || normalized == '0') {
        return false;
      }
    }
    return fallback;
  }

  String _followDocId(String followerUserId, String followedUserId) {
    return '${followerUserId}_$followedUserId';
  }

  Future<bool> isFollowing(String followerUserId, String followedUserId) async {
    if (followerUserId.trim().isEmpty || followedUserId.trim().isEmpty) {
      return false;
    }

    final snapshot = await _firestore
        .collection('follows')
        .doc(_followDocId(followerUserId, followedUserId))
        .get();
    return snapshot.exists;
  }

  Future<int> followerCount(String userId) async {
    final snapshot = await _firestore
        .collection('follows')
        .where('followedUserId', isEqualTo: userId)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<int> followingCount(String userId) async {
    final snapshot = await _firestore
        .collection('follows')
        .where('followerUserId', isEqualTo: userId)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<void> followUser(String followedUserId) async {
    final followerUserId = _auth.currentUser?.uid;
    if (followerUserId == null || followerUserId == followedUserId || followedUserId.trim().isEmpty) {
      return;
    }

    if (await _moderationService.hasBlockingRelationship(followerUserId, followedUserId)) {
      throw Exception('You cannot follow this user.');
    }

    final targetSnapshot = await _firestore.collection('users').doc(followedUserId).get();
    if (!targetSnapshot.exists) {
      throw Exception('User not found.');
    }

    final currentUserSnapshot = await _firestore.collection('users').doc(followerUserId).get();
  final actorName = _asString((currentUserSnapshot.data() ?? const <String, dynamic>{})['username']);

    await _firestore.collection('follows').doc(_followDocId(followerUserId, followedUserId)).set({
      'followerUserId': followerUserId,
      'followedUserId': followedUserId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('notifications').add({
      'userId': followedUserId,
      'actorId': followerUserId,
      'type': 'follow',
      'content': '${actorName.isEmpty ? 'Someone' : actorName} started following you.',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unfollowUser(String followedUserId) async {
    final followerUserId = _auth.currentUser?.uid;
    if (followerUserId == null || followedUserId.trim().isEmpty) {
      return;
    }

    await _firestore.collection('follows').doc(_followDocId(followerUserId, followedUserId)).delete();
  }

  Future<void> inviteUserToHostedRoom(String invitedUserId) async {
    final inviterUserId = _auth.currentUser?.uid;
    if (inviterUserId == null || invitedUserId.trim().isEmpty || invitedUserId == inviterUserId) {
      return;
    }

    if (await _moderationService.hasBlockingRelationship(inviterUserId, invitedUserId)) {
      throw Exception('You cannot invite this user.');
    }

    final roomsSnapshot = await _firestore
        .collection('rooms')
        .where('hostId', isEqualTo: inviterUserId)
        .limit(10)
        .get();

    final roomDocs = roomsSnapshot.docs;
    if (roomDocs.isEmpty) {
      throw Exception('Create a live room first.');
    }

    final preferredRoom = roomDocs.cast<QueryDocumentSnapshot<Map<String, dynamic>>?>().firstWhere(
          (doc) => _asBool(doc?.data()['isLive']),
          orElse: () => roomDocs.first,
        );
    final roomData = preferredRoom?.data() ?? const <String, dynamic>{};
    final roomId = preferredRoom?.id ?? '';
        final roomName = _asString(roomData['name']);

    final inviterSnapshot = await _firestore.collection('users').doc(inviterUserId).get();
        final inviterName = _asString((inviterSnapshot.data() ?? const <String, dynamic>{})['username']);
        final safeInviterName = inviterName.isEmpty ? 'Someone' : inviterName;
        final safeRoomName = roomName.isEmpty ? 'their room' : roomName;

    await _firestore.collection('notifications').add({
      'userId': invitedUserId,
      'actorId': inviterUserId,
      'type': 'live_room_invite',
      'content': '$safeInviterName invited you to join $safeRoomName.',
      'roomId': roomId,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}