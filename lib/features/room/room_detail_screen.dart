import 'package:flutter/material.dart';

class RoomDetailScreen extends StatelessWidget {
  final String roomId;
  const RoomDetailScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Room Details')),
      body: Center(
        child: Text('Room ID: $roomId'),
      ),
    );
  }
}
