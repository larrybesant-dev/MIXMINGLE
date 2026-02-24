// lib/helpers/helpers.dart
// Minimal helper stubs to unblock builds/tests.
// Replace with real implementations as needed.

library;

/// Minimal AppNotification used by tests and code that reference it.
class AppNotification {
  final String id;
  final String title;
  final String? body;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.title,
    this.body,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  @override
  String toString() => 'AppNotification($id, $title)';
}

/// Minimal notifications provider stub.
/// Replace with your real provider (Riverpod/Provider/etc.) implementation.
class NotificationsProvider {
  final List<AppNotification> _items = [];

  void add(AppNotification n) => _items.add(n);
  List<AppNotification> get all => List.unmodifiable(_items);
  void clear() => _items.clear();
}

/// Export a top-level instance named `notificationsProvider` to satisfy tests.
final NotificationsProvider notificationsProvider = NotificationsProvider();

/// Minimal utility functions used across the app.
/// Add real implementations as needed.
String formatDurationShort(Duration d) {
  if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
  if (d.inMinutes > 0) return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
  return '${d.inSeconds}s';
}
