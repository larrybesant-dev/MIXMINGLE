import 'dart:js_interop';

import 'package:web/web.dart' as web;

const String _timelineKey = 'startupLogs';

void emitStartupMessageToRuntime(String message) {
  web.console.log(message.toJS);

  final storage = web.window.sessionStorage;
  final existing = storage.getItem(_timelineKey);
  final next = (existing == null || existing.isEmpty)
      ? message
      : '$existing\n$message';
  storage.setItem(_timelineKey, next);
}
