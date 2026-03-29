import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mixvy/models/moderation_model.dart';
import 'package:mixvy/services/follow_service.dart';
import 'package:mixvy/services/moderation_service.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/follow_button.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final ModerationService _moderationService = ModerationService();
  final FollowService _followService = FollowService();
  late Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  @override
  void didUpdateWidget(covariant UserProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _profileFuture = _loadProfile();
    }
  }

  void _refreshProfile() {
    setState(() {
      _profileFuture = _loadProfile();
    });
  }

  Future<Map<String, dynamic>> _loadProfile() async {
    final firestore = FirebaseFirestore.instance;
    final userRef = firestore.collection('users').doc(widget.userId);
    final privacyRef = userRef.collection('privacy').doc('settings');
    final userSnapshot = await userRef.get();
    final privacySnapshot = await privacyRef.get();

    var isBlocked = false;
    var isFollowing = false;
    var followerCount = 0;
    var followingCount = 0;
    final viewerId = FirebaseAuth.instance.currentUser?.uid;
    if (viewerId != null && viewerId != widget.userId) {
      try {
        isBlocked = await _moderationService.isBlocked(widget.userId);
        isFollowing = await _followService.isFollowing(viewerId, widget.userId);
      } catch (_) {
        isBlocked = false;
        isFollowing = false;
      }
    }

    try {
      followerCount = await _followService.followerCount(widget.userId);
      followingCount = await _followService.followingCount(widget.userId);
    } catch (_) {
      followerCount = 0;
      followingCount = 0;
    }

    return {
      'user': userSnapshot,
      'privacy': privacySnapshot.data() ?? const <String, dynamic>{},
      'isBlocked': isBlocked,
      'isFollowing': isFollowing,
      'followerCount': followerCount,
      'followingCount': followingCount,
    };
  }

  Future<void> _toggleFollow(bool currentlyFollowing) async {
    try {
      if (currentlyFollowing) {
        await _followService.unfollowUser(widget.userId);
      } else {
        await _followService.followUser(widget.userId);
      }
      if (!mounted) return;
      _refreshProfile();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(currentlyFollowing ? 'Unfollowed user.' : 'Now following user.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update follow status: $e')),
      );
    }
  }

  Future<void> _inviteToLiveRoom() async {
    try {
      await _followService.inviteUserToHostedRoom(widget.userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Live room invite sent.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not send invite: $e')),
      );
    }
  }

  Future<void> _toggleBlock(bool currentlyBlocked) async {
    try {
      if (currentlyBlocked) {
        await _moderationService.unblockUser(widget.userId);
      } else {
        await _moderationService.blockUser(widget.userId);
      }
      if (!mounted) return;
      _refreshProfile();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(currentlyBlocked ? 'User unblocked.' : 'User blocked.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update block status: $e')),
      );
    }
  }

  Future<void> _reportUser() async {
    final reasonController = TextEditingController();
    final detailsController = TextEditingController();

    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Report user'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(labelText: 'Reason'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: detailsController,
                decoration: const InputDecoration(labelText: 'Details'),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );

    if (submitted != true) {
      return;
    }

    try {
      await _moderationService.reportTarget(
        targetId: widget.userId,
        targetType: ReportTargetType.user,
        reason: reasonController.text.trim().isEmpty ? 'Profile review requested' : reasonController.text.trim(),
        details: detailsController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not submit report: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final payload = snapshot.data;
          if (payload == null) {
            return const Center(child: Text('User not found.'));
          }

          final userSnapshot = payload['user'] as DocumentSnapshot<Map<String, dynamic>>;
          if (!userSnapshot.exists) {
            return const Center(child: Text('User not found.'));
          }

          final data = userSnapshot.data() ?? const <String, dynamic>{};
          final privacy = Map<String, dynamic>.from(payload['privacy'] as Map<String, dynamic>? ?? const <String, dynamic>{});
          final isBlocked = payload['isBlocked'] as bool? ?? false;
          final isFollowing = payload['isFollowing'] as bool? ?? false;
          final followerCount = payload['followerCount'] as int? ?? 0;
          final followingCount = payload['followingCount'] as int? ?? 0;
          final viewerId = FirebaseAuth.instance.currentUser?.uid;
          final isOwnProfile = viewerId == widget.userId;

          final username = (data['username'] as String?)?.trim();
          final avatarUrl = (data['avatarUrl'] as String?)?.trim();
          final coverPhotoUrl = (data['coverPhotoUrl'] as String?)?.trim();
          final bio = (data['bio'] as String?)?.trim();
          final aboutMe = (data['aboutMe'] as String?)?.trim();
          final introVideoUrl = (data['introVideoUrl'] as String?)?.trim();
          final galleryUrls = List<String>.from(data['galleryUrls'] ?? const []);
          final vibePrompt = (data['vibePrompt'] as String?)?.trim();
          final firstDatePrompt = (data['firstDatePrompt'] as String?)?.trim();
          final musicTastePrompt = (data['musicTastePrompt'] as String?)?.trim();
          final interests = List<String>.from(data['interests'] ?? const []);
          final age = (data['age'] as num?)?.toInt();
          final gender = (data['gender'] as String?)?.trim();
          final location = (data['location'] as String?)?.trim();
          final relationshipStatus = (data['relationshipStatus'] as String?)?.trim();
          final camViewPolicy = (data['camViewPolicy'] as String?)?.trim();
          final themeId = (data['themeId'] as String?)?.trim();
          final coverImageUrl = (coverPhotoUrl ?? '').isNotEmpty
              ? coverPhotoUrl!.trim()
              : (galleryUrls.isNotEmpty ? galleryUrls.first.trim() : (avatarUrl ?? '').trim());
          final displayName = (username == null || username.isEmpty) ? 'MixVy user' : username;

          final details = <String>[];
          if (isOwnProfile || (privacy['showAge'] as bool? ?? false)) {
            if (age != null) details.add('$age');
          }
          if (isOwnProfile || (privacy['showGender'] as bool? ?? false)) {
            if ((gender ?? '').isNotEmpty) details.add(gender!);
          }
          if (isOwnProfile || (privacy['showLocation'] as bool? ?? false)) {
            if ((location ?? '').isNotEmpty) details.add(location!);
          }
          if (isOwnProfile || (privacy['showRelationshipStatus'] as bool? ?? false)) {
            if ((relationshipStatus ?? '').isNotEmpty) details.add(relationshipStatus!);
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.85),
                      Theme.of(context).colorScheme.secondary.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    if (coverImageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Opacity(
                          opacity: 0.22,
                          child: Image.network(
                            coverImageUrl,
                            height: 240,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const SizedBox(height: 240),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 44,
                            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: (avatarUrl != null && avatarUrl.isNotEmpty)
                                ? ClipOval(
                                    child: Image.network(
                                      avatarUrl,
                                      width: 88,
                                      height: 88,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Center(
                                          child: SizedBox(
                                            width: 44,
                                            height: 44,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.primary),
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 34),
                                    ),
                                  )
                                : const Icon(Icons.person, size: 34),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            displayName,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            details.isEmpty ? 'Live social creator' : details.join(' • '),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              if ((themeId ?? '').isNotEmpty)
                                _MiniBadge(label: themeId!, icon: Icons.palette_outlined),
                              if ((camViewPolicy ?? '').isNotEmpty)
                                _MiniBadge(label: camViewPolicy!, icon: Icons.videocam_outlined),
                              if (interests.isNotEmpty)
                                _MiniBadge(label: interests.first, icon: Icons.local_fire_department_rounded),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (!isOwnProfile)
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _inviteToLiveRoom,
                        icon: const Icon(Icons.mic),
                        label: const Text('Invite'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FollowButton(
                        isFollowing: isFollowing,
                        onPressed: () => _toggleFollow(isFollowing),
                      ),
                    ),
                  ],
                ),
              if (!isOwnProfile) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _toggleBlock(isBlocked),
                        icon: Icon(isBlocked ? Icons.lock_open_rounded : Icons.block_outlined),
                        label: Text(isBlocked ? 'Unblock' : 'Block'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _reportUser,
                        icon: const Icon(Icons.flag_outlined),
                        label: const Text('Report'),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _PublicStatTile(label: 'Followers', value: '$followerCount'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PublicStatTile(label: 'Following', value: '$followingCount'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PublicStatTile(label: 'Interests', value: '${interests.length}'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (bio != null && bio.isNotEmpty) ...[
                Text('Bio', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(bio, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 18),
              ],
              if (aboutMe != null && aboutMe.isNotEmpty) ...[
                Text('About Me', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(aboutMe, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 18),
              ],
              if ((vibePrompt ?? '').isNotEmpty || (firstDatePrompt ?? '').isNotEmpty || (musicTastePrompt ?? '').isNotEmpty) ...[
                Text('Conversation Starters', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                if ((vibePrompt ?? '').isNotEmpty)
                  _PromptCard(title: 'Tonight vibe', content: vibePrompt!),
                if ((firstDatePrompt ?? '').isNotEmpty)
                  _PromptCard(title: 'First date move', content: firstDatePrompt!),
                if ((musicTastePrompt ?? '').isNotEmpty)
                  _PromptCard(title: 'Music in rotation', content: musicTastePrompt!),
                const SizedBox(height: 18),
              ],
              if (introVideoUrl != null && introVideoUrl.isNotEmpty) ...[
                Text('Intro Video', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.play_circle_fill_rounded),
                      const SizedBox(width: 10),
                      const Expanded(child: Text('Intro video available')),
                      TextButton(
                        onPressed: () async {
                          final uri = Uri.tryParse(introVideoUrl);
                          if (uri == null) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Invalid intro video URL.')),
                            );
                            return;
                          }

                          final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
                          if (!opened && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Could not open intro video.')),
                            );
                          }
                        },
                        child: const Text('Open'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],
              if (galleryUrls.isNotEmpty) ...[
                Text('Photo Gallery', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 110,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: galleryUrls.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final url = galleryUrls[index].trim();
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 110,
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: Image.network(
                            url,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
              ],
              if (interests.isNotEmpty) ...[
                Text('Interests', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: interests
                      .take(12)
                      .map((interest) => Chip(label: Text(interest), side: BorderSide.none))
                      .toList(),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;
  final IconData icon;

  const _MiniBadge({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  final String title;
  final String content;

  const _PromptCard({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(content),
        ],
      ),
    );
  }
}

class _PublicStatTile extends StatelessWidget {
  final String label;
  final String value;

  const _PublicStatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
