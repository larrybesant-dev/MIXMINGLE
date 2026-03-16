import 'package:flutter/material.dart';

class RoomTile extends StatelessWidget {
  final String roomName;
  final VoidCallback? onTap;

  const RoomTile({required this.roomName, this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(title: Text(roomName), onTap: onTap);
  }
}
