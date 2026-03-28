import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/speed_dating_models.dart';

class SpeedDatingService {
  SpeedDatingService({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const Uuid _uuid = Uuid();

  Stream<List<SpeedDateCandidate>> candidatesStream({required String currentUserId}) {
    return _firestore.collection('users').limit(100).snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.id != currentUserId)
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
}
