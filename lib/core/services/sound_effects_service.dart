// lib/core/services/sound_effects_service.dart
//
// SoundEffectsService – plays short non-blocking micro-sounds for
// key app events (room joins, reactions, energy spikes, etc.).
//
// All sounds are < 500 ms and played at reduced volume.
// The service is resilient: if an asset is missing or on a platform
// where audio fails it simply logs and continues.
// ─────────────────────────────────────────────────────────────────

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'music_settings_service.dart';

class SoundEffectsService {
  SoundEffectsService(this._settings);

  final MusicSettingsService _settings;

  // Pool of players – one per event type so rapid calls don't queue.
  final _joinPlayer     = AudioPlayer();
  final _speakerPlayer  = AudioPlayer();
  final _energyPlayer   = AudioPlayer();
  final _reactionPlayer = AudioPlayer();

  static const double _sfxVolume = 0.35;

  // ── Public API ─────────────────────────────────────────────────
  Future<void> playJoinRoom()     => _play(_joinPlayer,     'audio/join_room.mp3');
  Future<void> playNewSpeaker()   => _play(_speakerPlayer,  'audio/new_speaker.mp3');
  Future<void> playEnergySpike()  => _play(_energyPlayer,   'audio/energy_spike.mp3');
  Future<void> playReaction()     => _play(_reactionPlayer, 'audio/reaction.mp3');

  // ── Internal helper ────────────────────────────────────────────
  Future<void> _play(AudioPlayer player, String assetPath) async {
    if (!_settings.canPlay(AudioFeature.sfx)) return;
    try {
      await player.setVolume(_sfxVolume);
      await player.play(AssetSource(assetPath));
    } catch (e) {
      // Missing asset or unsupported platform – fail silently in release.
      debugPrint('[SFX] Could not play $assetPath: $e');
    }
  }

  Future<void> dispose() async {
    await Future.wait([
      _joinPlayer.dispose(),
      _speakerPlayer.dispose(),
      _energyPlayer.dispose(),
      _reactionPlayer.dispose(),
    ]);
  }
}

// ── Riverpod provider ─────────────────────────────────────────────
final soundEffectsProvider = Provider<SoundEffectsService?>((ref) {
  final settingsAsync = ref.watch(musicSettingsProvider);
  return settingsAsync.whenOrNull(
    data: (settings) => SoundEffectsService(settings),
  );
});
