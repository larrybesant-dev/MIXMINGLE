import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Advanced Microphone Control Service
///
/// Provides fine-grained microphone control with features like:
/// - Volume level adjustment
/// - Echo cancellation
/// - Noise suppression
/// - Automatic gain control
class AdvancedMicService {
  double _volumeLevel = 100.0;
  bool _echoCancellationEnabled = true;
  bool _noiseSuppressionEnabled = true;
  bool _autoGainControlEnabled = true;
  int _soundMode = 0; // 0: default, 1: enhanced, 2: speech

  // Getters
  double get volumeLevel => _volumeLevel;
  bool get echoCancellationEnabled => _echoCancellationEnabled;
  bool get noiseSuppressionEnabled => _noiseSuppressionEnabled;
  bool get autoGainControlEnabled => _autoGainControlEnabled;
  int get soundMode => _soundMode;

  /// Set microphone volume level (0-100)
  void setVolumeLevel(double level) {
    _volumeLevel = level.clamp(0.0, 100.0);
  }

  /// Toggle echo cancellation
  void toggleEchoCancellation() {
    _echoCancellationEnabled = !_echoCancellationEnabled;
  }

  /// Toggle noise suppression
  void toggleNoiseSuppression() {
    _noiseSuppressionEnabled = !_noiseSuppressionEnabled;
  }

  /// Toggle automatic gain control
  void toggleAutoGainControl() {
    _autoGainControlEnabled = !_autoGainControlEnabled;
  }

  /// Set sound mode (0: default, 1: enhanced, 2: speech)
  void setSoundMode(int mode) {
    if (mode >= 0 && mode <= 2) {
      _soundMode = mode;
    }
  }

  /// Get sound mode name
  String getSoundModeName() {
    switch (_soundMode) {
      case 1:
        return 'Enhanced';
      case 2:
        return 'Speech';
      default:
        return 'Default';
    }
  }

  /// Reset all microphone settings to defaults
  void reset() {
    _volumeLevel = 100.0;
    _echoCancellationEnabled = true;
    _noiseSuppressionEnabled = true;
    _autoGainControlEnabled = true;
    _soundMode = 0;
  }
}

/// Provider for Advanced Mic Service
final advancedMicServiceProvider =
    NotifierProvider<AdvancedMicServiceNotifier, AdvancedMicServiceState>(
  AdvancedMicServiceNotifier.new,
);

/// Notifier for managing state
class AdvancedMicServiceNotifier extends Notifier<AdvancedMicServiceState> {
  final _service = AdvancedMicService();

  @override
  AdvancedMicServiceState build() {
    return AdvancedMicServiceState(
      volumeLevel: 100.0,
      echoCancellationEnabled: true,
      noiseSuppressionEnabled: true,
      autoGainControlEnabled: true,
      soundMode: 0,
    );
  }

  void setVolumeLevel(double level) {
    _service.setVolumeLevel(level);
    state = state.copyWith(volumeLevel: _service.volumeLevel);
  }

  void toggleEchoCancellation() {
    _service.toggleEchoCancellation();
    state = state.copyWith(
      echoCancellationEnabled: _service.echoCancellationEnabled,
    );
  }

  void toggleNoiseSuppression() {
    _service.toggleNoiseSuppression();
    state = state.copyWith(
      noiseSuppressionEnabled: _service.noiseSuppressionEnabled,
    );
  }

  void toggleAutoGainControl() {
    _service.toggleAutoGainControl();
    state = state.copyWith(
      autoGainControlEnabled: _service.autoGainControlEnabled,
    );
  }

  void setSoundMode(int mode) {
    _service.setSoundMode(mode);
    state = state.copyWith(soundMode: _service.soundMode);
  }

  void reset() {
    _service.reset();
    state = AdvancedMicServiceState(
      volumeLevel: 100.0,
      echoCancellationEnabled: true,
      noiseSuppressionEnabled: true,
      autoGainControlEnabled: true,
      soundMode: 0,
    );
  }
}

/// State class for Advanced Mic Service
class AdvancedMicServiceState {
  final double volumeLevel;
  final bool echoCancellationEnabled;
  final bool noiseSuppressionEnabled;
  final bool autoGainControlEnabled;
  final int soundMode;

  AdvancedMicServiceState({
    required this.volumeLevel,
    required this.echoCancellationEnabled,
    required this.noiseSuppressionEnabled,
    required this.autoGainControlEnabled,
    required this.soundMode,
  });

  AdvancedMicServiceState copyWith({
    double? volumeLevel,
    bool? echoCancellationEnabled,
    bool? noiseSuppressionEnabled,
    bool? autoGainControlEnabled,
    int? soundMode,
  }) {
    return AdvancedMicServiceState(
      volumeLevel: volumeLevel ?? this.volumeLevel,
      echoCancellationEnabled:
          echoCancellationEnabled ?? this.echoCancellationEnabled,
      noiseSuppressionEnabled:
          noiseSuppressionEnabled ?? this.noiseSuppressionEnabled,
      autoGainControlEnabled:
          autoGainControlEnabled ?? this.autoGainControlEnabled,
      soundMode: soundMode ?? this.soundMode,
    );
  }
}
