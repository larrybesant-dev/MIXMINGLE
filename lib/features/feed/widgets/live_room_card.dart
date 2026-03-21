import 'package:flutter/material.dart';
import 'package:mixvy/models/room_model.dart';

class LiveRoomCard extends StatelessWidget {
  final RoomModel room;
  final VoidCallback onTap;

  const LiveRoomCard({required this.room, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Room image or fallback visual
            if (room.thumbnailUrl != null && room.thumbnailUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  room.thumbnailUrl!,
                  height: 80,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 80,
                    width: double.infinity,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    child: const Icon(Icons.broken_image, size: 40, color: Colors.white54),
                  ),
                ),
              )
            else
              Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.videocam, size: 40, color: Colors.white70),
              ),
            const SizedBox(height: 12),
            if (room.name.isNotEmpty)
              Text(
                room.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            else
              Text(
                'Untitled Room',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      fontStyle: FontStyle.italic,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Text(
              room.description?.isNotEmpty == true ? room.description! : 'No description provided.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.people, size: 16, color: Colors.white54),
                const SizedBox(width: 4),
                Text(
                  '${room.stageUserIds.length + room.audienceUserIds.length} online',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white54,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
