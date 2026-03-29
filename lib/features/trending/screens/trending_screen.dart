import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/trending_provider.dart';

class TrendingScreen extends ConsumerStatefulWidget {
  const TrendingScreen({super.key});

  @override
  ConsumerState<TrendingScreen> createState() => _TrendingScreenState();
}

class _TrendingScreenState extends ConsumerState<TrendingScreen> {

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Trending'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Posts'),
              Tab(text: 'Hashtags'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Trending Posts Tab
            _buildTrendingPosts(),
            // Trending Hashtags Tab
            _buildTrendingHashtags(),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingPosts() {
    final postsAsync = ref.watch(trendingPostsProvider);

    return postsAsync.when(
      data: (posts) {
        if (posts.isEmpty) {
          return const Center(child: Text('No trending posts'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
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
                            (post.authorName)[0].toUpperCase(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.authorName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _formatTime(post.createdAt),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(post.content),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text('${post.likeCount}'),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text('${post.commentCount}'),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildTrendingHashtags() {
    final hashtagsAsync = ref.watch(trendingHashtagsProvider(DateTime.now()));

    return hashtagsAsync.when(
      data: (hashtags) {
        if (hashtags.isEmpty) {
          return const Center(child: Text('No trending hashtags'));
        }
        return ListView.builder(
          itemCount: hashtags.length,
          itemBuilder: (context, index) {
            final tag = hashtags[index];
            return ListTile(
              leading: Text(
                '#${index + 1}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              title: Text('#${tag['hashtag']}'),
              subtitle: Text('${tag['postCount']} posts'),
              onTap: () {
                _showHashtagPosts(tag['hashtag']);
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  void _showHashtagPosts(String hashtag) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) {
          final postsAsync = ref.watch(hashtagPostsProvider(hashtag));

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '#$hashtag',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: postsAsync.when(
                  data: (posts) {
                    if (posts.isEmpty) {
                      return const Center(child: Text('No posts'));
                    }
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        return ListTile(
                          title: Text(post.content),
                          subtitle: Text('${post.likeCount} likes'),
                          onTap: () => context.pop(),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) =>
                      Center(child: Text('Error: $error')),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return dateTime.toString().substring(0, 10);
    }
  }
}
