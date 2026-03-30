import 'package:flutter/material.dart';

import '../../../models/message_model.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final String? senderLabel;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.senderLabel,
  });

  String _formatClock(DateTime value) {
    final h = value.hour.toString().padLeft(2, '0');
    final m = value.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final resolvedSenderLabel = senderLabel?.trim().isNotEmpty == true
      ? senderLabel!.trim()
      : (isMe ? 'You' : message.senderId);
    final bubbleColor = isMe ? const Color(0xFF90CAF9) : const Color(0xFFE0E0E0);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        constraints: const BoxConstraints(maxWidth: 360),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              resolvedSenderLabel,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.content,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 18,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatClock(message.sentAt.toLocal()),
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
