import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mixvy/models/moderation_model.dart';
import 'package:mixvy/services/follow_service.dart';
import 'package:mixvy/services/friend_service.dart';
import 'package:mixvy/services/moderation_service.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/layout/app_layout.dart';
import '../../core/theme.dart';
import '../../shared/widgets/app_page_scaffold.dart';
import '../../shared/widgets/async_state_view.dart';
import '../../widgets/brand_ui_kit.dart';
import '../../widgets/follow_button.dart';
import '../../widgets/gift_picker_sheet.dart';
import '../../features/messaging/providers/messaging_provider.dart';
import '../../features/feed/models/post_model.dart';
import '../../features/feed/widgets/post_card.dart';
import '../../presentation/providers/friend_provider.dart';
import '../../presentation/providers/user_provider.dart';
import 'widgets/profile_music_player_stub.dart'
    if (dart.library.html) 'widgets/profile_music_player_web.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  final ModerationService _moderationService = ModerationService();
  final FollowService _followService = FollowService();
  final FriendService _friendService = FriendService();
  late Future<Map<String, dynamic>> _profileFuture;
  late TabController _tabController;
  bool _sendingFriendRequest = false;

  Color? _hexColorOrNull(String hex) {
    final clean = hex.replaceFirst('#', '');
    try {
      return Color(int.parse(clean.length == 6 ? 'FF$clean' : clean, radix: 16));
    } catch (_) {
      return null;
    }
  }

  String? _stringOrNull(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final normalized = value.trim();
      return normalized.isEmpty ? null : normalized;
    }
    final normalized = value.toString().trim();
    return normalized.isEmpty ? null : normalized;
  }

  List<String> _stringList(dynamic value) {
    if (value is! List) {
      return const <String>[];
    }
    return value
        .map((entry) => _stringOrNull(entry))
        .whereType<String>()
        .toList(growable: false);
  }

  bool _asBool(dynamic value, {required bool fallback}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
        return true;
      }
      if (normalized == 'false' || normalized == '0' || normalized == 'no') {
        return false;
      }
    }
    return fallback;
  }

  int _asInt(dynamic value, {required int fallback}) {
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
    final userSnapshot = await userRef.get();
    final viewerId = FirebaseAuth.instance.currentUser?.uid;
    Map<String, dynamic> privacyData = const <String, dynamic>{};
    if (viewerId == widget.userId) {
      final privacySnapshot =
          await userRef.collection('privacy').doc('settings').get();
      privacyData = privacySnapshot.data() ?? const <String, dynamic>{};
    }

    var isBlocked = false;
    var isFollowing = false;
    var followerCount = 0;
    var followingCount = 0;
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
      'privacy': privacyData,
      'isBlocked': isBlocked,
      'isFollowing': isFollowing,
      'followerCount': followerCount,
      'followingCount': followingCount,
    };
  }

  Future<void> _sendFriendRequest() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.uid == widget.userId) {
      return;
    }
    setState(() => _sendingFriendRequest = true);
    try {
      await _friendService.sendFriendRequest(currentUser.uid, widget.userId);
      ref.invalidate(pendingOutgoingFriendRequestIdsProvider);
      ref.invalidate(currentFriendIdsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend request sent.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not send friend request: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _sendingFriendRequest = false);
      }
    }
  }

  Future<void> _startConversation(String peerName, String? peerAvatarUrl) async {
    final currentUser = ref.read(userProvider);
    if (currentUser == null || currentUser.id == widget.userId) {
      return;
    }
    try {
      final conversationId = await ref
          .read(messagingControllerProvider)
          .createDirectConversation(
            userId1: currentUser.id,
            user1Name: currentUser.username,
            user1AvatarUrl: currentUser.avatarUrl,
            userId2: widget.userId,
            user2Name: peerName,
            user2AvatarUrl: peerAvatarUrl,
          );
      if (!mounted) return;
      context.go('/messages/$conversationId');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open conversation: $e')),
      );
    }
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
    final friendIds =
      ref.watch(currentFriendIdsProvider).valueOrNull ?? const <String>[];
    final pendingIds = ref
        .watch(pendingOutgoingFriendRequestIdsProvider)
        .valueOrNull ??
      const <String>{};
    final isFriend = friendIds.contains(widget.userId);
    final isRequestPending = pendingIds.contains(widget.userId);
    return AppPageScaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Profile',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: VelvetNoir.onSurface,
              ),
            ),
            Text(
              'Identity, chemistry, and receipts.',
              style: GoogleFonts.raleway(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: VelvetNoir.onSurfaceVariant,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'About'),
            Tab(text: 'Posts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── About tab ──────────────────────────────────────────────────
          FutureBuilder<Map<String, dynamic>>(
            future: _profileFuture,
            builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingView(label: 'Loading profile');
          }
          final payload = snapshot.data;
          if (payload == null) {
            return const AppEmptyView(title: 'User not found');
          }

          final userSnapshot = payload['user'] as DocumentSnapshot<Map<String, dynamic>>;
          if (!userSnapshot.exists) {
            return const AppEmptyView(title: 'User not found');
          }

          final data = userSnapshot.data() ?? const <String, dynamic>{};
          final privacy = Map<String, dynamic>.from(payload['privacy'] as Map<String, dynamic>? ?? const <String, dynamic>{});
          final isBlocked = _asBool(payload['isBlocked'], fallback: false);
          final isFollowing = _asBool(payload['isFollowing'], fallback: false);
          final followerCount = _asInt(payload['followerCount'], fallback: 0);
          final followingCount = _asInt(payload['followingCount'], fallback: 0);
          final viewerId = FirebaseAuth.instance.currentUser?.uid;
          final isOwnProfile = viewerId == widget.userId;

          final username = _stringOrNull(data['username']);
          final avatarUrl = _stringOrNull(data['avatarUrl']);
          final coverPhotoUrl = _stringOrNull(data['coverPhotoUrl']);
          final bio = _stringOrNull(data['bio']);
          final aboutMe = _stringOrNull(data['aboutMe']);
          final introVideoUrl = _stringOrNull(data['introVideoUrl']);
          final galleryUrls = _stringList(data['galleryUrls']);
          final vibePrompt = _stringOrNull(data['vibePrompt']);
          final firstDatePrompt = _stringOrNull(data['firstDatePrompt']);
          final musicTastePrompt = _stringOrNull(data['musicTastePrompt']);
          final interests = _stringList(data['interests']);
          final age = (data['age'] as num?)?.toInt();
          final gender = _stringOrNull(data['gender']);
          final location = _stringOrNull(data['location']);
          final relationshipStatus = _stringOrNull(data['relationshipStatus']);
          final camViewPolicy = _stringOrNull(data['camViewPolicy']);
          final themeId = _stringOrNull(data['themeId']);
          // Profile personalisation
          final profileAccentColor = _stringOrNull(data['profileAccentColor']);
          final profileBgGradientStart = _stringOrNull(data['profileBgGradientStart']);
          final profileBgGradientEnd = _stringOrNull(data['profileBgGradientEnd']);
          final profileMusicUrl = _stringOrNull(data['profileMusicUrl']);
          final profileMusicTitle = _stringOrNull(data['profileMusicTitle']) ?? '';
          final accentColor = profileAccentColor != null
              ? _hexColorOrNull(profileAccentColor)
              : null;
          final coverImageUrl = (coverPhotoUrl ?? '').isNotEmpty
              ? coverPhotoUrl!.trim()
              : (galleryUrls.isNotEmpty ? galleryUrls.first.trim() : (avatarUrl ?? '').trim());
          final displayName = (username == null || username.isEmpty) ? 'MixVy user' : username;

          final details = <String>[];
          if (isOwnProfile || _asBool(privacy['showAge'], fallback: false)) {
            if (age != null) details.add('$age');
          }
          if (isOwnProfile || _asBool(privacy['showGender'], fallback: false)) {
            if ((gender ?? '').isNotEmpty) details.add(gender!);
          }
          if (isOwnProfile || _asBool(privacy['showLocation'], fallback: false)) {
            if ((location ?? '').isNotEmpty) details.add(location!);
          }
          if (isOwnProfile || _asBool(privacy['showRelationshipStatus'], fallback: false)) {
            if ((relationshipStatus ?? '').isNotEmpty) details.add(relationshipStatus!);
          }

          return ListView(
            padding: EdgeInsets.fromLTRB(
              context.pageHorizontalPadding,
              16,
              context.pageHorizontalPadding,
              32,
            ),
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    colors: (profileBgGradientStart != null && profileBgGradientEnd != null)
                        ? [
                            _hexColorOrNull(profileBgGradientStart) ??
                                Theme.of(context).colorScheme.primary.withValues(alpha: 0.85),
                            _hexColorOrNull(profileBgGradientEnd) ??
                                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.8),
                          ]
                        : [
                            Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
                            const Color(0xFF781E2B).withValues(alpha: 0.6),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: VelvetNoir.primary.withValues(alpha: 0.18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    if (coverImageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Opacity(
                          opacity: 0.26,
                          child: CachedNetworkImage(
                            imageUrl: coverImageUrl,
                            height: 320,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => const SizedBox(height: 320),
                          ),
                        ),
                      ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.08),
                              Colors.black.withValues(alpha: 0.42),
                              Colors.black.withValues(alpha: 0.72),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MixvyGoldAvatar(
                                imageUrl: avatarUrl,
                                fallbackInitial: displayName,
                                radius: 42,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayName,
                                      style: GoogleFonts.playfairDisplay(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                        color: accentColor ?? VelvetNoir.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      details.isEmpty ? 'Live social creator' : details.join(' • '),
                                      style: GoogleFonts.raleway(
                                        color: Colors.white.withValues(alpha: 0.84),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
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
                          if ((bio ?? '').isNotEmpty) ...[
                            const SizedBox(height: 18),
                            Text(
                              bio!,
                              style: GoogleFonts.raleway(
                                color: Colors.white.withValues(alpha: 0.90),
                                fontSize: 15,
                                height: 1.45,
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _PublicStatTile(label: 'Followers', value: '$followerCount'),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _PublicStatTile(label: 'Following', value: '$followingCount'),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _PublicStatTile(label: 'Interests', value: '${interests.length}'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (!isOwnProfile)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            (isFriend || isRequestPending || _sendingFriendRequest)
                                ? null
                                : _sendFriendRequest,
                        icon: Icon(
                          isFriend
                              ? Icons.check_circle_outline
                              : isRequestPending
                                  ? Icons.schedule_rounded
                                  : Icons.person_add_alt_1_outlined,
                        ),
                        label: Text(
                          isFriend
                              ? 'Already Friends'
                              : isRequestPending
                                  ? 'Request Sent'
                                  : (_sendingFriendRequest
                                      ? 'Sending...'
                                      : 'Add Friend'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _startConversation(displayName, avatarUrl),
                        icon: const Icon(Icons.message_outlined),
                        label: const Text('Message'),
                      ),
                    ),
                  ],
                ),
              if (!isOwnProfile) ...[
                const SizedBox(height: 10),
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
                const SizedBox(height: 10),
                Consumer(
                  builder: (consumerCtx, widgetRef, _) => SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => GiftPickerSheet.show(
                        consumerCtx,
                        widgetRef,
                        recipientId: widget.userId,
                        recipientName: displayName,
                      ),
                      icon: const Icon(Icons.card_giftcard),
                      label: const Text('Send Gift'),
                    ),
                  ),
                ),
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
              if (isOwnProfile) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => context.push('/edit-profile'),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit Profile'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(
                          text: 'https://mixvy.app/profile/${widget.userId}',
                        ));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profile link copied!')),
                        );
                      },
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('Share'),
                    ),
                  ],
                ),
              ],
              if (aboutMe != null && aboutMe.isNotEmpty) ...[
                const SizedBox(height: 18),
                const MixvySectionHeader(
                  title: 'About',
                  padding: EdgeInsets.fromLTRB(0, 0, 0, 10),
                ),
                _ProfileSectionCard(
                  child: Text(aboutMe, style: Theme.of(context).textTheme.bodyMedium),
                ),
              ],
              if ((profileMusicUrl ?? '').isNotEmpty) ...[
                const SizedBox(height: 18),
                const MixvySectionHeader(
                  title: 'Profile Music',
                  padding: EdgeInsets.fromLTRB(0, 0, 0, 10),
                ),
                _ProfileSectionCard(
                  child: ProfileMusicPlayer(
                    musicUrl: profileMusicUrl!,
                    musicTitle: profileMusicTitle,
                  ),
                ),
              ],
              if ((vibePrompt ?? '').isNotEmpty || (firstDatePrompt ?? '').isNotEmpty || (musicTastePrompt ?? '').isNotEmpty) ...[
                const SizedBox(height: 18),
                const MixvySectionHeader(
                  title: 'Conversation Starters',
                  padding: EdgeInsets.fromLTRB(0, 0, 0, 10),
                ),
                if ((vibePrompt ?? '').isNotEmpty)
                  _PromptCard(title: 'Tonight vibe', content: vibePrompt!),
                if ((firstDatePrompt ?? '').isNotEmpty)
                  _PromptCard(title: 'First date move', content: firstDatePrompt!),
                if ((musicTastePrompt ?? '').isNotEmpty)
                  _PromptCard(title: 'Music in rotation', content: musicTastePrompt!),
              ],
              if (introVideoUrl != null && introVideoUrl.isNotEmpty) ...[
                const SizedBox(height: 18),
                const MixvySectionHeader(
                  title: 'Intro Video',
                  padding: EdgeInsets.fromLTRB(0, 0, 0, 10),
                ),
                _ProfileSectionCard(
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
              ],
              if (galleryUrls.isNotEmpty) ...[
                const SizedBox(height: 18),
                const MixvySectionHeader(
                  title: 'Photo Gallery',
                  padding: EdgeInsets.fromLTRB(0, 0, 0, 10),
                ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: galleryUrls.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: context.isExpandedLayout ? 4 : 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final url = galleryUrls[index].trim();
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => const Icon(Icons.broken_image),
                        ),
                      ),
                    );
                  },
                ),
              ],
              if (interests.isNotEmpty) ...[
                const SizedBox(height: 18),
                const MixvySectionHeader(
                  title: 'Interests',
                  padding: EdgeInsets.fromLTRB(0, 0, 0, 10),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: interests
                      .take(18)
                      .map(
                        (interest) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: VelvetNoir.surfaceHigh.withValues(alpha: 0.76),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: VelvetNoir.primary.withValues(alpha: 0.14),
                            ),
                          ),
                          child: Text(
                            interest,
                            style: GoogleFonts.raleway(
                              color: VelvetNoir.onSurface,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          );
        },
      ),
          // ── Posts tab ──────────────────────────────────────────────────
          _UserPostsTab(userId: widget.userId),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Posts tab — streams the profile user's posts from Firestore
// ---------------------------------------------------------------------------
class _UserPostsTab extends ConsumerWidget {
  final String userId;
  const _UserPostsTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewerId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('authorId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(30)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppLoadingView(label: 'Loading posts');
        }
        if (snapshot.hasError) {
          return AppErrorView(
            error: snapshot.error ?? 'Unknown error',
            fallbackContext: 'Unable to load posts.',
          );
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const AppEmptyView(
            title: 'No posts yet',
            icon: Icons.post_add_outlined,
          );
        }
        final posts = docs.map((d) => PostModel.fromDoc(d.id, d.data())).toList();
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: posts.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (ctx, i) => PostCard(post: posts[i], currentUserId: viewerId),
        );
      },
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
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
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
    return _ProfileSectionCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
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
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: VelvetNoir.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.raleway(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSectionCard extends StatelessWidget {
  const _ProfileSectionCard({
    required this.child,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VelvetNoir.surfaceHigh.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: VelvetNoir.primary.withValues(alpha: 0.10),
        ),
      ),
      child: child,
    );
  }
}
