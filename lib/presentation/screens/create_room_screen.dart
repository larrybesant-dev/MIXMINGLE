import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateRoomScreen extends StatelessWidget {
  const CreateRoomScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Room')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Room Name'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              child: const Text('Create Room'),
              onPressed: () async {
                // Example Firestore room creation
                await FirebaseFirestore.instance.collection('rooms').add({
                  'name': 'Room Name',
                  'createdAt': DateTime.now(),
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
