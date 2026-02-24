
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/chat/event_chat_service.dart';
import '../models/chat_message.dart';

// Service provider
final eventChatServiceProvider = Provider<EventChatService>((ref) => EventChatService());

// Event chat messages provider
final eventChatProvider = StreamProvider.family<List<ChatMessage>, String>((ref, eventId) {
  final service = ref.watch(eventChatServiceProvider);
  return service.watchEventChat(eventId);
});

// Send message action provider
final sendEventMessageProvider = FutureProvider.family<void, ({
  String eventId,
  String message,
  String senderName,
  String? senderAvatarUrl,
  String? replyToId,
})>((ref, params) async {
  final service = ref.watch(eventChatServiceProvider);
  await service.sendMessage(
    eventId: params.eventId,
    message: params.message,
    senderName: params.senderName,
    senderAvatarUrl: params.senderAvatarUrl,
    replyToId: params.replyToId,
  );

  // Invalidate chat to refresh
  ref.invalidate(eventChatProvider(params.eventId));
});


