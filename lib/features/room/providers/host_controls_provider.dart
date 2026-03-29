import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/notification_service.dart';
import 'room_firestore_provider.dart';

class HostControls {
  HostControls(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _roomRef(String roomId) {
    return _db.collection('rooms').doc(roomId);
  }

  DocumentReference<Map<String, dynamic>> _policyRef(String roomId) {
    return _roomRef(roomId).collection('policies').doc('settings');
  }

  Future<void> toggleSlowMode(String roomId, int seconds) {
    return _roomRef(roomId).update({'slowModeSeconds': seconds});
  }

  Future<void> toggleLockRoom(String roomId) async {
    final roomRef = _roomRef(roomId);
    final snapshot = await roomRef.get();
    final currentValue = (snapshot.data()?['isLocked'] ?? false) as bool;
    await roomRef.update({'isLocked': !currentValue});
  }

  Future<void> toggleAllowChat(String roomId) async {
    final policyRef = _policyRef(roomId);
    final snapshot = await policyRef.get();
    final currentValue = (snapshot.data()?['allowChat'] ?? true) as bool;
    await policyRef.set({'allowChat': !currentValue}, SetOptions(merge: true));
  }

  Future<void> toggleAllowCamRequests(String roomId) async {
    final policyRef = _policyRef(roomId);
    final snapshot = await policyRef.get();
    final currentValue = (snapshot.data()?['allowCamRequests'] ?? true) as bool;
    await policyRef.set({
      'allowCamRequests': !currentValue,
    }, SetOptions(merge: true));
  }

  Future<void> toggleAllowMicRequests(String roomId) async {
    final policyRef = _policyRef(roomId);
    final snapshot = await policyRef.get();
    final currentValue = (snapshot.data()?['allowMicRequests'] ?? true) as bool;
    await policyRef.set({
      'allowMicRequests': !currentValue,
    }, SetOptions(merge: true));
  }

  Future<void> toggleAllowGifts(String roomId) async {
    final policyRef = _policyRef(roomId);
    final snapshot = await policyRef.get();
    final currentValue = (snapshot.data()?['allowGifts'] ?? true) as bool;
    await policyRef.set({'allowGifts': !currentValue}, SetOptions(merge: true));
  }

  Future<void> muteUser(String roomId, String userId) {
    return _participantRef(roomId, userId).update({'isMuted': true});
  }

  Future<void> unmuteUser(String roomId, String userId) {
    return _participantRef(roomId, userId).update({'isMuted': false});
  }

  Future<void> banUser(String roomId, String userId) {
    return _participantRef(roomId, userId).update({'isBanned': true});
  }

  Future<void> unbanUser(String roomId, String userId) {
    return _participantRef(roomId, userId).update({'isBanned': false});
  }

  Future<void> promoteToCohost(String roomId, String userId) {
    return _participantRef(roomId, userId).update({'role': 'cohost'});
  }

  Future<void> promoteToModerator(String roomId, String userId) {
    return _participantRef(roomId, userId).update({'role': 'moderator'});
  }

  Future<void> demoteToAudience(String roomId, String userId) {
    return _participantRef(roomId, userId).update({'role': 'audience'});
  }

  Future<void> removeUser(String roomId, String userId) {
    return _participantRef(roomId, userId).delete();
  }

  Future<void> transferHost({
    required String roomId,
    required String fromUserId,
    required String toUserId,
  }) async {
    if (fromUserId.trim().isEmpty || toUserId.trim().isEmpty) {
      throw ArgumentError('Host transfer requires valid user IDs.');
    }
    if (fromUserId == toUserId) {
      throw ArgumentError('Host transfer target must be a different user.');
    }

    final roomSnapshot = await _roomRef(roomId).get();
    if (!roomSnapshot.exists) {
      throw StateError('Room not found.');
    }
    final currentHostId = (roomSnapshot.data()?['hostId'] as String? ?? '').trim();
    if (currentHostId != fromUserId) {
      throw StateError('Only the current room host can transfer ownership.');
    }

    final targetParticipantSnapshot = await _participantRef(roomId, toUserId).get();
    final targetIsBanned = (targetParticipantSnapshot.data()?['isBanned'] ?? false) as bool;
    if (targetIsBanned) {
      throw StateError('Cannot transfer host ownership to a banned participant.');
    }

    final batch = _db.batch();
    final roomRef = _roomRef(roomId);
    batch.update(roomRef, {
      'hostId': toUserId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(
      _participantRef(roomId, toUserId),
      {
        'userId': toUserId,
        'role': 'host',
        'lastActiveAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    batch.set(
      _participantRef(roomId, fromUserId),
      {
        'userId': fromUserId,
        'role': 'cohost',
        'lastActiveAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await batch.commit();

    final notifier = NotificationService(firestore: _db);
    await notifier.inAppNotification(
      toUserId,
      'You are now the room host for room $roomId.',
    );
    await notifier.inAppNotification(
      fromUserId,
      'You transferred room ownership to $toUserId.',
    );
  }

  DocumentReference<Map<String, dynamic>> _participantRef(
    String roomId,
    String userId,
  ) {
    return _roomRef(roomId).collection('participants').doc(userId);
  }
}

final hostControlsProvider = Provider<HostControls>(
  (ref) => HostControls(ref.watch(roomFirestoreProvider)),
);
