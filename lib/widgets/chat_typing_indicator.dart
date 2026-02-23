// lib/widgets/chat_typing_indicator.dart

import 'package:flutter/material.dart';

class ChatTypingIndicator extends StatelessWidget {
  final String userId;

  const ChatTypingIndicator({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        children: [
          const SizedBox(width: 4),
          const Icon(Icons.more_horiz, color: Colors.white54, size: 18),
          const SizedBox(width: 4),
          Text('$userId is typing...', style: const TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }
}
