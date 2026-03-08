import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/design_constants.dart';
import '../../core/routing/app_routes.dart';
import '../../services/social/activity_feed_service.dart';

// ── Providers ───────────────────────────────────────────────────────────────

final activityFeedProvider = StreamProvider.autoDispose<List<ActivityEvent>>(
  (ref) => ActivityFeedService.instance.watchMyFeed(),
);

final activityUnreadCountProvider = StreamProvider.autoDispose<int>(
  (ref) => ActivityFeedService.instance.watchUnreadCount(),
);

// ── Page ────────────────────────────────────────────────────────────────────

class ActivityFeedPage extends ConsumerStatefulWidget {
  const ActivityFeedPage({super.key});

  @override
  ConsumerState<ActivityFeedPage> createState() => _ActivityFeedPageState();
}

class _ActivityFeedPageState extends ConsumerState<ActivityFeedPage> {
  @override
  void initState() {
    super.initState();
    // Mark events as read after entering
    Future.microtask(() => ActivityFeedService.instance.markAllRead());
  }

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(activityFeedProvider);

    return Scaffold(
      backgroundColor: DesignColors.background,
      appBar: AppBar(
        backgroundColor: DesignColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: DesignColors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Activity',
          style: TextStyle(
            color: DesignColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: ActivityFeedService.instance.markAllRead,
            child: const Text('Mark all read',
                style: TextStyle(color: DesignColors.accent, fontSize: 12)),
          ),
        ],
      ),
      body: feedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: DesignColors.accent)),
        error: (e, _) => Center(
          child: Text('Could not load activity: $e',
              style: const TextStyle(color: DesignColors.textGray)),
        ),
        data: (events) {
          if (events.isEmpty) {
            return _buildEmpty();
          }
          return RefreshIndicator(
            color: DesignColors.accent,
            backgroundColor: DesignColors.surfaceLight,
            onRefresh: () async {
              ref.invalidate(activityFeedProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: events.length,
              separatorBuilder: (_, __) => const Divider(
                  color: DesignColors.divider, height: 1, indent: 72),
              itemBuilder: (context, i) => _ActivityTile(event: events[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('✨', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        const Text('No activity yet',
            style: TextStyle(
                color: DesignColors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const Text('Follow people and join rooms\nto see their activity here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: DesignColors.textGray, fontSize: 14)),
        const SizedBox(height: 24),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: DesignColors.accent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => Navigator.pushNamed(context, AppRoutes.discovery),
          child: const Text('Discover People',
              style: TextStyle(color: DesignColors.white, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}

// ── Individual tile ──────────────────────────────────────────────────────────

class _ActivityTile extends StatelessWidget {
  final ActivityEvent event;
  const _ActivityTile({required this.event});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _handleTap(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: Colors.transparent,
        child: Row(children: [
          // Avatar
          Stack(clipBehavior: Clip.none, children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: DesignColors.surfaceLight,
              backgroundImage: event.actorPhotoUrl != null
                  ? NetworkImage(event.actorPhotoUrl!)
                  : null,
              child: event.actorPhotoUrl == null
                  ? Text(
                      event.actorName.isNotEmpty
                          ? event.actorName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: DesignColors.white,
                          fontWeight: FontWeight.w700))
                  : null,
            ),
            Positioned(
              right: -4,
              bottom: -4,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: DesignColors.surfaceDefault,
                  shape: BoxShape.circle,
                  border: Border.all(color: DesignColors.background, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(event.iconEmoji, style: const TextStyle(fontSize: 10)),
              ),
            ),
          ]),
          const SizedBox(width: 12),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.displayText,
                  style: const TextStyle(
                      color: DesignColors.white, fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 2),
                Text(
                  event.createdAt.toString(),
                  style: const TextStyle(
                      color: DesignColors.textGray, fontSize: 12),
                ),
              ],
            ),
          ),
          // Context thumbnail (if available)
          if (event.metadata['thumbnailUrl'] != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                event.metadata['thumbnailUrl'] as String,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
        ]),
      ),
    );
  }

  void _handleTap(BuildContext context) {
    switch (event.type) {
      case ActivityEventType.follow:
        Navigator.pushNamed(context, AppRoutes.userProfile,
            arguments: event.actorId);
        break;
      case ActivityEventType.like:
      case ActivityEventType.comment:
        // Navigate to the post if postId is available
        break;
      case ActivityEventType.roomJoin:
        final roomId = event.metadata['roomId'] as String?;
        if (roomId != null) {
          Navigator.pushNamed(context, AppRoutes.room, arguments: roomId);
        }
        break;
      case ActivityEventType.match:
        Navigator.pushNamed(context, AppRoutes.matches);
        break;
      default:
        break;
    }
  }

}
