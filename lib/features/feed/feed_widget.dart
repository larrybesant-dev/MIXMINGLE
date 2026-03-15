// Basic UI widget for Feed
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'feed_provider.dart';

class FeedWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(feedProvider);
    if (feed.isEmpty) {
      return Center(child: Text('No posts yet'));
    }
    return ListView.builder(
      itemCount: feed.length,
      itemBuilder: (context, index) {
        final post = feed[index];
        return Card(
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('User: ${post.userId}', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text(post.content),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.thumb_up),
                    SizedBox(width: 4),
                    Text('${post.likes}'),
                    SizedBox(width: 16),
                    Icon(Icons.comment),
                    SizedBox(width: 4),
                    Text('${post.comments}'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
