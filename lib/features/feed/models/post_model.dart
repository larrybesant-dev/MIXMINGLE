import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String userId;
  final String text;
  final DateTime createdAt;
  final String? authorName;
  final String? authorAvatarUrl;
  final int likeCount;
  final List<String> likedBy;
  final int commentCount;

  PostModel({
    required this.id,
    required this.userId,
    required this.text,
    required this.createdAt,
    this.authorName,
    this.authorAvatarUrl,
    this.likeCount = 0,
    this.likedBy = const [],
    this.commentCount = 0,
  });

  bool isLikedBy(String uid) => likedBy.contains(uid);

  factory PostModel.fromDoc(String id, Map<String, dynamic> data) {
    return PostModel(
      id: id,
      userId: data['userId'] ?? '',
      text: data['text'] ?? '',
      createdAt: _parseDateTime(data['createdAt']),
      authorName: data['authorName'] as String?,
      authorAvatarUrl: data['authorAvatarUrl'] as String?,
      likeCount: (data['likeCount'] as num?)?.toInt() ?? 0,
      likedBy: _asStringList(data['likes']),
      commentCount: (data['commentCount'] as num?)?.toInt() ?? 0,
    );
  }

  static List<String> _asStringList(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<String>().toList();
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
