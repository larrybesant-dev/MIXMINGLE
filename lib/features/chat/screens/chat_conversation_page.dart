/// Chat Conversation Page
/// Real-time messaging with another user
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/design_system/design_constants.dart';
import '../../../shared/widgets/club_background.dart';
import '../../../providers/auth_providers.dart';

/// Chat Conversation - Real-time messaging
class ChatConversationPage extends ConsumerStatefulWidget {
  final String chatId;

  const ChatConversationPage({
    super.key,
    required this.chatId,
  });

  @override
  ConsumerState<ChatConversationPage> createState() =>
      _ChatConversationPageState();
}

class _ChatConversationPageState extends ConsumerState<ChatConversationPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    try {
      // Clear input immediately
      _messageController.clear();

      // Add message to subcollection
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add({
        'senderId': user.id,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      // Update chat metadata
      final chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .get();

      if (chatDoc.exists) {
        final chatData = chatDoc.data()!;
        final participantIds =
            List<String>.from(chatData['participantIds'] ?? []);
        final otherUserId = participantIds.firstWhere(
          (id) => id != user.id,
          orElse: () => '',
        );

        // Update last message and unread count
        final currentUnreadCount =
            (chatData['unreadCount'] as Map<String, dynamic>?)?[otherUserId] ??
                0;

        await FirebaseFirestore.instance
            .collection('chats')
            .doc(widget.chatId)
            .update({
          'lastMessage': text,
          'lastMessageTimestamp': FieldValue.serverTimestamp(),
          'lastMessageSenderId': user.id,
          'unreadCount.$otherUserId': currentUnreadCount + 1,
        });
      }

      // Scroll to bottom
      _scrollToBottom();
    } catch (e) {
      debugPrint('❌ Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _markMessagesAsRead() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    try {
      // Reset unread count for current user
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({
        'unreadCount.${user.id}': 0,
      });

      // Mark all unread messages from other user as read
      final unreadMessages = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: user.id)
          .where('read', isEqualTo: false)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('❌ Error marking messages as read: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    // Mark messages as read when opening chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markMessagesAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in')),
      );
    }

    return ClubBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('chats')
                .doc(widget.chatId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Text('Chat');
              }

              final chatData = snapshot.data?.data() as Map<String, dynamic>?;
              if (chatData == null) {
                return const Text('Chat');
              }

              final participantIds =
                  List<String>.from(chatData['participantIds'] ?? []);
              final otherUserId = participantIds.firstWhere(
                (id) => id != user.id,
                orElse: () => '',
              );

              final participantNames =
                  Map<String, String>.from(chatData['participantNames'] ?? {});
              final otherUserName = participantNames[otherUserId] ?? 'Unknown';

              return Text(
                otherUserName,
                style: const TextStyle(
                  color: DesignColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.videocam),
              onPressed: () {
                // TODO: Start video call
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Video call coming soon!')),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Messages list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .doc(widget.chatId)
                    .collection('messages')
                    .orderBy('timestamp', descending: true)
                    .limit(50)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data?.docs ?? [];

                  if (messages.isEmpty) {
                    return Center(
                      child: Text(
                        'No messages yet.\nSay hello! 👋',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: DesignColors.white.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final messageDoc = messages[index];
                      final messageData =
                          messageDoc.data() as Map<String, dynamic>;

                      final senderId = messageData['senderId'] as String;
                      final text = messageData['text'] as String;
                      final timestamp =
                          (messageData['timestamp'] as Timestamp?)?.toDate();

                      final isMe = senderId == user.id;

                      return _buildMessageBubble(
                        text: text,
                        timestamp: timestamp,
                        isMe: isMe,
                      );
                    },
                  );
                },
              ),
            ),

            // Message input
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DesignColors.background,
                border: Border(
                  top: BorderSide(
                    color: DesignColors.accent.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(color: DesignColors.white),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(
                            color: DesignColors.white.withOpacity(0.5),
                          ),
                          filled: true,
                          fillColor: DesignColors.accent.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: DesignColors.accent.withOpacity(0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: DesignColors.accent.withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: DesignColors.accent,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send),
                      color: DesignColors.accent,
                      iconSize: 28,
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble({
    required String text,
    required DateTime? timestamp,
    required bool isMe,
  }) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? DesignColors.accent.withOpacity(0.8)
              : DesignColors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isMe
                ? DesignColors.accent
                : DesignColors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: const TextStyle(
                color: DesignColors.white,
                fontSize: 15,
              ),
            ),
            if (timestamp != null) ...[
              const SizedBox(height: 4),
              Text(
                timeago.format(timestamp),
                style: TextStyle(
                  color: DesignColors.white.withOpacity(0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
