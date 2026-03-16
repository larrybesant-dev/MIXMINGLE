import 'package:cloud_firestore/cloud_firestore.dart';

class RoomModel {
  final String id;
  final String name;
  final String ownerId;
  final List<String> participantIds;
  final bool isLive;
  final DateTime createdAt;

  RoomModel({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.participantIds,
    required this.isLive,
    required this.createdAt,
  });

  factory RoomModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RoomModel(
      id: doc.id,
      name: data['name'] ?? '',
      ownerId: data['ownerId'] ?? '',
      participantIds: List<String>.from(data['participantIds'] ?? []),
      isLive: data['isLive'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ownerId': ownerId,
      'participantIds': participantIds,
      'isLive': isLive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
