import 'package:flutter/material.dart';

class RoomHistoryScreen extends StatelessWidget {
  const RoomHistoryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Room History')), 
      body: Center(child: Text('Room History Content Here')),
    );
  }
}
