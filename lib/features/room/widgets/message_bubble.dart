import 'package:flutter/material.dart';

import '../../../models/message_model.dart';
import 'rich_text_toolbar.dart';

/// Live-room chat row styled like Paltalk – avatar on the left, then a column
/// containing a header row (username + timestamp) and the message body below.
/// All messages are left-aligned and full-width regardless of sender.
///
/// System messages (type == 'system') render as a centered italic separator row.
/// Announcement messages (type == 'announcement') render as a highlighted banner.
class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final String? senderLabel;
  /// VIP level for the sender. Level ≥1 shows a bronze/silver/gold name colour.
  final int senderVipLevel;
  /// Optional avatar URL for the sender's profile picture.
  final String? senderAvatarUrl;
  /// Called when the user taps the avatar or sender name. Receives the senderId.
  final void Function(String senderId)? onTapSender;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.senderLabel,
    this.senderVipLevel = 0,
    this.senderAvatarUrl,
    this.onTapSender,
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
    // --- System event row (join/leave/cam-on/off) ---
    if (message.type == 'system') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        child: Row(
          children: [
            Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.10), height: 1)),
            const SizedBox(width: 8),
            Text(
              message.content,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.10), height: 1)),
          ],
        ),
      );
    }

    // --- Announcement banner ---
    if (message.type == 'announcement') {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0x22BA9EFF),
          border: Border.all(color: const Color(0x55BA9EFF)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            const Icon(Icons.campaign_outlined, color: Color(0xFFBA9EFF), size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message.content,
                style: const TextStyle(
                  color: Color(0xFFECEDF6),
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      );
    }

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
          // Avatar — tappable to view profile
          GestureDetector(
            onTap: onTapSender != null ? () => onTapSender!(message.senderId) : null,
            child: CircleAvatar(
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
                      child: GestureDetector(
                        onTap: onTapSender != null ? () => onTapSender!(message.senderId) : null,
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
                // Message body — parse markup when tags present
                _buildMessageBody(message.content),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBody(String content) {
    const baseStyle = TextStyle(
      color: Color(0xEBFFFFFF),
      fontSize: 13,
      height: 1.4,
    );
    // Quick check: markup tags present?
    if (content.contains('[b]') ||
        content.contains('[i]') ||
        content.contains('[u]') ||
        content.contains('[s]') ||
        content.contains('[color=')) {
      return RichText(
        text: RichTextParser.parse(content, baseStyle: baseStyle),
      );
    }
    return Text(content, style: baseStyle);
  }
}

