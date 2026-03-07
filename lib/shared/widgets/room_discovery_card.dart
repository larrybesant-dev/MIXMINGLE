// lib/shared/widgets/room_discovery_card.dart
//
// Phase 10 – Reusable card for room discovery rails.
// Shows host avatar with presence dot, title, participant count, and a join tap.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design_system/design_constants.dart';
import '../models/room.dart';
import '../providers/user_providers.dart';
import 'presence_indicator.dart';

class RoomDiscoveryCard extends ConsumerWidget {
  final Room room;
  final VoidCallback onTap;

  const RoomDiscoveryCard({
    super.key,
    required this.room,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hostAsync = ref.watch(userProfileProvider(room.hostId));

    final hostName = hostAsync.when(
      data: (p) =>
          (p?.displayName?.isNotEmpty == true ? p!.displayName! : null) ??
          (p?.nickname?.isNotEmpty == true ? p!.nickname! : null) ??
          room.hostName ??
          'Host',
      loading: () => room.hostName ?? '…',
      error: (_, __) => room.hostName ?? 'Host',
    );

    final avatarUrl = hostAsync.when(
      data: (p) => p?.photoUrl,
      loading: () => null,
      error: (_, __) => null,
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: DesignColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: room.isLive
                ? DesignColors.accent30
                : DesignColors.surfaceDefault,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: room.isLive
                  ? DesignColors.accent10
                  : Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Host avatar + presence badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage:
                      avatarUrl != null && avatarUrl.isNotEmpty
                          ? NetworkImage(avatarUrl)
                          : null,
                  backgroundColor: DesignColors.accent30,
                  child: (avatarUrl == null || avatarUrl.isEmpty)
                      ? Text(
                          hostName.isNotEmpty
                              ? hostName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: DesignColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: PresenceIndicator(
                    userId: room.hostId,
                    size: 13,
                    showBorder: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Room title
            Text(
              room.title.isNotEmpty ? room.title : (room.name ?? 'Untitled'),
              style: const TextStyle(
                color: DesignColors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // Host name
            Text(
              hostName,
              style: const TextStyle(
                color: DesignColors.accentLight,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const Spacer(),

            // Participant count + LIVE badge row
            Row(
              children: [
                const Icon(
                  Icons.people,
                  size: 13,
                  color: DesignColors.accentLight,
                ),
                const SizedBox(width: 4),
                Text(
                  '${room.viewerCount}',
                  style: const TextStyle(
                    color: DesignColors.accentLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (room.isLive)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade700,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
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
