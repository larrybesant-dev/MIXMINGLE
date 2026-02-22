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

  SpeedDatingResult({
    required this.id,
    required this.roundId,
    required this.userId,
    required this.matchedUserId,
    required this.userLiked,
    required this.matchedUserLiked,
    required this.isMutual,
    required this.timestamp,
  });

  factory SpeedDatingResult.fromMap(Map<String, dynamic> map) {
    return SpeedDatingResult(
      id: map['id'] as String,
      roundId: map['roundId'] as String,
      userId: map['userId'] as String,
      matchedUserId: map['matchedUserId'] as String,
      userLiked: map['userLiked'] as bool,
      matchedUserLiked: map['matchedUserLiked'] as bool,
      isMutual: map['isMutual'] as bool,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
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
    };
  }
}


