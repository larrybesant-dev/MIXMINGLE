import '../models/message_model.dart';




  Future<void> sendMessage(String roomId, String senderId, String content) async {
    // TODO: Implement sendMessage using Firebase/Firestore
  }

  Future<List<MessageModel>> fetchMessages(String roomId) async {
    // TODO: Implement fetchMessages using Firebase/Firestore
    return [];
  }

  Stream<List<MessageModel>> listenToMessages(String roomId) {
    // TODO: Implement real-time messaging with Firebase/Firestore
    return Stream.value([]);
  }
}
