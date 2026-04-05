import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:uuid/uuid.dart';

import '../../../services/moderation_service.dart';
import '../models/speed_dating_models.dart';

class SpeedDatingService {
  SpeedDatingService({
    FirebaseFirestore? firestore,
    ModerationService? moderationService,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _moderationService = moderationService ??
            ModerationService(
                firestore: firestore ?? FirebaseFirestore.instance),
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final ModerationService _moderationService;
  final FirebaseFunctions _functions;
  static const Uuid _uuid = Uuid();

  Stream<List<SpeedDateCandidate>> candidatesStream({required String currentUserId}) {
    // Query only users who have a non-empty username — avoids a full-collection
    // scan and filters out incomplete accounts server-side. Limit to 40 so the
    // Dart-side block filter still leaves a useful candidate set.
    return _firestore
        .collection('users')
        .where('username', isGreaterThan: '')
        .orderBy('username')
        .limit(40)
        .snapshots()
        .asyncMap((snapshot) async {
      final blockedIds = await _moderationService.getExcludedUserIds(currentUserId);
      return snapshot.docs
          .where((doc) => doc.id != currentUserId)
          .where((doc) => !blockedIds.contains(doc.id))
          .map(SpeedDateCandidate.fromDoc)
          .where((candidate) => candidate.username.trim().isNotEmpty)
          .toList();
    });
  }

  Stream<List<SpeedDatingMatch>> matchesStream(String currentUserId) {
    return _firestore
        .collection('speed_dating_matches')
        .where('participantIds', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(SpeedDatingMatch.fromDoc).toList());
  }

  Future<SpeedDateDecisionResult> submitDecision({
    required String fromUserId,
    required String toUserId,
    required bool liked,
    required int sessionSeconds,
  }) async {
    if (await _moderationService.hasBlockingRelationship(fromUserId, toUserId)) {
      throw Exception('Cannot interact with a blocked user.');
    }

    final actionId = '${fromUserId}_$toUserId';
    final reciprocalActionId = '${toUserId}_$fromUserId';

    await _firestore.collection('speed_dating_actions').doc(actionId).set({
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'decision': liked ? 'like' : 'pass',
      'sessionSeconds': sessionSeconds,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!liked) {
      return const SpeedDateDecisionResult(isMatch: false);
    }

    final reciprocalDoc = await _firestore.collection('speed_dating_actions').doc(reciprocalActionId).get();
    final reciprocalData = reciprocalDoc.data();
    final reciprocalLiked = reciprocalData != null && reciprocalData['decision'] == 'like';

    if (!reciprocalLiked) {
      return const SpeedDateDecisionResult(isMatch: false);
    }

    final sorted = [fromUserId, toUserId]..sort();
    final matchId = '${sorted.first}_${sorted.last}';

    await _firestore.collection('speed_dating_matches').doc(matchId).set({
      'participantIds': sorted,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastActionBy': fromUserId,
    }, SetOptions(merge: true));

    final notificationsRef = _firestore.collection('notifications');
    await notificationsRef.add({
      'userId': toUserId,
      'actorId': fromUserId,
      'type': 'speed_dating_match',
      'content': 'You have a new speed dating match.',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return SpeedDateDecisionResult(isMatch: true, matchId: matchId);
  }

  Future<String> startLiveDateRoom({
    required String hostUserId,
    required String targetUserId,
    required String matchId,
  }) async {
    final roomRef = _firestore.collection('rooms').doc();
    await roomRef.set({
      'name': 'Speed Date',
      'description': 'Private speed date session',
      'hostId': hostUserId,
      'isLive': true,
      'isLocked': true,
      'category': 'speed_dating',
      'memberCount': 2,
      'stageUserIds': [hostUserId, targetUserId],
      'audienceUserIds': <String>[],
      'coHosts': <String>[],
      'tags': ['speed_dating', 'private'],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('speed_dating_matches').doc(matchId).set({
      'latestRoomId': roomRef.id,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return roomRef.id;
  }

  String randomSessionId() => _uuid.v4();

  // ── Queue-based matchmaking (server-side) ────────────────────────────────

  /// Enters the server-side matchmaking queue via Cloud Function.
  /// Returns a [SpeedDatingQueueResult] indicating whether a partner was
  /// immediately found and the resulting session details.
  Future<SpeedDatingQueueResult> joinQueue() async {
    final result = await _functions
        .httpsCallable('joinSpeedDatingQueue')
        .call<Map<String, dynamic>>();
    final data = Map<String, dynamic>.from(result.data as Map);
    return SpeedDatingQueueResult(
      matched: data['matched'] as bool? ?? false,
      sessionId: data['sessionId'] as String?,
      partnerId: data['partnerId'] as String?,
    );
  }

  /// Removes the current user from the matchmaking queue.
  Future<void> leaveQueue() async {
    await _functions.httpsCallable('leaveSpeedDatingQueue').call();
  }

  /// Watches the live queue entry for the current user so the UI can react
  /// when the server matches them to a partner.
  Stream<SpeedDatingQueueResult?> watchQueueEntry(String userId) {
    return _firestore
        .collection('speed_dating_queue')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      final data = doc.data()!;
      return SpeedDatingQueueResult(
        matched: data['matched'] as bool? ?? false,
        sessionId: data['sessionId'] as String?,
        partnerId: null,
      );
    });
  }

  /// Watches a specific speed dating session doc (active + expiresAt).
  Stream<Map<String, dynamic>?> watchSession(String sessionId) {
    return _firestore
        .collection('speed_dating_sessions')
        .doc(sessionId)
        .snapshots()
        .map((doc) => doc.exists ? doc.data() : null);
  }
}
