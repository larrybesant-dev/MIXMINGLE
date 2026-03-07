import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_providers.dart';
import '../services/messaging_service.dart';

class ChatRoomPage extends ConsumerStatefulWidget {
  final String otherUserId;
  final String conversationId;

  const ChatRoomPage({
    super.key,
    required this.otherUserId,
    required this.conversationId,
  });

  @override
  ConsumerState<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends ConsumerState<ChatRoomPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _canSend = false;

  // Track the last seen message count so we only markAsRead when new
  // messages from the other user arrive.
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);

    // Mark as read on open.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markAsRead();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final canSend = _controller.text.trim().isNotEmpty;
    if (canSend != _canSend) {
      setState(() => _canSend = canSend);
    }
  }

  void _markAsRead() {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser != null) {
      ref
          .read(messagingServiceProvider)
          .markAsRead(widget.conversationId, currentUser.id);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    _controller.clear();

    try {
      await ref.read(messagingServiceProvider).sendMessage(
            conversationId: widget.conversationId,
            senderId: currentUser.id,
            text: text,
          );
      _scrollToBottom();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send message. Please try again.'),
          ),
        );
        // Restore draft so the user doesn't lose their text.
        _controller.text = text;
        _controller.selection =
            TextSelection.collapsed(offset: _controller.text.length);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).value;
    final messaging = ref.watch(messagingServiceProvider);

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: messaging.streamMessages(widget.conversationId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;

                // Auto-scroll and markAsRead when new messages arrive.
                if (messages.length != _lastMessageCount) {
                  _lastMessageCount = messages.length;
                  _scrollToBottom();

                  // Mark as read only if the latest message is from the other user.
                  if (messages.isNotEmpty &&
                      messages.last['senderId'] != currentUser.id) {
                    WidgetsBinding.instance.addPostFrameCallback(
                        (_) => _markAsRead());
                  }
                }

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet. Say hello!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['senderId'] == currentUser.id;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        constraints: BoxConstraints(
                          maxWidth:
                              MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Colors.blueAccent
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          msg['text'] ?? '',
                          softWrap: true,
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Input bar — sits above keyboard thanks to Scaffold resizeToAvoidBottomInset.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.grey.shade200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: null,
                    textInputAction: TextInputAction.newline,
                    keyboardType: TextInputType.multiline,
                    decoration: const InputDecoration(
                      hintText: 'Message...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _canSend ? _sendMessage : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
