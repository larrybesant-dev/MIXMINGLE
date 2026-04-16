import 'dart:math' as math;
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mixvy/core/theme.dart';
import 'package:mixvy/core/utils/network_image_url.dart';
import 'package:mixvy/models/room_model.dart';

// ── Category accent colours ───────────────────────────────────────────────────
Color _categoryColor(String? category) {
  switch (category?.toLowerCase()) {
    case 'music':   return const Color(0xFF7C3AED);
    case 'gaming':  return const Color(0xFF0EA5E9);
    case 'dating':  return const Color(0xFFEC4899);
    case 'talk':    return const Color(0xFF10B981);
    case 'chill':   return const Color(0xFF64748B);
    case 'art':     return const Color(0xFFF59E0B);
    case 'dance':   return const Color(0xFFEF4444);
    case 'study':   return const Color(0xFF3B82F6);
    default:        return VelvetNoir.primary;
  }
}

String _categoryEmoji(String? category) {
  switch (category?.toLowerCase()) {
    case 'music':   return '🎵';
    case 'gaming':  return '🎮';
    case 'dating':  return '💕';
    case 'talk':    return '💬';
    case 'chill':   return '🍃';
    case 'art':     return '🎨';
    case 'dance':   return '💃';
    case 'study':   return '📚';
    default:        return '✨';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Reusable room card for the social layer (list-style, landscape).
///
/// Shows room title, host avatar, category tag, live indicator,
/// listener/speaker counts and a Join button. When [showWaveform] is true and
/// the room has active speakers, animated waveform bars are rendered.
// ─────────────────────────────────────────────────────────────────────────────
class SocialRoomCard extends StatelessWidget {
  const SocialRoomCard({
    required this.room,
    required this.onTap,
    this.showWaveform = true,
    this.hostAvatarUrl,
    super.key,
  });

  final RoomModel room;
  final VoidCallback onTap;
  final bool showWaveform;

  /// Optional pre-fetched host avatar URL so callers can pass it in.
  final String? hostAvatarUrl;

  @override
  Widget build(BuildContext context) {
    final accentColor = _categoryColor(room.category);
    final speakerCount = room.stageUserIds.length;
    final listenerCount = room.audienceUserIds.length;
    final totalCount = room.memberCount > 0
        ? room.memberCount
        : speakerCount + listenerCount;
    final hasActiveSpeakers = speakerCount > 0;
    final thumb = sanitizeNetworkImageUrl(room.thumbnailUrl);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: VelvetNoir.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasActiveSpeakers
                ? accentColor.withValues(alpha: 0.35)
                : VelvetNoir.outlineVariant.withValues(alpha: 0.4),
          ),
          boxShadow: hasActiveSpeakers
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : const [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              // Left accent bar
              Container(
                width: 4,
                height: 90,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentColor, accentColor.withValues(alpha: 0.4)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

              // Thumbnail
              _Thumbnail(url: thumb, category: room.category, size: 72),

              const SizedBox(width: 12),

              // Info column
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Category tag + LIVE badge
                      Row(
                        children: [
                          _CategoryTag(
                            label:
                                '${_categoryEmoji(room.category)} ${_capitalize(room.category ?? 'Room')}',
                            color: accentColor,
                          ),
                          const SizedBox(width: 6),
                          _LiveDot(),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Room title
                      Text(
                        room.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: VelvetNoir.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Stats row
                      Row(
                        children: [
                          _StatChip(
                            icon: Icons.people_alt_rounded,
                            label: _formatCount(totalCount),
                          ),
                          const SizedBox(width: 10),
                          _StatChip(
                            icon: Icons.mic_rounded,
                            label: '$speakerCount',
                            color: hasActiveSpeakers
                                ? VelvetNoir.secondaryBright
                                : VelvetNoir.onSurfaceVariant,
                          ),
                          if (showWaveform && hasActiveSpeakers) ...[
                            const SizedBox(width: 8),
                            _WaveformBars(color: accentColor),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Join button
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: _JoinButton(onTap: onTap),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Compact horizontal variant used inside horizontal scroll strips.
// ─────────────────────────────────────────────────────────────────────────────
class SocialRoomCardCompact extends StatelessWidget {
  const SocialRoomCardCompact({
    required this.room,
    required this.onTap,
    super.key,
  });

  final RoomModel room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accentColor = _categoryColor(room.category);
    final totalCount = room.memberCount > 0
        ? room.memberCount
        : room.stageUserIds.length + room.audienceUserIds.length;
    final thumb = sanitizeNetworkImageUrl(room.thumbnailUrl);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: VelvetNoir.surfaceHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: accentColor.withValues(alpha: 0.28)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero image
            Stack(
              children: [
                _Thumbnail(
                    url: thumb, category: room.category, size: 88,
                    width: double.infinity, borderRadius: 0),
                Positioned(
                  top: 8, left: 8,
                  child: _LiveDot(compact: true),
                ),
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    height: 36,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Color(0xDD0B0B0B),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.raleway(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: VelvetNoir.onSurface,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.people_rounded,
                          size: 11,
                          color: VelvetNoir.onSurfaceVariant),
                      const SizedBox(width: 3),
                      Text(
                        _formatCount(totalCount),
                        style: GoogleFonts.raleway(
                          fontSize: 11,
                          color: VelvetNoir.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({
    required this.url,
    required this.category,
    required this.size,
    this.width,
    this.borderRadius = 12,
  });

  final String? url;
  final String? category;
  final double size;
  final double? width;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final accentColor = _categoryColor(category);
    final w = width ?? size;

    if (url != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: CachedNetworkImage(
          imageUrl: url!,
          width: w,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) =>
              _FallbackThumb(category: category, size: size, width: w),
        ),
      );
    }
    return _FallbackThumb(category: category, size: size, width: w,
        borderRadius: borderRadius);
  }
}

class _FallbackThumb extends StatelessWidget {
  const _FallbackThumb({
    required this.category,
    required this.size,
    required this.width,
    this.borderRadius = 12,
  });

  final String? category;
  final double size;
  final double width;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(category);
    return Container(
      width: width,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.3), VelvetNoir.surfaceHighest],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Text(
          _categoryEmoji(category),
          style: TextStyle(fontSize: size * 0.38),
        ),
      ),
    );
  }
}

class _CategoryTag extends StatelessWidget {
  const _CategoryTag({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: GoogleFonts.raleway(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _LiveDot extends StatelessWidget {
  const _LiveDot({this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 5, vertical: 2)
          : const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: VelvetNoir.liveGlow.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: VelvetNoir.liveGlow.withValues(alpha: 0.45),
            blurRadius: compact ? 6 : 10,
          ),
        ],
      ),
      child: Text(
        '● LIVE',
        style: GoogleFonts.raleway(
          fontSize: compact ? 8 : 9,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label, this.color});
  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? VelvetNoir.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: c),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.raleway(fontSize: 11, color: c),
        ),
      ],
    );
  }
}

class _JoinButton extends StatelessWidget {
  const _JoinButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [VelvetNoir.primary, VelvetNoir.primaryDim],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: VelvetNoir.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          'Join',
          style: GoogleFonts.raleway(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: VelvetNoir.surface,
          ),
        ),
      ),
    );
  }
}

// ── Animated waveform bars ────────────────────────────────────────────────────
class _WaveformBars extends StatefulWidget {
  const _WaveformBars({required this.color});
  final Color color;

  @override
  State<_WaveformBars> createState() => _WaveformBarsState();
}

class _WaveformBarsState extends State<_WaveformBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(4, (i) {
            final phase = (i * 0.25 + _controller.value) % 1.0;
            final height = 6.0 + 8.0 * math.sin(phase * math.pi * 2).abs();
            return Container(
              width: 3,
              height: height,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
String _formatCount(int count) {
  if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
  return '$count';
}

String _capitalize(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1);
}
