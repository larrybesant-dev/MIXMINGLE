import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  final dynamic message;
  final bool isMe;

  const MessageBubble({Key? key, required this.message, required this.isMe}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue[200] : Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.toString(),
          style: const TextStyle(
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
