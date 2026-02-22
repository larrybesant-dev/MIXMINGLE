class Activity {
  final String id;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final ActivityType type;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata; // Extra data (roomId, eventId, etc.)

  Activity({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.type,
    required this.description,
    required this.timestamp,
    this.metadata,
  });

  factory Activity.fromMap(Map<String, dynamic> map) {
    return Activity(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userPhotoUrl: map['userPhotoUrl'],
      type: ActivityType.values.firstWhere(
        (e) => e.toString() == 'ActivityType.${map['type']}',
        orElse: () => ActivityType.other,
      ),
      description: map['description'] ?? '',
      timestamp: map['timestamp'] != null ? DateTime.parse(map['timestamp']) : DateTime.now(),
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'type': type.toString().split('.').last,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  String get iconEmoji {
    switch (type) {
      case ActivityType.joinedRoom:
        return 'ðŸšª';
      case ActivityType.hostedRoom:
        return 'ðŸŽ¤';
      case ActivityType.attendedEvent:
        return 'ðŸŽ‰';
      case ActivityType.hostedEvent:
        return 'ðŸ“…';
      case ActivityType.newFriend:
        return 'ðŸ‘‹';
      case ActivityType.gotMatch:
        return 'ðŸ’•';
      case ActivityType.achievementUnlocked:
        return 'ðŸ†';
      case ActivityType.leveledUp:
        return 'â­';
      case ActivityType.streakMilestone:
        return 'ðŸ”¥';
      default:
        return 'âœ¨';
    }
  }

  Activity copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    ActivityType? type,
    String? description,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return Activity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      type: type ?? this.type,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Activity &&
        other.id == id &&
        other.userId == userId &&
        other.userName == userName &&
        other.userPhotoUrl == userPhotoUrl &&
        other.type == type &&
        other.description == description &&
        other.timestamp == timestamp &&
        other.metadata == metadata;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        userName.hashCode ^
        (userPhotoUrl?.hashCode ?? 0) ^
        type.hashCode ^
        description.hashCode ^
        timestamp.hashCode ^
        (metadata?.hashCode ?? 0);
  }

  @override
  String toString() {
    return 'Activity(id: $id, userId: $userId, type: $type, description: $description, timestamp: $timestamp)';
  }
}

enum ActivityType {
  joinedRoom,
  hostedRoom,
  attendedEvent,
  hostedEvent,
  newFriend,
  gotMatch,
  achievementUnlocked,
  leveledUp,
  streakMilestone,
  other,
}
