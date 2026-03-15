<<<<<<< HEAD
﻿import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
=======
// Speed Dating Service - DISABLED FOR V1 LAUNCH
// Re-enable in lib/_disabled/speed_dating/ after core features stabilize
>>>>>>> origin/develop

/// Real speed dating service connected to Firebase Cloud Functions
/// (speedDatingComplete.ts — production matchmaking system)
class SpeedDatingService {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

<<<<<<< HEAD
  SpeedDatingService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions =
            functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  // ── Queue ──────────────────────────────────────────────────────────────────

  /// Join the matchmaking queue with optional preferences.
  Future<void> joinQueue({Map<String, dynamic>? preferences}) async {
    await _functions.httpsCallable('joinSpeedDatingQueue').call({
      'preferences': preferences ?? {},
    });
  }

  /// Leave the matchmaking queue.
  Future<void> leaveQueue() async {
    await _functions.httpsCallable('leaveSpeedDatingQueue').call();
  }

  /// Stream the user's queue document.
  /// Emits the sessionId when [status] becomes "matched", otherwise null.
  Stream<String?> listenForMatch(String userId) {
    return _firestore
        .collection('speed_dating_queue')
        .doc(userId)
        .snapshots()
        .map((snap) {
      if (!snap.exists) return null;
      final data = snap.data()!;
      if (data['status'] == 'matched') return data['sessionId'] as String?;
      return null;
    });
  }

  /// Stream the full queue document for this user.
  Stream<Map<String, dynamic>?> listenToQueue(String userId) {
    return _firestore
        .collection('speed_dating_queue')
        .doc(userId)
        .snapshots()
        .map((snap) => snap.exists ? snap.data() : null);
  }

  // ── Session ────────────────────────────────────────────────────────────────

  /// Stream the session document for real-time UI updates.
  Stream<Map<String, dynamic>?> listenToSession(String sessionId) {
    return _firestore
        .collection('speed_dating_sessions')
        .doc(sessionId)
        .snapshots()
        .map((snap) => snap.exists ? snap.data() : null);
  }

  /// Generate an Agora RTC token for the given session.
  Future<Map<String, dynamic>> generateToken({
    required String sessionId,
    required int uid,
  }) async {
    final result = await _functions.httpsCallable('generateSpeedDatingToken').call({
      'sessionId': sessionId,
      'uid': uid,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  /// Submit a decision for the active session.
  /// [decision] must be "like" or "pass".
  Future<void> submitDecision({
    required String sessionId,
    required String decision,
  }) async {
    assert(
      decision == 'like' || decision == 'pass',
      'decision must be "like" or "pass"',
    );
    await _functions.httpsCallable('submitSpeedDatingDecision').call({
      'sessionId': sessionId,
      'decision': decision,
    });
  }

  /// Leave an active session early (marks it as cancelled).
  Future<void> leaveSession(String sessionId) async {
    await _functions.httpsCallable('leaveSpeedDatingSession').call({
      'sessionId': sessionId,
    });
  }
=======
  // Stub methods - Feature disabled for V1 launch
  Future<dynamic> getSpeedDatingRound(String roundId) async => null;
  Future<List<dynamic>> getActiveRoundsForEvent(String eventId) async => [];
  Future<List<dynamic>> getUserSpeedDatingResults(String userId) async => [];
  Future<List<String>> getMutualMatches(String userId) async => [];
  Future<String?> createSpeedDatingRound({
    required String eventId,
    required String name,
    required int duration,
    required List<String> participantIds,
  }) async =>
      null;
  Future<bool> joinSpeedDatingRound(String roundId, String userId) async =>
      false;
  Future<bool> leaveSpeedDatingRound(String roundId, String userId) async =>
      false;
  Future<bool> startSpeedDatingRound(String roundId) async => false;
  Future<bool> submitSpeedDatingResult({
    required String roundId,
    required String userId,
    required String matchedUserId,
    required bool userLiked,
    bool? matchedUserLiked,
  }) async =>
      false;
  Future<bool> advanceToNextRound(String roundId) async => false;
  Future<bool> endSpeedDatingRound(String roundId) async => false;
  Future<dynamic> findActiveSession(String eventId) async => null;
  Future<String?> createSession(Map<String, dynamic> sessionData) async => null;
  Future<dynamic> getSession(String sessionId) async => null;
  Future<bool> cancelSession(String sessionId) async => false;
  Future<bool> submitDecision(String roundId, String userId,
          String matchedUserId, bool liked) async =>
      false;
  Future<bool> startNextRound(String roundId) async => false;
  Future<bool> endSession(String roundId) async => false;

  // Additional stub methods for lobby/queue features
  Future<String?> joinQueue(String userId) async => null;
  Future<bool> leaveQueue(String sessionId, String userId) async => false;
  Stream<Map<String, dynamic>?> listenForMatch(
          String sessionId, String userId) =>
      Stream.value(null);
  Stream<Map<String, dynamic>?> listenToSessionStatus(String sessionId) =>
      Stream.value(null);
  Future<Map<String, dynamic>?> getUserInfo(String userId) async => null;
  Future<bool> leaveSession(String sessionId, String userId) async => false;
>>>>>>> origin/develop
}
