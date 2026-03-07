import 'dart:async';

import 'window_manager.dart';

class WindowSyncEvent {
  const WindowSyncEvent({
    required this.name,
    this.data,
    required this.source,
  });

  final String name;
  final Object? data;
  final String source;
}

class WindowSyncService {
  static final StreamController<WindowSyncEvent> _controller =
      StreamController<WindowSyncEvent>.broadcast();

  static final String instanceId =
      'win_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';

  static bool _initialized = false;

  static Stream<WindowSyncEvent> get events => _controller.stream;

  static void ensureInitialized() {
    if (_initialized) return;
    _initialized = true;

    WindowManager.listen((Object? message) {
      if (message is! Map) return;

      final rawEvent = message['event'];
      final rawData = message['data'];
      if (rawEvent is! String) return;

      String source = 'external';
      if (rawData is Map) {
        final maybeSource = rawData['source'];
        if (maybeSource is String) {
          source = maybeSource;
        }
      }

      // Ignore loopback events from this same window.
      if (source == instanceId) return;

      _controller.add(
        WindowSyncEvent(
          name: rawEvent,
          data: rawData,
          source: source,
        ),
      );
    });
  }

  static void send(String event, [Map<String, Object?> data = const {}]) {
    final payload = <String, Object?>{
      ...data,
      'source': instanceId,
      'ts': DateTime.now().millisecondsSinceEpoch,
    };
    WindowManager.send(event, payload);
  }
}
