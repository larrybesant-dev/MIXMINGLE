// lib/features/match_inbox/services/match_inbox_service.dart
//
// MatchInboxService — full Firestore-backed match inbox.
//
// Firestore layout:
//   /users/{uid}/matches/{matchId}    — per-user match entries (bidirectional)
//   /users/{uid}/notifications/{id}   — in-app notification for new match
//
// Key operations:
//   createMatch(userA, userB, source, metadata)  — writes to both users' inboxes
//   markMatchAsSeen(uid, matchId)                — flips isNew → false
//   removeMatch(uid, matchId)                    — deletes from one user's inbox
//   streamUserMatches(uid)                       — real-time match list
// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/match_inbox_item.dart';
import '../../../shared/models/app_notification.dart';
import '../../../services/analytics/analytics_service.dart';

class MatchInboxService {
  MatchInboxService._();
  static final MatchInboxService instance = MatchInboxService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? '';

  // ── Collection helpers ────────────────────────────────────────────────────

  CollectionReference _matchesCol(String uid) =>
      _db.collection('users').doc(uid).collection('matches');

  CollectionReference _notifCol(String uid) =>
      _db.collection('users').doc(uid).collection('notifications');

  // ── createMatch ───────────────────────────────────────────────────────────

  /// Creates a match entry in both users' inboxes atomically.
  /// No-ops if a match already exists between the same two users.
  Future<void> createMatch(
    String userAId,
    String userBId, {
    MatchSource source = MatchSource.discovery,
    Map<String, dynamic> metadata = const {},
    String? userAName,
    String? userAAvatarUrl,
    String? userBName,
    String? userBAvatarUrl,
  }) async {
    if (userAId.isEmpty || userBId.isEmpty || userAId == userBId) {
      debugPrint('[MatchInboxService] createMatch: invalid user IDs');
      return;
    }

    // De-duplicate guard: check if match already exists
    final existing = await _matchesCol(userAId)
        .where('matchedUserId', isEqualTo: userBId)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      debugPrint('[MatchInboxService] Match already exists between $userAId and $userBId');
      return;
    }

    final now = FieldValue.serverTimestamp();
    final batch = _db.batch();

    // Entry in userA's inbox
    final refA = _matchesCol(userAId).doc();
    batch.set(refA, {
      'matchedUserId': userBId,
      'timestamp': now,
      'lastInteraction': null,
      'isNew': true,
      'source': source.name,
      'metadata': {
        ...metadata,
        if (userBName != null) 'matchedUserName': userBName,
        if (userBAvatarUrl != null) 'matchedUserAvatar': userBAvatarUrl,
      },
    });

    // Entry in userB's inbox
    final refB = _matchesCol(userBId).doc();
    batch.set(refB, {
      'matchedUserId': userAId,
      'timestamp': now,
      'lastInteraction': null,
      'isNew': true,
      'source': source.name,
      'metadata': {
        ...metadata,
        if (userAName != null) 'matchedUserName': userAName,
        if (userAAvatarUrl != null) 'matchedUserAvatar': userAAvatarUrl,
      },
    });

    // In-app notification for userA
    final notifA = _notifCol(userAId).doc();
    batch.set(notifA, {
      'type': AppNotificationType.speedDatingMatch.name,
      'receiverId': userAId,
      'senderId': userBId,
      'senderName': userBName,
      'senderAvatarUrl': userBAvatarUrl,
      'body': userBName != null
          ? "You matched with $userBName! 🎉"
          : "You have a new match! 🎉",
      'metadata': {'matchId': refA.id, 'source': source.name},
      'isRead': false,
      'timestamp': now,
    });

    // In-app notification for userB
    final notifB = _notifCol(userBId).doc();
    batch.set(notifB, {
      'type': AppNotificationType.speedDatingMatch.name,
      'receiverId': userBId,
      'senderId': userAId,
      'senderName': userAName,
      'senderAvatarUrl': userAAvatarUrl,
      'body': userAName != null
          ? "You matched with $userAName! 🎉"
          : "You have a new match! 🎉",
      'metadata': {'matchId': refB.id, 'source': source.name},
      'isRead': false,
      'timestamp': now,
    });

    await batch.commit();

    // Analytics: track match event (non-blocking)
    AnalyticsService().logEvent('match_created', parameters: {
      'source': source.name,
    });

    debugPrint('[MatchInboxService] \u2705 Match created: $userAId \u2194 $userBId '
        '(source: ${source.name})');
  }

  // ── markMatchAsSeen ───────────────────────────────────────────────────────

  /// Marks a match as seen (isNew → false) for the current user.
  Future<void> markMatchAsSeen(String matchId) async {
    if (_uid.isEmpty || matchId.isEmpty) return;
    try {
      await _matchesCol(_uid).doc(matchId).update({'isNew': false});
      debugPrint('[MatchInboxService] Marked $matchId as seen for $_uid');
    } catch (e) {
      debugPrint('[MatchInboxService] markMatchAsSeen error: $e');
    }
  }

  /// Marks all new matches as seen for the current user.
  Future<void> markAllMatchesSeen() async {
    if (_uid.isEmpty) return;
    try {
      final newMatches = await _matchesCol(_uid)
          .where('isNew', isEqualTo: true)
          .get();
      final batch = _db.batch();
      for (final doc in newMatches.docs) {
        batch.update(doc.reference, {'isNew': false});
      }
      await batch.commit();
      debugPrint(
          '[MatchInboxService] Marked ${newMatches.docs.length} matches as seen');
    } catch (e) {
      debugPrint('[MatchInboxService] markAllMatchesSeen error: $e');
    }
  }

  // ── removeMatch ───────────────────────────────────────────────────────────

  /// Removes a match from the current user's inbox (soft delete — only removes
  /// from the current user, not from the other user's inbox).
  Future<void> removeMatch(String matchId) async {
    if (_uid.isEmpty || matchId.isEmpty) return;
    try {
      await _matchesCol(_uid).doc(matchId).delete();
      debugPrint('[MatchInboxService] Removed match $matchId for $_uid');
    } catch (e) {
      debugPrint('[MatchInboxService] removeMatch error: $e');
    }
  }

  // ── streamUserMatches ─────────────────────────────────────────────────────

  /// Real-time stream of the current user's matches, ordered by timestamp desc.
  Stream<List<MatchInboxItem>> streamUserMatches() {
    if (_uid.isEmpty) return const Stream.empty();
    return _matchesCol(_uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) =>
                MatchInboxItem.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  /// Stream for a specific user ID (used by providers).
  Stream<List<MatchInboxItem>> streamMatchesForUser(String uid) {
    if (uid.isEmpty) return const Stream.empty();
    return _matchesCol(uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) =>
                MatchInboxItem.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  // ── updateLastInteraction ─────────────────────────────────────────────────

  /// Call this whenever a user sends/receives a message with a match.
  /// Keeps `lastInteraction` fresh for sorting/display.
  Future<void> updateLastInteraction(
      String currentUserId, String matchedUserId) async {
    try {
      final snap = await _matchesCol(currentUserId)
          .where('matchedUserId', isEqualTo: matchedUserId)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        await snap.docs.first.reference.update({
          'lastInteraction': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('[MatchInboxService] updateLastInteraction error: $e');
    }
  }
}
