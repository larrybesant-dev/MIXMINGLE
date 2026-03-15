// Feedback model for MIXVY
class FeedbackItem {
  final String id;
  final String userId;
  final String message;
  final DateTime timestamp;

  FeedbackItem({
    required this.id,
    required this.userId,
    required this.message,
    required this.timestamp,
  });
}
