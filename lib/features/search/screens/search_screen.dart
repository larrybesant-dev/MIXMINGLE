import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/search_provider.dart';
import '../../feed/models/post_model.dart';
import '../../feed/widgets/post_card.dart';
import '../../follow/providers/follow_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late TextEditingController _searchController;
  String _searchQuery = '';
  int _selectedTab = 0; // 0: People, 1: Posts, 2: Hashtags

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search people, posts, #hashtags...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          if (_searchQuery.isEmpty)
            Expanded(
              child: _buildTrendingContent(),
            )
          else
            Expanded(
              child: Column(
                children: [
                  TabBar(
                    tabs: const [
                      Tab(text: 'People'),
                      Tab(text: 'Posts'),
                      Tab(text: 'Hashtags'),
                    ],
                    onTap: (index) {
                      setState(() => _selectedTab = index);
                    },
                  ),
                  Expanded(
                    child: _buildSearchResults(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTrendingContent() {
    final trendingAsync = ref.watch(trendingHashtagsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trending Now',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          trendingAsync.when(
            data: (hashtags) {
              if (hashtags.isEmpty) {
                return const Text('No trending hashtags yet');
              }
              return Column(
                children: hashtags.map((tag) {
                  return ListTile(
                    leading: const Icon(Icons.tag),
                    title: Text('#${tag.hashtag}'),
                    subtitle: Text('${tag.postCount} posts'),
                    onTap: () {
                      _searchController.text = '#${tag.hashtag}';
                      setState(() => _searchQuery = '#${tag.hashtag}');
                    },
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text('Error loading trending: $error'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_selectedTab == 0) {
      final usersAsync = ref.watch(searchUsersProvider(_searchQuery));
      return usersAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return const Center(child: Text('No users found'));
          }
          return ListView.separated(
            itemCount: users.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: user.avatarUrl != null
                      ? CachedNetworkImageProvider(user.avatarUrl!)
                      : null,
                  child: user.avatarUrl == null
                      ? Text(user.username[0].toUpperCase())
                      : null,
                ),
                title: Row(
                  children: [
                    Text(user.username),
                    if (user.isVerified)
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(Icons.verified, size: 16, color: Colors.blue),
                      ),
                  ],
                ),
                subtitle: Text('${user.followerCount} followers'),
                trailing: _FollowButton(targetUserId: user.id),
                onTap: () => context.push('/profile/${user.id}'),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      );
    } else if (_selectedTab == 1) {
      final postsAsync = ref.watch(searchPostsProvider(_searchQuery));
      return postsAsync.when(
        data: (posts) {
          if (posts.isEmpty) {
            return const Center(child: Text('No posts found'));
          }
          return ListView.separated(
            itemCount: posts.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
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
    } else {
      final hashtagsAsync = ref.watch(searchHashtagsProvider(_searchQuery));
      return hashtagsAsync.when(
        data: (hashtags) {
          if (hashtags.isEmpty) {
            return const Center(child: Text('No hashtags found'));
          }
          return ListView.separated(
            itemCount: hashtags.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final tag = hashtags[index];
              return ListTile(
                leading: const Icon(Icons.tag),
                title: Text('#${tag.hashtag}'),
                subtitle: Text('${tag.postCount} posts'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Navigate to hashtag feed
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      );
    }
  }
}

class _FollowButton extends ConsumerStatefulWidget {
  final String targetUserId;
  const _FollowButton({required this.targetUserId});

  @override
  ConsumerState<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends ConsumerState<_FollowButton> {
  bool? _optimisticFollowing;

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (currentUid.isEmpty || currentUid == widget.targetUserId) {
      return const SizedBox.shrink();
    }

    final isFollowingAsync = ref.watch(
      isFollowingProvider((currentUserId: currentUid, targetUserId: widget.targetUserId)),
    );

    final isFollowing = _optimisticFollowing ?? isFollowingAsync.valueOrNull ?? false;

    return TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        minimumSize: const Size(72, 32),
      ),
      onPressed: () async {
        setState(() => _optimisticFollowing = !isFollowing);
        final controller = ref.read(followControllerProvider);
        try {
          if (isFollowing) {
            await controller.unfollowUser(
              currentUserId: currentUid,
              targetUserId: widget.targetUserId,
            );
          } else {
            await controller.followUser(
              currentUserId: currentUid,
              targetUserId: widget.targetUserId,
              targetUsername: '',
            );
          }
        } catch (_) {
          if (mounted) setState(() => _optimisticFollowing = isFollowing);
        }
      },
      child: Text(isFollowing ? 'Following' : 'Follow'),
    );
  }
}
