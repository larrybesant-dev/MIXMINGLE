import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../models/chat_room.dart';
import '../../services/chat/chat_service.dart';

// Chat service provider
final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService();
});

// Chat rooms provider (real-time stream)
final chatRoomsProvider = StreamProvider<List<ChatRoom>>((ref) {
  final chatService = ref.watch(chatServiceProvider);
  return chatService.streamUserChatRooms();
});

// Chat actions provider (for methods that modify data)
final chatActionsProvider = Provider<ChatActions>((ref) {
  return ChatActions(ref.watch(chatServiceProvider));
});

// Messages provider for a specific room
final messagesProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, roomId) {
  final chatService = ref.watch(chatServiceProvider);
  return chatService.streamMessages(roomId);
});

// Typing status provider for a specific room
final typingStatusProvider = StreamProvider.family<bool, String>((ref, roomId) {
  final chatService = ref.watch(chatServiceProvider);
  return chatService.streamTypingStatus(roomId);
});

// Current chat room provider
final currentChatRoomProvider = NotifierProvider<ChatRoomNotifier, ChatRoom?>(
  () => ChatRoomNotifier(),
);

class ChatRoomNotifier extends Notifier<ChatRoom?> {
  @override
  ChatRoom? build() => null;

  void setChatRoom(ChatRoom? room) {
    state = room;
  }
}

// Chat actions class for performing operations
class ChatActions {
  final ChatService _chatService;

  ChatActions(this._chatService);

  Future<void> sendMessage(String roomId, String content,
      {String? imageUrl}) async {
    try {
      await _chatService.sendMessage(roomId, content, imageUrl: imageUrl);
    } catch (e) {
      debugPrint('Failed to send message: $e');
      rethrow;
    }
  }

  Future<void> markMessagesAsRead(String roomId) async {
    try {
      await _chatService.markMessagesAsRead(roomId);
    } catch (e) {
      debugPrint('Failed to mark messages as read: $e');
    }
  }

  Future<void> updateTypingStatus(String roomId, bool isTyping) async {
    try {
      await _chatService.updateTypingStatus(roomId, isTyping);
    } catch (e) {
      debugPrint('Failed to update typing status: $e');
    }
  }

  Future<void> deleteMessage(String roomId, String messageId) async {
    try {
      await _chatService.deleteMessage(roomId, messageId);
    } catch (e) {
      debugPrint('Failed to delete message: $e');
      rethrow;
    }
  }

  Future<void> reportMessage(
      String roomId, String messageId, String reason) async {
    try {
      await _chatService.reportMessage(roomId, messageId, reason);
    } catch (e) {
      debugPrint('Failed to report message: $e');
      rethrow;
    }
  }

  Future<ChatRoom> getOrCreateChatRoom(String otherUserId) async {
    return await _chatService.getOrCreateChatRoom(otherUserId);
  }
}
