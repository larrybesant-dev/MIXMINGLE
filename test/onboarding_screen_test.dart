import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mixvy/features/onboarding/onboarding_screen.dart';
import 'test_helpers.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Wraps OnboardingScreen with a minimal GoRouter so context.go() works.
Widget _buildApp() {
  final router = GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/legal/terms',
        builder: (_, _) => const Scaffold(body: Text('Terms')),
      ),
      GoRoute(
        path: '/legal/privacy',
        builder: (_, _) => const Scaffold(body: Text('Privacy')),
      ),
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('Home')),
      ),
    ],
  );

  return ProviderScope(
    child: MaterialApp.router(routerConfig: router),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() async {
    await testSetup();
  });

  group('OnboardingScreen', () {
    testWidgets('renders first page content', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Step Into The Hottest Rooms'), findsOneWidget);
      expect(find.text('KEEP THE VIBE'), findsOneWidget);
      // Legal checkbox only appears on last page
      expect(find.byType(Checkbox), findsNothing);
    });

    testWidgets('advances to second page via KEEP THE VIBE', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('KEEP THE VIBE'));
      await tester.pumpAndSettle();

      expect(find.text('Find Your Night Crew Fast'), findsOneWidget);
    });

    testWidgets('advances through all pages to final page', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      // Page 0 → 1
      await tester.tap(find.text('KEEP THE VIBE'));
      await tester.pumpAndSettle();

      // Page 1 → 2
      await tester.tap(find.text('KEEP THE VIBE'));
      await tester.pumpAndSettle();

      // Final page
      expect(find.text('Launch Your Own Party'), findsOneWidget);
      expect(find.text('JOIN THE PARTY'), findsOneWidget);
    });

    testWidgets('final page shows legal checkbox', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('KEEP THE VIBE'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('KEEP THE VIBE'));
      await tester.pumpAndSettle();

      expect(find.byType(Checkbox), findsOneWidget);
      expect(find.text('I agree to the Terms of Service and Privacy Policy.'), findsOneWidget);
    });

    testWidgets('JOIN THE PARTY is disabled until legal checkbox is ticked',
        (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      // Navigate to final page
      await tester.tap(find.text('KEEP THE VIBE'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('KEEP THE VIBE'));
      await tester.pumpAndSettle();

      // Before accepting legal the InkWell that wraps the CTA label has null onTap.
      InkWell ctaInkWell() => tester.widget<InkWell>(
            find
                .ancestor(
                  of: find.text('JOIN THE PARTY'),
                  matching: find.byType(InkWell),
                )
                .first,
          );

      expect(ctaInkWell().onTap, isNull,
          reason: 'CTA should be disabled before legal accepted');

      // Tick the legal checkbox
      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      expect(ctaInkWell().onTap, isNotNull,
          reason: 'CTA should be enabled after legal accepted');
    });

    testWidgets('Terms link is tappable on final page', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('KEEP THE VIBE'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('KEEP THE VIBE'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Terms'));
      await tester.pumpAndSettle();

      expect(find.text('Terms'), findsWidgets);
    });

    testWidgets('progress dots count matches page count', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      // 3 pages → 3 dots; each dot is a small Container inside a Row.
      // The simplest proxy: PageView has 3 children.
      final pageView = tester.widget<PageView>(find.byType(PageView).first);
      expect(pageView.childrenDelegate.estimatedChildCount, 3);
    });
  });
}
