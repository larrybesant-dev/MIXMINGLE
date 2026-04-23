import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRepository {
  final FirebaseFirestore _db;
  ChatRepository(this._db);

  Stream<List<Map<String, dynamic>>> MessageModeltream(String roomId) {
    return _db
      .collection('rooms')
      .doc(roomId)
      .collection('MessageModel')
      .orderBy('timestamp', descending: false)
      .snapshots()
      .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  Future<void> sendMessageModel(String roomId, String userId, String text, {Map<String, dynamic>? metadata}) async {
    await _db
      .collection('rooms')
      .doc(roomId)
      .collection('MessageModel')
      .add({
        'userId': userId,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        if (metadata != null) ...metadata,
      });
  }
}
