import 'package:flutter_test/flutter_test.dart';
import 'package:MIXVY/lib/features/notifications/notification.dart';

void main() {
  group('NotificationItem', () {
    test('copyWith returns updated notification', () {
      final notification = NotificationItem(
        id: '1',
        userId: '2',
        title: 'Welcome',
        body: 'Hello',
        timestamp: DateTime.now(),
        read: false,
      );
      final updated = notification.copyWith(read: true);
      expect(updated.read, true);
      expect(updated.title, 'Welcome');
    });
  });
}
