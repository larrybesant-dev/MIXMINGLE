import 'package:flutter/material.dart';

class RoomDetailScreen extends StatelessWidget {
  final String roomId;
  const RoomDetailScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with real room detail logic
    return Scaffold(
      appBar: AppBar(title: Text('Room: $roomId')),
      body: Center(
        child: Text('Room details for $roomId'),
      ),
    );
  }
}
