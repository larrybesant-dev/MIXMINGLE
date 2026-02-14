/// Event types for room activity tracking
enum RoomEventType {
  userJoined,
  userLeft,
  kicked,
  banned,
  muted,
  unmuted,
  topicChanged,
  settingsChanged,
  camEnabled,
  camDisabled,
  roleChanged,
}

/// Model for tracking events in a room
class RoomEvent {
  final String id;
  final RoomEventType type;
  final String actorId; // User who triggered the event
  final String? targetId; // User affected by the event (if applicable)
  final DateTime createdAt;
  final Map<String, dynamic>? metadata; // Additional context (reason, old/new values, etc.)

  const RoomEvent({
    required this.id,
    required this.type,
    required this.actorId,
    this.targetId,
    required this.createdAt,
    this.metadata,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'actorId': actorId,
      'targetId': targetId,
      'createdAt': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory RoomEvent.fromJson(Map<String, dynamic> json) {
    return RoomEvent(
      id: json['id'] as String,
      type: RoomEventType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => RoomEventType.userJoined,
      ),
      actorId: json['actorId'] as String,
      targetId: json['targetId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'type': type.name,
      'actorId': actorId,
      'targetId': targetId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'metadata': metadata,
    };
  }

  /// Create from Firestore document
  factory RoomEvent.fromFirestore(String docId, Map<String, dynamic> data) {
    return RoomEvent(
      id: docId,
      type: RoomEventType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => RoomEventType.userJoined,
      ),
      actorId: data['actorId'] as String,
      targetId: data['targetId'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Create a user joined event
  factory RoomEvent.userJoined({
    required String userId,
    required DateTime timestamp,
  }) {
    return RoomEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: RoomEventType.userJoined,
      actorId: userId,
      createdAt: timestamp,
    );
  }

  /// Create a user left event
  factory RoomEvent.userLeft({
    required String userId,
    required DateTime timestamp,
  }) {
    return RoomEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: RoomEventType.userLeft,
      actorId: userId,
      createdAt: timestamp,
    );
  }

  /// Create a kicked event
  factory RoomEvent.kicked({
    required String moderatorId,
    required String userId,
    required DateTime timestamp,
    String? reason,
  }) {
    return RoomEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: RoomEventType.kicked,
      actorId: moderatorId,
      targetId: userId,
      createdAt: timestamp,
      metadata: reason != null ? {'reason': reason} : null,
    );
  }

  /// Create a banned event
  factory RoomEvent.banned({
    required String moderatorId,
    required String userId,
    required DateTime timestamp,
    String? reason,
  }) {
    return RoomEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: RoomEventType.banned,
      actorId: moderatorId,
      targetId: userId,
      createdAt: timestamp,
      metadata: reason != null ? {'reason': reason} : null,
    );
  }

  /// Create a muted event
  factory RoomEvent.muted({
    required String moderatorId,
    required String userId,
    required DateTime timestamp,
    String? reason,
  }) {
    return RoomEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: RoomEventType.muted,
      actorId: moderatorId,
      targetId: userId,
      createdAt: timestamp,
      metadata: reason != null ? {'reason': reason} : null,
    );
  }

  /// Create a role changed event
  factory RoomEvent.roleChanged({
    required String moderatorId,
    required String userId,
    required String oldRole,
    required String newRole,
    required DateTime timestamp,
  }) {
    return RoomEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: RoomEventType.roleChanged,
      actorId: moderatorId,
      targetId: userId,
      createdAt: timestamp,
      metadata: {
        'oldRole': oldRole,
        'newRole': newRole,
      },
    );
  }

  /// Get a human-readable description of this event
  String getDescription({required Map<String, String> userNames}) {
    final actorName = userNames[actorId] ?? 'Unknown';
    final targetName = targetId != null ? (userNames[targetId!] ?? 'Unknown') : null;

    switch (type) {
      case RoomEventType.userJoined:
        return '$actorName joined the room';
      case RoomEventType.userLeft:
        return '$actorName left the room';
      case RoomEventType.kicked:
        final reason = metadata?['reason'] as String?;
        return '$actorName kicked $targetName${reason != null ? ": $reason" : ""}';
      case RoomEventType.banned:
        final reason = metadata?['reason'] as String?;
        return '$actorName banned $targetName${reason != null ? ": $reason" : ""}';
      case RoomEventType.muted:
        final reason = metadata?['reason'] as String?;
        return '$actorName muted $targetName${reason != null ? ": $reason" : ""}';
      case RoomEventType.unmuted:
        return '$actorName unmuted $targetName';
      case RoomEventType.topicChanged:
        final newTopic = metadata?['newTopic'] as String?;
        return '$actorName changed the topic${newTopic != null ? " to: $newTopic" : ""}';
      case RoomEventType.settingsChanged:
        return '$actorName changed room settings';
      case RoomEventType.camEnabled:
        return '$actorName turned on their camera';
      case RoomEventType.camDisabled:
        return '$actorName turned off their camera';
      case RoomEventType.roleChanged:
        final newRole = metadata?['newRole'] as String?;
        return '$actorName promoted $targetName to $newRole';
    }
  }

  /// Copy with updated fields
  RoomEvent copyWith({
    String? id,
    RoomEventType? type,
    String? actorId,
    String? targetId,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return RoomEvent(
      id: id ?? this.id,
      type: type ?? this.type,
      actorId: actorId ?? this.actorId,
      targetId: targetId ?? this.targetId,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }
}
