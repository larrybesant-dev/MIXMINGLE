import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// User presence status enum
enum PresenceStatus {
  online,
  away,
  offline,
  doNotDisturb,
}

/// User presence model
class UserPresence {
  final String userId;
  final String displayName;
  final String avatarUrl;
  final PresenceStatus status;
  final DateTime lastSeen;
  final bool isTyping;
  final String? roomId;

  UserPresence({
    required this.userId,
    required this.displayName,
    required this.avatarUrl,
    required this.status,
    required this.lastSeen,
    this.isTyping = false,
    this.roomId,
  });

  factory UserPresence.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserPresence(
      userId: doc.id,
      displayName: data['displayName'] ?? 'Unknown',
      avatarUrl: data['avatarUrl'] ?? '',
      status: PresenceStatus.values[data['status'] ?? 0],
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isTyping: data['isTyping'] ?? false,
      roomId: data['roomId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'status': status.index,
      'lastSeen': Timestamp.fromDate(lastSeen),
      'isTyping': isTyping,
      'roomId': roomId,
    };
  }

  UserPresence copyWith({
    String? userId,
    String? displayName,
    String? avatarUrl,
    PresenceStatus? status,
    DateTime? lastSeen,
    bool? isTyping,
    String? roomId,
  }) {
    return UserPresence(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
      isTyping: isTyping ?? this.isTyping,
      roomId: roomId ?? this.roomId,
    );
  }
}

/// User Presence Service
/// Manages user presence and status indicators in rooms
class UserPresenceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Update user presence status
  Future<void> updatePresenceStatus(
    String userId,
    PresenceStatus status,
  ) async {
    await _firestore.collection('user_presence').doc(userId).set({
      'status': status.index,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Update room presence
  Future<void> updateRoomPresence(String userId, String roomId) async {
    await _firestore.collection('user_presence').doc(userId).set({
      'roomId': roomId,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Set user typing status
  Future<void> setTypingStatus(String userId, bool isTyping) async {
    await _firestore.collection('user_presence').doc(userId).set({'isTyping': isTyping}, SetOptions(merge: true));
  }

  /// Get user presence
  Future<UserPresence?> getUserPresence(String userId) async {
    try {
      final doc = await _firestore.collection('user_presence').doc(userId).get();
      if (!doc.exists) return null;
      return UserPresence.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  /// Get room presence (all users in a room)
  Stream<List<UserPresence>> getRoomPresenceStream(String roomId) {
    return _firestore.collection('user_presence').where('roomId', isEqualTo: roomId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserPresence.fromFirestore(doc)).toList();
    });
  }

  /// Get online users in room
  Stream<List<UserPresence>> getOnlineUsersStream(String roomId) {
    return _firestore
        .collection('user_presence')
        .where('roomId', isEqualTo: roomId)
        .where('status', isEqualTo: PresenceStatus.online.index)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => UserPresence.fromFirestore(doc)).toList();
    });
  }

  /// Get users who are typing
  Stream<List<UserPresence>> getTypingUsersStream(String roomId) {
    return _firestore
        .collection('user_presence')
        .where('roomId', isEqualTo: roomId)
        .where('isTyping', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => UserPresence.fromFirestore(doc)).toList();
    });
  }

  /// Clear user presence (user left room)
  Future<void> clearPresence(String userId) async {
    await _firestore.collection('user_presence').doc(userId).set({
      'status': PresenceStatus.offline.index,
      'roomId': null,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

/// Provider for User Presence Service
final userPresenceServiceProvider = Provider<UserPresenceService>((ref) {
  return UserPresenceService();
});

/// Provider for room presence
final roomPresenceProvider = StreamProvider.family<List<UserPresence>, String>((ref, roomId) {
  final service = ref.watch(userPresenceServiceProvider);
  return service.getRoomPresenceStream(roomId);
});

/// Provider for online users in room
final onlineUsersInRoomProvider = StreamProvider.family<List<UserPresence>, String>((ref, roomId) {
  final service = ref.watch(userPresenceServiceProvider);
  return service.getOnlineUsersStream(roomId);
});

/// Provider for typing users in room
final typingUsersProvider = StreamProvider.family<List<UserPresence>, String>((ref, roomId) {
  final service = ref.watch(userPresenceServiceProvider);
  return service.getTypingUsersStream(roomId);
});


