import 'package:flutter/material.dart';

class FeedItemWidget extends StatelessWidget {
  final Map<String, dynamic> feedItem;
  const FeedItemWidget({required this.feedItem, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(feedItem['avatarUrl'] ?? ''),
        ),
        title: Text(feedItem['title'] ?? ''),
        subtitle: Text(feedItem['description'] ?? ''),
        trailing: Text(feedItem['timestamp'] ?? ''),
      ),
    );
  }
}
