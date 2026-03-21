import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/presence_model.dart';

class PresenceRepository {
  final FirebaseFirestore _db;
  PresenceRepository(this._db);

  Stream<List<PresenceModel>> presenceStream(String roomId) {
    return _db
      .collection('rooms')
      .doc(roomId)
      .collection('presence')
      .snapshots()
      .map((snap) => snap.docs
        .map((d) => PresenceModel.fromJson(d.data()))
        .toList());
  }

  Future<void> setUserPresent(String roomId, String userId) async {
    await _db
      .collection('rooms')
      .doc(roomId)
      .collection('presence')
      .doc(userId)
      .set({
        'userId': userId,
        'lastActive': FieldValue.serverTimestamp(),
      });
  }

  Future<void> removeUser(String roomId, String userId) async {
    await _db
      .collection('rooms')
      .doc(roomId)
      .collection('presence')
      .doc(userId)
      .delete();
  }
}
