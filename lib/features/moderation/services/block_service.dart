import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/analytics/analytics_service.dart';

class BlockService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AnalyticsService _analytics = AnalyticsService.instance;

  /// Blocks a user
  ///
  /// [userId] - The ID of the user performing the block
  /// [blockedUserId] - The ID of the user being blocked
  Future<void> blockUser({
    required String userId,
    required String blockedUserId,
  }) async {
    await _firestore
        .collection('blocks')
        .doc(userId)
        .collection('blockedUsers')
        .doc(blockedUserId)
        .set({
      'blockedUserId': blockedUserId,
      'blockedAt': FieldValue.serverTimestamp(),
    });

    // Track analytics
    await _analytics.logUserBlocked(blockedUserId: blockedUserId);
  }

  /// Unblocks a user
  ///
  /// [userId] - The ID of the user performing the unblock
  /// [blockedUserId] - The ID of the user being unblocked
  Future<void> unblockUser({
    required String userId,
    required String blockedUserId,
  }) async {
    await _firestore
        .collection('blocks')
        .doc(userId)
        .collection('blockedUsers')
        .doc(blockedUserId)
        .delete();

    // Track analytics
    await _analytics.logUserUnblocked(unblockedUserId: blockedUserId);
  }

  /// Checks if a user is blocked
  ///
  /// [userId] - The ID of the user who may have blocked
  /// [blockedUserId] - The ID of the user to check
  /// Returns true if the user is blocked
  Future<bool> isBlocked({
    required String userId,
    required String blockedUserId,
  }) async {
    final doc = await _firestore
        .collection('blocks')
        .doc(userId)
        .collection('blockedUsers')
        .doc(blockedUserId)
        .get();
    return doc.exists;
  }

  /// Streams the list of blocked user IDs for a user
  ///
  /// [userId] - The ID of the user whose blocked list to stream
  Stream<List<String>> streamBlockedUsers(String userId) {
    return _firestore
        .collection('blocks')
        .doc(userId)
        .collection('blockedUsers')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }
}
