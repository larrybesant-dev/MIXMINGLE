import 'package:flutter_test/flutter_test.dart';
import 'package:MIXVY/lib/features/connections/connection.dart';

void main() {
  group('Connection', () {
    test('copyWith returns updated connection', () {
      final connection = Connection(
        id: '1',
        userId: '2',
        status: 'pending',
      );
      final updated = connection.copyWith(status: 'accepted');
      expect(updated.status, 'accepted');
      expect(updated.userId, '2');
    });
  });
}
