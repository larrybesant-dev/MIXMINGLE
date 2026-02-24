/// Feature flags for gradual rollout and A/B testing
///
/// Usage:
/// ```dart
/// if (FeatureFlags.agoraWebEnabled) {
///   // Agora code path
/// } else {
///   // Chat-only fallback
/// }
/// ```
library;

class FeatureFlags {
  /// Enable Agora Web video/audio (can be toggled remotely)
  /// Default: true (enabled after SDK fix)
  static const bool agoraWebEnabled = true;

  /// Enable detailed Agora bridge logging (debug builds)
  static const bool agoraBridgeDebugLogging = false;

  /// Require explicit permission before initializing Agora
  static const bool agoraRequireExplicitInit = false;

  /// Maximum concurrent video publishers in a single Agora channel
  /// Agora does not limit connections per account â€” only per channel.
  /// For Flutter Web + Agora Web SDK, 12 publishers is the stable limit
  /// where Chrome stays smooth, CPU is controlled, and audio stays synced.
  static const int maxConcurrentAgoraConnections = 12;

  /// Fallback to chat-only if Agora fails after N attempts
  static const int agoraFailureRetryLimit = 3;

  /// Enable experimental Web RTC features (requires SDK v5+)
  static const bool agoraExperimentalFeatures = false;

  // ============ PRODUCT FLAGS ============

  /// Enable full video call feature
  /// If false, shows chat-only UI
  static const bool videoCalls = true;

  /// Enable screen sharing (requires additional SDK config)
  static const bool screenSharing = false;

  /// Enable recording (requires backend support)
  static const bool recordingEnabled = false;

  // ============ SAFETY FLAGS ============

  /// Report telemetry to Agora for debugging
  static const bool agoraTelemetry = true;

  /// Enforce secure tokens (production only)
  static const bool requireSecureTokens = true;

  // ============ SYSTEM FLAGS ============

  /// Enable comprehensive health checking
  static const bool enableHealthChecks = true;

  /// Auto-seed Firestore collections if missing
  static const bool autoSeedFirestore = true;
}
