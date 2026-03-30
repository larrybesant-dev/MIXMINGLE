// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

Future<void> ensureUserMediaAccess({
  required bool video,
  required bool audio,
}) async {
  if (html.window.isSecureContext != true) {
    throw StateError('Camera/microphone requires a secure context (HTTPS).');
  }

  final devices = html.window.navigator.mediaDevices;
  if (devices == null) {
    throw StateError('Media devices are not available in this browser.');
  }

  final stream = await devices.getUserMedia(<String, dynamic>{
    'video': video,
    'audio': audio,
  });

  for (final track in stream.getTracks()) {
    track.stop();
  }
}
