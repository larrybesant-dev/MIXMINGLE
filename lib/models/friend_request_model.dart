import 'package:cloud_firestore/cloud_firestore.dart';

class FriendRequestModel {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String status;
  final DateTime createdAt;

  const FriendRequestModel({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.status,
    required this.createdAt,
  });

  factory FriendRequestModel.fromJson(String id, Map<String, dynamic> json) {
    final createdAt = json['createdAt'];
    return FriendRequestModel(
      id: id,
      fromUserId: json['fromUserId'] as String? ?? '',
      toUserId: json['toUserId'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      createdAt: createdAt is Timestamp
          ? createdAt.toDate()
          : DateTime.tryParse(createdAt?.toString() ?? '') ?? DateTime.now(),
    );
  }
}