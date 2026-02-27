// lib/shared/providers/notification_providers.dart
//
// Riverpod providers for the in-app Notification System.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/notifications/app_notification_service.dart';
import '../../shared/models/app_notification.dart';

// ── Service ────────────────────────────────────────────────────────────────────

final appNotificationServiceProvider = Provider<AppNotificationService>((ref) {
  return AppNotificationService.instance;
});

// ── Real-time streams ──────────────────────────────────────────────────────────

/// Full live notification list for the current user.
final appNotificationsProvider =
    StreamProvider<List<AppNotification>>((ref) {
  return ref
      .watch(appNotificationServiceProvider)
      .streamUserNotifications();
});

/// Live unread notification count — drives the bell badge.
final unreadNotificationCountProvider = StreamProvider<int>((ref) {
  return ref
      .watch(appNotificationServiceProvider)
      .streamUnreadCount();
});

/// Whether the user has ANY unread notifications (for simple badge check).
final hasUnreadNotificationsProvider = Provider<bool>((ref) {
  final count = ref.watch(unreadNotificationCountProvider).asData?.value ?? 0;
  return count > 0;
});

// ── Grouped notifications ──────────────────────────────────────────────────────

/// Notifications partitioned by [AppNotification.groupLabel].
final groupedNotificationsProvider =
    Provider<Map<String, List<AppNotification>>>((ref) {
  final notifications =
      ref.watch(appNotificationsProvider).asData?.value ?? [];
  final Map<String, List<AppNotification>> grouped = {};
  for (final notif in notifications) {
    grouped.putIfAbsent(notif.groupLabel, () => []).add(notif);
  }
  return grouped;
});

// ── Actions ────────────────────────────────────────────────────────────────────

final markNotificationReadProvider =
    FutureProvider.family<void, String>((ref, notificationId) async {
  await ref
      .read(appNotificationServiceProvider)
      .markAsRead(notificationId);
});

final markAllNotificationsReadProvider = FutureProvider<void>((ref) async {
  await ref
      .read(appNotificationServiceProvider)
      .markAllAsRead();
  ref.invalidate(appNotificationsProvider);
  ref.invalidate(unreadNotificationCountProvider);
});

final deleteNotificationProvider =
    FutureProvider.family<void, String>((ref, notificationId) async {
  await ref
      .read(appNotificationServiceProvider)
      .deleteNotification(notificationId);
  ref.invalidate(appNotificationsProvider);
});

// ── Badge state (combined friends + notifications) ─────────────────────────────

/// Total badge count = unread notifications + pending friend requests.
/// Import both providers and combine here.
final totalBadgeCountProvider = Provider<int>((ref) {
  final notifCount =
      ref.watch(unreadNotificationCountProvider).asData?.value ?? 0;
  return notifCount;
});
