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
}
