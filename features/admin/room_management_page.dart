import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RoomManagementPage extends ConsumerWidget {
  const RoomManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Room Management')),
      body: const Column(
        children: [
          Text('Room view, join, monitor coming soon'),
        ],
      ),
    );
  }
}
