// Notification model for MIXVY notifications
class NotificationItem {
  final String id;
  final String userId;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool read;

  NotificationItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.read,
  });

  NotificationItem copyWith({
    bool? read,
  }) {
    return NotificationItem(
      id: id,
      userId: userId,
      title: title,
      body: body,
      timestamp: timestamp,
      read: read ?? this.read,
    );
  }
}
