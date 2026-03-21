import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoomModel {
  final String id;
  final String name;
  final String hostId;
  final String? description;
  final List<String> members;
  final bool isLive;
  final DateTime createdAt;

  RoomModel({
    required this.id,
    required this.name,
    required this.hostId,
    this.description,
    this.members = const [],
    this.isLive = false,
    required this.createdAt,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) => RoomModel(
        id: json['id'] ?? '',
        name: json['name'] ?? json['title'] ?? '',
        hostId: json['hostId'] ?? '',
        description: json['description'],
        members: List<String>.from(json['members'] ?? json['participantIds'] ?? []),
        isLive: json['isLive'] ?? json['active'] ?? false,
        createdAt: (json['createdAt'] is Timestamp)
            ? (json['createdAt'] as Timestamp).toDate()
            : DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'hostId': hostId,
        'description': description,
        'members': members,
        'isLive': isLive,
        'createdAt': createdAt.toIso8601String(),
      };

  factory RoomModel.fromFirestore(DocumentSnapshot doc) =>
      RoomModel.fromJson(doc.data() as Map<String, dynamic>);
}




