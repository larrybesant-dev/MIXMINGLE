// Basic UI widget for Connections
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'connection_provider.dart';

class ConnectionWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connections = ref.watch(connectionsProvider);
    if (connections.isEmpty) {
      return Center(child: Text('No connections'));
    }
    return ListView.builder(
      itemCount: connections.length,
      itemBuilder: (context, index) {
        final connection = connections[index];
        return ListTile(
          title: Text('User: ${connection.userId}'),
          subtitle: Text('Status: ${connection.status}'),
        );
      },
    );
  }
}
