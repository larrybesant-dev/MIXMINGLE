
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';

DateTime _parseDateTime(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  return DateTime.now();
}

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> sendMessage(String roomId, String senderId, String content) async {
    await _firestore.collection('rooms').doc(roomId).collection('messages').add({
      'senderId': senderId,
      'roomId': roomId,
      'content': content,
      'sentAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<MessageModel>> fetchMessages(String roomId) async {
    final query = await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('sentAt', descending: false)
        .get();
    return query.docs
        .map((doc) => MessageModel.fromJson({
              ...doc.data(),
              'id': doc.id,
            'sentAt': _parseDateTime(doc.data()['sentAt']),
            }))
        .toList();
  }

  Stream<List<MessageModel>> listenToMessages(String roomId) {
    return _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromJson({
                  ...doc.data(),
                  'id': doc.id,
                  'sentAt': _parseDateTime(doc.data()['sentAt']),
                }))
            .toList());
  }
}
