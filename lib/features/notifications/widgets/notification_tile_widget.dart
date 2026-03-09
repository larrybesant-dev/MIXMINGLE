import 'package:flutter/material.dart';

class NotificationTileWidget extends StatelessWidget {
  final Map<String, dynamic> notification;
  const NotificationTileWidget({required this.notification, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: Icon(Icons.notifications),
        title: Text(notification['title'] ?? ''),
        subtitle: Text(notification['description'] ?? ''),
        trailing: Text(notification['timestamp'] ?? ''),
      ),
    );
  }
}
