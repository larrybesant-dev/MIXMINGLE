import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthService Tests', () {
    test('should validate email format', () {
      // Valid email formats
      expect(() => _validateEmail('test@example.com'), returnsNormally);
      expect(() => _validateEmail('user@domain.co.uk'), returnsNormally);

      // Invalid formats
      expect(
        () => _validateEmail('notanemail'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => _validateEmail('missing@'),
        throwsA(isA<FormatException>()),
      );
    });

    test('should validate password strength', () {
      // Strong password
      expect(() => _validatePassword('StrongPass123'), returnsNormally);

      // Weak passwords
      expect(
        () => _validatePassword('weak'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => _validatePassword('nouppercasehere1'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => _validatePassword('NoNumbers'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should enforce rate limiting after max attempts', () {
      // Create 6 failed attempts in last 15 minutes
      final now = DateTime.now();
      final recentAttempts = [
        now,
        now.subtract(Duration(minutes: 1)),
        now.subtract(Duration(minutes: 2)),
        now.subtract(Duration(minutes: 3)),
        now.subtract(Duration(minutes: 5)),
        now.subtract(Duration(minutes: 10)),
      ];

      // Should be rate limited (6 attempts > 5 max)
      final isLimited = _checkRateLimit(recentAttempts, maxAttempts: 5);
      expect(isLimited, isTrue);

      // Only 3 attempts within window should not be limited
      final fewAttempts = [
        now,
        now.subtract(Duration(minutes: 1)),
        now.subtract(Duration(minutes: 2)),
      ];
      final isNotLimited = _checkRateLimit(fewAttempts, maxAttempts: 5);
      expect(isNotLimited, isFalse);
    });

    test('should handle rate limit edge cases', () {
      final now = DateTime.now();

      // Attempts from over 15 minutes ago should not count
      final oldAttempts = [
        now.subtract(Duration(minutes: 20)),
        now.subtract(Duration(minutes: 30)),
      ];
      final isNotLimited = _checkRateLimit(oldAttempts, maxAttempts: 5);
      expect(isNotLimited, isFalse);

      // Empty list should not be rate limited
      expect(_checkRateLimit([], maxAttempts: 5), isFalse);
    });
  });
}

// Helper validation functions (mimicking service logic)
void _validateEmail(String email) {
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  if (!emailRegex.hasMatch(email)) {
    throw FormatException('Invalid email format');
  }
}

void _validatePassword(String password) {
  if (password.length < 8) {
    throw ArgumentError('Password must be at least 8 characters');
  }
  if (!password.contains(RegExp(r'[A-Z]'))) {
    throw ArgumentError('Password must contain uppercase letter');
  }
  if (!password.contains(RegExp(r'[0-9]'))) {
    throw ArgumentError('Password must contain number');
  }
}

bool _checkRateLimit(List<DateTime> attempts, {int maxAttempts = 5}) {
  final now = DateTime.now();
  final recentAttempts = attempts
      .where(
        (time) => now.difference(time).inMinutes < 15,
      )
      .length;
  return recentAttempts >= maxAttempts;
}
