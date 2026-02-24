// lib/core/theme/vibe_theme.dart
//
// VibeTheme – maps a room's vibe tag + energy level (0–100) to a
// consistent set of colors, glow intensities, and animation speeds.
//
// Usage:
//   final vt = VibeTheme.of(vibeTag: room.vibeTag, energy: 72);
//   Container(decoration: BoxDecoration(gradient: vt.gradient))
//   AnimationController(duration: vt.pulseDuration, vsync: this)
// ─────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

/// Supported vibe identifiers (lowercase, matches Room.vibeTag values).
enum VibeTag {
  chill,
  hype,
  deepTalk,
  party,
  lateNight,
  unknown,
}

/// All resolved visual properties for a given vibe + energy.
class VibeThemeData {
  final VibeTag tag;
  final int energy;           // 0–100

  // Colors
  final Color primary;
  final Color secondary;
  final Color glowColor;
  final Color background;

  // Gradient
  final LinearGradient gradient;

  // Glow intensity: 0.0 (none) → 1.0 (max)
  final double glowIntensity;

  // Blur radius for BoxShadow / neon effects
  final double glowBlur;

  // Spread for outer glow ring
  final double glowSpread;

  // Animation speed
  final Duration pulseDuration;

  // Human-readable energy label
  final String energyLabel;

  const VibeThemeData({
    required this.tag,
    required this.energy,
    required this.primary,
    required this.secondary,
    required this.glowColor,
    required this.background,
    required this.gradient,
    required this.glowIntensity,
    required this.glowBlur,
    required this.glowSpread,
    required this.pulseDuration,
    required this.energyLabel,
  });

  /// Returns a [BoxDecoration] ready for containers / card borders.
  BoxDecoration cardDecoration({
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(16)),
    double borderWidth = 1.5,
  }) {
    return BoxDecoration(
      gradient: gradient,
      borderRadius: borderRadius,
      border: Border.all(
        color: primary.withValues(alpha: 0.6),
        width: borderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: glowColor.withValues(alpha: glowIntensity * 0.6),
          blurRadius: glowBlur,
          spreadRadius: glowSpread,
        ),
      ],
    );
  }

  /// Returns a [List<BoxShadow>] suitable for a speaking-glow ring.
  List<BoxShadow> speakingGlow({double scale = 1.0}) => [
    BoxShadow(
      color: glowColor.withValues(alpha: (glowIntensity * 0.9).clamp(0, 1)),
      blurRadius: glowBlur * scale,
      spreadRadius: glowSpread * scale,
    ),
    BoxShadow(
      color: glowColor.withValues(alpha: (glowIntensity * 0.4).clamp(0, 1)),
      blurRadius: glowBlur * scale * 2,
      spreadRadius: 0,
    ),
  ];
}

class VibeTheme {
  VibeTheme._();

  // ── Base palette ──────────────────────────────────────────────
  static const Color _chillPrimary    = Color(0xFF00D9FF); // cyan
  static const Color _chillSec        = Color(0xFF0056A0); // deep blue
  static const Color _hypePrimary     = Color(0xFFFF2BD7); // hot pink
  static const Color _hypeSec         = Color(0xFFBD00FF); // purple
  static const Color _deepTalkPrimary = Color(0xFFBD00FF); // purple
  static const Color _deepTalkSec     = Color(0xFF5533AA); // indigo
  static const Color _partyPrimary    = Color(0xFFFF7A3C); // orange
  static const Color _partySec        = Color(0xFFFF2BD7); // pink
  static const Color _latePrimary     = Color(0xFFFF00A8); // magenta
  static const Color _lateSec         = Color(0xFF33003A); // very dark purple
  static const Color _bg              = Color(0xFF0A0E27); // brand darkBg

  // ── Factory ───────────────────────────────────────────────────
  /// Resolves a [VibeThemeData] from a nullable string vibe tag and an
  /// integer energy level (0–100). Safe to call with nulls / unknowns.
  static VibeThemeData of({
    String? vibeTag,
    int energy = 50,
  }) {
    final tag = _parseTag(vibeTag);
    final e   = energy.clamp(0, 100);
    // Energy modulates glow intensity: more energy = stronger glow
    final baseGlow     = 0.3 + (e / 100) * 0.7;          // 0.3 → 1.0
    final baseBlur     = 8.0 + (e / 100) * 20.0;          // 8 → 28
    final baseSpread   = 0.5 + (e / 100) * 3.5;           // 0.5 → 4.0
    // Faster pulse as energy rises: 2000ms → 500ms
    final pulseMs      = (2000 - (e / 100) * 1500).round();

    switch (tag) {
      case VibeTag.chill:
        return VibeThemeData(
          tag: tag,
          energy: e,
          primary: _chillPrimary,
          secondary: _chillSec,
          glowColor: _chillPrimary,
          background: _bg,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_bg, _chillSec.withValues(alpha: 0.4)],
          ),
          glowIntensity: baseGlow * 0.7,
          glowBlur: baseBlur * 0.8,
          glowSpread: baseSpread * 0.6,
          pulseDuration: Duration(milliseconds: (pulseMs * 1.4).round()),
          energyLabel: _energyLabel(e),
        );

      case VibeTag.hype:
        return VibeThemeData(
          tag: tag,
          energy: e,
          primary: _hypePrimary,
          secondary: _hypeSec,
          glowColor: _hypePrimary,
          background: _bg,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _hypeSec.withValues(alpha: 0.6),
              _hypePrimary.withValues(alpha: 0.4),
            ],
          ),
          glowIntensity: baseGlow,
          glowBlur: baseBlur,
          glowSpread: baseSpread,
          pulseDuration: Duration(milliseconds: pulseMs),
          energyLabel: _energyLabel(e),
        );

      case VibeTag.deepTalk:
        return VibeThemeData(
          tag: tag,
          energy: e,
          primary: _deepTalkPrimary,
          secondary: _deepTalkSec,
          glowColor: _deepTalkPrimary,
          background: const Color(0xFF080610),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF080610),
              _deepTalkSec.withValues(alpha: 0.5),
            ],
          ),
          glowIntensity: baseGlow * 0.6,
          glowBlur: baseBlur * 0.9,
          glowSpread: baseSpread * 0.5,
          pulseDuration: Duration(milliseconds: (pulseMs * 1.6).round()),
          energyLabel: _energyLabel(e),
        );

      case VibeTag.party:
        return VibeThemeData(
          tag: tag,
          energy: e,
          primary: _partyPrimary,
          secondary: _partySec,
          glowColor: _partyPrimary,
          background: _bg,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _partyPrimary.withValues(alpha: 0.5),
              _partySec.withValues(alpha: 0.6),
            ],
          ),
          glowIntensity: (baseGlow * 1.1).clamp(0, 1),
          glowBlur: baseBlur * 1.2,
          glowSpread: baseSpread * 1.1,
          pulseDuration: Duration(milliseconds: (pulseMs * 0.8).round()),
          energyLabel: _energyLabel(e),
        );

      case VibeTag.lateNight:
        return VibeThemeData(
          tag: tag,
          energy: e,
          primary: _latePrimary,
          secondary: _lateSec,
          glowColor: _latePrimary,
          background: const Color(0xFF05030A),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF05030A),
              _lateSec.withValues(alpha: 0.8),
            ],
          ),
          glowIntensity: baseGlow * 0.8,
          glowBlur: baseBlur * 0.9,
          glowSpread: baseSpread * 0.7,
          pulseDuration: Duration(milliseconds: (pulseMs * 1.2).round()),
          energyLabel: _energyLabel(e),
        );

      case VibeTag.unknown:
        return VibeThemeData(
          tag: VibeTag.unknown,
          energy: e,
          primary: const Color(0xFF00D9FF),
          secondary: const Color(0xFF1A1F3A),
          glowColor: const Color(0xFF00D9FF),
          background: _bg,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_bg, Color(0xFF1A1F3A)],
          ),
          glowIntensity: baseGlow * 0.5,
          glowBlur: baseBlur * 0.6,
          glowSpread: baseSpread * 0.4,
          pulseDuration: Duration(milliseconds: pulseMs),
          energyLabel: _energyLabel(e),
        );
    }
  }

  // ── Helpers ───────────────────────────────────────────────────
  static VibeTag _parseTag(String? raw) {
    switch (raw?.toLowerCase().replaceAll(' ', '').replaceAll('_', '')) {
      case 'chill':    return VibeTag.chill;
      case 'hype':     return VibeTag.hype;
      case 'deeptalk': return VibeTag.deepTalk;
      case 'party':    return VibeTag.party;
      case 'latenight':return VibeTag.lateNight;
      default:         return VibeTag.unknown;
    }
  }

  static String _energyLabel(int e) {
    if (e < 20) return '❄️ Chill';
    if (e < 40) return '🌤 Warming up';
    if (e < 60) return '🔥 Heating up';
    if (e < 80) return '⚡ Hype';
    return '🚀 On fire';
  }

  /// Compute an energy level (0–100) from raw room activity signals.
  static int computeEnergy({
    int activeSpeakers  = 0,
    int reactionsPerMin = 0,
    int messagesPerMin  = 0,
    int recentJoins     = 0,
    int totalViewers    = 0,
  }) {
    final score =
        (activeSpeakers  * 12) +
        (reactionsPerMin *  5) +
        (messagesPerMin  *  3) +
        (recentJoins     *  8) +
        (totalViewers    *  1);
    return score.clamp(0, 100);
  }
}
