import 'package:flutter/material.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      body: Center(
        child: Semantics(
          label: 'Events Screen',
          child: Text('Events Screen', style: TextStyle(fontSize: MediaQuery.of(context).size.width > 400 ? 20 : 18)),
        ),
      ),
    );
  }
}
