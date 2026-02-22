/// Followers List Page
/// Display list of users who follow the target user
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design_system/design_constants.dart';
import '../../../shared/widgets/club_background.dart';
import '../../../shared/widgets/neon_components.dart';
import '../../../shared/widgets/presence_indicator.dart';
import '../../../providers/social_graph_providers.dart';

/// Followers List - Users who follow this user
class FollowersListPage extends ConsumerWidget {
  final String userId;
  final String displayName;

  const FollowersListPage({
    super.key,
    required this.userId,
    required this.displayName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followersAsync = ref.watch(followerProfilesProvider(userId));

    return ClubBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: NeonText(
            '${displayName.toUpperCase()}\'S FOLLOWERS',
            fontSize: 20,
            fontWeight: FontWeight.w900,
            textColor: DesignColors.white,
            glowColor: DesignColors.accent,
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: followersAsync.when(
          data: (followers) {
            if (followers.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: followers.length,
              itemBuilder: (context, index) {
                final follower = followers[index];
                return _buildFollowerCard(context, ref, follower);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: DesignColors.white.withValues(alpha: 255, red: 255, green: 255, blue: 255),
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading followers',
                  style: TextStyle(
                    color: DesignColors.white.withValues(alpha: 255, red: 255, green: 255, blue: 255),
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: TextStyle(
                    color: DesignColors.white.withValues(alpha: 255, red: 255, green: 255, blue: 255),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFollowerCard(BuildContext context, WidgetRef ref, dynamic follower) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: NeonGlowCard(
        glowColor: DesignColors.accent,
        onTap: () {
          Navigator.pushNamed(
            context,
            '/profile',
            arguments: follower.id,
          );
        },
        child: Row(
          children: [
            // Avatar with presence
            Stack(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: DesignColors.accent.withValues(alpha: 255, red: 255, green: 255, blue: 255),
                  backgroundImage:
                      follower.photos.isNotEmpty ? NetworkImage(follower.photos.first) : null,
                  child: follower.photos.isEmpty
                      ? Text(
                          follower.displayName[0].toUpperCase(),
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
                  child: PresenceIndicator(
                    userId: follower.id,
                    size: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),

            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    follower.displayName,
                    style: const TextStyle(
                      color: DesignColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (follower.bio != null && follower.bio!.isNotEmpty)
                    Text(
                      follower.bio!,
                      style: TextStyle(
                        color: DesignColors.white.withValues(alpha: 255, red: 255, green: 255, blue: 255),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: 14,
                        color: DesignColors.gold,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${follower.followersCount ?? 0} followers',
                        style: TextStyle(
                          color: DesignColors.gold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Follow button
            Icon(
              Icons.arrow_forward_ios,
              color: DesignColors.accent,
              size: 20,
            ),
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
          Icon(
            Icons.people_outline,
            size: 80,
            color: DesignColors.white.withValues(alpha: 255, red: 255, green: 255, blue: 255),
          ),
          const SizedBox(height: 16),
          Text(
            'No followers yet',
            style: TextStyle(
              color: DesignColors.white.withValues(alpha: 255, red: 255, green: 255, blue: 255),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'When someone follows this user,\nthey\'ll appear here',
            style: TextStyle(
              color: DesignColors.white,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
