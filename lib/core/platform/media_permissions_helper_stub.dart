// Stub for non-web platforms.

/// Exception thrown when media permissions are denied
class MediaPermissionException implements Exception {
  final String message;
  final Object? originalError;
  MediaPermissionException(this.message, {this.originalError});
  @override
  String toString() => 'MediaPermissionException: $message';
}

/// Non-web stub: always succeeds (permissions are managed by OS on mobile/desktop).
class MediaPermissionsHelper {
  static Future<void> ensureMediaPermissions({
    bool requireVideo = true,
    bool requireAudio = true,
  }) async {
    // On native platforms, permissions are requested by the OS via the plugin.
  }

  static Future<bool> checkPermissions() async => true;
}
