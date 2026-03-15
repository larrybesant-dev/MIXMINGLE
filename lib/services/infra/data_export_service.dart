import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Service to handle GDPR-compliant data export
/// Allows users to download all their personal data
class DataExportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Exports all user data to JSON format (GDPR Right to Data Portability)
  /// Returns JSON string containing all user data
  Future<String> exportUserData(String userId) async {
    try {
      debugPrint('Starting data export for user: $userId');

      final Map<String, dynamic> exportData = {
        'export_info': {
          'user_id': userId,
          'export_date': DateTime.now().toIso8601String(),
          'format_version': '1.0',
        },
        'profile': await _exportUserProfile(userId),
        'events': await _exportUserEvents(userId),
        'messages': await _exportUserMessages(userId),
        'participations': await _exportEventParticipations(userId),
        'follows': await _exportFollowRelationships(userId),
        'reports': await _exportUserReports(userId),
        'blocks': await _exportUserBlocks(userId),
        'subscription': await _exportSubscriptionData(userId),
        'analytics': await _exportAnalyticsData(userId),
      };

      // Remove null sections
      exportData.removeWhere((key, value) => value == null);

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      debugPrint('Data export completed successfully');

      return jsonString;
    } catch (e) {
      debugPrint('Error exporting user data: $e');
      rethrow;
    }
  }

  /// Exports user profile data
  Future<Map<String, dynamic>?> _exportUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;

      final data = doc.data()!;

      // Include Firebase Auth data
      final user = _auth.currentUser;
      if (user != null && user.uid == userId) {
        data['auth_providers'] = user.providerData
            .map((info) => {
                  'provider_id': info.providerId,
                  'uid': info.uid,
                  'email': info.email,
                  'display_name': info.displayName,
                })
            .toList();
        data['email_verified'] = user.emailVerified;
        data['phone_number'] = user.phoneNumber;
        data['creation_time'] = user.metadata.creationTime?.toIso8601String();
        data['last_sign_in'] = user.metadata.lastSignInTime?.toIso8601String();
      }

      return _sanitizeTimestamps(data);
    } catch (e) {
      debugPrint('Error exporting profile: $e');
      return null;
    }
  }

  /// Exports all events created by the user
  Future<List<Map<String, dynamic>>> _exportUserEvents(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('events')
          .where('createdBy', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => {
                'event_id': doc.id,
                ..._sanitizeTimestamps(doc.data()),
              })
          .toList();
    } catch (e) {
      debugPrint('Error exporting events: $e');
      return [];
    }
  }

  /// Exports all messages sent by the user
  Future<Map<String, dynamic>> _exportUserMessages(String userId) async {
    try {
      final messagesSnapshot = await _firestore
          .collection('messages')
          .where('senderId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      final conversationsSnapshot = await _firestore
          .collection('conversations')
          .where('participants', arrayContains: userId)
          .get();

      return {
        'sent_messages': messagesSnapshot.docs
            .map((doc) => {
                  'message_id': doc.id,
                  ..._sanitizeTimestamps(doc.data()),
                })
            .toList(),
        'conversations': conversationsSnapshot.docs
            .map((doc) => {
                  'conversation_id': doc.id,
                  ..._sanitizeTimestamps(doc.data()),
                })
            .toList(),
      };
    } catch (e) {
      debugPrint('Error exporting messages: $e');
      return {'sent_messages': [], 'conversations': []};
    }
  }

  /// Exports events the user has joined
  Future<List<Map<String, dynamic>>> _exportEventParticipations(
      String userId) async {
    try {
      final snapshot = await _firestore
          .collection('events')
          .where('participants', arrayContains: userId)
          .get();

      return snapshot.docs
          .map((doc) => {
                'event_id': doc.id,
                'event_title': doc.data()['title'],
                'joined_date': doc.data()['joinedAt']?.toString(),
                'status': doc.data()['status'],
              })
          .toList();
    } catch (e) {
      debugPrint('Error exporting participations: $e');
      return [];
    }
  }

  /// Exports follow relationships
  Future<Map<String, dynamic>> _exportFollowRelationships(String userId) async {
    try {
      final followingSnapshot = await _firestore
          .collection('follows')
          .where('followerId', isEqualTo: userId)
          .get();

      final followersSnapshot = await _firestore
          .collection('follows')
          .where('followingId', isEqualTo: userId)
          .get();

      return {
        'following': followingSnapshot.docs
            .map((doc) => {
                  'user_id': doc.data()['followingId'],
                  'followed_at': doc.data()['createdAt']?.toString(),
                })
            .toList(),
        'followers': followersSnapshot.docs
            .map((doc) => {
                  'user_id': doc.data()['followerId'],
                  'followed_at': doc.data()['createdAt']?.toString(),
                })
            .toList(),
      };
    } catch (e) {
      debugPrint('Error exporting follow relationships: $e');
      return {'following': [], 'followers': []};
    }
  }

  /// Exports reports submitted by and against the user
  Future<Map<String, dynamic>> _exportUserReports(String userId) async {
    try {
      final submittedSnapshot = await _firestore
          .collection('reports')
          .where('reporterId', isEqualTo: userId)
          .get();

      final receivedSnapshot = await _firestore
          .collection('reports')
          .where('reportedUserId', isEqualTo: userId)
          .get();

      return {
        'submitted_reports': submittedSnapshot.docs
            .map((doc) => {
                  'report_id': doc.id,
                  ..._sanitizeTimestamps(doc.data()),
                })
            .toList(),
        'received_reports': receivedSnapshot.docs
            .map((doc) => {
                  'report_id': doc.id,
                  'reason': doc.data()['reason'],
                  'status': doc.data()['status'],
                  'created_at': doc.data()['createdAt']?.toString(),
                })
            .toList(),
      };
    } catch (e) {
      debugPrint('Error exporting reports: $e');
      return {'submitted_reports': [], 'received_reports': []};
    }
  }

  /// Exports blocked users
  Future<Map<String, dynamic>> _exportUserBlocks(String userId) async {
    try {
      final blockedByUserSnapshot = await _firestore
          .collection('blocks')
          .where('blockerId', isEqualTo: userId)
          .get();

      final blockedUserSnapshot = await _firestore
          .collection('blocks')
          .where('blockedUserId', isEqualTo: userId)
          .get();

      return {
        'users_you_blocked': blockedByUserSnapshot.docs
            .map((doc) => {
                  'blocked_user_id': doc.data()['blockedUserId'],
                  'blocked_at': doc.data()['createdAt']?.toString(),
                })
            .toList(),
        'users_who_blocked_you': blockedUserSnapshot.docs
            .map((doc) => {
                  'blocker_user_id': doc.data()['blockerId'],
                  'blocked_at': doc.data()['createdAt']?.toString(),
                })
            .toList(),
      };
    } catch (e) {
      debugPrint('Error exporting blocks: $e');
      return {'users_you_blocked': [], 'users_who_blocked_you': []};
    }
  }

  /// Exports subscription data
  Future<Map<String, dynamic>?> _exportSubscriptionData(String userId) async {
    try {
      final doc =
          await _firestore.collection('subscriptions').doc(userId).get();
      if (!doc.exists) return null;

      return _sanitizeTimestamps(doc.data()!);
    } catch (e) {
      debugPrint('Error exporting subscription: $e');
      return null;
    }
  }

  /// Exports analytics data (if stored in Firestore)
  Future<Map<String, dynamic>?> _exportAnalyticsData(String userId) async {
    try {
      // If you store any analytics in Firestore, export it here
      // Otherwise, return null or minimal data
      return {
        'note':
            'Analytics data is processed by Firebase Analytics and not stored in exportable format',
        'user_id': userId,
      };
    } catch (e) {
      debugPrint('Error exporting analytics: $e');
      return null;
    }
  }

  /// Converts Firestore Timestamps to ISO strings for JSON compatibility
  Map<String, dynamic> _sanitizeTimestamps(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};

    data.forEach((key, value) {
      if (value is Timestamp) {
        sanitized[key] = value.toDate().toIso8601String();
      } else if (value is Map) {
        sanitized[key] = _sanitizeTimestamps(Map<String, dynamic>.from(value));
      } else if (value is List) {
        sanitized[key] = value.map((item) {
          if (item is Map) {
            return _sanitizeTimestamps(Map<String, dynamic>.from(item));
          }
          return item;
        }).toList();
      } else {
        sanitized[key] = value;
      }
    });

    return sanitized;
  }

  /// Generates a summary of what data will be exported
  Future<Map<String, int>> getExportSummary(String userId) async {
    try {
      final summary = <String, int>{};

      // Count events
      final eventsCount = await _firestore
          .collection('events')
          .where('createdBy', isEqualTo: userId)
          .count()
          .get();
      summary['events_created'] = eventsCount.count ?? 0;

      // Count messages
      final messagesCount = await _firestore
          .collection('messages')
          .where('senderId', isEqualTo: userId)
          .count()
          .get();
      summary['messages_sent'] = messagesCount.count ?? 0;

      // Count follows
      final followingCount = await _firestore
          .collection('follows')
          .where('followerId', isEqualTo: userId)
          .count()
          .get();
      summary['following'] = followingCount.count ?? 0;

      final followersCount = await _firestore
          .collection('follows')
          .where('followingId', isEqualTo: userId)
          .count()
          .get();
      summary['followers'] = followersCount.count ?? 0;

      return summary;
    } catch (e) {
      debugPrint('Error getting export summary: $e');
      return {};
    }
  }
}
