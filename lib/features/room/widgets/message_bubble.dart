import 'package:flutter/material.dart';

import '../../../models/message_model.dart';

/// Live-room chat bubble styled like TikTok/Bigo overlay messages.
/// My-own messages get a tinted purple-ish background; others get a
/// semi-transparent dark background so they sit cleanly over the camera feed.
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

    final Color bg = isMe
        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.72)
        : Colors.black.withValues(alpha: 0.54);

    final Color textColor = Colors.white;
    final Color nameColor = isMe
        ? Colors.white.withValues(alpha: 0.85)
        : Colors.white.withValues(alpha: 0.70);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 7),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$resolvedSenderLabel  ',
                    style: TextStyle(
                      color: nameColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  TextSpan(
                    text: message.content,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _formatClock(message.sentAt),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 10,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

