// lib/core/motion/app_motion.dart
//
// AppMotion – single source of truth for every duration, curve, and
// common animation builder used across MixMingle.
//
// Usage:
//   AnimationController(duration: AppMotion.normal, vsync: this)
//   AppMotion.fadeIn(child: myWidget)
//   AppMotion.glowPulse(controller: _ctrl, child: myWidget)
// ─────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

/// Centralized motion constants and builders.
class AppMotion {
  AppMotion._();

  // ── Durations ──────────────────────────────────────────────────
  static const Duration fast   = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow   = Duration(milliseconds: 400);
  static const Duration xSlow  = Duration(milliseconds: 600);
  static const Duration glow   = Duration(milliseconds: 1800);

  // Aliases kept for backward-compatibility with existing code that
  // references NeonAnimations.quickDuration / normalDuration etc.
  static const Duration quickDuration    = fast;
  static const Duration normalDuration   = normal;
  static const Duration slowDuration     = slow;
  static const Duration verySlowDuration = xSlow;
  static const Duration glowDuration     = glow;

  // ── Curves ────────────────────────────────────────────────────
  /// Use for element entrances.
  static const Curve entrance  = Curves.easeOutCubic;
  /// Use for page / room transitions.
  static const Curve transition = Curves.easeInOutCubic;
  /// Use for oscillating glow / pulse loops.
  static const Curve pulse     = Curves.easeInOut;
  static const Curve snap      = Curves.decelerate;
  static const Curve spring    = Curves.elasticOut;

  // ── Fade ──────────────────────────────────────────────────────
  /// Fades [child] in from transparent.
  static Widget fadeIn({
    required Widget child,
    Duration duration = normal,
    Curve curve = entrance,
    double from = 0.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: from, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (_, v, c) => Opacity(opacity: v, child: c),
      child: child,
    );
  }

  // ── Scale ─────────────────────────────────────────────────────
  /// Scales [child] in from [beginScale] to 1.0.
  static Widget scaleIn({
    required Widget child,
    Duration duration = normal,
    Curve curve = entrance,
    double beginScale = 0.9,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: beginScale, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (_, v, c) => Transform.scale(scale: v, child: c),
      child: child,
    );
  }

  // ── Slide ─────────────────────────────────────────────────────
  /// Slides [child] in from [offset] (logical pixels, Y axis by default).
  static Widget slideIn({
    required Widget child,
    Duration duration = normal,
    Curve curve = entrance,
    Offset beginOffset = const Offset(0, 40),
  }) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween<Offset>(begin: beginOffset, end: Offset.zero),
      duration: duration,
      curve: curve,
      builder: (_, v, c) => Transform.translate(offset: v, child: c),
      child: child,
    );
  }

  /// Slides and fades in together (most common combo for banners / cards).
  static Widget slideFadeIn({
    required Widget child,
    Duration duration = normal,
    Curve curve = entrance,
    Offset beginOffset = const Offset(0, 24),
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (_, v, c) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(beginOffset.dx * (1 - v), beginOffset.dy * (1 - v)),
          child: c,
        ),
      ),
      child: child,
    );
  }

  // ── Glow pulse (continuous) ───────────────────────────────────
  /// Wraps [child] in an opacity oscillation driven by [controller].
  /// [controller] should be set to repeat(reverse: true).
  static Widget glowPulse({
    required AnimationController controller,
    required Widget child,
    double minOpacity = 0.5,
    double maxOpacity = 1.0,
  }) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, c) {
        final t = Curves.easeInOut.transform(controller.value);
        final opacity = minOpacity + (maxOpacity - minOpacity) * t;
        return Opacity(opacity: opacity, child: c);
      },
      child: child,
    );
  }

  // ── Page/room neon wipe ───────────────────────────────────────
  /// Returns a [PageRouteBuilder] with a horizontal slide + fade transition
  /// sized for room-hop navigation.
  static PageRouteBuilder<T> roomHopRoute<T>({
    required WidgetBuilder builder,
    bool slideFromRight = true,
  }) {
    final dx = slideFromRight ? 1.0 : -1.0;
    return PageRouteBuilder<T>(
      transitionDuration: normal,
      reverseTransitionDuration: normal,
      pageBuilder: (ctx, _, __) => builder(ctx),
      transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
        final slide = Tween<Offset>(begin: Offset(dx, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: transition));
        final fade = Tween<double>(begin: 0.0, end: 1.0)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeIn));
        return SlideTransition(
          position: slide,
          child: FadeTransition(opacity: fade, child: child),
        );
      },
    );
  }
}
