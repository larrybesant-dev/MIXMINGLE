import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final hostControlsProvider = Provider((ref) => _HostControls());

class _HostControls {
  Future<void> setSlowMode(String roomId, int seconds) async {
    await FirebaseFirestore.instance.collection('rooms').doc(roomId).update({'slowModeSeconds': seconds});
  }

  Future<void> setLock(String roomId, bool isLocked) async {
    await FirebaseFirestore.instance.collection('rooms').doc(roomId).update({'isLocked': isLocked});
  }

  Future<void> muteUser(String roomId, String userId, bool mute) async {
    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomId)
        .collection('participants')
        .doc(userId)
        .update({'isMuted': mute});
  }

  Future<void> banUser(String roomId, String userId, bool ban) async {
    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomId)
        .collection('participants')
        .doc(userId)
        .update({'isBanned': ban});
  }
}
