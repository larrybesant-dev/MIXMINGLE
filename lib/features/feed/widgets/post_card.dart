import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/post_model.dart';
import '../providers/feed_providers.dart';

/// A feed post card with author info, like button, and comment count.
/// [currentUserId] is required for optimistic like toggling.
class PostCard extends ConsumerStatefulWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.currentUserId,
  });

  final PostModel post;
  final String currentUserId;

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> {
  bool _toggling = false;

  Future<void> _toggleLike() async {
    if (_toggling) return;
    setState(() => _toggling = true);
    try {
      await ref.read(feedRepositoryProvider).toggleLike(
            widget.post.id,
            widget.currentUserId,
            widget.post.isLikedBy(widget.currentUserId),
          );
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final liked = post.isLikedBy(widget.currentUserId);
    final authorInitial =
        (post.authorName?.trim().isNotEmpty == true ? post.authorName! : post.userId)[0]
            .toUpperCase();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author row
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: post.authorAvatarUrl != null
                      ? NetworkImage(post.authorAvatarUrl!)
                      : null,
                  child: post.authorAvatarUrl == null
                      ? Text(authorInitial)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName?.trim().isNotEmpty == true
                            ? post.authorName!
                            : post.userId,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        _formatTime(post.createdAt),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Post body
            Text(post.text),
            const SizedBox(height: 10),
            // Action row
            Row(
              children: [
                // Like button
                GestureDetector(
                  onTap: _toggling ? null : _toggleLike,
                  child: Row(
                    children: [
                      Icon(
                        liked ? Icons.favorite : Icons.favorite_border,
                        size: 20,
                        color: liked ? Colors.redAccent : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${post.likeCount}',
                        style: TextStyle(
                          color: liked ? Colors.redAccent : Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // Comment count → tap to open comments
                GestureDetector(
                  onTap: () => context.push('/post/${post.id}/comments'),
                  child: Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline,
                          size: 20, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${post.commentCount}',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}
