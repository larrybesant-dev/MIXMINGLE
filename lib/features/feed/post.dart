// Post model for MIXVY community feed
class Post {
  final String id;
  final String userId;
  final String content;
  final DateTime timestamp;
  final int likes;
  final int comments;

  Post({
    required this.id,
    required this.userId,
    required this.content,
    required this.timestamp,
    required this.likes,
    required this.comments,
  });

  Post copyWith({
    String? content,
    int? likes,
    int? comments,
  }) {
    return Post(
      id: id,
      userId: userId,
      content: content ?? this.content,
      timestamp: timestamp,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
    );
  }
}
