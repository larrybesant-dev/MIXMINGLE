import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/presence_model.dart';

class PresenceRepository {
  final FirebaseFirestore _db;
  PresenceRepository(this._db);

  Stream<List<PresenceModel>> presenceStream(String roomId) {
    return _db
      .collection('rooms')
      .doc(roomId)
      .collection('participants')
      .snapshots()
      .map((snap) => snap.docs
        .map((d) => PresenceModel.fromJson({
          'id': d.id,
          ...d.data(),
          'isOnline': true,
          'lastSeen': d.data()['lastActiveAt'],
        }))
        .toList());
  }

  Future<void> setUserPresent(String roomId, String userId) async {
    await _db
      .collection('rooms')
      .doc(roomId)
      .collection('participants')
      .doc(userId)
      .set({
        'userId': userId,
        'role': 'audience',
        'isMuted': false,
        'isBanned': false,
        'joinedAt': FieldValue.serverTimestamp(),
        'lastActiveAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
  }

  Future<void> removeUser(String roomId, String userId) async {
    await _db
      .collection('rooms')
      .doc(roomId)
      .collection('participants')
      .doc(userId)
      .delete();
  }
}
