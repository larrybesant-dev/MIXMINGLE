import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/trending_provider.dart';
import '../../feed/models/post_model.dart';
import '../../feed/widgets/post_card.dart';

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
            final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
            return PostCard(
              post: PostModel(
                id: post.id,
                userId: post.authorId,
                text: post.content,
                authorName: post.authorName,
                authorAvatarUrl: post.authorAvatarUrl,
                likeCount: post.likeCount,
                commentCount: post.commentCount,
                createdAt: post.createdAt,
              ),
              currentUserId: uid,
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
                        final uid =
                            FirebaseAuth.instance.currentUser?.uid ?? '';
                        return PostCard(
                          post: PostModel(
                            id: post.id,
                            userId: post.authorId,
                            text: post.content,
                            authorName: post.authorName,
                            authorAvatarUrl: post.authorAvatarUrl,
                            likeCount: post.likeCount,
                            commentCount: post.commentCount,
                            createdAt: post.createdAt,
                          ),
                          currentUserId: uid,
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

}

