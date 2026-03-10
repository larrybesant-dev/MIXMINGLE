/// Vibe Intelligence Service
/// Powers Vybe Social's self-improving discovery systems:
///   #1 — Vibe Affinity tracking (vibeHistory writes to Firestore)
///   #7 — Auto vibe suggestion logic (computed client-side)
///  #10 — Behavior tag helpers (mirrored by Cloud Function nightly)
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_profile.dart';

// ─────────────────────────────────────────────────────────────────────────────

final vibeIntelligenceServiceProvider = Provider<VibeIntelligenceService>((ref) {
  return VibeIntelligenceService(FirebaseFirestore.instance);
});

// ─────────────────────────────────────────────────────────────────────────────

class VibeIntelligenceService {
  final FirebaseFirestore _db;

  const VibeIntelligenceService(this._db);

  // ── #1: Vibe Affinity ─────────────────────────────────────────────────────

  /// Call this every time a user joins a room with a vibeTag.
  /// Increments the vibe counter in Firestore atomically.
  Future<void> recordVibeJoin({
    required String userId,
    required String vibeTag,
  }) async {
    if (vibeTag.isEmpty) return;
    await _db.collection('users').doc(userId).update({
      'vibeHistory.$vibeTag': FieldValue.increment(1),
    });
  }

  // ── #7: Vibe Suggestion ───────────────────────────────────────────────────

  /// Returns a suggestion nudge string if the user has been stuck in
  /// the same vibe ≥ [threshold] times, otherwise null.
  ///
  /// e.g. "You've been Chill lately — try a Hype room 🔥"
  String? getVibeSuggestion(UserProfile p, {int threshold = 3}) {
    final history = p.vibeHistoryOrEmpty;
    if (history.isEmpty) return null;

    final top = p.topVibeOrEmpty;
    final topCount = p.topVibeCountOrZero;
    if (top.isEmpty || topCount < threshold) return null;

    // Find an alternative vibe to suggest
    final alternatives = _kVibes
        .where((v) => v != top)
        .toList()
      ..sort(); // deterministic across builds
    if (alternatives.isEmpty) return null;

    // Prefer a vibe the user has never tried
    final neverTried = alternatives
        .where((v) => !history.containsKey(v))
        .toList();

    final suggestion = neverTried.isNotEmpty
        ? neverTried.first
        : alternatives.reduce(
            (a, b) => (history[a] ?? 0) < (history[b] ?? 0) ? a : b,
          );

    final emojis = {
      'Chill': '🌊',
      'Hype': '🔥',
      'Deep Talk': '🧠',
      'Late Night': '🌙',
      'Study': '📚',
      'Party': '🎉',
    };

        return "You've been $top lately — try a $suggestion room ${emojis[suggestion] ?? '✨'}";
  }

  // ── #10: Behavior Tag Computation (client-side mirror) ───────────────────

  /// Computes behavior tags from a user's profile metrics.
  /// The Cloud Function runs this nightly and writes the results back to
  /// Firestore. This client-side version enables instant previews during
  /// onboarding and testing.
  List<String> computeBehaviorTags(UserProfile p) {
    final tags = <String>[];

    // Activity tiers
    if (p.roomsHostedCountOrZero >= 10) {
      tags.add('Super Host');
    } else if (p.roomsHostedCountOrZero >= 3) {
      tags.add('Rising Host');
    }

    if (p.totalRoomsJoinedOrZero >= 50) {
      tags.add('Room Regular');
    } else if (p.totalRoomsJoinedOrZero >= 20) {
      tags.add('Social Butterfly');
    }

    if (p.eventsAttendedOrZero >= 10) { tags.add('Event Lover'); }

    // Timing-based
    final lastActive = p.updatedAt;
    if (lastActive != null) {
      // Timestamp does not have hour directly, so skip or implement if needed
      // tags.add('Night Owl');
      // tags.add('Early Bird');
    }

    // Vibe-based
    final top = p.topVibeOrEmpty;
    if (top.isNotEmpty && p.topVibeCountOrZero >= 5) {
      tags.add('$top Enthusiast');
    }
    if (p.vibeHistoryOrEmpty.length >= 4) { tags.add('Vibe Explorer'); }

    // Social proof
    if (p.communityRatingOrZero >= 4.5) { tags.add('Top Rated'); }
    if (p.followersCountOrZero >= 100) { tags.add('Influencer'); }

    // Energy
    if (p.energyScoreOrZero >= 90) {
      tags.add('High Energy');
    } else if (p.energyScoreOrZero >= 50) {
      tags.add('Active Member');
    }

    return tags.take(5).toList(); // cap at 5 tags
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static const _kVibes = [
    'Chill', 'Hype', 'Deep Talk', 'Late Night', 'Study', 'Party',
  ];
}
