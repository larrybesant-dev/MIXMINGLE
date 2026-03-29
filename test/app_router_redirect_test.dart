import 'package:flutter_test/flutter_test.dart';
import 'package:mixvy/router/app_router.dart';

void main() {
  group('evaluateAppRedirect', () {
    test('routes first-run users to onboarding', () async {
      final result = await evaluateAppRedirect(
        matchedLocation: '/',
        uid: null,
        isFirstRun: () async => true,
        isProfileComplete: (_) async => true,
        isLegalAccepted: () async => false,
      );

      expect(result, '/onboarding');
    });

    test('routes logged-out users to login after onboarding', () async {
      final result = await evaluateAppRedirect(
        matchedLocation: '/',
        uid: null,
        isFirstRun: () async => false,
        isProfileComplete: (_) async => true,
        isLegalAccepted: () async => true,
      );

      expect(result, '/login');
    });

    test('routes logged-in users with incomplete profile to profile', () async {
      final result = await evaluateAppRedirect(
        matchedLocation: '/',
        uid: 'user-1',
        isFirstRun: () async => false,
        isProfileComplete: (_) async => false,
        isLegalAccepted: () async => true,
      );

      expect(result, '/profile');
    });

    test('keeps logged-in user on profile when incomplete', () async {
      final result = await evaluateAppRedirect(
        matchedLocation: '/profile',
        uid: 'user-1',
        isFirstRun: () async => false,
        isProfileComplete: (_) async => false,
        isLegalAccepted: () async => true,
      );

      expect(result, isNull);
    });

    test('routes logged-in users away from login', () async {
      final result = await evaluateAppRedirect(
        matchedLocation: '/login',
        uid: 'user-1',
        isFirstRun: () async => false,
        isProfileComplete: (_) async => true,
        isLegalAccepted: () async => true,
      );

      expect(result, '/');
    });

    test('routes users to legal terms when current legal is not accepted', () async {
      final result = await evaluateAppRedirect(
        matchedLocation: '/login',
        uid: null,
        isFirstRun: () async => false,
        isProfileComplete: (_) async => true,
        isLegalAccepted: () async => false,
      );

      expect(result, '/legal/terms');
    });
  });
}
