import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mixmingle/shared/providers/profile_controller.dart';
import 'package:mixmingle/shared/providers/providers.dart';
import 'package:mixmingle/shared/models/user_profile.dart';
import 'package:mixmingle/shared/widgets/club_background.dart';
import 'package:mixmingle/shared/widgets/async_value_view_enhanced.dart';
import 'package:mixmingle/app/app_routes.dart';
import 'package:mixmingle/core/design_system/design_constants.dart';

import '../widgets/profile_mode_selector.dart';
import '../widgets/layer_attraction.dart';
import '../widgets/layer_live_presence.dart';
import '../widgets/layer_social_proof.dart';
import '../widgets/layer_creator.dart';
import '../widgets/layer_safety.dart';

// ════════════════════════════════════════════════════════════════════
// ProfilePage — 5-Layer Identity + Attraction + Authority + Monetization + Control
// Supports 4 modes: Social | Dating | Creator | EventHost
// 18+ adult content gated behind is18PlusVerified + isAdultContentEnabled
// Firestore collections:
//   publicProfile/{uid}         — all public layers
//   privateUser/{uid}           — safety/control settings
//   creatorData/{uid}           — earnings, subscribers (owner-only reads)
//   subscriptions/{uid}/subs/   — subscriber records
//   activityStats/{uid}         — rooms joined, events attended, rating
//   moderationFlags/{uid}       — reports, content reviews
// ════════════════════════════════════════════════════════════════════
class ProfilePage extends ConsumerStatefulWidget {
  /// If null → own profile. If provided → viewing someone else's profile.
  final String? targetUserId;

  const ProfilePage({super.key, this.targetUserId});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _scaffoldKey = GlobalKey<ScaffoldMessengerState>();

  /// Local mode state — starts from what the profile says, owner can toggle.
  ProfileMode? _selectedMode;

  bool get _isOwner =>
      widget.targetUserId == null ||
      widget.targetUserId == FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return ClubBackground(
      child: ScaffoldMessenger(
        key: _scaffoldKey,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: AsyncValueViewEnhanced<UserProfile?>(
            value: profileAsync,
            maxRetries: 3,
            screenName: 'ProfilePage',
            providerName: 'currentUserProfileProvider',
            onRetry: () => ref.invalidate(currentUserProfileProvider),
            data: (profile) {
              if (profile == null) {
                return const Center(
                  child: Text('Profile not found',
                      style: TextStyle(color: DesignColors.white)),
                );
              }
              _selectedMode ??= profile.profileMode;
              return _buildContent(profile);
            },
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  MAIN SCROLL VIEW
  // ══════════════════════════════════════════════════════════
  Widget _buildContent(UserProfile p) {
    final mode = _selectedMode ?? p.profileMode;

    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(p),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildIdentityCard(p),
              const SizedBox(height: 14),
              ProfileModeSelector(
                selected: mode,
                isOwner: _isOwner,
                onChanged: (m) => setState(() => _selectedMode = m),
              ),
              const SizedBox(height: 20),
              ..._buildOrderedLayers(p, mode),
              if (_isOwner) ..._buildOwnerFooter(p),
            ]),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  //  MODE-ORDERED LAYERS
  // ══════════════════════════════════════════════════════════
  List<Widget> _buildOrderedLayers(UserProfile p, ProfileMode mode) {
    final attraction = [
      LayerAttraction(
        p: p,
        isOwner: _isOwner,
        onFollow: _isOwner ? null : () => _toast('Follow'),
        onMessage: _isOwner ? null : () => _toast('Message'),
      ),
      const SizedBox(height: 24),
    ];

    final live = (p.roomsHostedCount > 0 || p.presenceStatus == 'in_room' || p.eventsHostingCount > 0)
        ? [
            LayerLivePresence(
              p: p,
              onJoinRoom: () => _toast('Join Room'),
              onViewEvents: () => _toast('View Events'),
            ),
            const SizedBox(height: 24),
          ]
        : <Widget>[];

    final social = [
      LayerSocialProof(p: p, isOwner: _isOwner),
      const SizedBox(height: 24),
    ];

    final creator = p.isCreatorEnabled
        ? [
            LayerCreator(
              p: p,
              isOwner: _isOwner,
              onSubscribe: () => _toast('Subscribe'),
              onTip: () => _toast('Tip'),
              onJoinPaidRoom: () => _toast('Join Paid Room'),
              onViewVault: () => _toast('Vault'),
              onWithdraw: _isOwner ? () => _toast('Withdraw') : null,
            ),
            const SizedBox(height: 24),
          ]
        : <Widget>[];

    final dating = _hasDatingData(p)
        ? [_buildDatingLayer(p), const SizedBox(height: 24)]
        : <Widget>[];

    final supporting = _buildSupportingContent(p);

    switch (mode) {
      case ProfileMode.dating:
        return [...attraction, ...dating, ...social, ...live, ...creator, ...supporting];
      case ProfileMode.creator:
        return [...creator, ...attraction, ...live, ...social, ...supporting];
      case ProfileMode.eventHost:
        return [...live, ...social, ...attraction, ...creator, ...supporting];
      case ProfileMode.social:
        return [...social, ...attraction, ...live, ...creator, ...dating, ...supporting];
    }
  }

  // ── Dating Intent Layer ────────────────────────────────────
  bool _hasDatingData(UserProfile p) =>
      (p.lookingFor != null && p.lookingFor!.isNotEmpty) ||
      p.relationshipType != null ||
      (p.preferredGenders != null && p.preferredGenders!.isNotEmpty);

  Widget _buildDatingLayer(UserProfile p) {
    const color = Color(0xFFFF4D8B);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(Icons.favorite_border, 'Looking For', color),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Column(children: [
            if (p.lookingFor != null && p.lookingFor!.isNotEmpty)
              _datingRow('Intent', p.lookingFor!.join(' • '), color),
            if (p.relationshipType != null)
              _datingRow('Relationship', p.relationshipType!, color),
            if (p.preferredGenders != null && p.preferredGenders!.isNotEmpty)
              _datingRow('Interested in', p.preferredGenders!.join(', '), color),
            if (p.minAgePreference != null && p.maxAgePreference != null)
              _datingRow('Age range', '${p.minAgePreference} – ${p.maxAgePreference}', color),
          ]),
        ),
      ],
    );
  }

  Widget _datingRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF8892A4), fontSize: 13)),
          Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Supporting Content ─────────────────────────────────────
  List<Widget> _buildSupportingContent(UserProfile p) {
    final widgets = <Widget>[];
    if (p.galleryPhotos != null && p.galleryPhotos!.isNotEmpty) {
      widgets.addAll([
        _sectionHeader(Icons.photo_library_outlined, 'Gallery', DesignColors.accent),
        const SizedBox(height: 10),
        _buildGalleryGrid(p.galleryPhotos!),
        const SizedBox(height: 20),
      ]);
    }
    if (p.lifestylePrompts != null && p.lifestylePrompts!.values.any((v) => v)) {
      widgets.addAll([
        _sectionHeader(Icons.favorite_border, 'Lifestyle', DesignColors.secondary),
        const SizedBox(height: 10),
        _buildLifestyleRow(p.lifestylePrompts!),
        const SizedBox(height: 20),
      ]);
    }
    if (p.musicTastes != null && p.musicTastes!.isNotEmpty) {
      widgets.addAll([
        _sectionHeader(Icons.music_note_outlined, 'Music', DesignColors.tertiary),
        const SizedBox(height: 10),
        _buildChipWrap(p.musicTastes!, DesignColors.tertiary),
        const SizedBox(height: 20),
      ]);
    }
    if (p.socialLinks != null && p.socialLinks!.isNotEmpty) {
      widgets.addAll([
        _sectionHeader(Icons.link_outlined, 'Socials', DesignColors.tertiary),
        const SizedBox(height: 10),
        _buildSocialRow(p.socialLinks!),
        const SizedBox(height: 20),
      ]);
    }
    return widgets;
  }

  // ── Owner Footer: Safety + Settings ───────────────────────
  List<Widget> _buildOwnerFooter(UserProfile p) {
    return [
      LayerSafety(
        p: p,
        isOwner: true,
        onEditDmRestriction: () => Navigator.pushNamed(context, '/settings/privacy'),
        onToggleHideDistance: () => Navigator.pushNamed(context, '/settings/privacy'),
        onToggleHideFollowers: () => Navigator.pushNamed(context, '/settings/privacy'),
        onToggleRestrictInvites: () => Navigator.pushNamed(context, '/settings/privacy'),
        onBlockList: () => Navigator.pushNamed(context, '/settings/blocked'),
        onSetup2FA: () => Navigator.pushNamed(context, '/settings/security'),
        onContentModeration: () => Navigator.pushNamed(context, '/creator/moderation'),
      ),
      const SizedBox(height: 24),
      _sectionHeader(Icons.settings_outlined, 'Account', DesignColors.textGray),
      const SizedBox(height: 10),
      _navTile(Icons.privacy_tip_outlined, 'Privacy Settings', () => Navigator.pushNamed(context, '/settings/privacy')),
      _navTile(Icons.notifications_outlined, 'Notifications', () => Navigator.pushNamed(context, '/notifications')),
      _navTile(Icons.settings_outlined, 'Account Settings', () => Navigator.pushNamed(context, '/settings')),
      if (p.isCreatorEnabled)
        _navTile(Icons.monetization_on_outlined, 'Creator Settings', () => Navigator.pushNamed(context, '/creator/settings')),
      const SizedBox(height: 20),
      _buildLogoutButton(),
      const SizedBox(height: 12),
      Center(
        child: TextButton(
          onPressed: _showDeleteAccountDialog,
          child: const Text('Delete Account',
              style: TextStyle(color: DesignColors.error, decoration: TextDecoration.underline)),
        ),
      ),
      const SizedBox(height: 20),
    ];
  }

  // ══════════════════════════════════════════════════════════
  //  SLIVER APP BAR
  // ══════════════════════════════════════════════════════════
  Widget _buildSliverAppBar(UserProfile p) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: DesignColors.background,
      leading: null,
      automaticallyImplyLeading: false,
      actions: [
        if (_isOwner)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _neonIconButton(
              Icons.edit_outlined,
              DesignColors.accent,
              () => Navigator.pushNamed(context, AppRoutes.editProfile),
            ),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            p.coverPhotoUrl != null
                ? Image.network(p.coverPhotoUrl!, fit: BoxFit.cover)
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0D1117), Color(0xFF1A1A2E), Color(0xFF0D1117)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.music_note, color: Color(0x224A90FF), size: 80),
                    ),
                  ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Color(0xCC080C14)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  IDENTITY CARD
  // ══════════════════════════════════════════════════════════
  Widget _buildIdentityCard(UserProfile p) {
    final name = p.displayName ?? p.nickname ?? 'Anonymous';
    final age = p.age;
    final mode = _selectedMode ?? p.profileMode;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _modeAccent(mode).withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          // Avatar — neon ring tinted to active mode color
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _modeAccent(mode), width: 2.5),
              boxShadow: [
                BoxShadow(color: _modeAccent(mode).withValues(alpha: 0.45), blurRadius: 18, spreadRadius: 2),
              ],
            ),
            child: CircleAvatar(
              radius: 44,
              backgroundColor: DesignColors.surfaceDefault,
              backgroundImage: p.photoUrl != null ? NetworkImage(p.photoUrl!) : null,
              child: p.photoUrl == null
                  ? const Icon(Icons.person, size: 44, color: DesignColors.textGray)
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        age != null ? '$name, $age' : name,
                        style: DesignTypography.heading.copyWith(shadows: DesignColors.primaryGlow),
                      ),
                    ),
                    // Online dot
                    if (p.presenceStatus == 'online' || p.presenceStatus == 'in_room')
                      Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: p.presenceStatus == 'in_room'
                              ? const Color(0xFFFFAB00)
                              : const Color(0xFF00C853),
                          boxShadow: [
                            BoxShadow(
                              color: (p.presenceStatus == 'in_room'
                                  ? const Color(0xFFFFAB00)
                                  : const Color(0xFF00C853)).withValues(alpha: 0.6),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (p.gender != null) ...[
                  const SizedBox(height: 2),
                  Text(p.gender!, style: DesignTypography.caption.copyWith(color: DesignColors.textGray)),
                ],
                if (p.location != null && p.location!.isNotEmpty && !p.hideDistance) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.location_on_outlined, size: 13, color: DesignColors.secondary),
                    const SizedBox(width: 4),
                    Text(p.location!, style: DesignTypography.caption.copyWith(color: DesignColors.secondary)),
                  ]),
                ],
                const SizedBox(height: 8),
                Row(children: [
                  if (!p.hideFollowers || _isOwner)
                    _statPill('${p.followersCount}', 'Followers'),
                  if (!p.hideFollowers || _isOwner) const SizedBox(width: 8),
                  _statPill('${p.followingCount}', 'Following'),
                  if (p.isCreatorEnabled) ...[
                    const SizedBox(width: 8),
                    _statPill('${p.subscriberCount}', 'Subs'),
                  ],
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statPill(String count, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: DesignColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DesignColors.accent.withValues(alpha: 0.3)),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(text: '$count ', style: const TextStyle(color: DesignColors.white, fontWeight: FontWeight.w700, fontSize: 12)),
            TextSpan(text: label, style: const TextStyle(color: DesignColors.textGray, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  SUPPORTING CONTENT SUB-WIDGETS
  // ══════════════════════════════════════════════════════════
  Widget _buildGalleryGrid(List<String> photos) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 6, mainAxisSpacing: 6, childAspectRatio: 1,
      ),
      itemCount: photos.length,
      itemBuilder: (ctx, i) => GestureDetector(
        onTap: () => _openPhotoViewer(photos, i),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(photos[i], fit: BoxFit.cover),
        ),
      ),
    );
  }

  void _openPhotoViewer(List<String> photos, int index) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(child: Image.network(photos[index], fit: BoxFit.contain)),
            Padding(
              padding: const EdgeInsets.all(8),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const Map<String, String> _lifestyleLabels = {
    'smoking': 'Smoking', 'drinking': 'Drinking', 'fitness': 'Fitness',
    'pets': 'Has Pets', 'kids': 'Has Kids',
  };
  static const Map<String, IconData> _lifestyleIcons = {
    'smoking': Icons.smoke_free, 'drinking': Icons.local_bar_outlined,
    'fitness': Icons.fitness_center_outlined, 'pets': Icons.pets_outlined,
    'kids': Icons.child_care_outlined,
  };

  Widget _buildLifestyleRow(Map<String, bool> lifestyle) {
    final active = lifestyle.entries.where((e) => e.value).toList();
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: active.map((e) {
        final label = _lifestyleLabels[e.key] ?? e.key;
        final icon = _lifestyleIcons[e.key] ?? Icons.check_circle_outline;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: DesignColors.secondary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: DesignColors.secondary.withValues(alpha: 0.4)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 14, color: DesignColors.secondary),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: DesignColors.secondary, fontSize: 13, fontWeight: FontWeight.w500)),
          ]),
        );
      }).toList(),
    );
  }

  Widget _buildChipWrap(List<String> items, Color color) {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: items.map((item) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text(item, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500)),
      )).toList(),
    );
  }

  static const Map<String, String> _socialIcons = {
    'instagram': 'IG', 'tiktok': 'TK', 'snapchat': 'SC', 'twitter': 'X',
  };
  static const Map<String, Color> _socialColors = {
    'instagram': Color(0xFFE1306C), 'tiktok': Color(0xFF69C9D0),
    'snapchat': Color(0xFFFFFC00), 'twitter': Color(0xFF1DA1F2),
  };

  Widget _buildSocialRow(Map<String, String> links) {
    return Wrap(
      spacing: 10, runSpacing: 10,
      children: links.entries.map((e) {
        final color = _socialColors[e.key] ?? DesignColors.accent;
        final abbr = _socialIcons[e.key] ?? e.key.substring(0, 2).toUpperCase();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.25), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(abbr, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 8),
            Text(e.value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500)),
          ]),
        );
      }).toList(),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  HELPERS
  // ══════════════════════════════════════════════════════════
  Widget _sectionHeader(IconData icon, String title, Color color) {
    return Row(children: [
      Icon(icon, size: 18, color: color),
      const SizedBox(width: 8),
      Text(title, style: DesignTypography.subheading.copyWith(
        color: color,
        shadows: [Shadow(color: color.withValues(alpha: 0.5), blurRadius: 12)],
      )),
      const SizedBox(width: 8),
      Expanded(child: Container(height: 1, color: color.withValues(alpha: 0.25))),
    ]);
  }

  Widget _navTile(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: DesignColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(children: [
              Icon(icon, size: 20, color: DesignColors.accent),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: DesignTypography.body)),
              const Icon(Icons.arrow_forward_ios, size: 14, color: DesignColors.textGray),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _neonIconButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: DesignColors.background.withValues(alpha: 0.7),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.6)),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8)],
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignColors.error.withValues(alpha: 0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _showLogoutDialog,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: Text('Logout',
                  style: TextStyle(color: DesignColors.error, fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
        ),
      ),
    );
  }

  Color _modeAccent(ProfileMode m) {
    switch (m) {
      case ProfileMode.social:    return const Color(0xFF4A90FF);
      case ProfileMode.dating:    return const Color(0xFFFF4D8B);
      case ProfileMode.creator:   return const Color(0xFFFFAB00);
      case ProfileMode.eventHost: return const Color(0xFF00E5CC);
    }
  }

  void _toast(String msg) {
    _scaffoldKey.currentState?.showSnackBar(SnackBar(
      content: Text('$msg — coming soon'),
      backgroundColor: const Color(0xFF1E2D40),
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ══════════════════════════════════════════════════════════
  //  DIALOGS
  // ══════════════════════════════════════════════════════════
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: DesignColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout', style: TextStyle(color: DesignColors.white)),
        content: const Text('Are you sure you want to logout?',
            style: TextStyle(color: DesignColors.textGray)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: DesignColors.textGray)),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                // ignore: use_build_context_synchronously
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            },
            child: const Text('Logout', style: TextStyle(color: DesignColors.error)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: DesignColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Account', style: TextStyle(color: DesignColors.white)),
        content: const Text(
            'This action cannot be undone. All data will be permanently deleted.',
            style: TextStyle(color: DesignColors.textGray)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: DesignColors.textGray)),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              try {
                await ref.read(authServiceProvider).deleteAccount();
                if (mounted) {
                  navigator.pop();
                  navigator.pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
                }
              } catch (e) {
                if (mounted) {
                  _scaffoldKey.currentState?.showSnackBar(
                      SnackBar(content: Text('Failed to delete account: $e')));
                  navigator.pop();
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: DesignColors.error)),
          ),
        ],
      ),
    );
  }
}
