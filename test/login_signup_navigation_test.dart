import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mixvy/features/auth/controllers/auth_controller.dart';
import 'package:mixvy/presentation/screens/mixvy_login_screen.dart';
import 'package:mocktail/mocktail.dart';
import 'test_helpers.dart';

void main() {
  setUpAll(() async {
    await testSetup();
  });

  setUp(() {
    when(() => mockAuth.currentUser).thenReturn(null);
    emitAuthState(null);
  });

  testWidgets('login screen exposes signup navigation', (tester) async {
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const MixVyLoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const Scaffold(
            body: Text('Register Screen'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(() => AuthController(auth: mockAuth)),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    expect(find.text("Don't have an account? Sign up"), findsOneWidget);

    await tester.tap(find.text("Don't have an account? Sign up"));
    await tester.pumpAndSettle();

    expect(find.text('Register Screen'), findsOneWidget);
  });
}
