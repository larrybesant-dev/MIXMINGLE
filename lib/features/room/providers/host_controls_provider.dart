import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final hostControlsProvider = Provider((ref) => _HostControls());

class _HostControls {
  /// Set room lock state directly
  Future<void> setLock(String roomId, bool isLocked) async {
    await FirebaseFirestore.instance.collection('rooms').doc(roomId).update({'isLocked': isLocked});
  }

  /// Set slow mode seconds directly
  Future<void> setSlowMode(String roomId, int seconds) async {
    await FirebaseFirestore.instance.collection('rooms').doc(roomId).update({'slowModeSeconds': seconds});
  }

  /// Toggle slow mode between Off/5/10/30s
  Future<void> toggleSlowMode(String roomId, int newSeconds) async {
    await setSlowMode(roomId, newSeconds);
  }

  /// Toggle room lock state
  Future<void> toggleLockRoom(String roomId) async {
    final doc = await FirebaseFirestore.instance.collection('rooms').doc(roomId).get();
    final isLocked = (doc.data()?['isLocked'] ?? false) as bool;
    await setLock(roomId, !isLocked);
  }

  /// Mute a user
  Future<void> muteUser(String roomId, String userId) async {
    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomId)
        .collection('participants')
        .doc(userId)
        .update({'isMuted': true});
  }

  /// Unmute a user
  Future<void> unmuteUser(String roomId, String userId) async {
    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomId)
        .collection('participants')
        .doc(userId)
        .update({'isMuted': false});
  }

  /// Ban a user
  Future<void> banUser(String roomId, String userId) async {
    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomId)
        .collection('participants')
        .doc(userId)
        .update({'isBanned': true});
  }

  /// Unban a user
  Future<void> unbanUser(String roomId, String userId) async {
    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomId)
        .collection('participants')
        .doc(userId)
        .update({'isBanned': false});
  }

  /// Legacy compatibility: set mute/ban directly
  Future<void> setMute(String roomId, String userId, bool mute) async {
    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomId)
        .collection('participants')
        .doc(userId)
        .update({'isMuted': mute});
  }

  Future<void> setBan(String roomId, String userId, bool ban) async {
    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomId)
        .collection('participants')
        .doc(userId)
        .update({'isBanned': ban});
  }
}
