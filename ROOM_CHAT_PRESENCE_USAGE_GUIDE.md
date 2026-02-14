/// ROOM CHAT & PRESENCE PROVIDERS - USAGE EXAMPLES
///
/// This file demonstrates how to use the new chat and presence providers
/// in a Flutter widget with proper lifecycle management.
///
/// DO NOT EDIT - This is a reference guide only.

// EXAMPLE 1: Displaying Room Messages with Pagination
/*
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mix_and_mingle/providers/room_chat_presence_providers.dart';

class RoomChatWidget extends ConsumerStatefulWidget {
  final String roomId;

  const RoomChatWidget({required this.roomId});

  @override
  ConsumerState<RoomChatWidget> createState() => _RoomChatWidgetState();
}

class _RoomChatWidgetState extends ConsumerState<RoomChatWidget> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // Load previous messages when scrolling to top
    if (_scrollController.position.pixels == _scrollController.position.minScrollExtent) {
      ref.read(roomMessagesProvider(widget.roomId).notifier).loadPreviousMessages();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesState = ref.watch(roomMessagesProvider(widget.roomId));

    return Column(
      children: [
        // Messages list
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            reverse: true, // Newest messages at bottom
            itemCount: messagesState.messages.length + (messagesState.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == messagesState.messages.length) {
                // Load more indicator
                return messagesState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : const SizedBox.shrink();
              }

              final message = messagesState.messages[index];
              return ListTile(
                title: Text(message.senderName),
                subtitle: Text(message.text),
                trailing: Text(
                  message.createdAt.toString(),
                  style: const TextStyle(fontSize: 12),
                ),
              );
            },
          ),
        ),
        // Message input
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: RoomMessageInput(roomId: widget.roomId),
        ),
      ],
    );
  }
}

class RoomMessageInput extends ConsumerWidget {
  final String roomId;
  final _controller = TextEditingController();

  RoomMessageInput({required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesNotifier = ref.read(roomMessagesProvider(roomId).notifier);

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: const InputDecoration(hintText: 'Type a message...'),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.send),
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              messagesNotifier.sendMessage(_controller.text, 'Your Name');
              _controller.clear();
            }
          },
        ),
      ],
    );
  }
}
*/

// EXAMPLE 2: Displaying Room Presence
/*
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mix_and_mingle/providers/room_chat_presence_providers.dart';

class RoomPresenceWidget extends ConsumerWidget {
  final String roomId;

  const RoomPresenceWidget({required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(roomMembersProvider(roomId));

    return membersAsync.when(
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
      data: (members) {
        // Filter online members
        final onlineMembers = members.where((m) => m.online).toList();

        return Column(
          children: [
            Text('Online: ${onlineMembers.length}/${members.length}'),
            Expanded(
              child: ListView.builder(
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: member.online ? Colors.green : Colors.grey,
                      child: Text(member.displayName[0]),
                    ),
                    title: Text(member.displayName),
                    subtitle: Text(member.platform),
                    trailing: member.typing ? const Text('typing...') : null,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
*/

// EXAMPLE 3: Managing User Presence (Online/Offline/Typing)
/*
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mix_and_mingle/providers/room_chat_presence_providers.dart';

class PresenceManagementWidget extends ConsumerStatefulWidget {
  final String roomId;

  const PresenceManagementWidget({required this.roomId});

  @override
  ConsumerState<PresenceManagementWidget> createState() => _PresenceManagementWidgetState();
}

class _PresenceManagementWidgetState extends ConsumerState<PresenceManagementWidget> {
  @override
  void initState() {
    super.initState();
    // Mark user as online when entering room
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(localUserPresenceProvider(widget.roomId).notifier).setOnline();
    });
  }

  @override
  void dispose() {
    // Mark user as offline when leaving room
    ref.read(localUserPresenceProvider(widget.roomId).notifier).setOffline();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final presenceState = ref.watch(localUserPresenceProvider(widget.roomId));

    return Column(
      children: [
        Text('Online: ${presenceState.online}'),
        Text('Typing: ${presenceState.typing}'),
        ElevatedButton(
          onPressed: presenceState.typing
              ? () => ref
                  .read(localUserPresenceProvider(widget.roomId).notifier)
                  .setTyping(false)
              : () => ref
                  .read(localUserPresenceProvider(widget.roomId).notifier)
                  .setTyping(true),
          child: Text(presenceState.typing ? 'Stop Typing' : 'Start Typing'),
        ),
      ],
    );
  }
}
*/

// EXAMPLE 4: Full Room Chat Screen (Complete Integration)
/*
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mix_and_mingle/providers/room_chat_presence_providers.dart';

class RoomChatPage extends ConsumerStatefulWidget {
  final String roomId;
  final String roomName;

  const RoomChatPage({
    required this.roomId,
    required this.roomName,
  });

  @override
  ConsumerState<RoomChatPage> createState() => _RoomChatPageState();
}

class _RoomChatPageState extends ConsumerState<RoomChatPage> {
  late TextEditingController _messageController;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _scrollController = ScrollController();

    // Mark user as online when entering the room
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(localUserPresenceProvider(widget.roomId).notifier).setOnline();
    });
  }

  @override
  void dispose() {
    // Mark user as offline when leaving the room
    ref.read(localUserPresenceProvider(widget.roomId).notifier).setOffline();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    ref
        .read(roomMessagesProvider(widget.roomId).notifier)
        .sendMessage(_messageController.text, 'Current User Name');

    _messageController.clear();

    // Update lastSeen timestamp
    ref
        .read(localUserPresenceProvider(widget.roomId).notifier)
        .updateLastSeen();
  }

  void _onMessageTyping(String text) {
    // Mark as typing while user is editing
    if (text.isNotEmpty) {
      ref.read(localUserPresenceProvider(widget.roomId).notifier).setTyping(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesState = ref.watch(roomMessagesProvider(widget.roomId));
    final membersAsync = ref.watch(roomMembersProvider(widget.roomId));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roomName),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Room info and member count
          Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.all(12),
            child: membersAsync.when(
              data: (members) {
                final onlineCount = members.where((m) => m.online).length;
                return Text('$onlineCount online');
              },
              loading: () => const CircularProgressIndicator(),
              error: (error, _) => Text('Error: $error'),
            ),
          ),

          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true,
              itemCount: messagesState.messages.length +
                  (messagesState.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messagesState.messages.length) {
                  return messagesState.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : const SizedBox.shrink();
                }

                final message = messagesState.messages[index];
                return MessageBubble(message: message);
              },
            ),
          ),

          // Message input
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onChanged: _onMessageTyping,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed: _sendMessage,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final RoomMessage message;

  const MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.senderName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              Text(message.text),
              Text(
                message.createdAt.toString().substring(11, 16),
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
*/
