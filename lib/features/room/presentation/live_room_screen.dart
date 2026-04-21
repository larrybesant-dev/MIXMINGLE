import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/room_live_state_provider.dart';

class LiveRoomScreen extends ConsumerWidget {
  final String roomId;

  const LiveRoomScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomStateAsync = ref.watch(roomLiveStateProvider(roomId));

    return roomStateAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
      data: (roomState) {
        return Scaffold(
          appBar: AppBar(
            title: Text(roomState.title.isEmpty ? 'Room' : roomState.title),
          ),
          body: Column(
            children: [
              Expanded(
                child: _MessageList(
                  messages: roomState.messages,
                ),
              ),
              _TypingIndicator(
                typingUsers: roomState.typingUsers.keys.toList(),
              ),
              _MessageInput(
                roomId: roomId,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MessageList extends StatelessWidget {
  final List messages;

  const _MessageList({required this.messages});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      reverse: true,
      itemCount: messages.length,
      itemBuilder: (_, i) {
        final msg = messages[i];
        return ListTile(
          title: Text(msg.content),
          subtitle: Text(msg.senderId),
        );
      },
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  final List<String> typingUsers;

  const _TypingIndicator({required this.typingUsers});

  @override
  Widget build(BuildContext context) {
    if (typingUsers.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        '${typingUsers.join(", ")} typing...',
        style: const TextStyle(fontStyle: FontStyle.italic),
      ),
    );
  }
}

class _MessageInput extends StatefulWidget {
  final String roomId;

  const _MessageInput({required this.roomId});

  @override
  State<_MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<_MessageInput> {
  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Send a message...',
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) return;

              // TODO: hook to your message service
              controller.clear();
            },
          ),
        ],
      ),
    );
  }
}