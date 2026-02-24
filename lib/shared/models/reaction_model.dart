// lib/models/reaction_model.dart

class ReactionModel {
  final String userId;
  final String type;
  final DateTime timestamp;

  ReactionModel(
      {required this.userId, required this.type, required this.timestamp});

  factory ReactionModel.fromMap(Map<String, dynamic> map) => ReactionModel(
        userId: map['userId'],
        type: map['type'],
        timestamp: DateTime.parse(map['timestamp']),
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'type': type,
        'timestamp': timestamp.toIso8601String(),
      };
}
