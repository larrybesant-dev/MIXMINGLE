import 'package:flutter/material.dart';

class RoomMembersScreen extends StatelessWidget {
  const RoomMembersScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Room Members')),
      body: Center(child: Text('Room Members List Here')),
    );
  }
}
