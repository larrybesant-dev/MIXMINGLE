import 'package:cloud_firestore/cloud_firestore.dart';

/// Manages user safety features including blocking, reporting, and moderation
class UserSafetyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Block a user to prevent any interaction
  Future<void> blockUser(String userId, String blockedUserId) async {
    try {
      await _firestore.collection('users').doc(userId).collection('blocked_users').doc(blockedUserId).set({
        'blocked_user_id': blockedUserId,
        'blocked_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to block user: $e');
    }
  }

  /// Unblock a user
  Future<void> unblockUser(String userId, String blockedUserId) async {
    try {
      await _firestore.collection('users').doc(userId).collection('blocked_users').doc(blockedUserId).delete();
    } catch (e) {
      throw Exception('Failed to unblock user: $e');
    }
  }

  /// Check if a user is blocked
  Future<bool> isUserBlocked(String userId, String targetUserId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).collection('blocked_users').doc(targetUserId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Get list of blocked users
  Future<List<String>> getBlockedUsers(String userId) async {
    try {
      final snapshot = await _firestore.collection('users').doc(userId).collection('blocked_users').get();
      return snapshot.docs.map((doc) => doc['blocked_user_id'] as String).toList();
    } catch (e) {
      return [];
    }
  }

  /// Report a user for inappropriate behavior
  Future<void> reportUser({
    required String reporterId,
    required String reportedUserId,
    required String reason,
    String? description,
  }) async {
    try {
      await _firestore.collection('reports').add({
        'reporter_id': reporterId,
        'reported_user_id': reportedUserId,
        'reason': reason,
        'description': description,
        'status': 'pending', // pending, investigating, resolved, dismissed
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Auto-increment report count for user
      await _firestore.collection('users').doc(reportedUserId).update({
        'report_count': FieldValue.increment(1),
      }).catchError((_) => null); // Ignore if user doesn't exist
    } catch (e) {
      throw Exception('Failed to report user: $e');
    }
  }

  /// Get report reasons for reporting dialog
  static List<String> getReportReasons() {
    return [
      'Inappropriate language',
      'Harassment or bullying',
      'Sexual content',
      'Spam',
      'Impersonation',
      'Copyright infringement',
      'Other',
    ];
  }

  /// Check if user should be suspended based on report count
  Future<bool> shouldSuspendUser(String userId, int suspensionThreshold) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final reportCount = userDoc['report_count'] as int? ?? 0;
      return reportCount >= suspensionThreshold;
    } catch (e) {
      return false;
    }
  }

  /// Suspend a user (prevent access to app)
  Future<void> suspendUser(String userId, String reason) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'suspension_status': 'suspended',
        'suspension_reason': reason,
        'suspended_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to suspend user: $e');
    }
  }

  /// Get content filter for checking inappropriate messages
  static bool containsInappropriateContent(String text) {
    // Simple profanity filter - implement more comprehensive solution for production
    final bannedWords = [
      'explicit_word_1',
      'explicit_word_2',
      // Add more banned words as needed
    ];

    final lowerText = text.toLowerCase();
    return bannedWords.any((word) => lowerText.contains(word));
  }
}


