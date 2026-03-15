import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/chat_service.dart';
import '../../models/message_model.dart';

class _MessageInput extends ConsumerStatefulWidget {
  final String roomId;
  const _MessageInput({required this.roomId});

  @override
  ConsumerState<_MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends ConsumerState<_MessageInput> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
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
          onPressed: () async {
            final text = _controller.text.trim();
            if (text.isNotEmpty) {
              final message = Message(
                roomId: widget.roomId,
                senderId: 'currentUser', // Replace with actual user ID
                text: text,
                type: MessageType.text,
                createdAt: DateTime.now() as dynamic, // Firestore Timestamp conversion
              );
              await ChatService().sendMessage(widget.roomId, message);
              _controller.clear();
            }
          },
        ),
      ],
    );
  }
}
