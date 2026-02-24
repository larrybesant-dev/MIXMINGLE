import 'package:flutter/foundation.dart' show kIsWeb;

// Intentionally empty - web-specific implementation pending
/*
import 'package:web/web.dart' as web;
*/

/// Exception thrown when JS bridge is unavailable or call fails
class JsBridgeException implements Exception {
  final String message;
  final Object? originalError;

  JsBridgeException(this.message, [this.originalError]);

  @override
  String toString() => 'JsBridgeException: $message${originalError != null ? ' (${originalError.toString()})' : ''}';
}

/*
/// Low-level JS bridge for calling Agora Web SDK methods
/// DISABLED FOR NON-WEB BUILD - Requires js_util which is web-only

Future<T> callAgoraMethod<T>(String methodName, List<dynamic> args) async {
  throw UnsupportedError('JS bridge not available on this platform');
}

Future<Map<String, dynamic>> getAgoraState() async {
  throw UnsupportedError('JS bridge not available on this platform');
}

void enableJsBridgeLogging(bool enable) {
  // No-op
}

bool isAgoraBridgeAvailable() {
  return false;
}

Future<void> printAgoraDebugInfo() {
  throw UnsupportedError('JS bridge not available on this platform');
}
*/

// Stub implementations for non-web platforms
Future<T> callAgoraMethod<T>(String methodName, List<dynamic> args) async {
  if (!kIsWeb) {
    throw UnsupportedError('JS bridge only available on web platform');
  }
  throw UnsupportedError('JS bridge implementation pending');
}

Future<Map<String, dynamic>> getAgoraState() async {
  if (!kIsWeb) {
    throw UnsupportedError('JS bridge only available on web platform');
  }
  return {};
}

void enableJsBridgeLogging(bool enable) {
  if (!kIsWeb) return;
}

bool isAgoraBridgeAvailable() {
  return false;
}

Future<void> printAgoraDebugInfo() {
  if (!kIsWeb) {
    throw UnsupportedError('JS bridge only available on web platform');
  }
  return Future.value();
}

/*
ORIGINAL WEB IMPLEMENTATION (pending ):
/// Low-level JS bridge for calling Agora Web SDK methods
///
/// Pattern:
/// ```dart
/// final result = await callAgoraMethod('joinChannel', [token, channelId, uid]);
/// ```
*/




