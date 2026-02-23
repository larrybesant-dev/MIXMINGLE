import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  message,
  match,
  eventInvite,
  eventReminder,
  speedDatingMatch,
  friendRequest,
  system,
}

class NotificationItem {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    return NotificationItem(
      id: map['id'] as String,
      userId: map['userId'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == 'NotificationType.${map['type']}',
      ),
      title: map['title'] as String,
      message: map['message'] as String,
      data: map['data'] as Map<String, dynamic>,
      isRead: map['isRead'] as bool,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type.toString().split('.').last,
      'title': title,
      'message': message,
      'data': data,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}


