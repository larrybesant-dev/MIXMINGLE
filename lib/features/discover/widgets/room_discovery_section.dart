// lib/features/discover/widgets/room_discovery_section.dart
//
// Reusable section widget for Room Discovery.
// Shows: gradient section header + horizontal scroll list of RoomPreviewCards,
// with optional ad tile inserted after every [adEvery] cards.
// Handles: loading skeleton, empty state, error + retry.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../../core/design_system/design_constants.dart';
import '../../../shared/models/room.dart';
import '../../../shared/models/ad_entry.dart';
import '../../../shared/widgets/ad_tile_widget.dart';
import 'room_preview_card.dart';

// ── Section widget ────────────────────────────────────────────────────────────

class RoomDiscoverySection extends StatelessWidget {
  /// Section title (e.g. "🔥 Trending Now").
  final String title;

  /// Gradient colours for the section title.
  final List<Color> titleGradient;

  /// Rooms to display.
  final List<Room>? rooms;

  /// Whether data is still loading.
  final bool isLoading;

  /// Error message when Firestore call fails.
  final String? errorMessage;

  /// Retry callback shown on error.
  final VoidCallback? onRetry;

  /// Empty-state message when no rooms found.
  final String emptyMessage;

  /// Icon for empty state.
  final IconData emptyIcon;

  /// Called when a card is tapped. Passes the tapped [Room].
  final void Function(Room room) onRoomTap;

  /// Whether adult ads are allowed.
  final bool userIsAdult;

  /// Insert an ad tile after every N cards (0 = no ads).
  final int adEvery;

  const RoomDiscoverySection({
    super.key,
    required this.title,
    required this.onRoomTap,
    this.titleGradient = const [Color(0xFF4A90FF), Color(0xFF8B5CF6)],
    this.rooms,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.emptyMessage = 'Nothing here yet',
    this.emptyIcon = Icons.search_off_rounded,
    this.userIsAdult = false,
    this.adEvery = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Gradient section header ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: titleGradient,
            ).createShader(bounds),
            blendMode: BlendMode.srcIn,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white, // overridden by shader
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),

        // ── Content area ─────────────────────────────────────────────────────
        if (isLoading)
          _SkeletonRow()
        else if (errorMessage != null)
          _ErrorRetry(message: errorMessage!, onRetry: onRetry)
        else if (rooms == null || rooms!.isEmpty)
          _EmptyState(message: emptyMessage, icon: emptyIcon)
        else
          _CardRail(
            rooms: rooms!,
            onRoomTap: onRoomTap,
            userIsAdult: userIsAdult,
            adEvery: adEvery,
          ),

        const SizedBox(height: 6),
      ],
    );
  }
}

// ── Horizontal card rail ──────────────────────────────────────────────────────

class _CardRail extends StatelessWidget {
  final List<Room> rooms;
  final void Function(Room) onRoomTap;
  final bool userIsAdult;
  final int adEvery;

  const _CardRail({
    required this.rooms,
    required this.onRoomTap,
    required this.userIsAdult,
    required this.adEvery,
  });

  @override
  Widget build(BuildContext context) {
    // Build interleaved list: rooms + optional ad tiles
    final items = <Widget>[];
    for (var i = 0; i < rooms.length; i++) {
      items.add(
        RoomPreviewCard(
          room: rooms[i],
          onTap: () => onRoomTap(rooms[i]),
        ),
      );
      // Insert ad tile after every N rooms (but not at the very end)
      if (adEvery > 0 && (i + 1) % adEvery == 0 && i < rooms.length - 1) {
        items.add(
          SizedBox(
            width: 160,
            height: 220,
            child: AdTileWidget(
              placement: AdPlacement.discover,
              userIsAdult: userIsAdult,
            ),
          ),
        );
      }
    }

    return SizedBox(
      height: 220,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        children: items,
      ),
    );
  }
}

// ── Skeleton loader ───────────────────────────────────────────────────────────

class _SkeletonRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => _SkeletonCard(),
      ),
    );
  }
}

class _SkeletonCard extends StatefulWidget {
  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 180,
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Color.lerp(
            DesignColors.surfaceLight,
            DesignColors.surfaceAlt,
            _anim.value,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16)),
                  color: Color.lerp(
                    DesignColors.surfaceAlt,
                    DesignColors.divider,
                    _anim.value,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 12,
                      width: 130,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Color.lerp(
                          DesignColors.divider,
                          DesignColors.surfaceAlt,
                          _anim.value,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 10,
                      width: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Color.lerp(
                          DesignColors.divider,
                          DesignColors.surfaceAlt,
                          _anim.value,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error + retry ─────────────────────────────────────────────────────────────

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const _ErrorRetry({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: DesignColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: DesignColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded,
              color: DesignColors.error, size: 30),
          const SizedBox(height: 8),
          Text(message,
              style: const TextStyle(
                  color: DesignColors.textGray, fontSize: 13),
              textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 14),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(
                foregroundColor: DesignColors.accent,
                side: const BorderSide(color: DesignColors.accent),
                visualDensity: VisualDensity.compact,
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  const _EmptyState({required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: DesignColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DesignColors.divider),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: DesignColors.textGray, size: 30),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
                color: DesignColors.textGray, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
