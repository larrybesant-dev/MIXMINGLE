import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/glow_text.dart';
import '../../shared/widgets/neon_button.dart';
import '../../models/user.dart';
import '../../features/chat/chat_screen.dart';
// Add any other necessary imports for providers and custom widgets

class UserProfilePage extends ConsumerWidget {
  final String userId;
  const UserProfilePage({required this.userId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ...existing code...
    // Insert the main widget tree here, using the code already present
    // (The rest of the file remains unchanged)
  }
}

/* TODO: implement */
          data: (user) {
  /*
   TODO: implement
   */
            data: (user) {
            if (user == null) {
              return const Center(
                child: GlowText(
                  text: 'User not found',
                  fontSize: 18,
                  color: Color(0xFFFF4C4C),
                ),
              );
            }

            return currentUserAsync.when(
              data: (currentUser) {
                final isOwnProfile = currentUser?.id == userId;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Profile Header
                      _buildProfileHeader(user, isOwnProfile, ref),

                      const SizedBox(height: 24),

                      // Stats
                      _buildStats(user),

                      const SizedBox(height: 24),

                      // Bio
                      if (user.bio.isNotEmpty) ...[
                        _buildBioSection(user),
                        const SizedBox(height: 24),
                      ],

                      // Interests
                      if (user.interests.isNotEmpty) ...[
                        _buildInterestsSection(user),
                        const SizedBox(height: 24),
                      ],

                      // Social Links
                      if (user.socialLinks.isNotEmpty) ...[
                        _buildSocialLinksSection(user),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF4C4C)),
                ),
              ),
              error: (error, stack) => const Center(
                child: GlowText(
                  text: 'Error loading profile',
                  fontSize: 18,
                  color: Color(0xFFFF4C4C),
                ),
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF4C4C)),
            ),
          ),
          error: (error, stack) => const Center(
            child: GlowText(
              text: 'Error loading user',
              fontSize: 18,
              color: Color(0xFFFF4C4C),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(User user, bool isOwnProfile, WidgetRef ref) {
    // Determine relationship type for label
    final currentUser = ref.watch(currentUserProvider).value;
    String? relationshipLabel;
    IconData? relationshipIcon;
    if (currentUser != null && currentUser.id != user.id) {
      // Default to Follower label for non-own profile
      relationshipLabel = 'Follower';
      relationshipIcon = Icons.group;
    }

    return Column(
      children: [
        // Avatar
        Container(
          width: 120,
          height: 120,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
    // ...existing code...
                  Icons.person,
                  color: Colors.white,
                  size: 60,
                ),
        ),

        const SizedBox(height: 16),

        // Name and Username with relationship label
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GlowText(
              text: user.displayName ?? 'Unknown User',
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              glowColor: const Color(0xFFFF4C4C),
            ),
            if (relationshipLabel != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: relationshipLabel == 'Friend' ? Colors.blueAccent.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(relationshipIcon, size: 16, color: relationshipLabel == 'Friend' ? Colors.blueAccent : Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      relationshipLabel,
                      style: TextStyle(
                        color: relationshipLabel == 'Friend' ? Colors.blueAccent : Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),

        Text(
          '@${user.username}',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 16,
          ),
        ),

        const SizedBox(height: 16),

        // Follow Button (only show if not own profile)
        if (!isOwnProfile) _buildFollowButton(user, ref),
      ],
    );
  }

  Widget _buildFollowButton(User user, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final isFollowingAsync = ref.watch(isFollowingProvider({
      'followerId': currentUser.value?.id ?? '',
      'followingId': user.id,
    }));
    final feedbackNotifier = ref.watch(_followFeedbackProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Follow Button with feedback
        Expanded(
          child: isFollowingAsync.when(
            data: (isFollowing) => AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: feedbackNotifier.status == null
                    ? Colors.transparent
                    : (feedbackNotifier.status == 'Following'
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  NeonButton(
                    onPressed: () async {
                      if (isFollowing) {
                        await ref.read(unfollowUserProvider(user.id).future);
                        feedbackNotifier.show('Unfollowed');
                      } else {
                        await ref.read(followUserProvider(user.id).future);
                        feedbackNotifier.show('Following');
                      }
                    },
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text(
                      isFollowing ? 'Following' : 'Follow',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  if (feedbackNotifier.status != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        feedbackNotifier.status!,
                        style: TextStyle(
                          color: feedbackNotifier.status == 'Following' ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            loading: () => const SizedBox(
              width: 80,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF4C4C)),
              ),
            ),
            error: (error, stack) => NeonButton(
              onPressed: () {
                ref.read(followUserProvider(user.id).future);
              },
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: const Text(
                'Follow',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Message Button
        Expanded(
          child: NeonButton(
            // (Removed misplaced provider code)
            onPressed: () => _startConversation(user, ref),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: const Text(
              'Message',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  void _startConversation(User user, WidgetRef ref) {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser != null) {
      Navigator.push(
        ref.context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            currentUser: currentUser,
            otherUser: user,
          ),
        ),
      );
    }
  }

  Widget _buildStats(User user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem('${user.followersCount}', 'Followers'),
        _buildStatItem('${user.followingCount}', 'Following'),
        _buildStatItem('${user.liveSessionsHosted}', 'Sessions'),
        _buildStatItem('${user.totalTipsReceived}', 'Tips'),
      ],
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        GlowText(
          text: value,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: const Color(0xFFFFD700),
          glowColor: const Color(0xFFFF4C4C),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildBioSection(User user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFF4C4C).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GlowText(
            text: 'About',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFFD700),
            glowColor: Color(0xFFFF4C4C),
          ),
          const SizedBox(height: 8),
          Text(
            user.bio,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsSection(User user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFF4C4C).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GlowText(
            text: 'Interests',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFFD700),
            glowColor: Color(0xFFFF4C4C),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: user.interests.map((interest) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4C4C).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFF4C4C),
                    width: 1,
                  ),
                ),
                child: Text(
                  interest,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLinksSection(User user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFF4C4C).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GlowText(
            text: 'Social Links',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFFD700),
            glowColor: Color(0xFFFF4C4C),
          ),
          const SizedBox(height: 12),
          ...user.socialLinks.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(
                    '${entry.key}: ',
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    entry.value,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
  /*
   End of user_profile_page.dart
   */
}
