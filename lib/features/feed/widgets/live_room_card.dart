import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mixvy/models/room_model.dart';
import 'package:mixvy/core/utils/network_image_url.dart';
import '../../../core/theme.dart';

class LiveRoomCard extends StatelessWidget {
  final RoomModel room;
  final VoidCallback onTap;
  final String? recommendationReason;
  final String? recommendationTier;

  const LiveRoomCard({
    required this.room,
    required this.onTap,
    this.recommendationReason,
    this.recommendationTier,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl = sanitizeNetworkImageUrl(room.thumbnailUrl);
    final speakerCount = room.stageUserIds.length;
    final memberCount = room.memberCount > 0
        ? room.memberCount
        : room.stageUserIds.length + room.audienceUserIds.length;
    final activityLabel = speakerCount > 0
        ? 'Conversation live'
        : memberCount >= 6
        ? 'Crowd building'
        : 'Warming up';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: 160,
        decoration: BoxDecoration(
          color: VelvetNoir.surfaceHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: VelvetNoir.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: VelvetNoir.primaryDim.withValues(
                alpha: speakerCount > 0 ? 0.16 : 0.12,
              ),
              blurRadius: speakerCount > 0 ? 14 : 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail / hero area
            Stack(
              children: [
                if (thumbnailUrl != null)
                  CachedNetworkImage(
                    imageUrl: thumbnailUrl,
                    height: 68,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) =>
                        _FallbackThumbnail(category: room.category),
                  )
                else
                  _FallbackThumbnail(category: room.category),

                // LIVE badge top-left
                const Positioned(top: 8, left: 8, child: _AnimatedLiveBadge()),

                // Member count top-right
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.people,
                          size: 11,
                          color: VelvetNoir.secondary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '$memberCount',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: VelvetNoir.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Info section
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.name.isNotEmpty ? room.name : 'Live Room',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: VelvetNoir.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (room.description?.isNotEmpty == true) ...[
                    const SizedBox(height: 3),
                    Text(
                      room.description!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: VelvetNoir.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Text(
                      activityLabel,
                      key: ValueKey<String>(
                        'room-activity-${room.id}-$activityLabel',
                      ),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: speakerCount > 0
                            ? VelvetNoir.liveGlow
                            : VelvetNoir.onSurfaceVariant,
                      ),
                    ),
                  ),

                  // Category badge
                  if (room.category?.isNotEmpty == true) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: VelvetNoir.secondary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: VelvetNoir.secondary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        room.category!,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: VelvetNoir.secondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],

                  // Tier badge (optional)
                  if (recommendationTier?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: VelvetNoir.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        recommendationTier!,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: VelvetNoir.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Fallback thumbnail when no image is set — gradient with category emoji
class _AnimatedLiveBadge extends StatefulWidget {
  const _AnimatedLiveBadge();

  @override
  State<_AnimatedLiveBadge> createState() => _AnimatedLiveBadgeState();
}

class _AnimatedLiveBadgeState extends State<_AnimatedLiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
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
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: VelvetNoir.error,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: VelvetNoir.liveGlow.withValues(
                  alpha: 0.28 + (_controller.value * 0.18),
                ),
                blurRadius: 10,
              ),
            ],
          ),
          child: const Text(
            '● LIVE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        );
      },
    );
  }
}

class _FallbackThumbnail extends StatelessWidget {
  final String? category;
  const _FallbackThumbnail({this.category});

  static const _categoryEmojis = <String, String>{
    'music': '🎵',
    'gaming': '🎮',
    'talk': '🗣️',
    'events': '🎉',
    'dating': '💕',
    'karaoke': '🎤',
    'comedy': '😂',
    'news': '📰',
    'fitness': '💪',
    'cooking': '🍳',
    'travel': '✈️',
    'art': '🎨',
    'sports': '⚽',
    'crypto': '💰',
    'adult': '🔞',
  };

  @override
  Widget build(BuildContext context) {
    final key = category?.toLowerCase() ?? '';
    final emoji = _categoryEmojis[key] ?? '📡';

    return Container(
      height: 68,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [VelvetNoir.primaryDim, VelvetNoir.surfaceBright],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            if (category != null && category!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                category!,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
