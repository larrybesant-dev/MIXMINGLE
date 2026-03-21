import 'package:cloud_firestore/cloud_firestore.dart';

class ReactionModel {
  final String userId;
  final String emoji;
  final DateTime timestamp;

  ReactionModel({
    required this.userId,
    required this.emoji,
    required this.timestamp,
  });

  factory ReactionModel.fromJson(Map<String, dynamic> json) {
    return ReactionModel(
      userId: json['userId'] as String,
      emoji: json['emoji'] as String,
      timestamp: (json['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'emoji': emoji,
    'timestamp': Timestamp.fromDate(timestamp),
  };
}
