// Riverpod provider for Notifications
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart';
import 'notification.dart';

final notificationProvider = StateProvider<List<NotificationItem>>((ref) => []);
