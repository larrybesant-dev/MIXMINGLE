/// Enum for room participant roles
enum RoomRole {
  owner, // Room creator - full control
  admin, // Admin - can manage participants and settings
  member, // Regular member - can participate
  muted, // Temporarily muted by moderators
  banned // Banned from the room
}

extension RoomRoleX on RoomRole {
  String get label {
    switch (this) {
      case RoomRole.owner:
        return 'Owner';
      case RoomRole.admin:
        return 'Admin';
      case RoomRole.member:
        return 'Member';
      case RoomRole.muted:
        return 'Muted';
      case RoomRole.banned:
        return 'Banned';
    }
  }

  bool get canRemoveParticipants {
    return this == RoomRole.owner || this == RoomRole.admin;
  }

  bool get canMuteOthers {
    return this == RoomRole.owner || this == RoomRole.admin;
  }

  bool get canChat {
    return this != RoomRole.muted && this != RoomRole.banned;
  }

  bool get canSpeak {
    return this != RoomRole.muted && this != RoomRole.banned;
  }

  bool get canModerate {
    return this == RoomRole.owner || this == RoomRole.admin;
  }
}

/// Model for room participant with role and state
class RoomParticipant {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int agoraUid;
  final RoomRole role;
  final DateTime joinedAt;
  final DateTime lastActiveAt;
  final bool isOnCam;
  final bool isMuted;
  final bool isSpeaking;
  final String device; // 'web', 'android', 'ios', 'desktop'
  final String connectionQuality; // 'excellent', 'good', 'poor', 'unknown'

  const RoomParticipant({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.agoraUid,
    required this.role,
    required this.joinedAt,
    required this.lastActiveAt,
    this.isOnCam = false,
    this.isMuted = false,
    this.isSpeaking = false,
    this.device = 'web',
    this.connectionQuality = 'good',
  });

  /// Legacy hasAudio/hasVideo aliases for backward compatibility
  bool get hasAudio => !isMuted;
  bool get hasVideo => isOnCam;

  /// Create a copy with updated fields
  RoomParticipant copyWith({
    String? userId,
    String? displayName,
    String? avatarUrl,
    int? agoraUid,
    RoomRole? role,
    DateTime? joinedAt,
    DateTime? lastActiveAt,
    bool? isOnCam,
    bool? isMuted,
    bool? isSpeaking,
    String? device,
    String? connectionQuality,
  }) {
    return RoomParticipant(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      agoraUid: agoraUid ?? this.agoraUid,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      isOnCam: isOnCam ?? this.isOnCam,
      isMuted: isMuted ?? this.isMuted,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      device: device ?? this.device,
      connectionQuality: connectionQuality ?? this.connectionQuality,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'agoraUid': agoraUid,
      'role': role.name,
      'joinedAt': joinedAt.toIso8601String(),
      'lastActiveAt': lastActiveAt.toIso8601String(),
      'isOnCam': isOnCam,
      'isMuted': isMuted,
      'isSpeaking': isSpeaking,
      'device': device,
      'connectionQuality': connectionQuality,
    };
  }

  /// Create from JSON
  factory RoomParticipant.fromJson(Map<String, dynamic> json) {
    return RoomParticipant(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      agoraUid: json['agoraUid'] as int,
      role: RoomRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => RoomRole.member,
      ),
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      lastActiveAt: json['lastActiveAt'] != null
          ? DateTime.parse(json['lastActiveAt'] as String)
          : DateTime.parse(json['joinedAt'] as String),
      isOnCam: json['isOnCam'] as bool? ?? false,
      isMuted: json['isMuted'] as bool? ?? false,
      isSpeaking: json['isSpeaking'] as bool? ?? false,
      device: json['device'] as String? ?? 'web',
      connectionQuality: json['connectionQuality'] as String? ?? 'good',
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'agoraUid': agoraUid,
      'role': role.name,
      'joinedAt': joinedAt.millisecondsSinceEpoch,
      'lastActiveAt': lastActiveAt.millisecondsSinceEpoch,
      'isOnCam': isOnCam,
      'isMuted': isMuted,
      'isSpeaking': isSpeaking,
      'device': device,
      'connectionQuality': connectionQuality,
    };
  }

  /// Create from Firestore document
  factory RoomParticipant.fromFirestore(Map<String, dynamic> data) {
    return RoomParticipant(
      userId: data['userId'] as String,
      displayName: data['displayName'] as String,
      avatarUrl: data['avatarUrl'] as String?,
      agoraUid: data['agoraUid'] as int,
      role: RoomRole.values.firstWhere(
        (e) => e.name == data['role'],
        orElse: () => RoomRole.member,
      ),
      joinedAt: DateTime.fromMillisecondsSinceEpoch(data['joinedAt'] as int),
      lastActiveAt: data['lastActiveAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['lastActiveAt'] as int)
          : DateTime.fromMillisecondsSinceEpoch(data['joinedAt'] as int),
      isOnCam: data['isOnCam'] as bool? ?? false,
      isMuted: data['isMuted'] as bool? ?? false,
      isSpeaking: data['isSpeaking'] as bool? ?? false,
      device: data['device'] as String? ?? 'web',
      connectionQuality: data['connectionQuality'] as String? ?? 'good',
    );
  }
}
