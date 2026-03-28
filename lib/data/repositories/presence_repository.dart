import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/presence_model.dart';

abstract class PresenceRepository {
  Future<List<PresenceModel>> getPresence(String roomId);
  Future<void> setPresence(String roomId, PresenceModel presence);
}

class PresenceRepositoryImpl implements PresenceRepository {
  final FirebaseFirestore firestore;
  PresenceRepositoryImpl(this.firestore);

  @override
  Future<List<PresenceModel>> getPresence(String roomId) async {
    final snapshot = await firestore
        .collection('rooms')
        .doc(roomId)
        .collection('participants')
        .get();
    return snapshot.docs
        .map((doc) => PresenceModel.fromJson({
              'id': doc.id,
              ...doc.data(),
              'isOnline': true,
              'lastSeen': doc.data()['lastActiveAt'],
            }))
        .toList(growable: false);
  }

  @override
  Future<void> setPresence(String roomId, PresenceModel presence) async {
    final userId = presence.userId;
    if (userId == null || userId.isEmpty) {
      return;
    }

    await firestore
        .collection('rooms')
        .doc(roomId)
        .collection('participants')
        .doc(userId)
        .set({
      'userId': userId,
      'role': 'audience',
      'isMuted': false,
      'isBanned': false,
      'joinedAt': presence.lastSeen ?? FieldValue.serverTimestamp(),
      'lastActiveAt': presence.lastSeen ?? FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
