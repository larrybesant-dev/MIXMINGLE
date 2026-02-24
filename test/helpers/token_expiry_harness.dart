import 'dart:async';

/// Simulates token expiry and refresh for Agora/WebRTC/chat in tests.
/// Usage: Wrap your networked method calls with [TokenExpiryHarness.runWithExpiry].
class TokenExpiryHarness {
  final bool forceExpiry;
  final bool duringSession;
  final bool duringReconnect;
  final bool duringToggle;
  final int multiUserCount;
  final Duration expiryDelay;
  final void Function(String log)? logger;

  TokenExpiryHarness({
    this.forceExpiry = false,
    this.duringSession = false,
    this.duringReconnect = false,
    this.duringToggle = false,
    this.multiUserCount = 1,
    this.expiryDelay = const Duration(seconds: 2),
    this.logger,
  });

  /// Simulate a networked call with token expiry and refresh.
  Future<T> runWithExpiry<T>(FutureOr<T> Function() action,
      {FutureOr<void> Function()? onTokenRefresh}) async {
    if (forceExpiry) {
      logger?.call('[TokenExpiry] Forcing token expiry');
      await Future.delayed(expiryDelay);
      logger?.call('[TokenExpiry] Token expired');
      if (onTokenRefresh != null) {
        logger?.call('[TokenExpiry] Refreshing token...');
        await onTokenRefresh();
        logger?.call('[TokenExpiry] Token refresh complete');
      }
    }
    // Simulate expiry during session/reconnect/toggle as needed
    // (In real tests, you would trigger expiry at the right moment)
    return await action();
  }
}

/// Example usage in a test:
/// final harness = TokenExpiryHarness(forceExpiry: true, duringSession: true);
/// await harness.runWithExpiry(() => yourNetworkedFunction(), onTokenRefresh: () async { /* refresh logic */ });
