import 'package:cloud_firestore/cloud_firestore.dart';
// Removed unused imports
import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance.collection('rooms').doc('roomId').collection('messages').orderBy('timestamp').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = (snapshot.data as QuerySnapshot).docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) => ListTile(
                    leading: CircleAvatar(child: Text(docs[index]['sender'] ?? '?')),
                    title: Text(docs[index]['text'] ?? ''),
                    subtitle: Text(docs[index]['timestamp']?.toString() ?? ''),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(hintText: 'Type a message...'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    // Example send logic
                    // Add message to Firestore
                    FirebaseFirestore.instance
                        .collection('rooms')
                        .doc('roomId')
                        .collection('messages')
                        .add({
                      'sender': 'user',
                      'text': 'Hello!',
                      'timestamp': DateTime.now(),
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
