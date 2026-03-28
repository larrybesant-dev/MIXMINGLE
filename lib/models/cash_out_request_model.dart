import 'package:cloud_firestore/cloud_firestore.dart';

class CashOutRequestModel {
  const CashOutRequestModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.status,
    this.createdAt,
  });

  final String id;
  final String userId;
  final double amount;
  final String status;
  final DateTime? createdAt;

  factory CashOutRequestModel.fromJson(String id, Map<String, dynamic> json) {
    final createdAt = json['createdAt'];
    return CashOutRequestModel(
      id: id,
      userId: json['userId'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'pending',
      createdAt: createdAt is Timestamp
          ? createdAt.toDate()
          : DateTime.tryParse(createdAt?.toString() ?? ''),
    );
  }
}