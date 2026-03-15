import '../models/message_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  Future<void> sendMessage(String roomId, Message message) async {
    final messagesRef = FirebaseFirestore.instance.collection('rooms').doc(roomId).collection('messages');
    await messagesRef.add(message.toMap());
  }

  Stream<List<Message>> streamMessages(String roomId) {
    final messagesRef = FirebaseFirestore.instance.collection('rooms').doc(roomId).collection('messages');
    return messagesRef.orderBy('createdAt').snapshots().map((snapshot) =>
      snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList());
  }
}
