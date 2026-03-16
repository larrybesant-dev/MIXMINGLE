import 'package:flutter/material.dart';

class NotificationTile extends StatelessWidget {
  final String content;
  const NotificationTile({super.key, required this.content});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(content),
    );
  }
}
