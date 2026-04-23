import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import 'app_settings_provider.dart';
import 'user_provider.dart';

final notificationFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(firestore: ref.watch(notificationFirestoreProvider));
});

final currentNotificationUserIdProvider = Provider<String?>((ref) {
  return ref.watch(userProvider)?.id;
});

final notificationsEnabledProvider = Provider<bool>((ref) {
  return ref.watch(appSettingsControllerProvider).valueOrNull?.notificationsEnabled ?? true;
});

final notificationsStreamProvider = StreamProvider<List<NotificationModel>>((ref) {
  final userId = ref.watch(currentNotificationUserIdProvider);
  if (userId == null) {
    return const Stream<List<NotificationModel>>.empty();
  }

  return ref.watch(notificationServiceProvider).notificationsForUser(userId);
});

/// Count of unread notifications for the current user. Derived from the
/// notifications stream so it stays live without an extra Firestore query.
final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref
      .watch(notificationsStreamProvider)
      .whenData(
        (list) => list.where((n) => !n.isRead).length,
      )
      .valueOrNull ?? 0;
});
