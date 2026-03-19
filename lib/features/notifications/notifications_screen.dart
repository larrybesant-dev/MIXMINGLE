import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: Center(
        child: Semantics(
          label: 'Notifications Screen',
          child: Text('Notifications Screen', style: TextStyle(fontSize: MediaQuery.of(context).size.width > 400 ? 20 : 18)),
        ),
      ),
    );
  }
}
