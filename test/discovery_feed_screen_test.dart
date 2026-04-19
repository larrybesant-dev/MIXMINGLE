import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixvy/features/ads/ad_manager.dart';
import 'package:mixvy/features/feed/controllers/feed_controller.dart';
import 'package:mixvy/features/profile/profile_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

/// Minimal widget that mirrors the promo banner conditional in
/// [DiscoveryFeedContent], without pulling in [StoriesRow] or any
/// Firebase dependency.
class _PromoBanner extends ConsumerWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membership = ref.watch(
      profileControllerProvider.select((s) => s.membershipLevel ?? 'Free'),
    );
    if (!AdManager.shouldShowAds(membership)) {
      return const SizedBox.shrink();
    }
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Upgrade to MixVy Premium'),
        Text('Remove ads and unlock exclusive features.'),
        Text('Upgrade'),
      ],
    );
  }
}

Widget _buildWidget(List<Override> overrides) {
  return ProviderScope(
    overrides: overrides,
    child: const MaterialApp(home: Scaffold(body: _PromoBanner())),
  );
}

void main() {
  group('FeedState timing defaults', () {
    test('starts in loading mode to avoid a first-frame empty flash', () {
      const state = FeedState();

      expect(state.isLoading, isTrue);
      expect(state.liveRooms, isEmpty);
      expect(state.trendingUsers, isEmpty);
    });
  });

  group('AdManager.shouldShowAds', () {
    test('returns true for Free membership', () {
      expect(AdManager.shouldShowAds('Free'), isTrue);
    });

    test('returns false for Premium membership', () {
      expect(AdManager.shouldShowAds('Premium'), isFalse);
    });

    test('returns false for Gold membership', () {
      expect(AdManager.shouldShowAds('Gold'), isFalse);
    });

    test('returns false for any non-Free value', () {
      for (final level in ['VIP', 'Pro', 'Elite', 'Subscriber']) {
        expect(AdManager.shouldShowAds(level), isFalse,
            reason: 'Expected ads hidden for "$level"');
      }
    });
  });

  group('DiscoveryFeedContent -- promo banner', () {
    testWidgets('shows banner when membershipLevel is Free', (tester) async {
      await tester.pumpWidget(
        _buildWidget([
          profileControllerProvider.overrideWith(
            () => _StubProfileController(
              const ProfileState(membershipLevel: 'Free', followers: []),
            ),
          ),
        ]),
      );
      await tester.pump();

      expect(find.text('Upgrade to MixVy Premium'), findsOneWidget);
      expect(find.text('Remove ads and unlock exclusive features.'), findsOneWidget);
      expect(find.text('Upgrade'), findsOneWidget);
    });

    testWidgets('hides banner when membershipLevel is Premium', (tester) async {
      await tester.pumpWidget(
        _buildWidget([
          profileControllerProvider.overrideWith(
            () => _StubProfileController(
              const ProfileState(membershipLevel: 'Premium', followers: []),
            ),
          ),
        ]),
      );
      await tester.pump();

      expect(find.text('Upgrade to MixVy Premium'), findsNothing);
    });

    testWidgets('hides banner when membershipLevel is Gold', (tester) async {
      await tester.pumpWidget(
        _buildWidget([
          profileControllerProvider.overrideWith(
            () => _StubProfileController(
              const ProfileState(membershipLevel: 'Gold', followers: []),
            ),
          ),
        ]),
      );
      await tester.pump();

      expect(find.text('Upgrade to MixVy Premium'), findsNothing);
    });

    testWidgets('shows banner when membershipLevel is null (defaults to Free)',
        (tester) async {
      await tester.pumpWidget(
        _buildWidget([
          profileControllerProvider.overrideWith(
            () => _StubProfileController(
              const ProfileState(followers: []),
            ),
          ),
        ]),
      );
      await tester.pump();

      expect(find.text('Upgrade to MixVy Premium'), findsOneWidget);
    });
  });
}

/// Stub [ProfileController] that returns a fixed [ProfileState] without
/// requiring Firebase or Firestore. Passes a [_MockFirebaseAuth] and
/// [FakeFirebaseFirestore] so no real Firebase.instance is ever accessed.
class _StubProfileController extends ProfileController {
  final ProfileState _state;
  _StubProfileController(this._state)
      : super(auth: _MockFirebaseAuth(), firestore: FakeFirebaseFirestore());

  @override
  ProfileState build() => _state;
}
