import 'package:flutter/material.dart';

class LiveRoomScreen extends StatelessWidget {
  const LiveRoomScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Room')), 
      body: Center(child: Text('Live Room Content Here')),
    );
  }
}
