import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/social_activity_model.dart';

class SocialActivityService {
  SocialActivityService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<SocialActivity>> watchUserActivities(
    String userId, {
    int limit = 6,
  }) {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      return Stream.value(const <SocialActivity>[]);
    }

    return _firestore
        .collection('activity_feed')
        .where('userId', isEqualTo: normalizedUserId)
        .limit(limit * 3)
        .snapshots()
        .map((snapshot) {
          final activities =
              snapshot.docs
                  .map((doc) => SocialActivity.fromJson(doc.id, doc.data()))
                  .toList(growable: false)
                ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return activities.take(limit).toList(growable: false);
        });
  }

  Future<void> logActivity({
    required String userId,
    required String type,
    String? targetId,
    Map<String, dynamic>? metadata,
  }) async {
    final normalizedUserId = userId.trim();
    final normalizedType = type.trim();
    if (normalizedUserId.isEmpty || normalizedType.isEmpty) {
      return;
    }

    await _firestore.collection('activity_feed').add({
      'userId': normalizedUserId,
      'type': normalizedType,
      'targetId': (targetId ?? '').trim().isEmpty ? null : targetId!.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'metadata': metadata ?? const <String, dynamic>{},
    });
  }
}
