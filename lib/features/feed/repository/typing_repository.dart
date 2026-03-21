import 'package:cloud_firestore/cloud_firestore.dart';

class TypingRepository {
  final FirebaseFirestore _db;
  TypingRepository(this._db);

  Stream<Map<String, bool>> typingStream(String roomId) {
    return _db
      .collection('rooms')
      .doc(roomId)
      .collection('typing')
      .snapshots()
      .map((snap) => {
        for (var doc in snap.docs)
          doc.id: (doc.data()['typing'] ?? false) as bool
      });
  }

  Future<void> setTyping(String roomId, String userId, bool typing) async {
    await _db
      .collection('rooms')
      .doc(roomId)
      .collection('typing')
      .doc(userId)
      .set({
        'typing': typing,
        'timestamp': FieldValue.serverTimestamp(),
      });
  }
}
