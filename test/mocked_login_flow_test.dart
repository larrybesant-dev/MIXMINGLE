import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:mix_and_mingle/features/auth/testable_login_page.dart';
import 'package:mix_and_mingle/services/auth_service.dart';

// Generate mocks
@GenerateMocks([AuthService])
import 'mocked_login_flow_test.mocks.dart';

void main() {
  late MockAuthService mockAuthService;

  setUp(() {
    mockAuthService = MockAuthService();
  });

  testWidgets('Login form interaction with mocked auth service',
      (WidgetTester tester) async {
    when(mockAuthService.login(
      any,
      any,
    )).thenAnswer((_) async => MockUserCredential());

    // Track if login success callback was called
    bool loginSuccessCalled = false;

    // Build the testable login page with mocked auth service
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: TestableLoginPage(
            authService: mockAuthService,
            onLoginSuccess: () => loginSuccessCalled = true,
          ),
        ),
      ),
    );

    // Wait for the page to settle (no async Firebase initialization)
    await tester.pump();

    // Verify we're on the login page
    expect(find.text('Login'), findsOneWidget);

    // Enter email
    await tester.enterText(
        find.byKey(const Key('emailField')), 'test@example.com');
    await tester.pump();

    // Enter password
    await tester.enterText(find.byKey(const Key('passwordField')), 'Test123!!');
    await tester.pump();

    // Verify the login button exists and is enabled
    final loginButton = find.byKey(const Key('loginButton'));
    expect(loginButton, findsOneWidget);

    // Tap login button
    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    // Verify the login success callback was called
    expect(loginSuccessCalled, isTrue);

    // Verify the auth service was called with correct credentials
    verify(mockAuthService.login(
      'test@example.com',
      'Test123!!',
    )).called(1);
  });

  testWidgets('Login with invalid credentials shows error',
      (WidgetTester tester) async {
    // Setup mock to throw an exception for invalid credentials
    when(mockAuthService.login(
      any,
      any,
    )).thenThrow(Exception('Invalid credentials'));

    // Build the testable login page with mocked auth service
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: TestableLoginPage(authService: mockAuthService),
        ),
      ),
    );

    await tester.pump();

    // Enter invalid credentials
    await tester.enterText(
        find.byKey(const Key('emailField')), 'invalid@example.com');
    await tester.pump();

    await tester.enterText(
        find.byKey(const Key('passwordField')), 'wrongpassword');
    await tester.pump();

    // Tap login button
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pumpAndSettle();

    // Verify we're still on the login page (login failed)
    expect(find.text('Login'), findsOneWidget);

    // Check that error is shown
    expect(find.textContaining('Login failed'), findsOneWidget);

    // Verify the auth service was called
    verify(mockAuthService.login(
      'invalid@example.com',
      'wrongpassword',
    )).called(1);
  });
}

// Mock classes for testing
class MockUserCredential extends Mock implements UserCredential {}

class MockUser implements User {
  @override
  final String uid = 'test-user-id';
  @override
  final String? email = 'test@example.com';
  @override
  final String? displayName = 'Test User';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
