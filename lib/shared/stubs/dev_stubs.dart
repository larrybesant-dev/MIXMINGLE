// TEMP DEV STUBS â€” REMOVE LATER
// These stubs are temporary placeholders to unblock development
// They should be replaced with proper implementations when features are re-enabled

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Temporary stub for presence service
/// TODO: Replace with actual implementation when presence feature is re-enabled
final presenceServiceProvider = Provider((ref) => null);

/// ------------------------------
/// SPEED DATING (DISABLED STUBS)
/// ------------------------------

final activeSpeedDatingSessionProvider = Provider<dynamic>((ref) => null);

/// Speed dating matches provider - returns empty list wrapped in AsyncValue
final speedDatingMatchesProvider = StreamProvider<List<SpeedDatingMatch>>((ref) {
  return Stream.value(const []);
});

/// Stub for SpeedDatingMatch model
class SpeedDatingMatch {
  final String id;
  final String userId;
  final String matchedUserId;
  final DateTime matchedAt;

  SpeedDatingMatch({
    this.id = '',
    this.userId = '',
    this.matchedUserId = '',
    DateTime? matchedAt,
  }) : matchedAt = matchedAt ?? DateTime.now();
}

/// Stub for SpeedDatingResult model
class SpeedDatingResult {}


