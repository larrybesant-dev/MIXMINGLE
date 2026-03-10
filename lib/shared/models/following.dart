import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a following relationship between users
class Following {
  final String id; // Document ID (followerId_followingId)
  final String followerId; // User who is following
  final String followingId; // User being followed
  final DateTime createdAt;
  final bool isMutual; // Whether the follow is mutual

  Following({
    required this.id,
    required this.followerId,
    required this.followingId,
    required this.createdAt,
    this.isMutual = false,
  });

  factory Following.fromMap(Map<String, dynamic> map, String id) {
    return Following(
      id: id,
      followerId: map['followerId'] ?? '',
      followingId: map['followingId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isMutual: map['isMutual'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'followerId': followerId,
      'followingId': followingId,
      'createdAt': Timestamp.fromDate(createdAt),
      'isMutual': isMutual,
    };
  }

  /// Create a unique ID for the following relationship
  static String createId(String followerId, String followingId) {
    return '${followerId}_$followingId';
  }

  /// Check if this following relationship is mutual
  Future<bool> checkIfMutual() async {
    // This would be implemented in the service
    return false;
  }
}
