import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notifications_service.dart';

final notificationsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, userId) async {
  return await NotificationsService().getNotifications(userId);
});
