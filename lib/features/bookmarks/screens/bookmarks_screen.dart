import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/bookmark_provider.dart';

class BookmarksScreen extends ConsumerWidget {
  final String userId;

  const BookmarksScreen({
    super.key,
    required this.userId,
  });

  String _asString(dynamic value, {String fallback = ''}) {
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return fallback;
  }

  List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item is String ? item.trim() : item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    return const <String>[];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksAsync = ref.watch(bookmarkedPostsProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmarks'),
      ),
      body: bookmarksAsync.when(
        data: (posts) {
          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text('No bookmarks yet'),
                  const SizedBox(height: 8),
                  Text(
                    'Save posts to view them later',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final authorName = _asString(post['authorName']);
              final safeAuthorName =
                  authorName.isEmpty
                  ? 'Unknown'
                  : authorName;
              final bookmarkId = _asString(post['bookmarkId']);
              final content = _asString(post['content']);
              final tags = _asStringList(post['tags']);
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            child: Text(
                              safeAuthorName.substring(0, 1).toUpperCase(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  safeAuthorName,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  _formatTime(post['createdAt']),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.bookmark, color: Colors.blue),
                            onPressed: bookmarkId.isEmpty
                                ? null
                                : () {
                                    ref
                                        .read(bookmarkControllerProvider)
                                        .removeBookmark(
                                          userId: userId,
                                          bookmarkId: bookmarkId,
                                        );
                                  },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(content),
                      if (tags.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Wrap(
                            spacing: 4,
                            children: tags
                                .map((tag) => Chip(
                                      label: Text('#$tag', style: const TextStyle(fontSize: 12)),
                                      visualDensity: VisualDensity.compact,
                                    ))
                                .toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('Error loading bookmarks: $error'),
        ),
      ),
    );
  }

  String _formatTime(dynamic timestamp) {
    try {
      final dateTime = timestamp is DateTime
          ? timestamp
          : DateTime.now();
      final difference = DateTime.now().difference(dateTime);
      if (difference.inMinutes < 1) return 'now';
      if (difference.inHours < 1) return '${difference.inMinutes}m ago';
      if (difference.inDays < 1) return '${difference.inHours}h ago';
      return '${difference.inDays}d ago';
    } catch (e) {
      return 'unknown';
    }
  }
}
