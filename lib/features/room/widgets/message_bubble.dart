import 'package:flutter/material.dart';

import '../../../models/message_model.dart';

/// Live-room chat row styled like Paltalk – avatar on the left, then a column
/// containing a header row (username + timestamp) and the message body below.
/// All messages are left-aligned and full-width regardless of sender.
class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final String? senderLabel;
  /// VIP level for the sender. Level ≥1 shows a bronze/silver/gold name colour.
  final int senderVipLevel;
  /// Optional avatar URL for the sender's profile picture.
  final String? senderAvatarUrl;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.senderLabel,
    this.senderVipLevel = 0,
    this.senderAvatarUrl,
  });

  String _formatClock(DateTime value) {
    final h = value.hour.toString().padLeft(2, '0');
    final m = value.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Color _vipColor(int level) {
    if (level >= 5) return const Color(0xFFFFD700); // gold
    if (level >= 3) return const Color(0xFFC0C0C0); // silver
    if (level >= 1) return const Color(0xFFCD7F32); // bronze
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    final resolvedSenderLabel = senderLabel?.trim().isNotEmpty == true
        ? senderLabel!.trim()
        : (isMe ? 'You' : message.senderId);

    final vipC = _vipColor(senderVipLevel);
    final Color nameColor = (senderVipLevel > 0 && vipC != Colors.transparent)
        ? vipC
        : (isMe
            ? const Color(0xFF9B8FFF) // soft purple for own messages
            : Colors.white.withValues(alpha: 0.90));

    // Subtle left-border tint for own messages, none for others.
    final Color? rowTint = isMe
        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.10)
        : null;

    return Container(
      color: rowTint,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey.shade800,
            backgroundImage: (senderAvatarUrl != null &&
                    senderAvatarUrl!.isNotEmpty)
                ? NetworkImage(senderAvatarUrl!)
                : null,
            child: (senderAvatarUrl == null || senderAvatarUrl!.isEmpty)
                ? Text(
                    resolvedSenderLabel.isNotEmpty
                        ? resolvedSenderLabel[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          // Content column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header: username + timestamp
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        resolvedSenderLabel,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: nameColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatClock(message.sentAt),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 10,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
                // Message body
                Text(
                  message.content,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

