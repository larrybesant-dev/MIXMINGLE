import '../models/message_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  final supabase = Supabase.instance.client;

  Future<void> sendMessage(String roomId, String senderId, String content) async {
    await supabase.from('messages').insert({
      'room_id': roomId,
      'sender_id': senderId,
      'content': content,
      'sent_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<MessageModel>> fetchMessages(String roomId) async {
    final response = await supabase.from('messages').select().eq('room_id', roomId).order('sent_at');
    return (response as List).map((m) => MessageModel.fromJson(m)).toList();
  }

  Stream<List<MessageModel>> listenToMessages(String roomId) {
    // Placeholder: implement real-time messaging with Supabase Realtime
    return Stream.value([]);
  }
}
