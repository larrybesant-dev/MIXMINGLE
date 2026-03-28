import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  final ThemeMode themeMode;
  final bool notificationsEnabled;
  final bool analyticsEnabled;

  const AppSettings({
    required this.themeMode,
    required this.notificationsEnabled,
    required this.analyticsEnabled,
  });

  const AppSettings.defaults()
      : themeMode = ThemeMode.dark,
        notificationsEnabled = true,
        analyticsEnabled = true;

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? notificationsEnabled,
    bool? analyticsEnabled,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
    );
  }
}

class AppSettingsService {
  static const _themeModeKey = 'app.theme_mode';
  static const _notificationsEnabledKey = 'app.notifications_enabled';
  static const _analyticsEnabledKey = 'app.analytics_enabled';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      themeMode: _themeModeFromString(prefs.getString(_themeModeKey)),
      notificationsEnabled: prefs.getBool(_notificationsEnabledKey) ?? true,
      analyticsEnabled: prefs.getBool(_analyticsEnabledKey) ?? true,
    );
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, settings.themeMode.name);
    await prefs.setBool(_notificationsEnabledKey, settings.notificationsEnabled);
    await prefs.setBool(_analyticsEnabledKey, settings.analyticsEnabled);
  }

  ThemeMode _themeModeFromString(String? value) {
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.dark,
    };
  }
}