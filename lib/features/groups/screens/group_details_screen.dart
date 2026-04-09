import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/groups_provider.dart';
import '../../feed/models/post_model.dart';
import '../../feed/widgets/post_card.dart';
import '../../../core/theme.dart';

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
      backgroundColor: VelvetNoir.surface,
      appBar: AppBar(
        backgroundColor: VelvetNoir.surface,
        title: groupAsync.whenOrNull(
              data: (g) => g == null
                  ? null
                  : Text(
                      g.name,
                      style: const TextStyle(
                        color: VelvetNoir.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
            ) ??
            const Text(
              'Group',
              style: TextStyle(
                  color: VelvetNoir.onSurface, fontWeight: FontWeight.w700),
            ),
      ),
      body: groupAsync.when(
        data: (group) {
          if (group == null) {
            return const Center(
              child: Text('Group not found',
                  style: TextStyle(color: VelvetNoir.onSurfaceVariant)),
            );
          }

          final isMember = group.isMember(userId);

          return Column(
            children: [
              // Group header banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                color: VelvetNoir.surfaceContainer,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: const TextStyle(
                        color: VelvetNoir.onSurface,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (group.description.isNotEmpty) ...
                      [
                        const SizedBox(height: 6),
                        Text(
                          group.description,
                          style: const TextStyle(
                            color: VelvetNoir.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(Icons.people_outline,
                            color: VelvetNoir.onSurfaceVariant, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${group.memberCount} members',
                          style: const TextStyle(
                            color: VelvetNoir.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () {
                            if (isMember) {
                              ref
                                  .read(groupsControllerProvider)
                                  .leaveGroup(
                                    groupId: group.id,
                                    userId: userId,
                                  );
                            } else {
                              ref
                                  .read(groupsControllerProvider)
                                  .joinGroup(
                                    groupId: group.id,
                                    userId: userId,
                                  );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isMember
                                ? VelvetNoir.surfaceBright
                                : VelvetNoir.primaryDim,
                            foregroundColor: VelvetNoir.onSurface,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(isMember ? 'Leave' : 'Join Group'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Divider(
                  height: 1,
                  color: VelvetNoir.outlineVariant.withValues(alpha: 0.5)),
              // Posts section label
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Posts',
                    style: TextStyle(
                      color: VelvetNoir.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              // Posts list
              Expanded(
                child: postsAsync.when(
                  data: (posts) {
                    if (posts.isEmpty) {
                      return const Center(
                        child: Text('No posts in this group yet',
                            style: TextStyle(
                                color: VelvetNoir.onSurfaceVariant)),
                      );
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
                  loading: () => const Center(
                      child: CircularProgressIndicator(
                          color: VelvetNoir.primary)),
                  error: (e, _) => const Center(
                    child: Text('Could not load posts',
                        style:
                            TextStyle(color: VelvetNoir.onSurfaceVariant)),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: VelvetNoir.primary)),
        error: (e, _) => const Center(
          child: Text('Could not load group',
              style: TextStyle(color: VelvetNoir.onSurfaceVariant)),
        ),
      ),
    );
  }
}

