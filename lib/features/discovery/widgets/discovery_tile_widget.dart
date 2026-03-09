import 'package:flutter/material.dart';

class DiscoveryTileWidget extends StatelessWidget {
  final Map<String, dynamic> discovery;
  const DiscoveryTileWidget({required this.discovery, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: Icon(Icons.explore),
        title: Text(discovery['title'] ?? ''),
        subtitle: Text(discovery['description'] ?? ''),
        trailing: Text(discovery['timestamp'] ?? ''),
      ),
    );
  }
}
