import 'package:flutter/material.dart';

class FriendRequestsScreen extends StatelessWidget {
  const FriendRequestsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Friend Requests')),
      body: Center(child: Text('Friend Requests Here')),
    );
  }
}
