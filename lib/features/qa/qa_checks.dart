// lib/core/qa/qa_checks.dart

import 'package:flutter/material.dart';

class QAChecks {
  static bool isDebugMode() {
    var debug = false;
    assert(() {
      debug = true;
      return true;
    }());
    return debug;
  }

  static void logAgoraConnectionState(String state) {
    if (isDebugMode()) debugPrint('Agora Connection State: $state');
  }

  static void logTokenLifecycle(String event) {
    if (isDebugMode()) debugPrint('Token Lifecycle: $event');
  }

  static void logFirestoreSyncHealth(String status) {
    if (isDebugMode()) debugPrint('Firestore Sync Health: $status');
  }

  static void logQAEvent(String event) {
    if (isDebugMode()) debugPrint('QA Event: $event');
  }
}
