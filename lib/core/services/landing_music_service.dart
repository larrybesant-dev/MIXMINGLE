// lib/core/services/landing_music_service.dart
//
// LandingMusicService – plays the intro sting once then loops the
// ambient track when the landing / splash screen is visible.
// Call fadeOut() when the user navigates away.
//
// Audio files expected in assets/audio/:
//   intro_sting.mp3   – 0.5–1 s intro sting
//   ambient_loop.mp3  – 3–10 s seamless loop
// ─────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'music_settings_service.dart';

class LandingMusicService {
  LandingMusicService(this._settings);

  final MusicSettingsService _settings;

  final _stingPlayer = AudioPlayer();
  final _ambientPlayer = AudioPlayer();

  static const double _ambientVolume = 0.18;
  static const Duration _fadeDuration = Duration(milliseconds: 500);

  bool _started = false;
  bool _disposed = false;
  StreamSubscription<void>? _stingCompleteSub;

  // ── Public API ─────────────────────────────────────────────────

  /// Call once on landing page initState.
  Future<void> start() async {
    if (_disposed || _started) return;
    if (!_settings.canPlay(AudioFeature.landing)) return;
    _started = true;

    try {
      // Play intro sting at moderate volume once.
      await _stingPlayer.setVolume(0.55);
      await _stingPlayer.play(AssetSource('audio/intro_sting.mp3'));

      // Wait for the sting to finish, then start ambient loop.
      _stingCompleteSub?.cancel();
      _stingCompleteSub = _stingPlayer.onPlayerComplete.listen((_) {
        unawaited(_startAmbient());
      });
    } catch (e) {
      debugPrint('[LandingMusic] Sting failed: $e – trying ambient directly.');
      await _startAmbient();
    }
  }

  Future<void> _startAmbient() async {
    if (_disposed) return;
    if (!_settings.canPlay(AudioFeature.landing)) return;
    try {
      await _ambientPlayer.setReleaseMode(ReleaseMode.loop);
      await _ambientPlayer.setVolume(0.0);
      await _ambientPlayer.play(AssetSource('audio/ambient_loop.mp3'));
      await _fadeAmbientTo(_ambientVolume);
    } catch (e) {
      debugPrint('[LandingMusic] Ambient failed: $e');
    }
  }

  /// Fade out and stop all playback (call on navigation away).
  Future<void> fadeOut() async {
    if (_disposed) return;
    await Future.wait([
      _fadePlayerTo(_stingPlayer, 0.0),
      _fadeAmbientTo(0.0),
    ]);
    await _safeStop(_stingPlayer, 'sting');
    await _safeStop(_ambientPlayer, 'ambient');
    _started = false;
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _stingCompleteSub?.cancel();
    _stingCompleteSub = null;
    await _safeStop(_stingPlayer, 'sting');
    await _safeStop(_ambientPlayer, 'ambient');
    await _safeDispose(_stingPlayer, 'sting');
    await _safeDispose(_ambientPlayer, 'ambient');
  }

  // ── Volume fade helpers ────────────────────────────────────────
  Future<void> _fadeAmbientTo(double target) =>
      _fadePlayerTo(_ambientPlayer, target);

  Future<void> _fadePlayerTo(AudioPlayer player, double target) async {
    const steps = 20;
    final stepDuration = Duration(
      milliseconds: _fadeDuration.inMilliseconds ~/ steps,
    );
    double current;
    try {
      current = await player.getCurrentVolume() ?? 0.0;
    } catch (_) {
      current = 0.0;
    }

    for (int i = 1; i <= steps; i++) {
      await Future.delayed(stepDuration);
      final v = current + (target - current) * (i / steps);
      try {
        await player.setVolume(v.clamp(0.0, 1.0));
      } catch (_) {
        break;
      }
    }
  }

  Future<void> _safeStop(AudioPlayer player, String label) async {
    try {
      await player.stop();
    } catch (e) {
      debugPrint('[LandingMusic] Ignored $label stop error: $e');
    }
  }

  Future<void> _safeDispose(AudioPlayer player, String label) async {
    try {
      await player.dispose();
    } catch (e) {
      debugPrint('[LandingMusic] Ignored $label dispose error: $e');
    }
  }
}

// ── Extension for missing API ─────────────────────────────────────
extension on AudioPlayer {
  Future<double?> getCurrentVolume() async => null; // volume not readable in v6
}

// ── Riverpod provider ─────────────────────────────────────────────
final landingMusicProvider = Provider<LandingMusicService?>((ref) {
  final settingsAsync = ref.watch(musicSettingsProvider);
  return settingsAsync.whenOrNull(
    data: (settings) => LandingMusicService(settings),
  );
});
