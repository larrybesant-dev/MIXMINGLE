<<<<<<< HEAD
﻿import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/providers/providers.dart';
import '../../shared/models/notification.dart' as model;
import '../../features/error/error_page.dart';
import '../../shared/club_background.dart';
import '../../shared/glow_text.dart';
import '../../shared/loading_widgets.dart';
import '../../core/routing/app_routes.dart';
=======
// lib/features/notifications/notifications_page.dart
//
// Notifications Page — grouped by category, real-time, with mark-all-read.
//
// Groups: Chats · Feed · Friend Requests · Room Invites · Matches · Tips ·
//         Followers · System
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/providers/notification_providers.dart';
import '../../shared/models/app_notification.dart';
import '../../core/design_system/design_constants.dart';
import '../../shared/widgets/club_background.dart';
import 'widgets/notification_tile.dart';

// ── Group display order ────────────────────────────────────────────────────────
const _kGroupOrder = [
  'Chats',
  'Friend Requests',
  'Matches',
  'Feed',
  'Room Invites',
  'Tips',
  'Followers',
  'System',
];
>>>>>>> origin/develop

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(appNotificationsProvider);
    final unreadCount =
        ref.watch(unreadNotificationCountProvider).asData?.value ?? 0;

<<<<<<< HEAD
    return currentUser.when(
      data: (user) {
        if (user == null) {
          return const ErrorPage(
            errorMessage: 'User not authenticated',
          );
        }

        final notificationsAsync = ref.watch(notificationsProvider(user.id));

        return ClubBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: const GlowText(
                text: 'Notifications',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFD700),
                glowColor: Color(0xFFFF4C4C),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            body: notificationsAsync.when(
              data: (notifications) {
                if (notifications.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 64,
                          color: Colors.white54,
                        ),
                        SizedBox(height: 16),
                        GlowText(
                          text: 'No notifications yet',
                          fontSize: 18,
                          color: Colors.white70,
                          glowColor: Color(0xFFFF4C4C),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'You\'ll see updates about your rooms and followers here',
                          style: TextStyle(color: Colors.white54),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return _buildNotificationTile(
                        context, ref, notification, user.id);
                  },
                );
              },
              loading: () =>
                  const FullScreenLoader(message: 'Loading notifications...'),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const GlowText(
                      text: 'Failed to load notifications',
                      fontSize: 18,
                      color: Color(0xFFFF4C4C),
                      glowColor: Color(0xFFFF4C4C),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: const TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Semantics(
                      label: 'Retry loading notifications',
                      button: true,
                      child: ElevatedButton(
                        onPressed: () =>
                            ref.invalidate(notificationsProvider(user.id)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF4C4C),
                        ),
                        child: const Text('Retry'),
                      ),
                    ),
                  ],
=======
    return ClubBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: DesignColors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              const Text(
                'NOTIFICATIONS',
                style: TextStyle(
                  color: DesignColors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: 1.5,
>>>>>>> origin/develop
                ),
              ),
              if (unreadCount > 0) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFFFF4D8B), Color(0xFFFF6B35)]),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFFFF4D8B)
                              .withValues(alpha: 0.5),
                          blurRadius: 8),
                    ],
                  ),
                  child: Text(
                    '$unreadCount',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            if (unreadCount > 0)
              TextButton(
                onPressed: () =>
                    ref.read(markAllNotificationsReadProvider.future),
                child: const Text(
                  'Mark all read',
                  style: TextStyle(
                      color: DesignColors.accent, fontSize: 12),
                ),
              ),
          ],
        ),
        body: notifAsync.when(
          data: (notifications) =>
              _buildBody(context, ref, notifications),
          loading: () => const Center(
            child: CircularProgressIndicator(
                color: DesignColors.accent),
          ),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    color: Colors.redAccent, size: 48),
                const SizedBox(height: 12),
                const Text('Error loading notifications',
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(appNotificationsProvider),
                  child: const Text('Retry',
                      style: TextStyle(color: DesignColors.accent)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

<<<<<<< HEAD
  Widget _buildNotificationTile(
    BuildContext context,
    WidgetRef ref,
    model.Notification notification,
    String userId,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFF4C4C).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFFF4C4C),
          child: Icon(
            _getNotificationIcon(notification.type),
            color: Colors.white,
          ),
        ),
        title: Text(
          notification.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
=======
  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    List<AppNotification> notifications,
  ) {
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
>>>>>>> origin/develop
          children: [
            Icon(Icons.notifications_none,
                size: 72,
                color: DesignColors.accent.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text(
              'All caught up!',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'No notifications yet.\nWe\'ll let you know when something happens.',
              style: TextStyle(color: Colors.white38, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
<<<<<<< HEAD
        trailing: notification.isRead
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF4C4C),
                  shape: BoxShape.circle,
                ),
              ),
        onTap: () {
          if (!notification.isRead) {
            FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('notifications')
                .doc(notification.id)
                .update({'isRead': true}).catchError((_) {});
          }
          switch (notification.type) {
            case model.NotificationType.message:
              Navigator.pushNamed(context, AppRoutes.chats);
            case model.NotificationType.roomInvite:
              if (notification.roomId != null) {
                Navigator.pushNamed(context, AppRoutes.rooms);
              }
            case model.NotificationType.newFollower:
            case model.NotificationType.match:
            case model.NotificationType.like:
              if (notification.senderId != null) {
                Navigator.pushNamed(
                  context,
                  AppRoutes.userProfile,
                  arguments: notification.senderId,
                );
              }
            default:
              break;
          }
        },
      ),
=======
      );
    }

    // Partition into groups
    final Map<String, List<AppNotification>> grouped = {};
    for (final n in notifications) {
      grouped.putIfAbsent(n.groupLabel, () => []).add(n);
    }

    // Build ordered section list
    final sections = <Widget>[];
    for (final groupName in _kGroupOrder) {
      final items = grouped[groupName];
      if (items == null || items.isEmpty) continue;
      sections.add(_GroupSection(
          label: groupName,
          notifications: items));
    }
    // Any groups not in the ordered list (future types)
    for (final entry in grouped.entries) {
      if (!_kGroupOrder.contains(entry.key)) {
        sections.add(_GroupSection(
            label: entry.key,
            notifications: entry.value));
      }
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: sections,
>>>>>>> origin/develop
    );
  }
}

<<<<<<< HEAD
  IconData _getNotificationIcon(model.NotificationType type) {
    switch (type) {
      case model.NotificationType.roomInvite:
        return Icons.room;
      case model.NotificationType.newFollower:
        return Icons.person_add;
      case model.NotificationType.tip:
        return Icons.attach_money;
      case model.NotificationType.message:
        return Icons.message;
      case model.NotificationType.reaction:
        return Icons.favorite;
      case model.NotificationType.system:
        return Icons.info;
      case model.NotificationType.match:
        return Icons.favorite_border;
      case model.NotificationType.like:
        return Icons.thumb_up;
    }
  }
=======
// ── Section with sticky label ─────────────────────────────────────────────────
>>>>>>> origin/develop

class _GroupSection extends StatelessWidget {
  final String label;
  final List<AppNotification> notifications;

  const _GroupSection({required this.label, required this.notifications});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              color: DesignColors.accent.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
        ),
        const Divider(color: Colors.white10, height: 1, indent: 16, endIndent: 16),

        // Tiles
        ...notifications.map((n) => NotificationTile(notification: n)),
      ],
    );
  }
}
