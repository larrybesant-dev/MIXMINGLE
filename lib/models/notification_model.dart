import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String type;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.content,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(String id, Map<String, dynamic> json) {
    final createdAt = json['createdAt'];
    return NotificationModel(
      id: id,
      userId: json['userId'] as String? ?? '',
      type: json['type'] as String? ?? 'general',
      content: json['content'] as String? ?? json['body'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? false,
      createdAt: createdAt is Timestamp
          ? createdAt.toDate()
          : DateTime.tryParse(createdAt?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
