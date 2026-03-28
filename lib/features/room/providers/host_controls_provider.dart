import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'room_firestore_provider.dart';

class HostControls {
  HostControls(this._db);

  final FirebaseFirestore _db;

  Future<void> toggleSlowMode(String roomId, int seconds) {
    return _db.collection('rooms').doc(roomId).update({'slowModeSeconds': seconds});
  }

  Future<void> toggleLockRoom(String roomId) async {
    final roomRef = _db.collection('rooms').doc(roomId);
    final snapshot = await roomRef.get();
    final currentValue = (snapshot.data()?['isLocked'] ?? false) as bool;
    await roomRef.update({'isLocked': !currentValue});
  }

  Future<void> toggleAllowChat(String roomId) async {
    final policyRef = _db.collection('rooms').doc(roomId).collection('policies').doc('settings');
    final snapshot = await policyRef.get();
    final currentValue = (snapshot.data()?['allowChat'] ?? true) as bool;
    await policyRef.set({'allowChat': !currentValue}, SetOptions(merge: true));
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

  DocumentReference<Map<String, dynamic>> _participantRef(String roomId, String userId) {
    return _db.collection('rooms').doc(roomId).collection('participants').doc(userId);
  }
}

final hostControlsProvider = Provider<HostControls>(
  (ref) => HostControls(ref.watch(roomFirestoreProvider)),
);
