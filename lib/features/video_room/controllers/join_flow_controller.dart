library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design_system/design_constants.dart';

/// Join Flow Controller
///
/// Manages the ceremonial join experience:
/// 1. Entering (150ms) - "Entering room…"
/// 2. Connecting (400-1000ms) - "Connecting audio & video…"
/// 3. Live (400ms) - "You're live" notification
///
/// Total minimum: 950ms (intentional delay for ceremonial feel)
/// Reference: DESIGN_BIBLE.md Section C.4 (Join Flow Timing)

/// Phases of the join flow
enum JoinPhase {
  idle, // Not attempting to join
  entering, // Stage 1: "Entering room…" (150ms)
  connecting, // Stage 2: "Connecting audio & video…" (400-1000ms)
  live, // Stage 3: "You're live" appears (400ms)
  error, // Join failed
}

/// Extension to get display text for each phase
extension JoinPhaseText on JoinPhase {
  String get displayText {
    switch (this) {
      case JoinPhase.idle:
        return 'Ready to join';
      case JoinPhase.entering:
        return 'Entering room…';
      case JoinPhase.connecting:
        return 'Connecting audio & video…';
      case JoinPhase.live:
        return 'You\'re live';
      case JoinPhase.error:
        return 'Something went wrong';
    }
  }

  /// Expected duration for this phase
  Duration get duration {
    switch (this) {
      case JoinPhase.entering:
        return DesignAnimations.joinStage1Duration; // 150ms
      case JoinPhase.connecting:
        return DesignAnimations.joinStage2MinDuration; // 400ms
      case JoinPhase.live:
        return DesignAnimations.joinStage3Duration; // 400ms
      default:
        return Duration.zero;
    }
  }
}

/// Immutable state for join flow
class JoinFlowState {
  final JoinPhase phase;
  final String? errorMessage;
  final bool isJoining;

  const JoinFlowState({
    this.phase = JoinPhase.idle,
    this.errorMessage,
    this.isJoining = false,
  });

  JoinFlowState copyWith({
    JoinPhase? phase,
    String? errorMessage,
    bool? isJoining,
    bool clearError = false,
  }) {
    return JoinFlowState(
      phase: phase ?? this.phase,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isJoining: isJoining ?? this.isJoining,
    );
  }
}

/// Riverpod notifier managing join flow state machine
class JoinFlowNotifier extends Notifier<JoinFlowState> {
  @override
  JoinFlowState build() => const JoinFlowState();

  Future<void> startJoinFlow({
    Duration connectingDelay = const Duration(milliseconds: 400),
  }) async {
    if (state.isJoining) return;
    state = state.copyWith(isJoining: true, clearError: true);
    try {
      state = state.copyWith(phase: JoinPhase.entering);
      await Future.delayed(DesignAnimations.joinStage1Duration);
      state = state.copyWith(phase: JoinPhase.connecting);
      await Future.delayed(connectingDelay);
      state = state.copyWith(phase: JoinPhase.live);
      await Future.delayed(DesignAnimations.joinStage3Duration);
      state = state.copyWith(isJoining: false);
    } catch (e) {
      state = JoinFlowState(
          phase: JoinPhase.error,
          errorMessage: 'Join failed: $e',
          isJoining: false);
      rethrow;
    }
  }

  void setError(String message) {
    state = JoinFlowState(
        phase: JoinPhase.error, errorMessage: message, isJoining: false);
  }

  void reset() {
    state = const JoinFlowState();
  }
}

/// Provider for join flow state
final joinFlowProvider = NotifierProvider<JoinFlowNotifier, JoinFlowState>(
  JoinFlowNotifier.new,
);
