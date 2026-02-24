/// NeonProfileCard — Sprint 1 "Neon ID Card"
///
/// A compact profile snapshot used on:
/// • HomePageElectric — welcome header area
/// • RoomScreen       — host banner strip
/// • Any future peer card (matches, speed-dating queue)
///
/// Key elements
/// ─────────────────────────────────────────────────────────
/// • [NeonAvatarRing]  — circular avatar with animated neon
///   ring that pulses when the user is live or recently active.
/// • Display name
/// • Vibe tag chip (e.g. "🔥 Hype") in the tag's accent colour.
/// • Country flag emoji derived from ISO countryCode.
/// • "Joined X days ago" subtitle.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/vibe_genres.dart';
import '../../core/theme/neon_colors.dart';

// ── Public API ───────────────────────────────────────────────────────────────

/// Full Neon ID Card — avatar + name + vibe + flag + join date.
class NeonProfileCard extends StatelessWidget {
  final UserProfile profile;

  /// Compact mode used in list tiles / room strips (no join-date row).
  final bool compact;

  /// Override colour for the outer card border glow.
  final Color? glowOverride;

  const NeonProfileCard({
    super.key,
    required this.profile,
    this.compact = false,
    this.glowOverride,
  });

  @override
  Widget build(BuildContext context) {
    final isLiveNow =
        profile.presenceStatus == 'in_room' || profile.presenceStatus == 'live';
    final wasRecentlyActive = _wasRecentlyActive(profile.updatedAt);

    final vibeColor = VibeTags.colorFor(profile.vibeTag);
    final borderColor = glowOverride ?? (isLiveNow ? NeonColors.errorRed : vibeColor);

    return Container(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
          : const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NeonColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withValues(alpha: 0.55), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.35),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: compact ? _buildCompactRow(isLiveNow, wasRecentlyActive) : _buildFullCard(isLiveNow, wasRecentlyActive),
    );
  }

  // ── Compact: avatar + name + vibe tag in a horizontal row ──────────────────
  Widget _buildCompactRow(bool isLive, bool recentlyActive) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        NeonAvatarRing(
          photoUrl: profile.photoUrl,
          displayName: profile.displayName ?? '?',
          diameter: 46,
          isLive: isLive,
          recentlyActive: recentlyActive,
          vibeColor: VibeTags.colorFor(profile.vibeTag),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      profile.displayName ?? 'Unknown',
                      style: const TextStyle(
                        color: NeonColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (profile.isVip) ...[
                    const SizedBox(width: 4),
                    _vipBadge(),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  if (profile.vibeTag != null) _vibeChip(small: true),
                  const SizedBox(width: 6),
                  if (profile.countryCode != null)
                    Text(
                      CountryFlags.toEmoji(profile.countryCode),
                      style: const TextStyle(fontSize: 14),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Full card: stacked layout ────────────────────────────────────────────────
  Widget _buildFullCard(bool isLive, bool recentlyActive) {
    final joinDays = DateTime.now().difference(profile.createdAt).inDays;
    final joinLabel = joinDays == 0
        ? 'Joined today'
        : joinDays == 1
            ? 'Joined yesterday'
            : 'Joined $joinDays days ago';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Avatar + live/active dot ─────────────────────────────
        NeonAvatarRing(
          photoUrl: profile.photoUrl,
          displayName: profile.displayName ?? '?',
          diameter: 72,
          isLive: isLive,
          recentlyActive: recentlyActive,
          vibeColor: VibeTags.colorFor(profile.vibeTag),
        ),
        const SizedBox(height: 12),
        // ── Name row ─────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              profile.displayName ?? 'Unknown',
              style: const TextStyle(
                color: NeonColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: 0.4,
              ),
            ),
            if (profile.isVip) ...[
              const SizedBox(width: 6),
              _vipBadge(),
            ],
          ],
        ),
        const SizedBox(height: 8),
        // ── Vibe + flag row ───────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (profile.vibeTag != null) _vibeChip(),
            if (profile.vibeTag != null && profile.countryCode != null)
              const SizedBox(width: 8),
            if (profile.countryCode != null)
              _flagPill(),
          ],
        ),
        const SizedBox(height: 8),
        // ── Join date ─────────────────────────────────────────────
        Text(
          joinLabel,
          style: const TextStyle(
            color: NeonColors.textTertiary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // ── Chip / pill helpers ──────────────────────────────────────────────────────

  Widget _vibeChip({bool small = false}) {
    final color = VibeTags.colorFor(profile.vibeTag);
    final emoji = VibeTags.emojiFor(profile.vibeTag);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        '$emoji ${profile.vibeTag!}',
        style: TextStyle(
          color: color,
          fontSize: small ? 11 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _flagPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: NeonColors.darkBg3,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        CountryFlags.toEmoji(profile.countryCode),
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _vipBadge() {
    final tierColor = _vipColor(profile.vipTier);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: tierColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tierColor.withValues(alpha: 0.6), width: 1),
      ),
      child: Text(
        profile.vipTier?.toUpperCase() ?? 'VIP',
        style: TextStyle(
          color: tierColor,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  static Color _vipColor(String? tier) {
    switch (tier) {
      case 'gold':
        return NeonColors.warningYellow;
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'bronze':
        return const Color(0xFFCD7F32);
      default:
        return NeonColors.neonPurple;
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  static bool _wasRecentlyActive(DateTime updatedAt) {
    return DateTime.now().difference(updatedAt).inMinutes < 30;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Animated circular avatar with neon "live" or "recently active" ring.
///
/// • Live     → pulsing red ring  (2-second AnimationController loop)
/// • Active   → solid vibe-colour ring (no pulse)
/// • Offline  → dark grey ring
// ─────────────────────────────────────────────────────────────────────────────
class NeonAvatarRing extends StatefulWidget {
  final String? photoUrl;
  final String displayName;
  final double diameter;
  final bool isLive;
  final bool recentlyActive;
  final Color vibeColor;

  const NeonAvatarRing({
    super.key,
    required this.photoUrl,
    required this.displayName,
    this.diameter = 56,
    this.isLive = false,
    this.recentlyActive = false,
    this.vibeColor = NeonColors.neonBlue,
  });

  @override
  State<NeonAvatarRing> createState() => _NeonAvatarRingState();
}

class _NeonAvatarRingState extends State<NeonAvatarRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _glow = Tween<double>(begin: 6, end: 18).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
    if (widget.isLive) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(NeonAvatarRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLive && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.isLive && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Color get _ringColor {
    if (widget.isLive) return NeonColors.errorRed;
    if (widget.recentlyActive) return widget.vibeColor;
    return NeonColors.darkBg3;
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.diameter;
    final ringWidth = math.max(2.5, d * 0.045);

    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) {
        final blurRadius = widget.isLive ? _glow.value : (widget.recentlyActive ? 10.0 : 0.0);
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow ring
            Container(
              width: d + ringWidth * 2 + 4,
              height: d + ringWidth * 2 + 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _ringColor.withValues(alpha: widget.isLive ? 0.7 : 0.45),
                    blurRadius: blurRadius,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            // Coloured ring
            Container(
              width: d + ringWidth * 2,
              height: d + ringWidth * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _ringColor, width: ringWidth),
                color: Colors.transparent,
              ),
            ),
            // Avatar
            CircleAvatar(
              radius: d / 2,
              backgroundColor: NeonColors.darkBg2,
              backgroundImage:
                  widget.photoUrl != null ? NetworkImage(widget.photoUrl!) : null,
              child: widget.photoUrl == null
                  ? Text(
                      widget.displayName.isNotEmpty
                          ? widget.displayName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: NeonColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: d * 0.38,
                      ),
                    )
                  : null,
            ),
            // Live badge
            if (widget.isLive)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: NeonColors.errorRed,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: NeonColors.darkCard, width: 1.5),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
