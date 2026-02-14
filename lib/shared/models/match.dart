import 'package:cloud_firestore/cloud_firestore.dart';

enum MatchStatus { active, archived, blocked }

class Match {
  final String id;
  final String userId1;
  final String userId2;
  final int matchScore;
  final String? conversationId;
  final MatchStatus status;
  final DateTime matchedAt;
  final DateTime? lastInteractionAt;

  const Match({
    required this.id,
    required this.userId1,
    required this.userId2,
    required this.matchScore,
    this.conversationId,
    required this.status,
    required this.matchedAt,
    this.lastInteractionAt,
  });

  // Convenience getters for backward compatibility
  String get user1Id => userId1;
  String get user2Id => userId2;

  // Validation
  bool isValid() {
    return id.isNotEmpty &&
        userId1.isNotEmpty &&
        userId2.isNotEmpty &&
        userId1 != userId2 &&
        matchScore >= 0 &&
        matchScore <= 100;
  }

  // Check if user is part of this match
  bool includes(String userId) {
    return userId == userId1 || userId == userId2;
  }

  // Get the other user in the match
  String getOtherUserId(String currentUserId) {
    return currentUserId == userId1 ? userId2 : userId1;
  }

  // fromJson
  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'] as String? ?? '',
      userId1: json['userId1'] as String? ?? '',
      userId2: json['userId2'] as String? ?? '',
      matchScore: json['matchScore'] as int? ?? 0,
      conversationId: json['conversationId'] as String?,
      status: _parseStatus(json['status'] as String?),
      matchedAt: _parseTimestamp(json['matchedAt']),
      lastInteractionAt: json['lastInteractionAt'] != null ? _parseTimestamp(json['lastInteractionAt']) : null,
    );
  }

  // toJson
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId1': userId1,
      'userId2': userId2,
      'matchScore': matchScore,
      if (conversationId != null) 'conversationId': conversationId,
      'status': status.name,
      'matchedAt': Timestamp.fromDate(matchedAt),
      if (lastInteractionAt != null) 'lastInteractionAt': Timestamp.fromDate(lastInteractionAt!),
    };
  }

  // copyWith
  Match copyWith({
    String? id,
    String? userId1,
    String? userId2,
    int? matchScore,
    String? conversationId,
    MatchStatus? status,
    DateTime? matchedAt,
    DateTime? lastInteractionAt,
  }) {
    return Match(
      id: id ?? this.id,
      userId1: userId1 ?? this.userId1,
      userId2: userId2 ?? this.userId2,
      matchScore: matchScore ?? this.matchScore,
      conversationId: conversationId ?? this.conversationId,
      status: status ?? this.status,
      matchedAt: matchedAt ?? this.matchedAt,
      lastInteractionAt: lastInteractionAt ?? this.lastInteractionAt,
    );
  }

  // Equality
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Match &&
        other.id == id &&
        other.userId1 == userId1 &&
        other.userId2 == userId2 &&
        other.matchScore == matchScore &&
        other.conversationId == conversationId &&
        other.status == status &&
        other.matchedAt == matchedAt &&
        other.lastInteractionAt == lastInteractionAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId1,
      userId2,
      matchScore,
      conversationId,
      status,
      matchedAt,
      lastInteractionAt,
    );
  }

  @override
  String toString() {
    return 'Match(id: $id, userId1: $userId1, userId2: $userId2, '
        'matchScore: $matchScore, status: $status, matchedAt: $matchedAt)';
  }

  // Helper methods
  static MatchStatus _parseStatus(String? status) {
    if (status == null) return MatchStatus.active;
    try {
      return MatchStatus.values.firstWhere(
        (e) => e.name == status,
        orElse: () => MatchStatus.active,
      );
    } catch (_) {
      return MatchStatus.active;
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
