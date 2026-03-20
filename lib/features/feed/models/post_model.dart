import 'package:cloud_firestore/cloud_firestore.dart';
class PostModel {
  final String id;
  final String userId;
  final String text;
  final DateTime createdAt;

  PostModel({
    required this.id,
    required this.userId,
    required this.text,
    required this.createdAt,
  });

  factory PostModel.fromDoc(String id, Map<String, dynamic> data) {
    return PostModel(
      id: id,
      userId: data['userId'] ?? '',
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
