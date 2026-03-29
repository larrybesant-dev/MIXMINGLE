import 'package:cloud_firestore/cloud_firestore.dart';

class Group {
  final String id;
  final String name;
  final String description;
  final String adminId;
  final List<String> memberIds;
  final String? coverImageUrl;
  final DateTime createdAt;
  final int memberCount;

  Group({
    required this.id,
    required this.name,
    required this.description,
    required this.adminId,
    required this.memberIds,
    this.coverImageUrl,
    required this.createdAt,
    required this.memberCount,
  });

  factory Group.fromJson(Map<String, dynamic> json, String id) {
    return Group(
      id: id,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      adminId: json['adminId'] as String? ?? '',
      memberIds: List<String>.from(json['memberIds'] as List? ?? []),
      coverImageUrl: json['coverImageUrl'] as String?,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      memberCount: json['memberCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'adminId': adminId,
      'memberIds': memberIds,
      'coverImageUrl': coverImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'memberCount': memberCount,
    };
  }

  bool isMember(String userId) => memberIds.contains(userId);
  bool isAdmin(String userId) => adminId == userId;
}

class GroupPost {
  final String id;
  final String groupId;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final String content;
  final List<String> tags;
  final DateTime createdAt;
  final int likeCount;
  final List<String> likedBy;

  GroupPost({
    required this.id,
    required this.groupId,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.content,
    required this.tags,
    required this.createdAt,
    required this.likeCount,
    required this.likedBy,
  });

  factory GroupPost.fromJson(Map<String, dynamic> json, String id) {
    return GroupPost(
      id: id,
      groupId: json['groupId'] as String? ?? '',
      authorId: json['authorId'] as String? ?? '',
      authorName: json['authorName'] as String? ?? '',
      authorAvatarUrl: json['authorAvatarUrl'] as String?,
      content: json['content'] as String? ?? '',
      tags: List<String>.from(json['tags'] as List? ?? []),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likeCount: json['likeCount'] as int? ?? 0,
      likedBy: List<String>.from(json['likedBy'] as List? ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatarUrl': authorAvatarUrl,
      'content': content,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'likeCount': likeCount,
      'likedBy': likedBy,
    };
  }
}
