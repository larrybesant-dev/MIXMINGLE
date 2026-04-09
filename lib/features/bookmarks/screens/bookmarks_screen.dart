import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mixvy/features/auth/controllers/auth_controller.dart';
import '../providers/bookmark_provider.dart';
import '../../feed/models/post_model.dart';
import '../../feed/widgets/post_card.dart';

class BookmarksScreen extends ConsumerWidget {
  final String userId;

  const BookmarksScreen({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksAsync = ref.watch(bookmarkedPostsProvider(userId));
    final viewerId = ref.watch(authControllerProvider).uid ?? '';

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

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: posts.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final raw = posts[index];
              final id = raw['id'] as String? ?? '';
              final post = PostModel.fromDoc(id, raw);
              return Stack(
                children: [
                  PostCard(post: post, currentUserId: viewerId),
                  // Bookmark remove button overlay (top-right)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _BookmarkRemoveButton(
                      userId: userId,
                      bookmarkId: raw['bookmarkId'] as String? ?? '',
                      bookmarkController: ref.read(bookmarkControllerProvider),
                    ),
                  ),
                ],
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
}

class _BookmarkRemoveButton extends StatelessWidget {
  final String userId;
  final String bookmarkId;
  final dynamic bookmarkController;

  const _BookmarkRemoveButton({
    required this.userId,
    required this.bookmarkId,
    required this.bookmarkController,
  });

  @override
  Widget build(BuildContext context) {
    if (bookmarkId.isEmpty) return const SizedBox.shrink();
    return Material(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
      shape: const CircleBorder(),
      child: IconButton(
        icon: const Icon(Icons.bookmark, color: Colors.blue),
        tooltip: 'Remove bookmark',
        onPressed: () => bookmarkController.removeBookmark(
          userId: userId,
          bookmarkId: bookmarkId,
        ),
      ),
    );
  }
}
