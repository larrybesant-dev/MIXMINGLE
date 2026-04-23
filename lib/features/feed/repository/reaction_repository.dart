import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/reaction_model.dart';

class ReactionRepository {
  final FirebaseFirestore _db;
  ReactionRepository(this._db);

  Stream<List<ReactionModel>> reactionsStream(String roomId, String MessageModelId) {
    return _db
      .collection('rooms')
      .doc(roomId)
      .collection('MessageModel')
      .doc(MessageModelId)
      .collection('reactions')
      .snapshots()
      .map((snap) => snap.docs.map((d) => ReactionModel.fromJson(d.data())).toList());
  }

  Future<void> setReaction(String roomId, String MessageModelId, String userId, String emoji) async {
    await _db
      .collection('rooms')
      .doc(roomId)
      .collection('MessageModel')
      .doc(MessageModelId)
      .collection('reactions')
      .doc(userId)
      .set({
        'userId': userId,
        'emoji': emoji,
        'timestamp': FieldValue.serverTimestamp(),
      });
  }

  Future<void> removeReaction(String roomId, String MessageModelId, String userId) async {
    await _db
      .collection('rooms')
      .doc(roomId)
      .collection('MessageModel')
      .doc(MessageModelId)
      .collection('reactions')
      .doc(userId)
      .delete();
  }
}
