import 'package:cloud_firestore/cloud_firestore.dart';

class SpeedDatingResult {
  final String id;
  final String roundId;
  final String userId;
  final String matchedUserId;
  final bool userLiked;
  final bool matchedUserLiked;
  final bool isMutual;
  final DateTime timestamp;
  // Denormalized for fast inbox reads
  final String? matchedUserName;
  final String? matchedUserAvatar;

  SpeedDatingResult({
    required this.id,
    required this.roundId,
    required this.userId,
    required this.matchedUserId,
    required this.userLiked,
    required this.matchedUserLiked,
    required this.isMutual,
    required this.timestamp,
    this.matchedUserName,
    this.matchedUserAvatar,
  });

  factory SpeedDatingResult.fromMap(Map<String, dynamic> map) {
    return SpeedDatingResult(
      id: map['id'] as String? ?? '',
      roundId: map['roundId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      matchedUserId: map['matchedUserId'] as String? ?? '',
      userLiked: map['userLiked'] as bool? ?? false,
      matchedUserLiked: map['matchedUserLiked'] as bool? ?? false,
      isMutual: map['isMutual'] as bool? ?? false,
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] is Timestamp
              ? (map['timestamp'] as Timestamp).toDate()
              : DateTime.tryParse(map['timestamp'].toString()) ??
                  DateTime.now())
          : DateTime.now(),
      matchedUserName: map['matchedUserName'] as String?,
      matchedUserAvatar: map['matchedUserAvatar'] as String?,
    );
  }

  /// Alias for fromMap to support JSON conversion
  factory SpeedDatingResult.fromJson(Map<String, dynamic> json) {
    return SpeedDatingResult.fromMap(json);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'roundId': roundId,
      'userId': userId,
      'matchedUserId': matchedUserId,
      'userLiked': userLiked,
      'matchedUserLiked': matchedUserLiked,
      'isMutual': isMutual,
      'timestamp': Timestamp.fromDate(timestamp),
      if (matchedUserName != null) 'matchedUserName': matchedUserName,
      if (matchedUserAvatar != null) 'matchedUserAvatar': matchedUserAvatar,
    };
  }

  SpeedDatingResult copyWith({
    String? id,
    String? roundId,
    String? userId,
    String? matchedUserId,
    bool? userLiked,
    bool? matchedUserLiked,
    bool? isMutual,
    DateTime? timestamp,
    String? matchedUserName,
    String? matchedUserAvatar,
  }) {
    return SpeedDatingResult(
      id: id ?? this.id,
      roundId: roundId ?? this.roundId,
      userId: userId ?? this.userId,
      matchedUserId: matchedUserId ?? this.matchedUserId,
      userLiked: userLiked ?? this.userLiked,
      matchedUserLiked: matchedUserLiked ?? this.matchedUserLiked,
      isMutual: isMutual ?? this.isMutual,
      timestamp: timestamp ?? this.timestamp,
      matchedUserName: matchedUserName ?? this.matchedUserName,
      matchedUserAvatar: matchedUserAvatar ?? this.matchedUserAvatar,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SpeedDatingResult &&
        other.id == id &&
        other.roundId == roundId &&
        other.userId == userId &&
        other.matchedUserId == matchedUserId &&
        other.userLiked == userLiked &&
        other.matchedUserLiked == matchedUserLiked &&
        other.isMutual == isMutual &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        roundId.hashCode ^
        userId.hashCode ^
        matchedUserId.hashCode ^
        userLiked.hashCode ^
        matchedUserLiked.hashCode ^
        isMutual.hashCode ^
        timestamp.hashCode;
  }

  @override
  String toString() {
    return 'SpeedDatingResult(id: $id, roundId: $roundId, userId: $userId, matchedUserId: $matchedUserId, isMutual: $isMutual, timestamp: $timestamp)';
  }
}
