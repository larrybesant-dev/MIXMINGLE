import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/message_provider.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Consumer(builder: (context, ref, _) {
        final messages = ref.watch(messageListProvider);
        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) => ListTile(
                  leading: CircleAvatar(child: Text(messages[index].senderId ?? 'U$index')),
                  title: Text(messages[index].content ?? 'Message $index'),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
