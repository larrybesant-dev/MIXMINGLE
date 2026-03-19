import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Display Name'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () async {
                // Example Firestore profile update
                await FirebaseFirestore.instance.collection('users').doc('userId').update({
                  'displayName': 'Display Name',
                  'updatedAt': DateTime.now(),
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
