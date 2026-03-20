import 'package:cloud_firestore/cloud_firestore.dart';
class RoomModel {
  final String id;
  final String title;
  final String hostId;
  final bool active;
  final DateTime createdAt;

  RoomModel({
    required this.id,
    required this.title,
    required this.hostId,
    required this.active,
    required this.createdAt,
  });

  factory RoomModel.fromDoc(String id, Map<String, dynamic> data) {
    return RoomModel(
      id: id,
      title: data['title'] ?? '',
      hostId: data['hostId'] ?? '',
      active: data['active'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
