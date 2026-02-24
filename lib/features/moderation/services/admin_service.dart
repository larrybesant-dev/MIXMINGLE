import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetches all open reports
  ///
  /// Returns a list of report documents with status "open"
  Future<List<QueryDocumentSnapshot>> fetchOpenReports() async {
    final snapshot = await _firestore
        .collection('reports')
        .where('status', isEqualTo: 'open')
        .orderBy('timestamp', descending: true)
        .get();
    return snapshot.docs;
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
    await _firestore.collection('reports').doc(reportId).update({
      'status': status,
      'reviewedBy': reviewedBy,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
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
  }
}
