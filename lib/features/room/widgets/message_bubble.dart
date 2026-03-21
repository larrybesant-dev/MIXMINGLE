import 'package:flutter/material.dart';
import '../../../models/message_model.dart';
import '../../../models/user_model.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final UserModel? user;
  const MessageBubble({super.key, required this.message, this.user});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundImage: user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null,
          child: user?.avatarUrl == null ? Text(user?.username.substring(0, 1).toUpperCase() ?? '?') : null,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(user?.username ?? message.senderId, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Text(
                    _formatTime(message.sentAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              Text(message.content),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    // Use intl package for formatting
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
