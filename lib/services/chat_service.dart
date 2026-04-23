import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mixvy/features/messaging/models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> sendMessageModel({
    required String roomId,
    required String senderId,
    required String content,
  }) async {
    await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('MessageModel')
        .add({
      'senderId': senderId,
      'roomId': roomId,
      'content': content,
      'sentAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<MessageModel>> fetchMessageModel(String roomId) async {
    final query = await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('MessageModel')
        .orderBy('sentAt', descending: false)
        .get();

    return query.docs.map((doc) {
      final data = doc.data();

      return MessageModel.fromJson({
        ...data,
        'id': doc.id,
        'sentAt': data['sentAt'] is Timestamp
            ? (data['sentAt'] as Timestamp).toDate()
            : DateTime.now(),
      });
    }).toList();
  }

  Stream<List<MessageModel>> listenToMessageModel(String roomId) {
    return _firestore
        .collection('rooms')
        .doc(roomId)
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();

        return MessageModel.fromJson({
          ...data,
          'id': doc.id,
          'sentAt': data['sentAt'] is Timestamp
              ? (data['sentAt'] as Timestamp).toDate()
              : DateTime.now(),
        });
      }).toList();
    });
  }
}
