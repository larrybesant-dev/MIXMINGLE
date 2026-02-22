
import 'package:cloud_firestore/cloud_firestore.dart';

/// User presence status
enum PresenceStatus {
  online,
  away,
  offline,
  busy,
}

/// User presence model for real-time online/offline tracking
class UserPresence {
  final String userId;
  final PresenceStatus status;
  final DateTime lastSeen;
  final String? currentRoomId;
  final String? statusMessage;

  UserPresence({
    required this.userId,
    required this.status,
    required this.lastSeen,
    this.currentRoomId,
    this.statusMessage,
  });

  bool get isOnline => status == PresenceStatus.online;
  bool get isAway => status == PresenceStatus.away;
  bool get isOffline => status == PresenceStatus.offline;
  bool get isBusy => status == PresenceStatus.busy;

  factory UserPresence.fromMap(Map<String, dynamic> map) {
    return UserPresence(
      userId: map['userId'] ?? '',
      status: PresenceStatus.values.firstWhere(
        (e) => e.toString() == 'PresenceStatus.${map['status']}',
        orElse: () => PresenceStatus.offline,
      ),
      lastSeen: (map['lastSeen'] as Timestamp).toDate(),
      currentRoomId: map['currentRoomId'],
      statusMessage: map['statusMessage'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'status': status.toString().split('.').last,
      'lastSeen': Timestamp.fromDate(lastSeen),
      'currentRoomId': currentRoomId,
      'statusMessage': statusMessage,
    };
  }

  UserPresence copyWith({
    String? userId,
    PresenceStatus? status,
    DateTime? lastSeen,
    String? currentRoomId,
    String? statusMessage,
  }) {
    return UserPresence(
      userId: userId ?? this.userId,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
      currentRoomId: currentRoomId ?? this.currentRoomId,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}


