import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/trending_provider.dart';
import '../../feed/models/post_model.dart';
import '../../feed/widgets/post_card.dart';
import '../../../core/theme.dart';

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
        backgroundColor: NeonPulse.surface,
        appBar: AppBar(
          backgroundColor: NeonPulse.surface,
          title: ShaderMask(
            shaderCallback: (rect) =>
                NeonPulse.primaryGradient.createShader(rect),
            blendMode: BlendMode.srcIn,
            child: const Text(
              'Trending',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
            ),
          ),
          bottom: const TabBar(
            indicatorColor: NeonPulse.primary,
            labelColor: NeonPulse.primary,
            unselectedLabelColor: NeonPulse.onSurfaceVariant,
            indicatorWeight: 2,
            tabs: [
              Tab(text: 'Posts'),
              Tab(text: 'Hashtags'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTrendingPosts(),
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
          return const Center(
            child: Text(
              'No trending posts yet',
              style: TextStyle(color: NeonPulse.onSurfaceVariant),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(top: 4, bottom: 80),
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
      loading: () => const Center(
          child: CircularProgressIndicator(color: NeonPulse.primary)),
      error: (e, _) => Center(
        child: Text('Could not load trending posts',
            style: const TextStyle(color: NeonPulse.onSurfaceVariant)),
      ),
    );
  }

  Widget _buildTrendingHashtags() {
    // Snapshot the current time once so the provider key stays stable
    // for the lifetime of the widget tree (avoids rebuilding on every frame).
    final now = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final hashtagsAsync = ref.watch(trendingHashtagsProvider(now));

    return hashtagsAsync.when(
      data: (hashtags) {
        if (hashtags.isEmpty) {
          return const Center(
            child: Text(
              'No trending hashtags yet',
              style: TextStyle(color: NeonPulse.onSurfaceVariant),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: hashtags.length,
          itemBuilder: (context, index) {
            final tag = hashtags[index];
            final rank = index + 1;
            return GestureDetector(
              onTap: () => _showHashtagPosts(tag['hashtag'] as String),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: NeonPulse.surfaceContainer,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: NeonPulse.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: NeonPulse.primaryDim.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '#$rank',
                        style: const TextStyle(
                          color: NeonPulse.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#${tag['hashtag']}',
                            style: const TextStyle(
                              color: NeonPulse.onSurface,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${tag['postCount']} posts',
                            style: const TextStyle(
                              color: NeonPulse.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        color: NeonPulse.onSurfaceVariant, size: 18),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(color: NeonPulse.primary)),
      error: (e, _) => const Center(
        child: Text('Could not load hashtags',
            style: TextStyle(color: NeonPulse.onSurfaceVariant)),
      ),
    );
  }

  void _showHashtagPosts(String hashtag) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: NeonPulse.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (ctx, scrollController) {
          return Consumer(
            builder: (ctx, ref, _) {
              final postsAsync = ref.watch(hashtagPostsProvider(hashtag));
              return Column(
                children: [
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: NeonPulse.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ShaderMask(
                    shaderCallback: (rect) =>
                        NeonPulse.primaryGradient.createShader(rect),
                    blendMode: BlendMode.srcIn,
                    child: Text(
                      '#$hashtag',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: postsAsync.when(
                      data: (posts) {
                        if (posts.isEmpty) {
                          return const Center(
                            child: Text(
                              'No posts with this hashtag',
                              style: TextStyle(
                                  color: NeonPulse.onSurfaceVariant),
                            ),
                          );
                        }
                        final uid =
                            FirebaseAuth.instance.currentUser?.uid ?? '';
                        return ListView.builder(
                          controller: scrollController,
                          itemCount: posts.length,
                          itemBuilder: (context, index) {
                            final post = posts[index];
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
                      loading: () => const Center(
                          child: CircularProgressIndicator(
                              color: NeonPulse.primary)),
                      error: (e, _) => const Center(
                        child: Text('Could not load posts',
                            style: TextStyle(
                                color: NeonPulse.onSurfaceVariant)),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

}

