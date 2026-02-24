// lib/core/services/music_settings_service.dart
//
// MusicSettingsService – thin SharedPreferences wrapper for all
// user-facing audio preferences. Preferences are read/written
// synchronously from an in-memory cache backed by SharedPreferences.
// ─────────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keys used in SharedPreferences.
class _Keys {
  static const landingMusic    = 'pref_landing_music_enabled';
  static const profileMusic    = 'pref_profile_music_enabled';
  static const microSounds     = 'pref_micro_sounds_enabled';
  static const globalMute      = 'pref_global_mute';
}

class MusicSettingsService {
  MusicSettingsService._(this._prefs);

  final SharedPreferences _prefs;

  static Future<MusicSettingsService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return MusicSettingsService._(prefs);
  }

  // ── Landing page music ────────────────────────────────────────
  bool get landingMusicEnabled =>
      _prefs.getBool(_Keys.landingMusic) ?? true; // default ON

  Future<void> setLandingMusicEnabled(bool value) =>
      _prefs.setBool(_Keys.landingMusic, value);

  // ── Profile music ─────────────────────────────────────────────
  bool get profileMusicEnabled =>
      _prefs.getBool(_Keys.profileMusic) ?? true; // default ON

  Future<void> setProfileMusicEnabled(bool value) =>
      _prefs.setBool(_Keys.profileMusic, value);

  // ── Micro-sounds (SFX) ────────────────────────────────────────
  bool get microSoundsEnabled =>
      _prefs.getBool(_Keys.microSounds) ?? true; // default ON

  Future<void> setMicroSoundsEnabled(bool value) =>
      _prefs.setBool(_Keys.microSounds, value);

  // ── Global mute ───────────────────────────────────────────────
  bool get globalMute =>
      _prefs.getBool(_Keys.globalMute) ?? false;

  Future<void> setGlobalMute(bool value) =>
      _prefs.setBool(_Keys.globalMute, value);

  /// Convenience: returns true when the given feature should play audio.
  bool canPlay(AudioFeature feature) {
    if (globalMute) return false;
    switch (feature) {
      case AudioFeature.landing:  return landingMusicEnabled;
      case AudioFeature.profile:  return profileMusicEnabled;
      case AudioFeature.sfx:      return microSoundsEnabled;
    }
  }
}

enum AudioFeature { landing, profile, sfx }

// ── Riverpod provider ─────────────────────────────────────────────
final musicSettingsProvider = FutureProvider<MusicSettingsService>((ref) async {
  return MusicSettingsService.create();
});
