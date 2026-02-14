// ignore_for_file: avoid_web_libraries_in_flutter
import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mix_and_mingle/core/utils/app_logger.dart';

/// Web Media Permissions Helper
/// Ensures camera and mic permissions are granted BEFORE joining Agora
/// This prevents silent failures when browser denies permission
class MediaPermissionsHelper {
  /// Request camera and mic permissions from browser
  /// MUST be called before Agora.joinChannel()
  ///
  /// Why this matters:
  /// - Browsers won't prompt again once denied
  /// - Agora silently fails without explicit permissions
  /// - This gives clear error feedback to users
  static Future<void> ensureMediaPermissions({
    bool requireVideo = true,
    bool requireAudio = true,
  }) async {
    if (!kIsWeb) {
      AppLogger.info('⏭️  Not on web, skipping media permissions check');
      return;
    }

    try {
      AppLogger.info('🎥 Requesting media permissions...');

      final constraints = {
        if (requireVideo) 'video': true,
        if (requireAudio) 'audio': true,
      };

      if (constraints.isEmpty) {
        AppLogger.warning('⚠️  No media permissions requested');
        return;
      }

      // This will show browser permission prompt
      final mediaDevices = web.window.navigator.mediaDevices;
      final constraintsMap = <String, dynamic>{
        if (requireAudio) 'audio': true,
        if (requireVideo) 'video': true,
      }.jsify() as web.MediaStreamConstraints;

      final streamPromise = mediaDevices.getUserMedia(constraintsMap);
      final stream = await streamPromise.toDart;

      // Clean up the test stream immediately
      final tracks = stream.getTracks().toDart;
      for (int i = 0; i < tracks.length; i++) {
        tracks[i].stop();
      }

      AppLogger.info('✅ Media permissions granted');
    } catch (e) {
      // If user denies permission, this will throw
      AppLogger.error('❌ Media permissions denied: $e');
      throw MediaPermissionException(
        'Camera/Microphone access denied. Please allow access in your browser settings.',
        originalError: e,
      );
    }
  }

  /// Check if media permissions are already granted (without prompting)
  static Future<bool> checkPermissions() async {
    if (!kIsWeb) return true;

    try {
      final permissions = web.window.navigator.permissions;

      final cameraQueryMap = {'name': 'camera'}.jsify() as JSObject;
      final micQueryMap = {'name': 'microphone'}.jsify() as JSObject;

      final cameraStatusPromise = permissions.query(cameraQueryMap);
      final micStatusPromise = permissions.query(micQueryMap);

      final cameraStatus = await cameraStatusPromise.toDart;
      final micStatus = await micStatusPromise.toDart;

      return cameraStatus.state == 'granted' && micStatus.state == 'granted';
    } catch (e) {
      AppLogger.warning('⚠️  Could not check permissions: $e');
      return false;
    }
  }
}

/// Exception thrown when media permissions are denied
class MediaPermissionException implements Exception {
  final String message;
  final dynamic originalError;

  MediaPermissionException(this.message, {this.originalError});

  @override
  String toString() => 'MediaPermissionException: $message';
}
