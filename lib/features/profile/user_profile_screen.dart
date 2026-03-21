import 'package:flutter/material.dart';

class UserProfileScreen extends StatelessWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with real user profile logic
    return Scaffold(
      appBar: AppBar(title: Text('User Profile: $userId')),
      body: Center(
        child: Text('Profile details for user $userId'),
      ),
    );
  }
}
