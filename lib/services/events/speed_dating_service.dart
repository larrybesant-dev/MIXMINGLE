import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Real speed dating service connected to Firebase Cloud Functions
/// (speedDatingComplete.ts — production matchmaking system)
class SpeedDatingService {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

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
}


