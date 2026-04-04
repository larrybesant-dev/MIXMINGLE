import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/search_provider.dart';

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
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: post.authorAvatarUrl != null
                      ? CachedNetworkImageProvider(post.authorAvatarUrl!)
                      : null,
                  child: post.authorAvatarUrl == null
                      ? Text(post.authorName[0].toUpperCase())
                      : null,
                ),
                title: Text(post.authorName),
                subtitle: Text(
                  post.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text('${post.likeCount} likes'),
                onTap: () => context.push('/profile/${post.authorId}'),
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
