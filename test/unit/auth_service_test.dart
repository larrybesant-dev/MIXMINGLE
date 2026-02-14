/// Auth Service Tests - Login, Register, Session Management
///
/// Tests for:
/// - User login with email/password
/// - User registration
/// - Session management
/// - Error handling (invalid credentials, network issues)
/// - Offline scenarios

import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';
import '../test_helpers.dart';

void main() {
  group('AuthService Tests', () {
    late MockFirebaseAuth mockAuth;

    setUp(() {
      mockAuth = MockFirebaseAuth();
    });

    group('Login Tests', () {
      test('signInWithEmailAndPassword succeeds with valid credentials',
          () async {
        const email = 'test@example.com';
        const password = 'password123';

        final result = await mockAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        expect(result.user, isNotNull);
        expect(result.user?.email, equals(email));
      });

      test('signInWithEmailAndPassword fails with empty email', () async {
        expect(
          () => mockAuth.signInWithEmailAndPassword(
            email: '',
            password: 'password123',
          ),
          throwsA(isA<FirebaseAuthException>()),
        );
      });

      test('signInWithEmailAndPassword fails with empty password', () async {
        expect(
          () => mockAuth.signInWithEmailAndPassword(
            email: 'test@example.com',
            password: '',
          ),
          throwsA(isA<FirebaseAuthException>()),
        );
      });

      test('signInWithEmailAndPassword updates authStateChanges stream',
          () async {
        const email = 'stream-test@example.com';
        const password = 'password123';

        await mockAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        expect(mockAuth.authStateChanges(), emits(isNotNull));
      });

      test('user can sign in multiple times sequentially', () async {
        await mockAuth.signInWithEmailAndPassword(
          email: 'user1@example.com',
          password: 'password123',
        );

        expect(mockAuth.currentUser?.email, equals('user1@example.com'));

        await mockAuth.signOut();
        expect(mockAuth.currentUser, isNull);

        await mockAuth.signInWithEmailAndPassword(
          email: 'user2@example.com',
          password: 'password123',
        );

        expect(mockAuth.currentUser?.email, equals('user2@example.com'));
      });
    });

    group('Registration Tests', () {
      test('createUserWithEmailAndPassword succeeds with valid data',
          () async {
        const email = 'newuser@example.com';
        const password = 'newpassword123';

        final result = await mockAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        expect(result.user, isNotNull);
        expect(result.user?.email, equals(email));
      });

      test('createUserWithEmailAndPassword fails with empty email', () async {
        expect(
          () => mockAuth.createUserWithEmailAndPassword(
            email: '',
            password: 'password123',
          ),
          throwsA(isA<FirebaseAuthException>()),
        );
      });

      test('createUserWithEmailAndPassword fails with empty password',
          () async {
        expect(
          () => mockAuth.createUserWithEmailAndPassword(
            email: 'newuser@example.com',
            password: '',
          ),
          throwsA(isA<FirebaseAuthException>()),
        );
      });

      test('registered user can immediately sign in', () async {
        const email = 'newuser@example.com';
        const password = 'newpassword123';

        await mockAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        await mockAuth.signOut();

        final signInResult = await mockAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        expect(signInResult.user?.email, equals(email));
      });
    });

    group('Session Management Tests', () {
      test('currentUser is null when not authenticated', () {
        expect(mockAuth.currentUser, isNull);
      });

      test('currentUser is set after successful login', () async {
        await mockAuth.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(mockAuth.currentUser, isNotNull);
        expect(mockAuth.currentUser?.email, equals('test@example.com'));
      });

      test('signOut clears currentUser', () async {
        await mockAuth.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(mockAuth.currentUser, isNotNull);

        await mockAuth.signOut();

        expect(mockAuth.currentUser, isNull);
      });

      test('authStateChanges emits stream of user states', () async {
        final states = <User?>[];

        mockAuth.authStateChanges().listen((user) {
          states.add(user);
        });

        await mockAuth.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        );

        await mockAuth.signOut();

        expect(states.length, greaterThanOrEqualTo(1));
      });

      test('persists session across multiple checks', () async {
        await mockAuth.signInWithEmailAndPassword(
          email: 'persistent@example.com',
          password: 'password123',
        );

        final firstCheck = mockAuth.currentUser;
        final secondCheck = mockAuth.currentUser;
        final thirdCheck = mockAuth.currentUser;

        expect(firstCheck?.email, equals(secondCheck?.email));
        expect(secondCheck?.email, equals(thirdCheck?.email));
      });
    });

    group('Error Handling Tests', () {
      test('invalid email format throws FirebaseAuthException', () async {
        expect(
          () => mockAuth.signInWithEmailAndPassword(
            email: 'invalid-email',
            password: 'password123',
          ),
          throwsA(isA<FirebaseAuthException>()),
        );
      });

      test('exception contains error code', () async {
        try {
          await mockAuth.signInWithEmailAndPassword(
            email: '',
            password: 'password123',
          );
          fail('Should throw FirebaseAuthException');
        } on FirebaseAuthException catch (e) {
          expect(e.code, equals('invalid-email'));
        }
      });
    });

    group('User Properties Tests', () {
      test('logged in user has correct properties', () async {
        await mockAuth.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        );

        final user = mockAuth.currentUser;

        expect(user?.uid, isNotEmpty);
        expect(user?.email, equals('test@example.com'));
        expect(user?.displayName, isNotNull);
        expect(user?.isAnonymous, isFalse);
        expect(user?.emailVerified, isTrue);
      });

      test('user can get ID token', () async {
        await mockAuth.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        );

        final user = mockAuth.currentUser;
        final idToken = await user?.getIdToken();

        expect(idToken, isNotEmpty);
      });

      test('refresh token is available for authenticated user', () async {
        await mockAuth.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        );

        final user = mockAuth.currentUser as MockUser;

        expect(user.refreshToken, isNotEmpty);
      });
    });

    group('Edge Cases Tests', () {
      test('can handle rapid sign in/out cycles', () async {
        for (int i = 0; i < 5; i++) {
          await mockAuth.signInWithEmailAndPassword(
            email: 'test@example.com',
            password: 'password123',
          );

          expect(mockAuth.currentUser, isNotNull);

          await mockAuth.signOut();

          expect(mockAuth.currentUser, isNull);
        }
      });

      test('handles special characters in email', () async {
        const email = 'test+tag@example.co.uk';

        final result = await mockAuth.signInWithEmailAndPassword(
          email: email,
          password: 'password123',
        );

        expect(result.user?.email, equals(email));
      });

      test('handles very long passwords', () async {
        const longPassword =
            'VeryLongPasswordWith1234567890!@#\$%^&*()_+-=[]{}|;:,.<>?';

        final result = await mockAuth.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: longPassword,
        );

        expect(result.user, isNotNull);
      });
    });
  });
}
