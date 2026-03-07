/// Following List Page
/// Display list of users that the target user follows
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design_system/design_constants.dart';
import '../../../shared/widgets/club_background.dart';
import '../../../shared/widgets/neon_components.dart';
import '../../../shared/widgets/presence_indicator.dart';
import '../../../shared/providers/social_graph_providers.dart';

/// Following List — Users this user follows
class FollowingListPage extends ConsumerWidget {
  final String userId;
  final String displayName;

  const FollowingListPage({
    super.key,
    required this.userId,
    required this.displayName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followingAsync = ref.watch(followingProfilesProvider(userId));

    return ClubBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: NeonText(
            '${displayName.toUpperCase()} FOLLOWING',
            fontSize: 20,
            fontWeight: FontWeight.w900,
            textColor: DesignColors.white,
            glowColor: DesignColors.accent,
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: followingAsync.when(
          data: (following) {
            if (following.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: following.length,
              itemBuilder: (context, index) {
                final user = following[index];
                return _buildUserCard(context, user);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.white),
                const SizedBox(height: 16),
                const Text(
                  'Error loading following',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, dynamic user) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: NeonGlowCard(
        glowColor: DesignColors.accent,
        onTap: () {
          Navigator.pushNamed(
            context,
            '/profile/user',
            arguments: {'userId': user.id},
          );
        },
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: DesignColors.accent,
                  backgroundImage: user.photos.isNotEmpty ? NetworkImage(user.photos.first) : null,
                  child: user.photos.isEmpty
                      ? Text(
                          (user.displayName.isNotEmpty ? user.displayName[0] : '?').toUpperCase(),
                          style: const TextStyle(
                            color: DesignColors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: PresenceIndicator(userId: user.id, size: 12),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: const TextStyle(
                      color: DesignColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (user.bio != null && user.bio!.isNotEmpty)
                    Text(
                      user.bio!,
                      style: const TextStyle(color: DesignColors.white, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.people, size: 14, color: DesignColors.gold),
                      const SizedBox(width: 4),
                      Text(
                        '${user.followersCount ?? 0} followers',
                        style: const TextStyle(color: DesignColors.gold, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: DesignColors.accent, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search, size: 80, color: DesignColors.accent.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          NeonText(
            'NOT FOLLOWING ANYONE YET',
            fontSize: 18,
            fontWeight: FontWeight.w900,
            textColor: DesignColors.white,
            glowColor: DesignColors.accent,
          ),
        ],
      ),
    );
  }
}
