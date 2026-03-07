// lib/features/feed/social_feed_page.dart
//
// Social Feed — upgraded engine with:
//   • "For You" tab   — global feed, cursor-based pagination
//   • "Following" tab — following feed, offset pagination
//   • Trending rail   — horizontal top-posts strip (real-time stream)
//   • Infinite scroll + pull-to-refresh + loading / empty / error states
//   • Enhanced PostCard: image previews, video thumbnails, tap-to-detail

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../core/design_system/design_constants.dart';
import '../../shared/models/post.dart';
import '../../services/social/social_feed_service.dart';
import '../../shared/providers/feed_providers.dart';
import 'create_post_dialog.dart';

// ─────────────────────────────────────────────────────────────
// UTILITY
// ─────────────────────────────────────────────────────────────

/// Format counts for compact display: 1234 → 1.2k, 1500000 → 1.5m
String _fmtCount(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}m';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
  return '$n';
}

// ─────────────────────────────────────────────────────────────
// MAIN PAGE
// ─────────────────────────────────────────────────────────────

class SocialFeedPage extends ConsumerStatefulWidget {
  const SocialFeedPage({super.key});

  @override
  ConsumerState<SocialFeedPage> createState() => _SocialFeedPageState();
}

class _SocialFeedPageState extends ConsumerState<SocialFeedPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final ScrollController _forYouScroller = ScrollController();
  final ScrollController _followingScroller = ScrollController();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentUserId = fb.FirebaseAuth.instance.currentUser?.uid;
    _forYouScroller.addListener(_onForYouScroll);
    _followingScroller.addListener(_onFollowingScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _forYouScroller.dispose();
    _followingScroller.dispose();
    super.dispose();
  }

  void _onForYouScroll() {
    if (_forYouScroller.position.pixels >=
        _forYouScroller.position.maxScrollExtent - 300) {
      ref.read(globalFeedNotifierProvider.notifier).loadMore();
    }
  }

  void _onFollowingScroll() {
    if (_currentUserId == null) return;
    if (_followingScroller.position.pixels >=
        _followingScroller.position.maxScrollExtent - 300) {
      ref
          .read(followingFeedNotifierProvider.notifier)
          .loadMore();
    }
  }

  void _showCreatePostDialog() {
    if (_currentUserId == null) return;
    showDialog(
      context: context,
      builder: (ctx) => CreatePostDialog(userId: _currentUserId!),
    );
  }

  void _openPostDetail(Post post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: DesignColors.surfaceDefault,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _PostDetailSheet(
        post: post,
        currentUserId: _currentUserId,
        onTip: () {
          Navigator.pop(ctx);
          _showTipDialog(post);
        },
      ),
    );
  }

  void _showTipDialog(Post post) {
    if (_currentUserId == null || _currentUserId == post.userId) return;
    showDialog(
      context: context,
      builder: (ctx) => _TipDialog(
        post: post,
        fromUserId: _currentUserId!,
        feedService: SocialFeedService.instance,
      ),
    );
  }

  Future<void> _toggleLike(Post post) async {
    if (_currentUserId == null) return;
    await SocialFeedService.instance.toggleLike(post.id, _currentUserId!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignColors.background,
      appBar: AppBar(
        backgroundColor: DesignColors.surfaceDefault,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'FEED',
          style: TextStyle(
            color: DesignColors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: DesignColors.accent,
          labelColor: DesignColors.accent,
          unselectedLabelColor: DesignColors.textGray,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 1.2,
          ),
          tabs: const [Tab(text: 'FOR YOU'), Tab(text: 'FOLLOWING')],
        ),
      ),
      body: Column(
        children: [
          // Trending rail — always visible above both tabs
          _TrendingRail(onPostTap: _openPostDetail),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ForYouTab(
                  scrollController: _forYouScroller,
                  currentUserId: _currentUserId,
                  onLike: _toggleLike,
                  onPostTap: _openPostDetail,
                  onTip: _showTipDialog,
                  onRefresh: () =>
                      ref.read(globalFeedNotifierProvider.notifier).refresh(),
                ),
                _FollowingTab(
                  scrollController: _followingScroller,
                  currentUserId: _currentUserId,
                  onLike: _toggleLike,
                  onPostTap: _openPostDetail,
                  onTip: _showTipDialog,
                  onRefresh: () {
                    if (_currentUserId != null) {
                      ref
                          .read(followingFeedNotifierProvider
                              .notifier)
                          .refresh();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePostDialog,
        backgroundColor: DesignColors.accent,
        child: const Icon(Icons.add, color: DesignColors.white),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TRENDING RAIL
// ─────────────────────────────────────────────────────────────

class _TrendingRail extends ConsumerWidget {
  final void Function(Post) onPostTap;
  const _TrendingRail({required this.onPostTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendingAsync = ref.watch(trendingFeedProvider);
    return trendingAsync.when(
      data: (posts) {
        if (posts.isEmpty) return const SizedBox.shrink();
        return Container(
          color: DesignColors.surfaceDefault,
          padding: const EdgeInsets.only(top: 10, bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.trending_up,
                        size: 15, color: DesignColors.secondary),
                    const SizedBox(width: 6),
                    const Text(
                      'TRENDING',
                      style: TextStyle(
                        color: DesignColors.secondary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 96,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: posts.length > 8 ? 8 : posts.length,
                  itemBuilder: (ctx, i) => _TrendingPostCard(
                    post: posts[i],
                    onTap: () => onPostTap(posts[i]),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _TrendingPostCard extends StatelessWidget {
  final Post post;
  final VoidCallback onTap;
  const _TrendingPostCard({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 148,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: DesignColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: DesignColors.secondary.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 11,
                  backgroundColor: DesignColors.accent,
                  backgroundImage: post.userAvatar.isNotEmpty
                      ? NetworkImage(post.userAvatar)
                      : null,
                  child: post.userAvatar.isEmpty
                      ? Text(
                          post.userName.isNotEmpty
                              ? post.userName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: DesignColors.white, fontSize: 9),
                        )
                      : null,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    post.userName,
                    style: const TextStyle(
                        color: DesignColors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Expanded(
              child: Text(
                post.content,
                style: const TextStyle(
                    color: DesignColors.textLightGray, fontSize: 11),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              children: [
                const Icon(Icons.favorite, size: 11, color: DesignColors.error),
                const SizedBox(width: 3),
                Text(
                  _fmtCount(post.likeCount),
                  style: const TextStyle(
                      color: DesignColors.textGray, fontSize: 11),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chat_bubble_outline,
                    size: 11, color: DesignColors.textGray),
                const SizedBox(width: 3),
                Text(
                  _fmtCount(post.commentCount),
                  style: const TextStyle(
                      color: DesignColors.textGray, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// FOR YOU TAB
// ─────────────────────────────────────────────────────────────

class _ForYouTab extends ConsumerWidget {
  final ScrollController scrollController;
  final String? currentUserId;
  final Future<void> Function(Post) onLike;
  final void Function(Post) onTip;
  final void Function(Post) onPostTap;
  final void Function() onRefresh;

  const _ForYouTab({
    required this.scrollController,
    required this.currentUserId,
    required this.onLike,
    required this.onTip,
    required this.onPostTap,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedState = ref.watch(globalFeedNotifierProvider);

    if (feedState.isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: DesignColors.accent));
    }
    if (feedState.error != null && feedState.posts.isEmpty) {
      return _ErrorState(
        message: feedState.error!,
        onRetry: () => ref.read(globalFeedNotifierProvider.notifier).refresh(),
      );
    }
    return RefreshIndicator(
      onRefresh: () async =>
          ref.read(globalFeedNotifierProvider.notifier).refresh(),
      color: DesignColors.accent,
      child: feedState.posts.isEmpty
          ? _EmptyState(
              icon: Icons.feed_outlined,
              title: 'No posts yet',
              subtitle: 'Be the first to share something!',
            )
          : ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: feedState.posts.length + 1,
              itemBuilder: (ctx, index) {
                if (index == feedState.posts.length) {
                  return _LoadMoreFooter(
                    isLoading: feedState.isLoadingMore,
                    hasMore: feedState.hasMore,
                  );
                }
                final post = feedState.posts[index];
                return _PostCard(
                  post: post,
                  currentUserId: currentUserId,
                  onLike: () => onLike(post),
                  onTip: () => onTip(post),
                  onTap: () => onPostTap(post),
                );
              },
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// FOLLOWING TAB
// ─────────────────────────────────────────────────────────────

class _FollowingTab extends ConsumerWidget {
  final ScrollController scrollController;
  final String? currentUserId;
  final Future<void> Function(Post) onLike;
  final void Function(Post) onTip;
  final void Function(Post) onPostTap;
  final void Function() onRefresh;

  const _FollowingTab({
    required this.scrollController,
    required this.currentUserId,
    required this.onLike,
    required this.onTip,
    required this.onPostTap,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (currentUserId == null) {
      return const _EmptyState(
        icon: Icons.group_outlined,
        title: 'Not logged in',
        subtitle: 'Sign in to see posts from people you follow.',
      );
    }

    final feedState = ref.watch(followingFeedNotifierProvider);

    if (feedState.isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: DesignColors.accent));
    }
    if (feedState.error != null && feedState.posts.isEmpty) {
      return _ErrorState(
        message: feedState.error!,
        onRetry: () => ref
            .read(followingFeedNotifierProvider.notifier)
            .refresh(),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => ref
          .read(followingFeedNotifierProvider.notifier)
          .refresh(),
      color: DesignColors.accent,
      child: feedState.posts.isEmpty
          ? const _EmptyState(
              icon: Icons.group_outlined,
              title: 'Nothing here yet',
              subtitle: 'Follow people to see their posts.',
            )
          : ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: feedState.posts.length + 1,
              itemBuilder: (ctx, index) {
                if (index == feedState.posts.length) {
                  return _LoadMoreFooter(
                    isLoading: feedState.isLoadingMore,
                    hasMore: feedState.hasMore,
                  );
                }
                final post = feedState.posts[index];
                return _PostCard(
                  post: post,
                  currentUserId: currentUserId,
                  onLike: () => onLike(post),
                  onTip: () => onTip(post),
                  onTap: () => onPostTap(post),
                );
              },
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// LOAD MORE FOOTER
// ─────────────────────────────────────────────────────────────

class _LoadMoreFooter extends StatelessWidget {
  final bool isLoading;
  final bool hasMore;
  const _LoadMoreFooter({required this.isLoading, required this.hasMore});

  @override
  Widget build(BuildContext context) {
    if (!hasMore) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          "You're all caught up!",
          textAlign: TextAlign.center,
          style: TextStyle(
              color: DesignColors.textGray.withValues(alpha: 0.5),
              fontSize: 13),
        ),
      );
    }
    if (!isLoading) return const SizedBox(height: 24);
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Center(
        child: CircularProgressIndicator(
            color: DesignColors.accent, strokeWidth: 2),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// EMPTY & ERROR STATES
// ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,
              size: 72,
              color: DesignColors.textGray.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  color: DesignColors.textLightGray,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(subtitle,
              style: TextStyle(
                  color: DesignColors.textGray.withValues(alpha: 0.6),
                  fontSize: 14)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline,
              size: 60, color: DesignColors.error),
          const SizedBox(height: 16),
          const Text('Something went wrong',
              style: TextStyle(
                  color: DesignColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: DesignColors.textGray, fontSize: 13)),
          const SizedBox(height: 20),
          TextButton(
            onPressed: onRetry,
            child: const Text('Try again',
                style: TextStyle(color: DesignColors.accent)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// POST CARD
// ─────────────────────────────────────────────────────────────

class _PostCard extends StatelessWidget {
  final Post post;
  final String? currentUserId;
  final VoidCallback onLike;
  final VoidCallback onTip;
  final VoidCallback onTap;

  const _PostCard({
    required this.post,
    required this.currentUserId,
    required this.onLike,
    required this.onTip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLiked = currentUserId != null && post.isLikedBy(currentUserId!);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: DesignColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: DesignColors.accent.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: DesignColors.accent,
                    backgroundImage: post.userAvatar.isNotEmpty
                        ? NetworkImage(post.userAvatar)
                        : null,
                    child: post.userAvatar.isEmpty
                        ? Text(
                            post.userName.isNotEmpty
                                ? post.userName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                color: DesignColors.white,
                                fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post.userName,
                            style: const TextStyle(
                                color: DesignColors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                        Text(post.timeAgo,
                            style: TextStyle(
                                color: DesignColors.textGray
                                    .withValues(alpha: 0.7),
                                fontSize: 12)),
                      ],
                    ),
                  ),
                  if (post.type == PostType.roomShare)
                    _LiveBadge()
                  else if (post.type == PostType.achievement)
                    _AchievementBadge(),
                ],
              ),
            ),

            // ── Content ────────────────────────────────────────
            if (post.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: Text(
                  post.content,
                  style: const TextStyle(
                      color: DesignColors.white, fontSize: 15, height: 1.45),
                ),
              ),

            // ── Image / Video preview ──────────────────────────
            if (post.type == PostType.video)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _VideoThumb(thumbnailUrl: post.imageUrl),
              )
            else if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _ImagePreview(url: post.imageUrl!),
              ),

            // ── Actions ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _ActionButton(
                    icon: isLiked ? Icons.favorite : Icons.favorite_border,
                    label: _fmtCount(post.likeCount),
                    color:
                        isLiked ? DesignColors.error : DesignColors.textGray,
                    onTap: onLike,
                  ),
                  const SizedBox(width: 20),
                  _ActionButton(
                    icon: Icons.chat_bubble_outline,
                    label: _fmtCount(post.commentCount),
                    color: DesignColors.textGray,
                    onTap: onTap,
                  ),
                  const SizedBox(width: 20),
                  _ActionButton(
                    icon: Icons.monetization_on_outlined,
                    label: post.tipCount > 0
                        ? _fmtCount(post.tipCount)
                        : 'Tip',
                    color: DesignColors.gold,
                    onTap: onTip,
                  ),
                  const Spacer(),
                  Icon(Icons.open_in_new_outlined,
                      size: 17,
                      color:
                          DesignColors.textGray.withValues(alpha: 0.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// POST CARD CHILD WIDGETS
// ─────────────────────────────────────────────────────────────

class _LiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: DesignColors.secondary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: DesignColors.secondary.withValues(alpha: 0.4), width: 1),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.live_tv, size: 13, color: DesignColors.secondary),
          SizedBox(width: 4),
          Text('LIVE',
              style: TextStyle(
                  color: DesignColors.secondary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: DesignColors.gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: DesignColors.gold.withValues(alpha: 0.4), width: 1),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events, size: 13, color: DesignColors.gold),
          SizedBox(width: 4),
          Text('WIN',
              style: TextStyle(
                  color: DesignColors.gold,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final String url;
  const _ImagePreview({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius:
          const BorderRadius.vertical(bottom: Radius.circular(16)),
      child: Image.network(
        url,
        width: double.infinity,
        height: 220,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, _) => Container(
          height: 220,
          color: DesignColors.surfaceDefault,
          child: const Center(
              child: Icon(Icons.broken_image,
                  color: DesignColors.textGray, size: 40)),
        ),
      ),
    );
  }
}

class _VideoThumb extends StatelessWidget {
  final String? thumbnailUrl;
  const _VideoThumb({required this.thumbnailUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius:
          const BorderRadius.vertical(bottom: Radius.circular(16)),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty)
            Image.network(
              thumbnailUrl!,
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
              errorBuilder: (ctx, _, __) => Container(
                height: 220,
                width: double.infinity,
                color: DesignColors.surfaceDefault,
              ),
            )
          else
            Container(
                height: 220,
                width: double.infinity,
                color: DesignColors.surfaceDefault),
          Positioned.fill(
            child:
                Container(color: Colors.black.withValues(alpha: 0.35)),
          ),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow,
                color: DesignColors.background, size: 36),
          ),
          Positioned(
            bottom: 10,
            left: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.videocam, size: 13, color: Colors.white),
                  SizedBox(width: 4),
                  Text('VIDEO',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ACTION BUTTON
// ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// POST DETAIL SHEET  (full post + comments)
// ─────────────────────────────────────────────────────────────

class _PostDetailSheet extends StatefulWidget {
  final Post post;
  final String? currentUserId;
  final VoidCallback onTip;

  const _PostDetailSheet({
    required this.post,
    required this.currentUserId,
    required this.onTip,
  });

  @override
  State<_PostDetailSheet> createState() => _PostDetailSheetState();
}

class _PostDetailSheetState extends State<_PostDetailSheet> {
  final TextEditingController _commentController = TextEditingController();
  late bool _isLiked;
  late int _likeCount;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.currentUserId != null &&
        widget.post.isLikedBy(widget.currentUserId!);
    _likeCount = widget.post.likeCount;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    if (widget.currentUserId == null) return;
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });
    await SocialFeedService.instance
        .toggleLike(widget.post.id, widget.currentUserId!);
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty || widget.currentUserId == null) return;
    setState(() => _isSubmitting = true);
    await SocialFeedService.instance.addComment(
      postId: widget.post.id,
      userId: widget.currentUserId!,
      content: content,
    );
    _commentController.clear();
    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.4,
      maxChildSize: 1.0,
      expand: false,
      builder: (ctx, scrollController) {
        return Column(
          children: [
            // Sheet handle
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: DesignColors.textGray.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  const SizedBox(height: 12),

                  // Post header
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: DesignColors.accent,
                        backgroundImage: widget.post.userAvatar.isNotEmpty
                            ? NetworkImage(widget.post.userAvatar)
                            : null,
                        child: widget.post.userAvatar.isEmpty
                            ? Text(
                                widget.post.userName.isNotEmpty
                                    ? widget.post.userName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    color: DesignColors.white,
                                    fontWeight: FontWeight.bold))
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.post.userName,
                                style: const TextStyle(
                                    color: DesignColors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15)),
                            Text(widget.post.timeAgo,
                                style: TextStyle(
                                    color: DesignColors.textGray
                                        .withValues(alpha: 0.7),
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close,
                            color: DesignColors.textGray, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Content
                  if (widget.post.content.isNotEmpty)
                    Text(
                      widget.post.content,
                      style: const TextStyle(
                          color: DesignColors.white,
                          fontSize: 16,
                          height: 1.5),
                    ),

                  // Image / Video
                  if (widget.post.type == PostType.video)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child:
                            _VideoThumb(thumbnailUrl: widget.post.imageUrl),
                      ),
                    )
                  else if (widget.post.imageUrl != null &&
                      widget.post.imageUrl!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          widget.post.imageUrl!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 180,
                            color: DesignColors.surfaceDefault,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 14),

                  // Quick actions
                  Row(
                    children: [
                      _ActionButton(
                        icon: _isLiked
                            ? Icons.favorite
                            : Icons.favorite_border,
                        label: _fmtCount(_likeCount),
                        color: _isLiked
                            ? DesignColors.error
                            : DesignColors.textGray,
                        onTap: _toggleLike,
                      ),
                      const SizedBox(width: 24),
                      _ActionButton(
                        icon: Icons.monetization_on_outlined,
                        label: widget.post.tipCount > 0
                            ? _fmtCount(widget.post.tipCount)
                            : 'Tip',
                        color: DesignColors.gold,
                        onTap: widget.onTip,
                      ),
                    ],
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(color: DesignColors.divider),
                  ),

                  // Comments header
                  Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline,
                          size: 16, color: DesignColors.accent),
                      const SizedBox(width: 6),
                      Text(
                        'Comments  (${_fmtCount(widget.post.commentCount)})',
                        style: const TextStyle(
                            color: DesignColors.accent,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Comment stream
                  StreamBuilder<List<Comment>>(
                    stream: SocialFeedService.instance
                        .getCommentsStream(widget.post.id),
                    builder: (ctx, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(
                                color: DesignColors.accent, strokeWidth: 2),
                          ),
                        );
                      }
                      final comments = snapshot.data!;
                      if (comments.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'No comments yet. Start the conversation!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: DesignColors.textGray
                                    .withValues(alpha: 0.6),
                                fontSize: 13),
                          ),
                        );
                      }
                      return Column(
                        children: comments
                            .map((c) => _CommentTile(comment: c))
                            .toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),

            // Comment input
            Container(
              padding: EdgeInsets.only(
                left: 12,
                right: 8,
                top: 8,
                bottom: MediaQuery.of(context).viewInsets.bottom + 8,
              ),
              decoration: const BoxDecoration(
                color: DesignColors.surfaceLight,
                border:
                    Border(top: BorderSide(color: DesignColors.divider)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      style: const TextStyle(
                          color: DesignColors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Write a comment…',
                        hintStyle: TextStyle(
                            color: DesignColors.textGray
                                .withValues(alpha: 0.5),
                            fontSize: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: DesignColors.surfaceDefault,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: DesignColors.accent),
                        )
                      : IconButton(
                          onPressed: _submitComment,
                          icon: const Icon(Icons.send,
                              color: DesignColors.accent, size: 22),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// COMMENT TILE
// ─────────────────────────────────────────────────────────────

class _CommentTile extends StatelessWidget {
  final Comment comment;
  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: DesignColors.accent,
            backgroundImage: comment.userAvatar.isNotEmpty
                ? NetworkImage(comment.userAvatar)
                : null,
            child: comment.userAvatar.isEmpty
                ? Text(
                    comment.userName.isNotEmpty
                        ? comment.userName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: DesignColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(comment.userName,
                        style: const TextStyle(
                            color: DesignColors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                    const SizedBox(width: 8),
                    Text(comment.timeAgo,
                        style: TextStyle(
                            color: DesignColors.textGray
                                .withValues(alpha: 0.5),
                            fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(comment.content,
                    style: const TextStyle(
                        color: DesignColors.textLightGray, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TIP DIALOG
// ─────────────────────────────────────────────────────────────

class _TipDialog extends StatefulWidget {
  final Post post;
  final String fromUserId;
  final SocialFeedService feedService;

  const _TipDialog({
    required this.post,
    required this.fromUserId,
    required this.feedService,
  });

  @override
  State<_TipDialog> createState() => _TipDialogState();
}

class _TipDialogState extends State<_TipDialog> {
  int _selectedAmount = 10;
  bool _isSending = false;
  final List<int> _tipAmounts = [5, 10, 25, 50, 100];

  Future<void> _sendTip() async {
    setState(() => _isSending = true);
    final success = await widget.feedService.tipPost(
      postId: widget.post.id,
      fromUserId: widget.fromUserId,
      coinAmount: _selectedAmount,
    );
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success
          ? 'Sent $_selectedAmount coins to ${widget.post.userName}!'
          : 'Failed to send tip. Check your balance.'),
      backgroundColor: success ? DesignColors.success : DesignColors.error,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: DesignColors.surfaceLight,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.monetization_on,
                size: 48, color: DesignColors.gold),
            const SizedBox(height: 12),
            Text('Tip ${widget.post.userName}',
                style: const TextStyle(
                    color: DesignColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              children: _tipAmounts.map((amount) {
                final selected = amount == _selectedAmount;
                return ChoiceChip(
                  label: Text('$amount 🪙'),
                  selected: selected,
                  onSelected: (_) =>
                      setState(() => _selectedAmount = amount),
                  selectedColor: DesignColors.gold,
                  backgroundColor: DesignColors.surfaceDefault,
                  labelStyle: TextStyle(
                    color: selected
                        ? DesignColors.background
                        : DesignColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSending ? null : _sendTip,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignColors.gold,
                  foregroundColor: DesignColors.background,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: DesignColors.background),
                      )
                    : Text('Send $_selectedAmount coins',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
