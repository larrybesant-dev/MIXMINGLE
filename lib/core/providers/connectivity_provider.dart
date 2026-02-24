import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/connectivity_state.dart';
import '../utils/app_logger.dart';

/// Singleton to track network connectivity status
/// Simple, lightweight, no provider dependencies
class ConnectivityNotifier {
  static final ConnectivityNotifier _instance = ConnectivityNotifier._internal();
  factory ConnectivityNotifier() => _instance;
  ConnectivityNotifier._internal() {
    _startMonitoring();
  }

  final ValueNotifier<ConnectivityState> _state = ValueNotifier(ConnectivityState.online());
  Timer? _monitorTimer;
  bool _lastKnownStatus = true;

  ValueListenable<ConnectivityState> get state => _state;
  ConnectivityState get currentState => _state.value;
  bool get isOnline => _state.value.isOnline;
  bool get isOffline => !_state.value.isOnline;

  /// Start periodic connectivity monitoring
  void _startMonitoring() {
    _checkConnectivity();
    _monitorTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkConnectivity();
    });
  }

  /// Check actual internet connectivity
  Future<void> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));

      final isConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;

      if (isConnected && !_lastKnownStatus) {
        _lastKnownStatus = true;
        reportOnline();
      } else if (!isConnected && _lastKnownStatus) {
        _lastKnownStatus = false;
        reportOffline('No internet connection');
      }
    } catch (e) {
      if (_lastKnownStatus) {
        _lastKnownStatus = false;
        reportOffline('Connection check failed');
      }
    }
  }

  /// Call this when you detect a network error from Firebase
  void reportOffline(String? message) {
    if (_state.value.isOnline) {
      _state.value = ConnectivityState.offline(message);
      AppLogger.warning('Connection lost: ${message ?? "Unknown reason"}');
    }
  }

  /// Call this when a Firebase operation succeeds
  void reportOnline() {
    if (!_state.value.isOnline) {
      _state.value = ConnectivityState.online();
      AppLogger.info('Connection restored');
    }
  }

  /// Check if error is network-related
  static bool isNetworkError(dynamic error) {
    if (error == null) return false;

    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('offline') ||
        errorString.contains('unavailable') ||
        errorString.contains('timeout');
  }

  void dispose() {
    _monitorTimer?.cancel();
  }
}

/// Global instance for easy access
final connectivityNotifier = ConnectivityNotifier();

/// Riverpod provider for connectivity state
final connectivityStateProvider = StreamProvider<bool>((ref) {
  final controller = StreamController<bool>.broadcast();

  void listener() {
    controller.add(connectivityNotifier.isOnline);
  }

  connectivityNotifier.state.addListener(listener);

  ref.onDispose(() {
    connectivityNotifier.state.removeListener(listener);
    controller.close();
  });

  return controller.stream;
});
