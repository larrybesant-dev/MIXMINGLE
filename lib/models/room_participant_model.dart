import 'package:cloud_firestore/cloud_firestore.dart';

class RoomParticipantModel {
  final String userId;
  final String role; // e.g. 'host', 'cohost', 'audience', 'stage'
  final bool isMuted;
  final bool isBanned;
  final bool camOn;
  final bool micOn;
  final DateTime joinedAt;
  final DateTime lastActiveAt;

  RoomParticipantModel({
    required this.userId,
    required this.role,
    this.isMuted = false,
    this.isBanned = false,
    this.camOn = false,
    this.micOn = false,
    required this.joinedAt,
    required this.lastActiveAt,
  });

  factory RoomParticipantModel.fromMap(Map<String, dynamic> map) {
    return RoomParticipantModel(
      userId: map['userId'] ?? '',
      role: map['role'] ?? 'audience',
      isMuted: map['isMuted'] ?? false,
      isBanned: map['isBanned'] ?? false,
      camOn: map['camOn'] ?? false,
      micOn: map['micOn'] ?? false,
      joinedAt: (map['joinedAt'] is Timestamp)
          ? (map['joinedAt'] as Timestamp).toDate()
          : DateTime.tryParse(map['joinedAt']?.toString() ?? '') ?? DateTime.now(),
      lastActiveAt: (map['lastActiveAt'] is Timestamp)
          ? (map['lastActiveAt'] as Timestamp).toDate()
          : DateTime.tryParse(map['lastActiveAt']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'role': role,
      'isMuted': isMuted,
      'isBanned': isBanned,
      'camOn': camOn,
      'micOn': micOn,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'lastActiveAt': Timestamp.fromDate(lastActiveAt),
    };
  }

  RoomParticipantModel copyWith({
    String? userId,
    String? role,
    bool? isMuted,
    bool? isBanned,
    bool? camOn,
    bool? micOn,
    DateTime? joinedAt,
    DateTime? lastActiveAt,
  }) {
    return RoomParticipantModel(
      userId: userId ?? this.userId,
      role: role ?? this.role,
      isMuted: isMuted ?? this.isMuted,
      isBanned: isBanned ?? this.isBanned,
      camOn: camOn ?? this.camOn,
      micOn: micOn ?? this.micOn,
      joinedAt: joinedAt ?? this.joinedAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }
}
