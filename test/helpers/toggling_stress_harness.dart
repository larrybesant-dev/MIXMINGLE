import 'dart:async';
import 'dart:math';
import 'network_degradation_harness.dart';
import 'token_expiry_harness.dart';

/// Harness for rapid toggling stress tests (mic/cam/screen-share).
class TogglingStressHarness {
  final int micToggles;
  final int camToggles;
  final int screenShareToggles;
  final bool randomize;
  final NetworkDegradationHarness? networkHarness;
  final TokenExpiryHarness? tokenHarness;
  final void Function(String log)? logger;

  TogglingStressHarness({
    this.micToggles = 0,
    this.camToggles = 0,
    this.screenShareToggles = 0,
    this.randomize = false,
    this.networkHarness,
    this.tokenHarness,
    this.logger,
  });

  Future<void> run({
    required Future<void> Function() toggleMic,
    required Future<void> Function() toggleCam,
    required Future<void> Function() toggleScreenShare,
  }) async {
    final actions = <Future<void> Function()>[];
    actions.addAll(List.filled(micToggles, toggleMic));
    actions.addAll(List.filled(camToggles, toggleCam));
    actions.addAll(List.filled(screenShareToggles, toggleScreenShare));
    if (randomize) {
      actions.shuffle(Random());
    }
    for (final action in actions) {
      if (networkHarness != null) {
        await networkHarness!.runWithConditions(() async {
          if (tokenHarness != null) {
            await tokenHarness!.runWithExpiry(action);
          } else {
            await action();
          }
        });
      } else if (tokenHarness != null) {
        await tokenHarness!.runWithExpiry(action);
      } else {
        await action();
      }
      logger?.call('[TogglingStress] Action completed');
    }
  }
}

/// Example usage in a test:
/// final harness = TogglingStressHarness(micToggles: 100, camToggles: 100, randomize: true);
/// await harness.run(toggleMic: ..., toggleCam: ..., toggleScreenShare: ...);
