// lib/features/control_center/services/audit_log_service.dart
//
// Writes immutable audit log entries to the `admin_actions` Firestore
// collection and streams them back for the Control Center UI.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// The set of action types recorded in the audit log.
enum ActionType {
  setRole('set_role'),
  banUser('ban_user'),
  unbanUser('unban_user'),
  kickUser('kick_user'),
  muteUser('mute_user'),
  endRoom('end_room'),
  resolveReport('resolve_report'),
  dismissReport('dismiss_report'),
  deleteContent('delete_content');

  const ActionType(this.value);
  final String value;

  static ActionType fromString(String? raw) {
    return ActionType.values.firstWhere(
      (e) => e.value == raw,
      orElse: () => ActionType.resolveReport,
    );
  }
}

/// Represents a single entry in the audit log.
class AuditLogEntry {
  final String id;
  final ActionType actionType;
  final String performedBy;
  final String targetId;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  const AuditLogEntry({
    required this.id,
    required this.actionType,
    required this.performedBy,
    required this.targetId,
    required this.metadata,
    required this.timestamp,
  });

  factory AuditLogEntry.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AuditLogEntry(
      id: doc.id,
      actionType: ActionType.fromString(d['actionType'] as String?),
      performedBy: d['performedBy'] as String? ?? '',
      targetId: d['targetId'] as String? ?? '',
      metadata: Map<String, dynamic>.from(d['metadata'] as Map? ?? {}),
      timestamp:
          (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Service for writing and reading admin audit log entries.
class AuditLogService {
  static final AuditLogService _instance = AuditLogService._internal();
  factory AuditLogService() => _instance;
  AuditLogService._internal();
  static AuditLogService get instance => _instance;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Write ──────────────────────────────────────────────────────────────────

  /// Logs an admin action to the `admin_actions` collection.
  Future<void> logAction({
    required ActionType actionType,
    required String targetId,
    Map<String, dynamic> metadata = const {},
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('admin_actions').add({
      'actionType': actionType.value,
      'performedBy': uid,
      'targetId': targetId,
      'metadata': metadata,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // ── Read ───────────────────────────────────────────────────────────────────

  /// Streams the most recent [limit] audit log entries, newest first.
  Stream<List<AuditLogEntry>> watchRecentActions({int limit = 50}) {
    return _db
        .collection('admin_actions')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map(AuditLogEntry.fromFirestore).toList());
  }
}
