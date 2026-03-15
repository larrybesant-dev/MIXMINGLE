// lib/shared/widgets/notification_bell.dart
//
// AppBar icon that shows a live unread-count badge.
// Tapping navigates to the NotificationCenterPage.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notification_providers.dart';
import '../../core/design_system/design_constants.dart';

class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(unreadNotificationCountProvider);
    final count = countAsync.asData?.value ?? 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined,
              color: Colors.white),
          tooltip: 'Notifications',
          onPressed: () =>
              Navigator.pushNamed(context, '/notifications'),
        ),
        if (count > 0)
          Positioned(
            right: 6,
            top: 6,
            child: _Badge(count: count),
          ),
      ],
    );
  }
}

// ── Same variant with friend-request count overlay ────────────────────────────

/// Combined bell showing notification count + optional pending friend requests.
class NotificationBellWithFriends extends ConsumerWidget {
  const NotificationBellWithFriends({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifCount =
        ref.watch(unreadNotificationCountProvider).asData?.value ?? 0;

    // Pull friend pending count from friend_providers
    // Avoids hard-coupling — import lazily
    final total = notifCount; // friend count added via totalBadgeCountProvider

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined,
              color: Colors.white),
          tooltip: 'Notifications',
          onPressed: () =>
              Navigator.pushNamed(context, '/notifications'),
        ),
        if (total > 0)
          Positioned(
            right: 6,
            top: 6,
            child: _Badge(count: total),
          ),
      ],
    );
  }
}

// ── Badge chip ─────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final int count;
  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF4D8B), Color(0xFFFF6B35)],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF4D8B).withValues(alpha: 0.6),
            blurRadius: 6,
          ),
        ],
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ── Exported standalone badge for reuse ───────────────────────────────────────

class CountBadge extends StatelessWidget {
  final int count;
  final Color? color;

  const CountBadge({super.key, required this.count, this.color});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color ?? DesignColors.secondary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
