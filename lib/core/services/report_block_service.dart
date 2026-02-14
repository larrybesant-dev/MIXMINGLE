import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_logger.dart';
import '../utils/firestore_utils.dart';

/// Phase 13: Report & Block Service
/// Handles user reporting and blocking functionality with comprehensive abuse prevention

class ReportBlockService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ========================================
  // BLOCK FUNCTIONALITY
  // ========================================

  /// Block a user
  static Future<void> blockUser(String blockedUserId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    if (currentUserId == blockedUserId) {
      throw Exception('Cannot block yourself');
    }

    try {
      AppLogger.info('Blocking user: $blockedUserId');

      // Add to blocked list
      await SafeFirestore.safeSet(
        ref: _firestore.collection('users').doc(currentUserId).collection('blocked').doc(blockedUserId),
        data: {
          'blockedAt': FieldValue.serverTimestamp(),
          'blockedUserId': blockedUserId,
        },
      );

      // Remove follow relationships
      await _removeFollowRelationships(currentUserId, blockedUserId);

      AppLogger.info('User blocked successfully: $blockedUserId');
    } catch (e, stack) {
      AppLogger.error('Error blocking user', e, stack);
      rethrow;
    }
  }

  /// Unblock a user
  static Future<void> unblockUser(String blockedUserId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      AppLogger.info('Unblocking user: $blockedUserId');

      await SafeFirestore.safeDelete(
        ref: _firestore.collection('users').doc(currentUserId).collection('blocked').doc(blockedUserId),
      );

      AppLogger.info('User unblocked successfully: $blockedUserId');
    } catch (e, stack) {
      AppLogger.error('Error unblocking user', e, stack);
      rethrow;
    }
  }

  /// Check if user is blocked
  static Future<bool> isUserBlocked(String userId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return false;

    try {
      final doc = await SafeFirestore.safeGet(
        ref: _firestore.collection('users').doc(currentUserId).collection('blocked').doc(userId),
      );

      return doc?.exists ?? false;
    } catch (e, stack) {
      AppLogger.error('Error checking if user is blocked', e, stack);
      return false;
    }
  }

  /// Check if current user is blocked by another user
  static Future<bool> isBlockedBy(String userId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return false;

    try {
      final doc = await SafeFirestore.safeGet(
        ref: _firestore.collection('users').doc(userId).collection('blocked').doc(currentUserId),
      );

      return doc?.exists ?? false;
    } catch (e, stack) {
      AppLogger.error('Error checking if blocked by user', e, stack);
      return false;
    }
  }

  /// Get list of blocked users
  static Future<List<String>> getBlockedUsers() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return [];

    try {
      final snapshot = await SafeFirestore.safeQuery(
        query: _firestore.collection('users').doc(currentUserId).collection('blocked'),
      );

      if (snapshot == null) return [];

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e, stack) {
      AppLogger.error('Error getting blocked users', e, stack);
      return [];
    }
  }

  /// Remove follow relationships when blocking
  static Future<void> _removeFollowRelationships(
    String currentUserId,
    String blockedUserId,
  ) async {
    try {
      // Remove from current user's following
      await SafeFirestore.safeDelete(
        ref: _firestore.collection('users').doc(currentUserId).collection('following').doc(blockedUserId),
      );

      // Remove from blocked user's followers
      await SafeFirestore.safeDelete(
        ref: _firestore.collection('users').doc(blockedUserId).collection('followers').doc(currentUserId),
      );

      // Remove from blocked user's following
      await SafeFirestore.safeDelete(
        ref: _firestore.collection('users').doc(blockedUserId).collection('following').doc(currentUserId),
      );

      // Remove from current user's followers
      await SafeFirestore.safeDelete(
        ref: _firestore.collection('users').doc(currentUserId).collection('followers').doc(blockedUserId),
      );
    } catch (e, stack) {
      AppLogger.error('Error removing follow relationships', e, stack);
      // Don't rethrow - blocking should succeed even if unfollowing fails
    }
  }

  // ========================================
  // REPORT FUNCTIONALITY
  // ========================================

  /// Report a user
  static Future<void> reportUser({
    required String reportedUserId,
    required String reason,
    String? description,
    String? contentId,
    String? contentType,
  }) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    if (currentUserId == reportedUserId) {
      throw Exception('Cannot report yourself');
    }

    if (reason.trim().isEmpty) {
      throw Exception('Report reason is required');
    }

    if (reason.length > 1000) {
      throw Exception('Report reason is too long (max 1000 characters)');
    }

    try {
      AppLogger.info('Reporting user: $reportedUserId for reason: $reason');

      final reportData = {
        'reporterId': currentUserId,
        'reportedId': reportedUserId,
        'reason': reason.trim(),
        'description': description?.trim(),
        'contentId': contentId,
        'contentType': contentType,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'reviewedAt': null,
        'reviewedBy': null,
        'action': null,
      };

      await SafeFirestore.safeSet(
        ref: _firestore.collection('reports').doc(),
        data: reportData,
      );

      AppLogger.info('User reported successfully: $reportedUserId');
    } catch (e, stack) {
      AppLogger.error('Error reporting user', e, stack);
      rethrow;
    }
  }

  /// Report content (message, event, room, etc.)
  static Future<void> reportContent({
    required String contentId,
    required String contentType,
    required String ownerId,
    required String reason,
    String? description,
  }) async {
    await reportUser(
      reportedUserId: ownerId,
      reason: reason,
      description: description,
      contentId: contentId,
      contentType: contentType,
    );
  }

  /// Check if user has already been reported by current user
  static Future<bool> hasReportedUser(String reportedUserId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return false;

    try {
      final snapshot = await SafeFirestore.safeQuery(
        query: _firestore
            .collection('reports')
            .where('reporterId', isEqualTo: currentUserId)
            .where('reportedId', isEqualTo: reportedUserId)
            .limit(1),
      );

      return snapshot != null && snapshot.docs.isNotEmpty;
    } catch (e, stack) {
      AppLogger.error('Error checking if user is reported', e, stack);
      return false;
    }
  }

  // ========================================
  // REPORT REASONS
  // ========================================

  static const List<String> reportReasons = [
    'Harassment or bullying',
    'Inappropriate content',
    'Spam or scam',
    'Fake profile',
    'Hate speech',
    'Violence or threats',
    'Sexual content',
    'Impersonation',
    'Privacy violation',
    'Other',
  ];

  static const Map<String, String> reportReasonDescriptions = {
    'Harassment or bullying': 'This user is harassing or bullying others',
    'Inappropriate content': 'This user is posting inappropriate content',
    'Spam or scam': 'This user is sending spam or running scams',
    'Fake profile': 'This profile appears to be fake or fraudulent',
    'Hate speech': 'This user is posting hateful or discriminatory content',
    'Violence or threats': 'This user is threatening violence',
    'Sexual content': 'This user is posting unwanted sexual content',
    'Impersonation': 'This user is pretending to be someone else',
    'Privacy violation': 'This user is violating privacy',
    'Other': 'Other reason (please describe)',
  };

  // ========================================
  // SAFETY HELPERS
  // ========================================

  /// Filter out blocked users from a list
  static Future<List<String>> filterBlockedUsers(List<String> userIds) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return userIds;

    try {
      final blockedUsers = await getBlockedUsers();
      return userIds.where((id) => !blockedUsers.contains(id)).toList();
    } catch (e, stack) {
      AppLogger.error('Error filtering blocked users', e, stack);
      return userIds;
    }
  }

  /// Check if interaction is allowed between two users
  static Future<bool> canInteract(String otherUserId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return false;

    try {
      // Check if current user has blocked the other user
      final hasBlocked = await isUserBlocked(otherUserId);
      if (hasBlocked) return false;

      // Check if current user is blocked by the other user
      final isBlocked = await isBlockedBy(otherUserId);
      if (isBlocked) return false;

      return true;
    } catch (e, stack) {
      AppLogger.error('Error checking if interaction is allowed', e, stack);
      return false;
    }
  }
}
