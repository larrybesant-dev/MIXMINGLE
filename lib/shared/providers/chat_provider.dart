// Chat Messages Provider - Manages chat messages for rooms and direct messages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';

/// Mock messages generator
List<ChatMessage> _generateMockMessages() {
  return [
    ChatMessage(
      id: 'msg1',
      senderId: 'user1',
      senderName: 'Alex Johnson',
      senderAvatarUrl: 'https://i.pravatar.cc/150?u=alex',
      content: 'Hey everyone! Ready for the meeting?',
      timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      contentType: MessageContentType.text,
    ),
    ChatMessage(
      id: 'msg2',
      senderId: 'user2',
      senderName: 'Sarah Chen',
      senderAvatarUrl: 'https://i.pravatar.cc/150?u=sarah',
      content: 'Yes! Just joined the call ðŸ‘‹',
      timestamp: DateTime.now().subtract(const Duration(minutes: 9)),
      contentType: MessageContentType.text,
    ),
    ChatMessage(
      id: 'msg3',
      senderId: 'user1',
      senderName: 'Alex Johnson',
      senderAvatarUrl: 'https://i.pravatar.cc/150?u=alex',
      content: 'ðŸ˜„',
      timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
      contentType: MessageContentType.text,
    ),
    ChatMessage(
      id: 'msg4',
      senderId: 'user3',
      senderName: 'Jordan Taylor',
      senderAvatarUrl: 'https://i.pravatar.cc/150?u=jordan',
      content: 'Great project updates from the team!',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      contentType: MessageContentType.text,
    ),
    ChatMessage(
      id: 'msg5',
      senderId: 'user2',
      senderName: 'Sarah Chen',
      senderAvatarUrl: 'https://i.pravatar.cc/150?u=sarah',
      content: 'presentation.pdf',
      timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
      contentType: MessageContentType.file,
    ),
  ];
}

/// Chat messages notifier
class ChatMessagesNotifier extends Notifier<List<ChatMessage>> {
  @override
  List<ChatMessage> build() {
    return _generateMockMessages();
  }

  /// Add new message
  void addMessage(ChatMessage message) {
    state = [...state, message];
  }

  /// Send text message
  void sendMessage({
    required String senderId,
    required String senderName,
    required String senderAvatarUrl,
    required String content,
  }) {
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: senderId,
      senderName: senderName,
      senderAvatarUrl: senderAvatarUrl,
      content: content,
      timestamp: DateTime.now(),
      contentType: MessageContentType.text,
    );
    addMessage(message);
  }

  /// Send file
  void sendFile({
    required String senderId,
    required String senderName,
    required String senderAvatarUrl,
    required String fileName,
    required String fileUrl,
    required int fileSize,
  }) {
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: senderId,
      senderName: senderName,
      senderAvatarUrl: senderAvatarUrl,
      content: fileName,
      timestamp: DateTime.now(),
      contentType: MessageContentType.file,
    );
    addMessage(message);
  }

  /// Clear messages (when leaving room)
  void clearMessages() {
    state = [];
  }
}

/// Chat messages provider
final chatMessagesProvider =
    NotifierProvider<ChatMessagesNotifier, List<ChatMessage>>(
  () => ChatMessagesNotifier(),
);

/// Last message in chat
final lastMessageProvider = Provider<ChatMessage?>((ref) {
  final messages = ref.watch(chatMessagesProvider);
  return messages.isNotEmpty ? messages.last : null;
});

/// Messages grouped by sender
final messagesByUserProvider = Provider<Map<String, List<ChatMessage>>>((ref) {
  final messages = ref.watch(chatMessagesProvider);
  final grouped = <String, List<ChatMessage>>{};

  for (var message in messages) {
    if (!grouped.containsKey(message.senderId)) {
      grouped[message.senderId] = [];
    }
    grouped[message.senderId]!.add(message);
  }

  return grouped;
});
