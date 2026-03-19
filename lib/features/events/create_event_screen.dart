import 'package:flutter/material.dart';

class CreateEventScreen extends StatelessWidget {
  const CreateEventScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Event')),
      body: Center(
        child: Semantics(
          label: 'Create Event Screen',
          child: Text('Create Event Screen', style: TextStyle(fontSize: MediaQuery.of(context).size.width > 400 ? 20 : 18)),
        ),
      ),
    );
  }
}
