// lib/features/profile/screens/profile_badges_page.dart
//
// Shows all earned badges (computed + stored) in a scrollable grid,
// plus locked badges the user has not yet earned.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/design_constants.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/providers/profile_controller.dart';

// ─── Badge catalogue ──────────────────────────────────────────────────────────

class _BadgeDef {
  final String id;
  final IconData icon;
  final String label;
  final String description;
  final Color color;

  const _BadgeDef({
    required this.id,
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
  });
}

const _catalogue = <_BadgeDef>[
  _BadgeDef(
    id: 'vip',
    icon: Icons.workspace_premium,
    label: 'VIP',
    description: 'Premium or VIP member',
    color: Color(0xFFFFAB00),
  ),
  _BadgeDef(
    id: 'creator',
    icon: Icons.movie_creation_outlined,
    label: 'Creator',
    description: 'Creator mode enabled',
    color: Color(0xFFFF4D8B),
  ),
  _BadgeDef(
    id: 'verified',
    icon: Icons.verified_outlined,
    label: 'Verified',
    description: 'Photo or ID verified',
    color: Color(0xFF4A90FF),
  ),
  _BadgeDef(
    id: 'boosted',
    icon: Icons.rocket_launch_outlined,
    label: 'Boosted',
    description: 'Profile boost active',
    color: Color(0xFF00E5CC),
  ),
  _BadgeDef(
    id: 'top_host',
    icon: Icons.star_outline,
    label: 'Top Host',
    description: 'Rating ≥ 4.5 & hosted 10+ rooms',
    color: Color(0xFFFFAB00),
  ),
  _BadgeDef(
    id: 'secure',
    icon: Icons.security_outlined,
    label: 'Secure',
    description: '2-factor authentication enabled',
    color: DesignColors.success,
  ),
  // Stored badgeIds
  _BadgeDef(
    id: 'active_today',
    icon: Icons.bolt,
    label: 'Active Today',
    description: 'Active on Vybe Social today',
    color: Color(0xFF00E5CC),
  ),
  _BadgeDef(
    id: 'top_creator',
    icon: Icons.emoji_events_outlined,
    label: 'Top Creator',
    description: 'Top-ranked content creator',
    color: Color(0xFFFFAB00),
  ),
  _BadgeDef(
    id: 'rising_star',
    icon: Icons.star_half_outlined,
    label: 'Rising Star',
    description: 'Fast-growing new presence',
    color: Color(0xFFFF4D8B),
  ),
];

// ─────────────────────────────────────────────────────────────────────────────

class ProfileBadgesPage extends ConsumerWidget {
  final String userId;

  const ProfileBadgesPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(userId));

    return Scaffold(
      backgroundColor: DesignColors.background,
      appBar: AppBar(
        backgroundColor: DesignColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: DesignColors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Badges',
          style: TextStyle(
              color: DesignColors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: profileAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: DesignColors.accent)),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: DesignColors.error))),
        data: (profile) {
          if (profile == null) {
            return const Center(
                child: Text('Profile not found',
                    style: TextStyle(color: DesignColors.white)));
          }
          return _BadgesBody(profile: profile);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _BadgesBody extends StatelessWidget {
  final UserProfile profile;

  const _BadgesBody({required this.profile});

  Set<String> get _earnedIds {
    final earned = <String>{};
    if (profile.isPremium || profile.isVip) earned.add('vip');
    if (profile.isCreatorBadge || profile.isCreatorEnabled) earned.add('creator');
    if (profile.isPhotoVerified == true || profile.isIdVerified == true) earned.add('verified');
    if (profile.isBoosted) earned.add('boosted');
    if (profile.communityRating >= 4.5 && profile.totalRoomsJoined >= 10) earned.add('top_host');
    if (profile.twoFactorEnabled) earned.add('secure');
    // Stored badgeIds
    for (final id in profile.badgeIds ?? []) {
      earned.add(id);
    }
    return earned;
  }

  @override
  Widget build(BuildContext context) {
    final earned = _earnedIds;
    final earnedBadges =
        _catalogue.where((b) => earned.contains(b.id)).toList();
    final lockedBadges =
        _catalogue.where((b) => !earned.contains(b.id)).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (earnedBadges.isNotEmpty) ...[
          _sectionHeader('Earned — ${earnedBadges.length}',
              const Color(0xFFFFAB00)),
          const SizedBox(height: 12),
          _BadgeGrid(badges: earnedBadges, earned: true),
          const SizedBox(height: 24),
        ],
        if (lockedBadges.isNotEmpty) ...[
          _sectionHeader('Locked', DesignColors.textGray),
          const SizedBox(height: 12),
          _BadgeGrid(badges: lockedBadges, earned: false),
        ],
        if (earnedBadges.isEmpty && lockedBadges.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 60),
              child: Text(
                'No badges yet',
                style: TextStyle(color: DesignColors.textGray, fontSize: 15),
              ),
            ),
          ),
      ],
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Row(children: [
      Text(
        title.toUpperCase(),
        style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2),
      ),
      const SizedBox(width: 8),
      Expanded(
          child: Container(height: 1, color: color.withValues(alpha: 0.25))),
    ]);
  }
}

class _BadgeGrid extends StatelessWidget {
  final List<_BadgeDef> badges;
  final bool earned;

  const _BadgeGrid({required this.badges, required this.earned});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.85),
      itemCount: badges.length,
      itemBuilder: (_, i) => _BadgeTile(badge: badges[i], earned: earned),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final _BadgeDef badge;
  final bool earned;

  const _BadgeTile({required this.badge, required this.earned});

  @override
  Widget build(BuildContext context) {
    final color = earned ? badge.color : DesignColors.textGray;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: earned ? 0.1 : 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: earned ? 0.4 : 0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(badge.icon,
              size: 32,
              color: earned ? color : color.withValues(alpha: 0.4)),
          const SizedBox(height: 8),
          Text(
            badge.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: earned ? color : color.withValues(alpha: 0.5),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            badge.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: DesignColors.textGray.withValues(alpha: 0.6),
              fontSize: 10,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (!earned)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: DesignColors.surfaceLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'LOCKED',
                  style: TextStyle(
                      color: DesignColors.textGray,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
