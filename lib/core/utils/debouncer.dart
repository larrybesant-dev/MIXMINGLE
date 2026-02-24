import 'dart:async';

/// Debouncer for delaying execution of a function
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 500)});

  /// Execute the callback after the delay
  void call(void Function() callback) {
    _timer?.cancel();
    _timer = Timer(delay, callback);
  }

  /// Cancel any pending execution
  void cancel() {
    _timer?.cancel();
  }

  /// Dispose and cleanup
  void dispose() {
    _timer?.cancel();
  }
}

/// Throttler for limiting execution frequency
class Throttler {
  final Duration duration;
  DateTime? _lastExecution;

  Throttler({this.duration = const Duration(milliseconds: 1000)});

  /// Execute the callback if enough time has passed
  void call(void Function() callback) {
    final now = DateTime.now();
    if (_lastExecution == null || now.difference(_lastExecution!) >= duration) {
      callback();
      _lastExecution = now;
    }
  }

  /// Reset the throttler
  void reset() {
    _lastExecution = null;
  }
}
