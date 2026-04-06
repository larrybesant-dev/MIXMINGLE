import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'room_firestore_provider.dart';

class RoomPresenceModel {
  const RoomPresenceModel({
    required this.userId,
    required this.isOnline,
    required this.lastHeartbeatAt,
    required this.lastSeenAt,
    this.customStatus,
    this.userStatus,
  });

  final String userId;
  final bool isOnline;
  final DateTime? lastHeartbeatAt;
  final DateTime? lastSeenAt;
  /// Optional free-text status/away message set by the user.
  final String? customStatus;
  /// Enum status: 'online' | 'away' | 'dnd' | 'offline'
  final String? userStatus;

  factory RoomPresenceModel.fromMap(String userId, Map<String, dynamic> data) {
    DateTime? toDate(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is String) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    bool toBool(dynamic value) {
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
      }
      return false;
    }

    return RoomPresenceModel(
      userId: userId,
      isOnline: toBool(data['isOnline']),
      lastHeartbeatAt: toDate(data['lastHeartbeatAt']),
      lastSeenAt: toDate(data['lastSeenAt']),
      customStatus: data['customStatus'] as String?,
      userStatus: data['userStatus'] as String?,
    );
  }
}
class RoomPresenceController {
  RoomPresenceController(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _presenceRef(String roomId, String userId) {
    return _db.collection('rooms').doc(roomId).collection('presence').doc(userId);
  }

  Future<void> setOnline({
    required String roomId,
    required String userId,
  }) {
    return _presenceRef(roomId, userId).set({
      'userId': userId,
      'isOnline': true,
      'lastHeartbeatAt': FieldValue.serverTimestamp(),
      'lastSeenAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> heartbeat({
    required String roomId,
    required String userId,
  }) {
    return _presenceRef(roomId, userId).set({
      'userId': userId,
      'isOnline': true,
      'lastHeartbeatAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setOffline({
    required String roomId,
    required String userId,
  }) {
    return _presenceRef(roomId, userId).set({
      'userId': userId,
      'isOnline': false,
      'lastSeenAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setCustomStatus({
    required String roomId,
    required String userId,
    required String? status,
    String userStatus = 'online',
  }) {
    return _presenceRef(roomId, userId).set({
      'customStatus': status,
      'userStatus': userStatus,
      'lastHeartbeatAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

final roomPresenceControllerProvider = Provider<RoomPresenceController>((ref) {
  return RoomPresenceController(ref.watch(roomFirestoreProvider));
});

final roomPresenceStreamProvider =
    StreamProvider.autoDispose.family<List<RoomPresenceModel>, String>((ref, roomId) {
  final firestore = ref.watch(roomFirestoreProvider);
  return firestore
      .collection('rooms')
      .doc(roomId)
      .collection('presence')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => RoomPresenceModel.fromMap(doc.id, doc.data()))
          .toList(growable: false));
});
