// lib/core/services/audio_manager.dart
//
// AudioManager — central coordinator for all app audio.
// Single point of truth: landing music, profile previews, SFX.
// ─────────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'landing_music_service.dart';
import 'profile_music_service.dart';
import 'sound_effects_service.dart';
import 'music_settings_service.dart';

class AudioManager {
  AudioManager({
    required this.landing,
    required this.profile,
    required this.sfx,
    required this.settings,
  });

  final LandingMusicService? landing;
  final ProfileMusicNotifier profile;
  final SoundEffectsService? sfx;
  final MusicSettingsService settings;

  // ── Landing ──────────────────────────────────────────────────

  Future<void> playLanding() async {
    await stopAll();
    await landing?.start();
  }

  Future<void> stopLanding() async => landing?.fadeOut();

  // ── Profile preview ──────────────────────────────────────────

  Future<void> playProfileTrack(String? url) async {
    await stopLanding();
    await profile.playPreview(url);
  }

  Future<void> stopProfileTrack() => profile.stop();

  // ── SFX ──────────────────────────────────────────────────────

  Future<void> playJoinRoom()    async => sfx?.playJoinRoom();
  Future<void> playNewSpeaker()  async => sfx?.playNewSpeaker();
  Future<void> playReaction()    async => sfx?.playReaction();

  // ── Global ───────────────────────────────────────────────────

  Future<void> stopAll() async {
    await Future.wait([
      landing?.fadeOut() ?? Future.value(),
      profile.stop(),
    ]);
  }

  Future<void> setGlobalMute(bool muted) {
    return settings.setGlobalMute(muted);
  }

  bool get isMuted => settings.globalMute;
}

// ── Providers ────────────────────────────────────────────────────

final audioManagerProvider = Provider<AudioManager?>((ref) {
  final settingsAsync = ref.watch(musicSettingsProvider);
  return settingsAsync.whenOrNull(
    data: (settings) => AudioManager(
      landing: ref.watch(landingMusicProvider),
      profile: ref.watch(profileMusicProvider.notifier),
      sfx:     ref.watch(soundEffectsProvider),
      settings: settings,
    ),
  );
});
