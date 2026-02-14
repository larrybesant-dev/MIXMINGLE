import 'package:cloud_firestore/cloud_firestore.dart';

class Block {
  final String id;
  final String blockerId;
  final String blockedUserId;
  final String? reason;
  final DateTime blockedAt;

  const Block({
    required this.id,
    required this.blockerId,
    required this.blockedUserId,
    this.reason,
    required this.blockedAt,
  });

  // Validation
  bool isValid() {
    return id.isNotEmpty && blockerId.isNotEmpty && blockedUserId.isNotEmpty && blockerId != blockedUserId;
  }

  // Check if this block affects a specific user relationship
  bool blocks(String userId1, String userId2) {
    return (blockerId == userId1 && blockedUserId == userId2) || (blockerId == userId2 && blockedUserId == userId1);
  }

  // fromJson
  factory Block.fromJson(Map<String, dynamic> json) {
    return Block(
      id: json['id'] as String? ?? '',
      blockerId: json['blockerId'] as String? ?? '',
      blockedUserId: json['blockedUserId'] as String? ?? '',
      reason: json['reason'] as String?,
      blockedAt: _parseTimestamp(json['blockedAt']),
    );
  }

  // toJson
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'blockerId': blockerId,
      'blockedUserId': blockedUserId,
      if (reason != null) 'reason': reason,
      'blockedAt': Timestamp.fromDate(blockedAt),
    };
  }

  // copyWith
  Block copyWith({
    String? id,
    String? blockerId,
    String? blockedUserId,
    String? reason,
    DateTime? blockedAt,
  }) {
    return Block(
      id: id ?? this.id,
      blockerId: blockerId ?? this.blockerId,
      blockedUserId: blockedUserId ?? this.blockedUserId,
      reason: reason ?? this.reason,
      blockedAt: blockedAt ?? this.blockedAt,
    );
  }

  // Equality
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Block &&
        other.id == id &&
        other.blockerId == blockerId &&
        other.blockedUserId == blockedUserId &&
        other.reason == reason &&
        other.blockedAt == blockedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      blockerId,
      blockedUserId,
      reason,
      blockedAt,
    );
  }

  @override
  String toString() {
    return 'Block(id: $id, blockerId: $blockerId, '
        'blockedUserId: $blockedUserId, blockedAt: $blockedAt)';
  }

  // Helper methods
  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is String) return DateTime.parse(timestamp);
    if (timestamp is DateTime) return timestamp;
    return DateTime.now();
  }

  // Generate block ID from user IDs
  static String generateId(String blockerId, String blockedUserId) {
    return '${blockerId}_$blockedUserId';
  }
}
