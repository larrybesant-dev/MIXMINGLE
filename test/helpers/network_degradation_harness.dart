import 'dart:async';
import 'dart:math';

/// Simulates network degradation for Agora/WebRTC calls in tests.
/// Usage: Wrap your networked method calls with [NetworkDegradationHarness.runWithConditions].
class NetworkDegradationHarness {
  final double packetLossRate; // 0.0–1.0
  final int minLatencyMs;
  final int maxLatencyMs;
  final int bandwidthKbps;
  final bool simulateDisconnect;
  final int reconnectLoops;
  final void Function(String log)? logger;

  NetworkDegradationHarness({
    this.packetLossRate = 0.0,
    this.minLatencyMs = 0,
    this.maxLatencyMs = 0,
    this.bandwidthKbps = 10000,
    this.simulateDisconnect = false,
    this.reconnectLoops = 0,
    this.logger,
  });

  /// Simulate a networked call with the configured degradation.
  Future<T?> runWithConditions<T>(FutureOr<T> Function() action) async {
    // Simulate packet loss
    if (Random().nextDouble() < packetLossRate) {
      logger?.call('[NetworkDegradation] Packet lost');
      return null;
    }
    // Simulate latency
    if (maxLatencyMs > 0) {
      final latency =
          minLatencyMs + Random().nextInt(maxLatencyMs - minLatencyMs + 1);
      logger?.call('[NetworkDegradation] Latency: ${latency}ms');
      await Future.delayed(Duration(milliseconds: latency));
    }
    // Simulate bandwidth throttling (no real network, so just delay based on payload size)
    // In real tests, you can pass a payloadSize param and delay accordingly.
    // Simulate disconnect/reconnect
    if (simulateDisconnect && reconnectLoops > 0) {
      for (int i = 0; i < reconnectLoops; i++) {
        logger?.call(
            '[NetworkDegradation] Simulating disconnect (loop ${i + 1})');
        await Future.delayed(Duration(milliseconds: 500));
        logger
            ?.call('[NetworkDegradation] Simulating reconnect (loop ${i + 1})');
        await Future.delayed(Duration(milliseconds: 500));
      }
    }
    // Run the actual action
    return await action();
  }
}

/// Example usage in a test:
/// final harness = NetworkDegradationHarness(packetLossRate: 0.2, minLatencyMs: 100, maxLatencyMs: 500);
/// await harness.runWithConditions(() => yourNetworkedFunction());
