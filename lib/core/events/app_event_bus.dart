import 'dart:async';

import 'app_event.dart';

class AppEventBus {
  AppEventBus._internal()
    : _controller = StreamController<AppEvent>.broadcast();

  AppEventBus._test() : _controller = StreamController<AppEvent>.broadcast();

  static final AppEventBus instance = AppEventBus._internal();

  final StreamController<AppEvent> _controller;

  Stream<AppEvent> get stream => _controller.stream;

  void emit(AppEvent event) {
    if (_controller.isClosed) {
      return;
    }
    _controller.add(event);
  }

  static AppEventBus testInstance() => AppEventBus._test();

  Future<void> dispose() async {
    if (identical(this, instance)) {
      return;
    }
    await _controller.close();
  }
}
