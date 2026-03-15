class Friend {
  final String userId;
  final String friendId;
  final bool isOnline;
  final DateTime lastSeen;

  Friend({
    required this.userId,
    required this.friendId,
    required this.isOnline,
    required this.lastSeen,
  });

  factory Friend.fromMap(Map<String, dynamic> data) {
    return Friend(
      userId: data['userId'] ?? '',
      friendId: data['friendId'] ?? '',
      isOnline: data['isOnline'] ?? false,
      lastSeen: DateTime.tryParse(data['lastSeen'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'friendId': friendId,
      'isOnline': isOnline,
      'lastSeen': lastSeen.toIso8601String(),
    };
  }
}
