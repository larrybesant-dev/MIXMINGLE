import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mixvy/models/room_model.dart';
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
    final memberCount = room.memberCount > 0
        ? room.memberCount
        : room.stageUserIds.length + room.audienceUserIds.length;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: NeonPulse.surfaceHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: NeonPulse.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: NeonPulse.primaryDim.withValues(alpha: 0.12),
              blurRadius: 12,
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
                if (room.thumbnailUrl != null &&
                    room.thumbnailUrl!.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: room.thumbnailUrl!,
                    height: 96,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) =>
                        _FallbackThumbnail(category: room.category),
                  )
                else
                  _FallbackThumbnail(category: room.category),

                // LIVE badge top-left
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: NeonPulse.error,
                      borderRadius: BorderRadius.circular(6),
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
                  ),
                ),

                // Member count top-right
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.people,
                            size: 11,
                            color: NeonPulse.secondary),
                        const SizedBox(width: 3),
                        Text(
                          '$memberCount',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: NeonPulse.secondary,
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
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.name.isNotEmpty ? room.name : 'Live Room',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: NeonPulse.onSurface,
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
                        color: NeonPulse.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // Category badge
                  if (room.category?.isNotEmpty == true) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: NeonPulse.secondary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: NeonPulse.secondary.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        room.category!,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: NeonPulse.secondary,
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
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: NeonPulse.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        recommendationTier!,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: NeonPulse.primary,
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
      height: 96,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [NeonPulse.primaryDim, NeonPulse.surfaceBright],
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
