// lib/features/match_inbox/widgets/match_tile.dart
//
// MatchTile — a single card in the match inbox grid/list.
// Shows: avatar, name, source badge, last interaction time, "NEW" flash badge.
// Tap → navigates to chat or user profile.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/match_inbox_item.dart';
import '../../../core/design_system/design_constants.dart';
import '../../../shared/providers/user_providers.dart';

class MatchTile extends ConsumerWidget {
  final MatchInboxItem match;
  final VoidCallback? onTap;
  final VoidCallback? onProfileTap;

  const MatchTile({
    super.key,
    required this.match,
    this.onTap,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(match.matchedUserId));

    return profileAsync.when(
      loading: () => _buildShimmer(),
      error: (_, __) => _buildErrorTile(),
      data: (profile) => _buildTile(context, profile),
    );
  }

  Widget _buildTile(BuildContext context, dynamic profile) {
    final name = profile?.displayName ??
        (match.metadata['matchedUserName'] as String?) ??
        'Unknown';
    final avatarUrl = profile?.photoUrl ??
        (match.metadata['matchedUserAvatar'] as String?);
    final lastSeen = match.lastInteraction ?? match.timestamp;
    final timeAgo = timeago.format(lastSeen, allowFromNow: true);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: DesignColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: match.isNew
                ? DesignColors.accent.withValues(alpha: 0.5)
                : DesignColors.divider,
            width: match.isNew ? 1.5 : 1,
          ),
          boxShadow: match.isNew
              ? [
                  BoxShadow(
                    color: DesignColors.accent.withValues(alpha: 0.15),
                    blurRadius: 12,
                    spreadRadius: 0,
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Avatar stack ────────────────────────────────────────────────
            Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: onProfileTap,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: avatarUrl == null
                          ? const LinearGradient(
                              colors: [
                                DesignColors.accent,
                                DesignColors.tertiary
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: DesignColors.accent.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.transparent,
                      backgroundImage:
                          avatarUrl != null ? NetworkImage(avatarUrl) : null,
                      child: avatarUrl == null
                          ? Text(
                              name.isNotEmpty
                                  ? name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: DesignColors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
                // NEW badge
                if (match.isNew)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFF4D8B),
                            DesignColors.tertiary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFFF4D8B).withValues(alpha: 0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                // Source badge
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: _SourceBadge(source: match.source),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // ── Name ─────────────────────────────────────────────────────────
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: match.isNew
                    ? DesignColors.white
                    : DesignColors.textLightGray,
                fontSize: 13,
                fontWeight: match.isNew ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 3),
            // ── Last interaction ─────────────────────────────────────────────
            Text(
              timeAgo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: DesignColors.textGray,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 8),
            // ── Message button ───────────────────────────────────────────────
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [DesignColors.accent, DesignColors.tertiary],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Message',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Container(
      decoration: BoxDecoration(
        color: DesignColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: DesignColors.accent,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorTile() {
    return Container(
      decoration: BoxDecoration(
        color: DesignColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Icon(Icons.person_off_outlined,
            color: DesignColors.textGray, size: 28),
      ),
    );
  }
}

// ── Source badge ──────────────────────────────────────────────────────────────

class _SourceBadge extends StatelessWidget {
  final MatchSource source;
  const _SourceBadge({required this.source});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (source) {
      MatchSource.speedDating => (Icons.bolt, DesignColors.gold),
      MatchSource.discovery => (Icons.explore, DesignColors.accent),
      MatchSource.manual => (Icons.favorite, const Color(0xFFFF4D8B)),
    };

    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: DesignColors.background,
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Icon(icon, size: 11, color: color),
    );
  }
}
