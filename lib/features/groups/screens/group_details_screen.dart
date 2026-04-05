import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/groups_provider.dart';
import '../../feed/models/post_model.dart';
import '../../feed/widgets/post_card.dart';

class GroupDetailsScreen extends ConsumerWidget {
  final String groupId;
  final String userId;

  const GroupDetailsScreen({
    super.key,
    required this.groupId,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(groupDetailsProvider(groupId));
    final postsAsync = ref.watch(groupPostsProvider(groupId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group'),
      ),
      body: groupAsync.when(
        data: (group) {
          if (group == null) {
            return const Center(child: Text('Group not found'));
          }

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(group.description),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${group.memberCount} members'),
                        if (group.isMember(userId))
                          ElevatedButton(
                            onPressed: () {
                              ref.read(groupsControllerProvider).leaveGroup(
                                    groupId: group.id,
                                    userId: userId,
                                  );
                            },
                            child: const Text('Leave'),
                          )
                        else
                          ElevatedButton(
                            onPressed: () {
                              ref.read(groupsControllerProvider).joinGroup(
                                    groupId: group.id,
                                    userId: userId,
                                  );
                            },
                            child: const Text('Join'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: postsAsync.when(
                  data: (posts) {
                    if (posts.isEmpty) {
                      return const Center(child: Text('No posts in this group'));
                    }
                    return ListView.builder(
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
                            likedBy: post.likedBy,
                            createdAt: post.createdAt,
                          ),
                          currentUserId: userId,
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(child: Text('Error: $error')),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

}

