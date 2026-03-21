import 'package:cloud_firestore/cloud_firestore.dart';

class RoomParticipantModel {
  final String userId;
  final String role; // e.g. 'host', 'cohost', 'audience', 'stage'
  final bool isMuted;
  final bool isBanned;
  final DateTime joinedAt;
  final DateTime lastActiveAt;

  RoomParticipantModel({
    required this.userId,
    required this.role,
    this.isMuted = false,
    this.isBanned = false,
    required this.joinedAt,
    required this.lastActiveAt,
  });

  factory RoomParticipantModel.fromMap(Map<String, dynamic> map) {
    return RoomParticipantModel(
      userId: map['userId'] ?? '',
      role: map['role'] ?? 'audience',
      isMuted: map['isMuted'] ?? false,
      isBanned: map['isBanned'] ?? false,
      joinedAt: (map['joinedAt'] is Timestamp)
          ? (map['joinedAt'] as Timestamp).toDate()
          : DateTime.tryParse(map['joinedAt']?.toString() ?? '') ?? DateTime.now(),
      lastActiveAt: (map['lastActiveAt'] is Timestamp)
          ? (map['lastActiveAt'] as Timestamp).toDate()
          : DateTime.tryParse(map['lastActiveAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'role': role,
      'isMuted': isMuted,
      'isBanned': isBanned,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'lastActiveAt': Timestamp.fromDate(lastActiveAt),
    };
  }

  RoomParticipantModel copyWith({
    String? userId,
    String? role,
    bool? isMuted,
    bool? isBanned,
    DateTime? joinedAt,
    DateTime? lastActiveAt,
  }) {
    return RoomParticipantModel(
      userId: userId ?? this.userId,
      role: role ?? this.role,
      isMuted: isMuted ?? this.isMuted,
      isBanned: isBanned ?? this.isBanned,
      joinedAt: joinedAt ?? this.joinedAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }
}
