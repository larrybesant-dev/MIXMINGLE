import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/chat_service.dart';
import '../models/message_model.dart';

final messagesProvider = StreamProvider.family<List<Message>, String>((ref, roomId) {
  return ChatService().streamMessages(roomId);
});
