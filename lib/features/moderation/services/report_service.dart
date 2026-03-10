import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/crashlytics/crashlytics_service.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AnalyticsService _analytics = AnalyticsService.instance;
  final CrashlyticsService _crashlytics = CrashlyticsService.instance;

  /// Submits a report to Firestore
  ///
  /// [reporterId] - The ID of the user submitting the report
  /// [reportedUserId] - The ID of the user being reported
  /// [reason] - The reason for the report
  /// [details] - Additional details about the report
  /// [roomId] - Optional room ID if the report is related to a specific room
  Future<void> submitReport({
    required String reporterId,
    required String reportedUserId,
    required String reason,
    required String details,
    String? roomId,
  }) async {
    try {
      await _firestore.collection('reports').add({
        'reporterId': reporterId,
        'reportedUserId': reportedUserId,
        'roomId': roomId,
        'reason': reason,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'open',
      });

      // Track analytics
      await _analytics.logReportSubmitted(
        reportedUserId: reportedUserId,
        reason: reason,
        roomId: roomId,
      );
    } catch (e, stackTrace) {
      await _crashlytics.logModerationFailure(
        action: 'submit_report',
        error: e.toString(),
        targetUserId: reportedUserId,
        roomId: roomId,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Streams all open reports
  Stream<QuerySnapshot> streamOpenReports() {
    return _firestore
        .collection('reports')
        .where('status', isEqualTo: 'open')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Updates the status of a report
  ///
  /// [reportId] - The ID of the report to update
  /// [status] - The new status (reviewed, dismissed, etc.)
  /// [reviewedBy] - The ID of the admin who reviewed the report
  Future<void> updateReportStatus({
    required String reportId,
    required String status,
    required String reviewedBy,
  }) async {
    try {
      await _firestore.collection('reports').doc(reportId).update({
        'status': status,
        'reviewedBy': reviewedBy,
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      // Track analytics
      await _analytics.logAdminReportReviewed(
        reportId: reportId,
        action: status,
      );
    } catch (e, stackTrace) {
      await _crashlytics.logModerationFailure(
        action: 'update_report_status',
        error: e.toString(),
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Bans a user
  ///
  /// [userId] - The ID of the user to ban
  /// [bannedBy] - The ID of the admin who banned the user
  /// [reason] - The reason for the ban
  Future<void> banUser({
    required String userId,
    required String bannedBy,
    required String reason,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isBanned': true,
        'bannedAt': FieldValue.serverTimestamp(),
        'bannedBy': bannedBy,
        'banReason': reason,
      });

      await _firestore.collection('banned_users').doc(userId).set({
        'userId': userId,
        'bannedAt': FieldValue.serverTimestamp(),
        'bannedBy': bannedBy,
        'reason': reason,
      });

      // Track analytics
      await _analytics.logAdminUserBanned(bannedUserId: userId);
    } catch (e, stackTrace) {
      await _crashlytics.logModerationFailure(
        action: 'ban_user',
        error: e.toString(),
        targetUserId: userId,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}


