library;

import 'package:flutter/material.dart';
import '../core/design_system/design_constants.dart';

/// Join Flow Controller
///
/// Manages the ceremonial join experience:
/// 1. Entering (150ms) - "Entering roomâ€¦"
/// 2. Connecting (400-1000ms) - "Connecting audio & videoâ€¦"
/// 3. Live (400ms) - "You're live" notification
///
/// Total minimum: 950ms (intentional delay for ceremonial feel)
/// Reference: DESIGN_BIBLE.md Section C.4 (Join Flow Timing)

/// Phases of the join flow
enum JoinPhase {
  idle,         // Not attempting to join
  entering,     // Stage 1: "Entering roomâ€¦" (150ms)
  connecting,   // Stage 2: "Connecting audio & videoâ€¦" (400-1000ms)
  live,         // Stage 3: "You're live" appears (400ms)
  error,        // Join failed
}

/// Extension to get display text for each phase
extension JoinPhaseText on JoinPhase {
  String get displayText {
    switch (this) {
      case JoinPhase.idle:
        return 'Ready to join';
      case JoinPhase.entering:
        return 'Entering roomâ€¦';
      case JoinPhase.connecting:
        return 'Connecting audio & videoâ€¦';
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

/// Controller managing join flow state machine
///
/// Usage:
/// ```dart
/// final controller = JoinFlowController();
/// await controller.startJoinFlow(); // Runs all 3 phases with timing
/// ```
class JoinFlowController extends ChangeNotifier {
  /// Current phase
  JoinPhase _phase = JoinPhase.idle;
  JoinPhase get phase => _phase;

  /// Error message (if phase == error)
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Whether join is currently in progress
  bool _isJoining = false;
  bool get isJoining => _isJoining;

  /// Start the join flow with ceremonial timing
  ///
  /// Runs: entering (150ms) â†’ connecting (400-1000ms) â†’ live (400ms)
  /// Total minimum: 950ms
  Future<void> startJoinFlow({
    /// How long to wait during connecting phase
    /// Default: 400ms minimum, can be longer if SDK needs time
    Duration connectingDelay = const Duration(milliseconds: 400),
  }) async {
    if (_isJoining) return; // Prevent multiple simultaneous joins

    _isJoining = true;
    _errorMessage = null;

    try {
      // STAGE 1: Entering room (150ms)
      _setPhase(JoinPhase.entering);
      await Future.delayed(DesignAnimations.joinStage1Duration);

      // STAGE 2: Connecting to Agora/Firestore (400-1000ms)
      _setPhase(JoinPhase.connecting);
      await Future.delayed(connectingDelay);

      // STAGE 3: Live notification (400ms fade-in)
      _setPhase(JoinPhase.live);
      await Future.delayed(DesignAnimations.joinStage3Duration);

      // Join complete
      _isJoining = false;
      notifyListeners();
    } catch (e) {
      _setError('Join failed: $e');
      _isJoining = false;
      rethrow;
    }
  }

  /// Set error state with message
  void setError(String message) {
    _setError(message);
    _isJoining = false;
  }

  /// Reset to idle state
  void reset() {
    _phase = JoinPhase.idle;
    _errorMessage = null;
    _isJoining = false;
    notifyListeners();
  }

  /// Private helper to set phase and notify
  void _setPhase(JoinPhase newPhase) {
    _phase = newPhase;
    notifyListeners();
  }

  /// Private helper to set error state
  void _setError(String message) {
    _phase = JoinPhase.error;
    _errorMessage = message;
    notifyListeners();
  }
}
