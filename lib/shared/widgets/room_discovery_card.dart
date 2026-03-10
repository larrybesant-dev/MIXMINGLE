import 'package:flutter/material.dart';

class RoomDiscoveryCard extends StatelessWidget {
  final String roomId;
  final String userId;
  final VoidCallback? onTap;

  const RoomDiscoveryCard({
    super.key,
    required this.roomId,
    required this.userId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text("Room: $roomId"),
              Text("Host: $userId"),
            ],
          ),
        ),
      ),
    );
  }
}
