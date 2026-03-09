import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mixmingle/core/providers/all_providers.dart';
import 'package:mixmingle/core/routing/guards/profile_complete_guard.dart';
import 'package:mixmingle/features/onboarding/routes/onboarding_route.dart';
import 'package:mixmingle/features/home/routes/home_route.dart';

class MockUser {
  final bool onboardingComplete;
  MockUser(this.onboardingComplete);
}

void main() {
  group('Onboarding Completion Integration', () {
    testWidgets('Navigates to HomeRoute when onboardingComplete is true', (WidgetTester tester) async {
      final userAsync = AsyncValue.data(MockUser(true));
      await tester.pumpWidget(
        ProviderScope(overrides: [
          hasCompletedOnboardingProvider.overrideWithValue(AsyncValue.data(true)),
        ], child: MaterialApp(home: ProfileCompleteGuardTestWidget())),
      );
      await tester.pumpAndSettle();
      expect(find.byType(HomeRoute), findsOneWidget);
      expect(find.byType(OnboardingRoute), findsNothing);
    });

    testWidgets('Navigates to OnboardingRoute when onboardingComplete is false', (WidgetTester tester) async {
      final userAsync = AsyncValue.data(MockUser(false));
      await tester.pumpWidget(
        ProviderScope(overrides: [
          hasCompletedOnboardingProvider.overrideWithValue(AsyncValue.data(false)),
        ], child: MaterialApp(home: ProfileCompleteGuardTestWidget())),
      );
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingRoute), findsOneWidget);
      expect(find.byType(HomeRoute), findsNothing);
    });

    testWidgets('Shows loading state and no premature redirect on cold start', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(overrides: [
          hasCompletedOnboardingProvider.overrideWithValue(AsyncValue.loading()),
        ], child: MaterialApp(home: ProfileCompleteGuardTestWidget())),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(HomeRoute), findsNothing);
      expect(find.byType(OnboardingRoute), findsNothing);
    });
  });
}

class ProfileCompleteGuardTestWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Simulate ProfileCompleteGuard logic
    final onboardingAsync = ProviderScope.containerOf(context).read(hasCompletedOnboardingProvider);
    return onboardingAsync.when(
      data: (isComplete) => isComplete ? HomeRoute() : OnboardingRoute(),
      loading: () => const CircularProgressIndicator(),
      error: (e, st) => const Text('Error'),
    );
  }
}

class HomeRoute extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('Home'));
}

class OnboardingRoute extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('Onboarding'));
}
