/// Model for tracking Agora room participants
///
/// Represents a participant in a voice/video room with:
/// - Agora state (uid, video, audio, speaking)
/// - User identity (userId from Firestore, displayName)
/// - Timestamps (joinedAt)
class AgoraParticipant {
  final int uid; // Agora user ID
  final String userId; // Firestore user ID
  final String displayName; // User's display name
  final bool hasVideo; // Camera on/off
  final bool hasAudio; // Mic on/off (not muted)
  final bool isSpeaking; // Currently speaking (volume indicator)
  final DateTime joinedAt; // When they joined

  const AgoraParticipant({
    required this.uid,
    required this.userId,
    required this.displayName,
    this.hasVideo = false,
    this.hasAudio = true,
    this.isSpeaking = false,
    required this.joinedAt,
  });

  /// Create a copy with updated fields
  AgoraParticipant copyWith({
    int? uid,
    String? userId,
    String? displayName,
    bool? hasVideo,
    bool? hasAudio,
    bool? isSpeaking,
    DateTime? joinedAt,
  }) {
    return AgoraParticipant(
      uid: uid ?? this.uid,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      hasVideo: hasVideo ?? this.hasVideo,
      hasAudio: hasAudio ?? this.hasAudio,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'userId': userId,
      'displayName': displayName,
      'hasVideo': hasVideo,
      'hasAudio': hasAudio,
      'isSpeaking': isSpeaking,
      'joinedAt': joinedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory AgoraParticipant.fromJson(Map<String, dynamic> json) {
    return AgoraParticipant(
      uid: json['uid'] as int,
      userId: json['userId'] as String,
      displayName: json['displayName'] as String? ?? 'Unknown User',
      hasVideo: json['hasVideo'] as bool? ?? false,
      hasAudio: json['hasAudio'] as bool? ?? true,
      isSpeaking: json['isSpeaking'] as bool? ?? false,
      joinedAt: json['joinedAt'] != null ? DateTime.parse(json['joinedAt'] as String) : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AgoraParticipant && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;

  @override
  String toString() {
    return 'AgoraParticipant(uid: $uid, userId: $userId, displayName: $displayName, '
        'hasVideo: $hasVideo, hasAudio: $hasAudio, isSpeaking: $isSpeaking)';
  }
}
