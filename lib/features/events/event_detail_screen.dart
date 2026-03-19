import 'package:flutter/material.dart';

class EventDetailScreen extends StatelessWidget {
  const EventDetailScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Event Detail')),
      body: Center(
        child: Semantics(
          label: 'Event Detail Screen',
          child: Text('Event Detail Screen', style: TextStyle(fontSize: MediaQuery.of(context).size.width > 400 ? 20 : 18)),
        ),
      ),
    );
  }
}
