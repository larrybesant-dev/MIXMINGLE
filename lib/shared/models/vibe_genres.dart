import 'package:flutter/material.dart';

/// Vibe Tags — the emotional energy a user radiates.
/// Used in: profile display, NeonProfileCard, search filters, room tags.
class VibeTags {
  VibeTags._();

  static const List<String> all = [
    'Chill',
    'Hype',
    'Deep Talk',
    'Romantic',
    'Creative',
    'Chaotic',
    'Focused',
    'Playful',
  ];

  /// Neon accent color per vibe.
  static const Map<String, Color> colorMap = {
    'Chill':      Color(0xFF00CFFF),  // cyan
    'Hype':       Color(0xFFFF2D55),  // electric pink
    'Deep Talk':  Color(0xFF8A2BE2),  // violet
    'Romantic':   Color(0xFFFF6B6B),  // coral
    'Creative':   Color(0xFFFFD700),  // gold
    'Chaotic':    Color(0xFFFF8C00),  // orange
    'Focused':    Color(0xFF00FF87),  // neon green
    'Playful':    Color(0xFFFF69B4),  // hot pink
  };

  static Color colorFor(String? tag) =>
      colorMap[tag] ?? const Color(0xFF00D9FF);

  /// Short emoji label shown alongside the tag chip.
  static const Map<String, String> emojiMap = {
    'Chill':      '😌',
    'Hype':       '🔥',
    'Deep Talk':  '🧠',
    'Romantic':   '💞',
    'Creative':   '🎨',
    'Chaotic':    '🌀',
    'Focused':    '🎯',
    'Playful':    '🎉',
  };

  static String emojiFor(String? tag) => emojiMap[tag] ?? '✨';
}

/// Music Genres popular on social audio apps.
/// Used in: profile, NeonProfileCard, room recommendations, search filters.
class MusicGenres {
  MusicGenres._();

  static const List<String> all = [
    'Afrobeat',
    'Hip-Hop',
    'R&B',
    'House',
    'Techno',
    'EDM',
    'Lo-Fi',
    'Pop',
    'Dancehall',
    'Reggae',
    'Jazz',
    'Trap',
    'Drill',
    'Amapiano',
    'Soca',
    'Country',
    'Indie',
    'Classical',
    'Gospel',
    'Alternative',
  ];
}

/// Country codes (ISO 3166-1 alpha-2) mapped to their flag emoji.
/// Used on the NeonProfileCard.
class CountryFlags {
  CountryFlags._();

  /// Convert a 2-letter ISO country code to flag emoji.
  /// e.g. 'US' → '🇺🇸'
  static String toEmoji(String? code) {
    if (code == null || code.length != 2) return '';
    final base = 0x1F1E6; // Regional Indicator Symbol A
    final offset = code.toUpperCase().codeUnits;
    if (offset.length != 2) return '';
    return String.fromCharCode(base + offset[0] - 65) +
        String.fromCharCode(base + offset[1] - 65);
  }

  /// Popular country list shown in picker (code → display name).
  static const Map<String, String> commonCountries = {
    'US': 'United States',
    'GB': 'United Kingdom',
    'CA': 'Canada',
    'AU': 'Australia',
    'NG': 'Nigeria',
    'GH': 'Ghana',
    'ZA': 'South Africa',
    'KE': 'Kenya',
    'JM': 'Jamaica',
    'TT': 'Trinidad & Tobago',
    'FR': 'France',
    'DE': 'Germany',
    'BR': 'Brazil',
    'MX': 'Mexico',
    'IN': 'India',
    'JP': 'Japan',
    'SG': 'Singapore',
    'AE': 'UAE',
    'SE': 'Sweden',
    'NL': 'Netherlands',
  };
}
