import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/messaging_provider.dart';
import '../../../services/web_popout_service.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String userId;
  final String username;
  final String? avatarUrl;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.userId,
    required this.username,
    this.avatarUrl,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  late TextEditingController _messageController;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Mark conversation as read
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(messagingControllerProvider).markAsRead(
            conversationId: widget.conversationId,
            userId: widget.userId,
          );
    });
  }

  void _onScroll() {
    // Load more when the user scrolls close to the top of the list.
    if (_scrollController.hasClients &&
        _scrollController.offset <=
            _scrollController.position.minScrollExtent + 120) {
      ref
          .read(paginatedMessagesProvider(widget.conversationId).notifier)
          .loadMore(null);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();

    await ref.read(messagingControllerProvider).sendMessage(
          conversationId: widget.conversationId,
          senderId: widget.userId,
          senderName: widget.username,
          senderAvatarUrl: widget.avatarUrl,
          content: content,
        );

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesStreamProvider(widget.conversationId));
    final paginatedState = ref.watch(paginatedMessagesProvider(widget.conversationId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        elevation: 0,
        actions: [
          if (kIsWeb)
            IconButton(
              icon: const Icon(Icons.open_in_new),
              tooltip: 'Pop out',
              onPressed: () => WebPopoutService().openWhisperWindow(
                widget.userId,
                widget.username,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (liveMessages) {
                // Merge: older pages on top, live stream at the bottom.
                final allMessages = [
                  ...paginatedState.olderMessages,
                  ...liveMessages,
                ];

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(
                      _scrollController.position.maxScrollExtent,
                    );
                  }
                });

                if (allMessages.isEmpty) {
                  return const Center(
                    child: Text('No messages yet. Start the conversation!'),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: allMessages.length +
                      (paginatedState.hasMore ? 1 : 0), // +1 for load-more row
                  itemBuilder: (context, index) {
                    // Load-more row at the very top.
                    if (index == 0 && paginatedState.hasMore) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: paginatedState.isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : TextButton(
                                  onPressed: () => ref
                                      .read(paginatedMessagesProvider(
                                              widget.conversationId)
                                          .notifier)
                                      .loadMore(null),
                                  child: const Text('Load older messages'),
                                ),
                        ),
                      );
                    }

                    final message =
                        allMessages[index - (paginatedState.hasMore ? 1 : 0)];
                    final isOwn = message.senderId == widget.userId;

                    if (message.isDeleted) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: Text(
                            'Message deleted',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey,
                                ),
                          ),
                        ),
                      );
                    }

                    return Align(
                      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment:
                            isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.75,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isOwn
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isOwn)
                                  Text(
                                    message.senderName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                if (!isOwn) const SizedBox(height: 4),
                                Text(
                                  message.content,
                                  style: TextStyle(
                                    color: isOwn ? Colors.white : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
                            child: Text(
                              _formatTime(message.createdAt),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Text('Error loading messages: $error'),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
    );

    if (messageDate == today) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }
}
