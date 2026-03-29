import 'package:cloud_firestore/cloud_firestore.dart';

class MicAccessRequestModel {
  final String id;
  final String roomId;
  final String requesterId;
  final String hostId;
  final String status;
  final int priority;
  final DateTime expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MicAccessRequestModel({
    required this.id,
    required this.roomId,
    required this.requesterId,
    required this.hostId,
    required this.status,
    required this.priority,
    required this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MicAccessRequestModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return MicAccessRequestModel(
      id: (json['id'] as String? ?? '').trim(),
      roomId: (json['roomId'] as String? ?? '').trim(),
      requesterId: (json['requesterId'] as String? ?? '').trim(),
      hostId: (json['hostId'] as String? ?? '').trim(),
      status: (json['status'] as String? ?? 'pending').trim(),
      priority: (json['priority'] as int?) ?? 100,
      expiresAt: parseDate(json['expiresAt']),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
