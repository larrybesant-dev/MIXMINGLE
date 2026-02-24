import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType {
  purchase,
  gift,
  tip,
  withdrawal,
  reward,
  refund,
  penalty
}

class CoinTransaction {
  final String id;
  final String userId;
  final int amount;
  final TransactionType type;
  final String? description;
  final String? relatedUserId;
  final String? relatedItemId;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;

  const CoinTransaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    this.description,
    this.relatedUserId,
    this.relatedItemId,
    this.metadata,
    required this.timestamp,
  });

  // Validation
  bool isValid() {
    return id.isNotEmpty && userId.isNotEmpty && amount != 0;
  }

  // Check if transaction is a credit (positive)
  bool get isCredit => amount > 0;

  // Check if transaction is a debit (negative)
  bool get isDebit => amount < 0;

  // fromJson
  factory CoinTransaction.fromJson(Map<String, dynamic> json) {
    return CoinTransaction(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      amount: json['amount'] as int? ?? 0,
      type: _parseType(json['type'] as String?),
      description: json['description'] as String?,
      relatedUserId: json['relatedUserId'] as String?,
      relatedItemId: json['relatedItemId'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      timestamp: _parseTimestamp(json['timestamp']),
    );
  }

  // toJson
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'type': type.name,
      if (description != null) 'description': description,
      if (relatedUserId != null) 'relatedUserId': relatedUserId,
      if (relatedItemId != null) 'relatedItemId': relatedItemId,
      if (metadata != null) 'metadata': metadata,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  // copyWith
  CoinTransaction copyWith({
    String? id,
    String? userId,
    int? amount,
    TransactionType? type,
    String? description,
    String? relatedUserId,
    String? relatedItemId,
    Map<String, dynamic>? metadata,
    DateTime? timestamp,
  }) {
    return CoinTransaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      description: description ?? this.description,
      relatedUserId: relatedUserId ?? this.relatedUserId,
      relatedItemId: relatedItemId ?? this.relatedItemId,
      metadata: metadata ?? this.metadata,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  // Equality
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CoinTransaction &&
        other.id == id &&
        other.userId == userId &&
        other.amount == amount &&
        other.type == type &&
        other.description == description &&
        other.relatedUserId == relatedUserId &&
        other.relatedItemId == relatedItemId &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      amount,
      type,
      description,
      relatedUserId,
      relatedItemId,
      timestamp,
    );
  }

  @override
  String toString() {
    return 'CoinTransaction(id: $id, userId: $userId, amount: $amount, '
        'type: $type, timestamp: $timestamp)';
  }

  // Helper methods
  static TransactionType _parseType(String? type) {
    if (type == null) return TransactionType.purchase;
    try {
      return TransactionType.values.firstWhere(
        (e) => e.name == type,
        orElse: () => TransactionType.purchase,
      );
    } catch (_) {
      return TransactionType.purchase;
    }
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is String) return DateTime.parse(timestamp);
    if (timestamp is DateTime) return timestamp;
    return DateTime.now();
  }
}
