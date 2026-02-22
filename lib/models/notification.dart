import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  roomInvite,
  reaction,
  newFollower,
  tip,
  message,
  system,
}

class Notification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final String? senderId;
  final String? senderName;
  final String? roomId;
  final String? roomName;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime timestamp;

  Notification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.senderId,
    this.senderName,
    this.roomId,
    this.roomName,
    this.data,
    this.isRead = false,
    required this.timestamp,
  });

  factory Notification.fromMap(Map<String, dynamic> map) {
    return Notification(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      type: NotificationType.values[map['type'] ?? 0],
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      senderId: map['senderId'],
      senderName: map['senderName'],
      roomId: map['roomId'],
      roomName: map['roomName'],
      data: map['data'],
      isRead: map['isRead'] ?? false,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type.index,
      'title': title,
      'message': message,
      'senderId': senderId,
      'senderName': senderName,
      'roomId': roomId,
      'roomName': roomName,
      'data': data,
      'isRead': isRead,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}


