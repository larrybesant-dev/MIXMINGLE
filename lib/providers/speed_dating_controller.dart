import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shared/models/speed_dating_round.dart';
import '../shared/models/speed_dating_result.dart';
import '../services/speed_dating_service.dart';

// Speed dating service provider
final speedDatingServiceProvider = Provider<SpeedDatingService>((ref) {
  return SpeedDatingService();
});

// Speed dating round provider
final speedDatingRoundProvider = FutureProvider.family<SpeedDatingRound?, String>((ref, roundId) async {
  final service = ref.watch(speedDatingServiceProvider);
  return service.getSpeedDatingRound(roundId);
});

// Active rounds for event provider
final activeRoundsForEventProvider = FutureProvider.family<List<SpeedDatingRound>, String>((ref, eventId) async {
  final service = ref.watch(speedDatingServiceProvider);
  return service.getActiveRoundsForEvent(eventId);
});

// User's speed dating results provider
final userSpeedDatingResultsProvider = FutureProvider<List<SpeedDatingResult>>((ref) async {
  final service = ref.watch(speedDatingServiceProvider);
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  return service.getUserSpeedDatingResults(userId);
});

// Mutual matches provider
final mutualMatchesProvider = FutureProvider<List<String>>((ref) async {
  final service = ref.watch(speedDatingServiceProvider);
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  return service.getMutualMatches(userId);
});

// Current user ID provider (helper)
final currentUserIdProvider = Provider<String?>((ref) {
  // This would typically come from auth state
  // For now, return null - implement based on your auth setup
  return null;
});

class SpeedDatingController extends Notifier<AsyncValue<SpeedDatingRound?>> {
  late final SpeedDatingService _speedDatingService;

  @override
  AsyncValue<SpeedDatingRound?> build() {
    _speedDatingService = ref.watch(speedDatingServiceProvider);
    return const AsyncValue.data(null);
  }

  Future<void> createSpeedDatingRound({
    required String eventId,
    required String name,
    required int duration,
    required List<String> participantIds,
  }) async {
    try {
      await _speedDatingService.createSpeedDatingRound(
        eventId: eventId,
        name: name,
        duration: duration,
        participantIds: participantIds,
      );
    } catch (e) {
      // Handle error
      debugPrint('Failed to create speed dating round: $e');
    }
  }

  Future<void> joinRound(String roundId, String userId) async {
    try {
      await _speedDatingService.joinSpeedDatingRound(roundId, userId);
    } catch (e) {
      debugPrint('Failed to join speed dating round: $e');
    }
  }

  Future<void> leaveRound(String roundId, String userId) async {
    try {
      await _speedDatingService.leaveSpeedDatingRound(roundId, userId);
    } catch (e) {
      debugPrint('Failed to leave speed dating round: $e');
    }
  }

  Future<void> startRound(String roundId) async {
    try {
      await _speedDatingService.startSpeedDatingRound(roundId);
    } catch (e) {
      debugPrint('Failed to start speed dating round: $e');
    }
  }

  Future<void> submitResult({
    required String roundId,
    required String userId,
    required String matchedUserId,
    required bool userLiked,
    bool? matchedUserLiked,
  }) async {
    try {
      await _speedDatingService.submitSpeedDatingResult(
        roundId: roundId,
        userId: userId,
        matchedUserId: matchedUserId,
        userLiked: userLiked,
        matchedUserLiked: matchedUserLiked,
      );
    } catch (e) {
      debugPrint('Failed to submit speed dating result: $e');
    }
  }

  Future<void> advanceRound(String roundId) async {
    try {
      await _speedDatingService.advanceToNextRound(roundId);
    } catch (e) {
      debugPrint('Failed to advance to next round: $e');
    }
  }

  Future<void> endRound(String roundId) async {
    try {
      await _speedDatingService.endSpeedDatingRound(roundId);
    } catch (e) {
      debugPrint('Failed to end speed dating round: $e');
    }
  }
}

// Speed dating controller provider
final speedDatingControllerProvider = NotifierProvider<SpeedDatingController, AsyncValue<SpeedDatingRound?>>(
  () => SpeedDatingController(),
);
