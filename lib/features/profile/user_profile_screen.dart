import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileScreen extends StatelessWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User Profile: $userId')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('User not found.'));
          }
          final data = snapshot.data!.data() as Map<String, dynamic>;
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['username'] ?? 'User', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text('Email: ${data['email'] ?? ''}'),
                if (data['bio'] != null) ...[
                  const SizedBox(height: 8),
                  Text(data['bio']),
                ],
                const SizedBox(height: 16),
                Text('Joined: ${data['createdAt'] ?? ''}'),
                // Add more user fields as needed
              ],
            ),
          );
        },
      ),
    );
  }
}
