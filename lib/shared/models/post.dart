import 'package:cloud_firestore/cloud_firestore.dart';

/// Types of posts
enum PostType {
  text,
  image,
  video,
  roomShare,   // Sharing a live room
  achievement, // User achievement/badge
}

/// Post model for social feed
class Post {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String content;
  final String? imageUrl;
  final String? roomId;
  final PostType type;
  final List<String> likes;
  final int likeCount;
  final int commentCount;
  final int tipCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isVisible;

  Post({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.content,
    this.imageUrl,
    this.roomId,
    required this.type,
    required this.likes,
    required this.likeCount,
    required this.commentCount,
    required this.tipCount,
    required this.createdAt,
    required this.updatedAt,
    required this.isVisible,
  });

  factory Post.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Post(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'User',
      userAvatar: data['userAvatar'] ?? '',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'],
      roomId: data['roomId'],
      type: _parsePostType(data['type']),
      likes: List<String>.from(data['likes'] ?? []),
      likeCount: data['likeCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      tipCount: data['tipCount'] ?? 0,
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
      isVisible: data['isVisible'] ?? true,
    );
  }

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? 'User',
      userAvatar: json['userAvatar'] ?? '',
      content: json['content'] ?? '',
      imageUrl: json['imageUrl'],
      roomId: json['roomId'],
      type: _parsePostType(json['type']),
      likes: List<String>.from(json['likes'] ?? []),
      likeCount: json['likeCount'] ?? 0,
      commentCount: json['commentCount'] ?? 0,
      tipCount: json['tipCount'] ?? 0,
      createdAt: _parseTimestamp(json['createdAt']),
      updatedAt: _parseTimestamp(json['updatedAt']),
      isVisible: json['isVisible'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'content': content,
      'imageUrl': imageUrl,
      'roomId': roomId,
      'type': type.name,
      'likes': likes,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'tipCount': tipCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isVisible': isVisible,
    };
  }

  static PostType _parsePostType(dynamic value) {
    if (value == null) return PostType.text;
    if (value is PostType) return value;
    final str = value.toString().toLowerCase();
    return PostType.values.firstWhere(
      (t) => t.name.toLowerCase() == str,
      orElse: () => PostType.text,
    );
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  /// Check if current user has liked this post
  bool isLikedBy(String userId) => likes.contains(userId);

  /// Time ago string (e.g. "5m", "2h", "1d")
  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'now';
  }

  Post copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatar,
    String? content,
    String? imageUrl,
    String? roomId,
    PostType? type,
    List<String>? likes,
    int? likeCount,
    int? commentCount,
    int? tipCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVisible,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      roomId: roomId ?? this.roomId,
      type: type ?? this.type,
      likes: likes ?? this.likes,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      tipCount: tipCount ?? this.tipCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVisible: isVisible ?? this.isVisible,
    );
  }
}

/// Comment model for post comments
class Comment {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String content;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Comment(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'User',
      userAvatar: data['userAvatar'] ?? '',
      content: data['content'] ?? '',
      createdAt: Post._parseTimestamp(data['createdAt']),
    );
  }

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? 'User',
      userAvatar: json['userAvatar'] ?? '',
      content: json['content'] ?? '',
      createdAt: Post._parseTimestamp(json['createdAt']),
    );
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'now';
  }
}


