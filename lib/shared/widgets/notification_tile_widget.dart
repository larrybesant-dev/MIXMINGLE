import 'package:flutter/material.dart';

class NotificationTileWidget extends StatelessWidget {
  final Map<String, dynamic> notification;
  const NotificationTileWidget({required this.notification, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: const Icon(Icons.notifications),
        title: Text(notification['title'] ?? ''),
        subtitle: Text(notification['description'] ?? ''),
        trailing: Text(notification['timestamp'] ?? ''),
      ),
    );
  }
}
