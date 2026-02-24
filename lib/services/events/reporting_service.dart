import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Types of content that can be reported
enum ReportType {
  user,
  event,
  message,
  photo,
}

/// Reasons for reporting
enum ReportReason {
  inappropriateContent, // Explicit, violent, etc.
  harassment, // Bullying, threats
  spam, // Unwanted ads, repetitive content
  impersonation, // Fake identity
  scam, // Fraud, phishing
  underage, // User appears to be under 18
  hateSpeech, // Discriminatory content
  other, // Requires additional explanation
}

/// Status of a report
enum ReportStatus {
  pending, // Awaiting review
  investigating, // Under review
  resolved, // Action taken
  dismissed, // No action needed
}

/// Service to handle content reporting and moderation
class ReportingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Submits a report for review
  Future<String> submitReport({
    required ReportType type,
    required String reportedId, // userId, eventId, messageId, etc.
    required ReportReason reason,
    String? additionalInfo,
    List<String>? evidenceUrls, // Screenshots, etc.
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Must be logged in to submit a report');
    }

    try {
      // Check if user has already reported this content recently
      final existingReport = await _firestore
          .collection('reports')
          .where('reporterId', isEqualTo: user.uid)
          .where('reportedId', isEqualTo: reportedId)
          .where('createdAt', isGreaterThan: DateTime.now().subtract(const Duration(days: 7)))
          .limit(1)
          .get();

      if (existingReport.docs.isNotEmpty) {
        throw Exception('You have already reported this content recently');
      }

      // Create the report
      final reportData = {
        'reporterId': user.uid,
        'reporterEmail': user.email,
        'type': type.name,
        'reportedId': reportedId,
        'reason': reason.name,
        'additionalInfo': additionalInfo,
        'evidenceUrls': evidenceUrls ?? [],
        'status': ReportStatus.pending.name,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'reviewedBy': null,
        'reviewedAt': null,
        'actionTaken': null,
      };

      // Add type-specific data
      if (type == ReportType.user) {
        final reportedUser = await _firestore.collection('users').doc(reportedId).get();
        reportData['reportedUserEmail'] = reportedUser.data()?['email'];
        reportData['reportedUserName'] = reportedUser.data()?['displayName'];
      }

      final docRef = await _firestore.collection('reports').add(reportData);

      debugPrint('Report submitted: ${docRef.id}');

      // Update report count on reported content (for automated flagging)
      await _incrementReportCount(type, reportedId);

      return docRef.id;
    } catch (e) {
      debugPrint('Error submitting report: $e');
      rethrow;
    }
  }

  /// Increments report count on the reported content
  Future<void> _incrementReportCount(ReportType type, String contentId) async {
    try {
      String collection;
      switch (type) {
        case ReportType.user:
          collection = 'users';
          break;
        case ReportType.event:
          collection = 'events';
          break;
        case ReportType.message:
          collection = 'messages';
          break;
        case ReportType.photo:
          return; // Photos are part of user profiles
      }

      await _firestore.collection(collection).doc(contentId).update({
        'reportCount': FieldValue.increment(1),
        'lastReportedAt': FieldValue.serverTimestamp(),
      });

      // Auto-flag if report count exceeds threshold
      final doc = await _firestore.collection(collection).doc(contentId).get();
      final reportCount = doc.data()?['reportCount'] ?? 0;

      if (reportCount >= 3) {
        await _autoFlagContent(type, contentId);
      }
    } catch (e) {
      debugPrint('Error incrementing report count: $e');
      // Don't fail the report submission if this fails
    }
  }

  /// Auto-flags content that exceeds report threshold
  Future<void> _autoFlagContent(ReportType type, String contentId) async {
    try {
      debugPrint('Auto-flagging content: $type $contentId');

      String collection;
      switch (type) {
        case ReportType.user:
          collection = 'users';
          // Consider temporary restrictions
          await _firestore.collection(collection).doc(contentId).update({
            'isFlagged': true,
            'flaggedAt': FieldValue.serverTimestamp(),
            'flagReason': 'Multiple reports received',
          });
          break;
        case ReportType.event:
          collection = 'events';
          await _firestore.collection(collection).doc(contentId).update({
            'isFlagged': true,
            'isVisible': false, // Hide from public
            'flaggedAt': FieldValue.serverTimestamp(),
          });
          break;
        case ReportType.message:
          collection = 'messages';
          await _firestore.collection(collection).doc(contentId).update({
            'isFlagged': true,
            'flaggedAt': FieldValue.serverTimestamp(),
          });
          break;
        case ReportType.photo:
          // Handle photo flagging
          break;
      }
    } catch (e) {
      debugPrint('Error auto-flagging content: $e');
    }
  }

  /// Gets reports submitted by the current user
  Future<List<Map<String, dynamic>>> getMyReports() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Must be logged in');
    }

    try {
      final snapshot = await _firestore
          .collection('reports')
          .where('reporterId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      debugPrint('Error getting reports: $e');
      return [];
    }
  }

  /// Checks if user has reported specific content
  Future<bool> hasReported(String reportedId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final snapshot = await _firestore
          .collection('reports')
          .where('reporterId', isEqualTo: user.uid)
          .where('reportedId', isEqualTo: reportedId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking report status: $e');
      return false;
    }
  }

  /// Checks if content is flagged
  Future<bool> isContentFlagged(ReportType type, String contentId) async {
    try {
      String collection;
      switch (type) {
        case ReportType.user:
          collection = 'users';
          break;
        case ReportType.event:
          collection = 'events';
          break;
        case ReportType.message:
          collection = 'messages';
          break;
        case ReportType.photo:
          return false; // Handle separately
      }

      final doc = await _firestore.collection(collection).doc(contentId).get();
      return doc.data()?['isFlagged'] == true;
    } catch (e) {
      debugPrint('Error checking flag status: $e');
      return false;
    }
  }

  /// Gets friendly string for report reason
  static String getReasonText(ReportReason reason) {
    switch (reason) {
      case ReportReason.inappropriateContent:
        return 'Inappropriate Content';
      case ReportReason.harassment:
        return 'Harassment or Bullying';
      case ReportReason.spam:
        return 'Spam';
      case ReportReason.impersonation:
        return 'Impersonation';
      case ReportReason.scam:
        return 'Scam or Fraud';
      case ReportReason.underage:
        return 'Underage User';
      case ReportReason.hateSpeech:
        return 'Hate Speech';
      case ReportReason.other:
        return 'Other';
    }
  }

  /// Gets description for report reason
  static String getReasonDescription(ReportReason reason) {
    switch (reason) {
      case ReportReason.inappropriateContent:
        return 'Explicit, violent, or otherwise inappropriate content';
      case ReportReason.harassment:
        return 'Bullying, threats, or harassment';
      case ReportReason.spam:
        return 'Unwanted advertisements or repetitive content';
      case ReportReason.impersonation:
        return 'Pretending to be someone else';
      case ReportReason.scam:
        return 'Fraudulent activity or phishing attempts';
      case ReportReason.underage:
        return 'User appears to be under 18 years old';
      case ReportReason.hateSpeech:
        return 'Discriminatory or hateful content';
      case ReportReason.other:
        return 'Another reason not listed';
    }
  }
}
