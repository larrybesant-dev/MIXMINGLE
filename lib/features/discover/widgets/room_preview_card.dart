// lib/features/discover/widgets/room_preview_card.dart
//
// Compact horizontal-scroll card for Room Discovery sections.
// Displays: room thumbnail, name, category, viewer count, live indicator.
// Neon glow on hover (web) / on press (mobile).
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/design_system/design_constants.dart';
import '../../../shared/models/room.dart';

// ── Vibe colour map ───────────────────────────────────────────────────────────

const _kVibeColors = <String, Color>{
  'Chill': Color(0xFF4A90FF),
  'Hype': Color(0xFFFF4D8B),
  'Deep Talk': Color(0xFF8B5CF6),
  'Late Night': Color(0xFF6366F1),
  'Study': Color(0xFF00E5CC),
  'Party': Color(0xFFFFAB00),
};

Color _vibeColor(String? vibe) => _kVibeColors[vibe] ?? DesignColors.accent;

IconData _typeIcon(RoomType t) => switch (t) {
      RoomType.video => Icons.videocam_rounded,
      RoomType.voice => Icons.mic_rounded,
      RoomType.text => Icons.chat_bubble_rounded,
    };

// ── RoomPreviewCard ───────────────────────────────────────────────────────────

/// Compact card displayed in horizontal scroll rails.
/// Width ≈ 180 px, height ≈ 220 px (adjustable via [width]/[height]).
class RoomPreviewCard extends StatefulWidget {
  final Room room;
  final VoidCallback onTap;
  final double width;
  final double height;

  const RoomPreviewCard({
    super.key,
    required this.room,
    required this.onTap,
    this.width = 180,
    this.height = 220,
  });

  @override
  State<RoomPreviewCard> createState() => _RoomPreviewCardState();
}

class _RoomPreviewCardState extends State<RoomPreviewCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _glowAnim = CurvedAnimation(parent: _glowCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  void _onHover(bool hovering) {
    if (hovering) {
      _glowCtrl.forward();
    } else {
      _glowCtrl.reverse();
    }
  }

  void _onTap() {
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final vibeColor = _vibeColor(room.vibeTag);
    final hasThumbnail =
        room.thumbnailUrl != null && room.thumbnailUrl!.isNotEmpty;

    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (context, child) {
        final glowStrength = _glowAnim.value;
        return MouseRegion(
          onEnter: (_) => _onHover(true),
          onExit: (_) => _onHover(false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _onTap,
            child: Container(
              width: widget.width,
              height: widget.height,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: DesignColors.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: vibeColor.withValues(
                      alpha: 0.2 + (0.4 * glowStrength)),
                  width: 1 + glowStrength,
                ),
                boxShadow: [
                  BoxShadow(
                    color: vibeColor.withValues(
                        alpha: 0.08 + (0.18 * glowStrength)),
                    blurRadius: 8 + (16 * glowStrength),
                    spreadRadius: glowStrength * 2,
                  ),
                ],
              ),
              clipBehavior: Clip.hardEdge,
              child: child,
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Thumbnail area ─────────────────────────────────────────────────
          Expanded(
            flex: 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background image or gradient fallback
                hasThumbnail
                    ? Image.network(
                        widget.room.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _thumbnailFallback(widget.room, _vibeColor(widget.room.vibeTag)),
                      )
                    : _thumbnailFallback(widget.room, _vibeColor(widget.room.vibeTag)),

                // Gradient overlay
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          DesignColors.background.withValues(alpha: 0.7),
                        ],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                ),

                // LIVE badge top-left
                Positioned(
                  top: 8,
                  left: 8,
                  child: _LiveBadge(),
                ),

                // Type icon top-right
                Positioned(
                  top: 8,
                  right: 8,
                  child: _TypeIconBadge(type: widget.room.roomType),
                ),

                // Viewer count bottom-right
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: _ViewerCount(count: widget.room.viewerCount),
                ),
              ],
            ),
          ),

          // ── Info area ──────────────────────────────────────────────────────
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Room title
                  Text(
                    widget.room.title,
                    style: const TextStyle(
                      color: DesignColors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Category chip
                  if (widget.room.category.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _vibeColor(widget.room.vibeTag)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _vibeColor(widget.room.vibeTag)
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        widget.room.category,
                        style: TextStyle(
                          color: _vibeColor(widget.room.vibeTag),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Thumbnail fallback ────────────────────────────────────────────────────────

Widget _thumbnailFallback(Room room, Color vibeColor) {
  final icon = _typeIcon(room.roomType);
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          vibeColor.withValues(alpha: 0.25),
          DesignColors.background,
        ],
      ),
    ),
    child: Center(
      child: Icon(icon, size: 40, color: vibeColor.withValues(alpha: 0.6)),
    ),
  );
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _LiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.red.shade700.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.fiber_manual_record, size: 6, color: Colors.white),
          SizedBox(width: 3),
          Text(
            'LIVE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeIconBadge extends StatelessWidget {
  final RoomType type;
  const _TypeIconBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        _typeIcon(type),
        size: 12,
        color: Colors.white.withValues(alpha: 0.85),
      ),
    );
  }
}

class _ViewerCount extends StatelessWidget {
  final int count;
  const _ViewerCount({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people_outline, size: 10, color: Colors.white70),
          const SizedBox(width: 3),
          Text(
            count >= 1000
                ? '${(count / 1000).toStringAsFixed(1)}k'
                : '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
