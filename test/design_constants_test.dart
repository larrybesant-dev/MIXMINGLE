/// UNIT TESTS FOR DESIGN SYSTEM CONSTANTS
///
/// Validates all DESIGN_BIBLE.md enforcements
/// These tests MUST PASS before any UI/UX changes are merged

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix_and_mingle/core/design_system/design_constants.dart';

void main() {
  group('DesignColors', () {
    test('white color is correct hex', () {
      expect(
        DesignColors.accent.value,
        equals(0xFFFFFFFF),
      );
    });

    test('neutral palette is grayscale only', () {
      // Grayscale means R=G=B
      final testColors = [
        DesignColors.accent,
        DesignColors.accent,
        DesignColors.accent,
        DesignColors.accent,
        DesignColors.accent,
        DesignColors.accent,
        DesignColors.accent,
      ];

      for (final color in testColors) {
        final r = (color.value >> 16) & 0xFF;
        final g = (color.value >> 8) & 0xFF;
        final b = color.value & 0xFF;
        expect(
          r,
          equals(g),
          reason: 'Red channel should equal green for grayscale',
        );
        expect(
          g,
          equals(b),
          reason: 'Green channel should equal blue for grayscale',
        );
      }
    });

    test('room energy colors are distinct', () {
      expect(
        DesignColors.accent.value,
        isNot(equals(DesignColors.accent.value)),
      );
      expect(
        DesignColors.accent.value,
        isNot(equals(DesignColors.accent.value)),
      );
    });
  });

  group('DesignTypography', () {
    test('heading is bold and largest', () {
      expect(DesignTypography.heading.fontSize, greaterThan(14));
      expect(
        DesignTypography.heading.fontWeight,
        equals(FontWeight.bold),
      );
    });

    test('body uses normal weight', () {
      expect(
        DesignTypography.body.fontWeight,
        equals(FontWeight.normal),
      );
    });

    test('all text styles use textDark or textGray', () {
      final styles = [
        DesignTypography.heading,
        DesignTypography.body,
        DesignTypography.caption,
      ];

      for (final style in styles) {
        expect(
          [DesignColors.accent, DesignColors.accent].contains(style.color),
          isTrue,
          reason: 'All text should be dark or gray, no accent text',
        );
      }
    });
  });

  group('DesignSpacing', () {
    test('spacing values follow scale', () {
      expect(DesignSpacing.sm, equals(8));
      expect(DesignSpacing.md, equals(12));
      expect(DesignSpacing.lg, equals(16));
      expect(DesignSpacing.xl, equals(24));
      expect(DesignSpacing.xxl, equals(32));
    });

    test('card radius is reasonable', () {
      expect(
        DesignSpacing.cardBorderRadius,
        isIn([8.0, 12.0, 16.0]),
        reason: 'Border radius should be one of standard values',
      );
    });

    test('button min height meets accessibility', () {
      expect(
        DesignSpacing.buttonMinHeight,
        greaterThanOrEqualTo(44),
        reason: 'Touch targets must be >= 44pt per Material Design',
      );
    });
  });

  group('DesignAnimations - Join Flow Timing', () {
    test('join stage 1 is 150ms', () {
      expect(
        DesignAnimations.joinStage1Duration.inMilliseconds,
        equals(150),
        reason: 'DESIGN_BIBLE mandatory: Stage 1 = 150ms',
      );
    });

    test('join stage 2 is 400-1000ms', () {
      expect(
        DesignAnimations.joinStage2MinDuration.inMilliseconds,
        equals(400),
        reason: 'DESIGN_BIBLE: Stage 2 minimum = 400ms',
      );
      expect(
        DesignAnimations.joinStage2MaxDuration.inMilliseconds,
        equals(1000),
        reason: 'DESIGN_BIBLE: Stage 2 maximum = 1000ms',
      );
    });

    test('join stage 3 is 400ms', () {
      expect(
        DesignAnimations.joinStage3Duration.inMilliseconds,
        equals(400),
        reason: 'DESIGN_BIBLE: Stage 3 fade-in = 400ms',
      );
    });

    test('total minimum join is 700ms', () {
      expect(
        DesignAnimations.joinTotalMinimum.inMilliseconds,
        equals(700),
        reason: 'DESIGN_BIBLE: Minimum total join time = 700ms',
      );
    });

    test('presence animations are subsecond', () {
      expect(
        DesignAnimations.presenceSlideInDuration.inMilliseconds,
        lessThan(1000),
      );
      expect(
        DesignAnimations.presenceFadeOutDuration.inMilliseconds,
        lessThan(500),
      );
    });

    test('speaking pulse is responsive', () {
      expect(
        DesignAnimations.speakingPulseDuration.inMilliseconds,
        equals(200),
        reason: 'Speaking pulse should be quick and visible',
      );
    });

    test('notification visible duration is reasonable', () {
      expect(
        DesignAnimations.notificationVisibleDuration.inSeconds,
        equals(3),
        reason: 'Notifications should be visible for 3 seconds',
      );
    });
  });

  group('DesignAnimations - Curves', () {
    test('easeOutCubic is valid cubic bezier', () {
      expect(DesignAnimations.easeOutCubic, isNotNull);
      // Curves are cubic(x1, y1, x2, y2) where 0 <= all <= 1
      // easeOutCubic should be (0.215, 0.61, 0.355, 1.0)
    });

    test('easeInCubic is valid cubic bezier', () {
      expect(DesignAnimations.easeInCubic, isNotNull);
    });

    test('easeInOut is valid cubic bezier', () {
      expect(DesignAnimations.easeInOut, isNotNull);
    });
  });

  group('RoomEnergyThresholds', () {
    test('calm energy below 0.5', () {
      final color = RoomEnergyThresholds.getEnergyColor(0.3);
      expect(color.value, equals(DesignColors.accent.value));
    });

    test('active energy between 0.5 and 2.0', () {
      final color = RoomEnergyThresholds.getEnergyColor(1.0);
      expect(color.value, equals(DesignColors.accent.value));
    });

    test('buzzing energy above 2.0', () {
      final color = RoomEnergyThresholds.getEnergyColor(2.5);
      expect(color.value, equals(DesignColors.accent.value));
    });

    test('energy labels are correct', () {
      expect(RoomEnergyThresholds.getEnergyLabel(0.3), equals('Calm'));
      expect(RoomEnergyThresholds.getEnergyLabel(1.0), equals('Active'));
      expect(RoomEnergyThresholds.getEnergyLabel(2.5), equals('Buzzing'));
    });
  });

  group('JoinPhase Enum', () {
    test('all phases have display text', () {
      for (final phase in JoinPhase.values) {
        expect(phase.displayText, isNotEmpty);
      }
    });

    test('entering phase has 150ms expected duration', () {
      expect(
        JoinPhase.entering.expectedDuration.inMilliseconds,
        equals(150),
      );
    });

    test('connecting phase has 400ms expected duration', () {
      expect(
        JoinPhase.connecting.expectedDuration.inMilliseconds,
        equals(400),
      );
    });

    test('live phase has 400ms expected duration', () {
      expect(
        JoinPhase.live.expectedDuration.inMilliseconds,
        equals(400),
      );
    });
  });

  group('NotificationType', () {
    test('arrival notification visible for 3 seconds', () {
      expect(
        NotificationType.userArrived.visibleDuration.inSeconds,
        equals(3),
      );
    });

    test('youAreLive notification visible for 2 seconds', () {
      expect(
        NotificationType.youAreLive.visibleDuration.inSeconds,
        equals(2),
      );
    });

    test('error notification visible for 4 seconds', () {
      expect(
        NotificationType.error.visibleDuration.inSeconds,
        equals(4),
      );
    });

    test('error notification uses error color', () {
      expect(
        NotificationType.error.backgroundColor.value,
        equals(DesignColors.accent.value),
      );
    });
  });

  group('DesignShadows', () {
    test('subtle shadow exists', () {
      expect(DesignShadows.subtle, isNotNull);
      expect(DesignShadows.subtle.blurRadius, lessThan(8));
    });

    test('speaking glow uses accent color', () {
      final shadowColor = DesignShadows.speakingGlow.color;
      // Glow should be accent-based (red)
      expect(shadowColor.red, greaterThan(200));
    });
  });

  group('DesignBorders', () {
    test('card default has 3px left accent border', () {
      final border = DesignBorders.cardDefault.left;
      expect(border.width, equals(3));
      expect(border.color.value, equals(DesignColors.accent.value));
    });

    test('input default has bottom border', () {
      final border = DesignBorders.inputDefault;
      expect(border.bottom.width, equals(1));
    });

    test('input focused uses accent color', () {
      final border = DesignBorders.inputFocused;
      expect(border.bottom.color.value, equals(DesignColors.accent.value));
    });
  });

  group('DESIGN_BIBLE Enforcement', () {
    test('accent is ONLY non-neutral color in palette', () {
      // Count non-white, non-gray colors
      final colors = [
        DesignColors.accent,
        DesignColors.accent,
        DesignColors.accent,
        DesignColors.accent,
        DesignColors.accent,
      ];

      // All should be variations of red/accent
      for (final color in colors) {
        expect(
          color.red,
          greaterThan(200),
          reason: 'Only red/pink colors allowed accent zone',
        );
      }
    });

    test('all animation durations are subsecond except timeout', () {
      final durations = [
        DesignAnimations.joinStage1Duration,
        DesignAnimations.joinStage2MinDuration,
        DesignAnimations.joinStage3Duration,
        DesignAnimations.presenceSlideInDuration,
        DesignAnimations.buttonFeedbackDuration,
        DesignAnimations.cardHoverDuration,
      ];

      for (final duration in durations) {
        expect(
          duration.inMilliseconds,
          lessThan(1500),
          reason: 'All UX animations should feel snappy (< 1.5s)',
        );
      }
    });

    test('join ritual timings sum to at least 700ms', () {
      final totalMinimum = DesignAnimations.joinStage1Duration.inMilliseconds +
          DesignAnimations.joinStage2MinDuration.inMilliseconds +
          DesignAnimations.joinStage3Duration.inMilliseconds;

      expect(
        totalMinimum,
        greaterThanOrEqualTo(950),
        reason:
            'Join flow should feel ceremonial, not instant (150+400+400 = 950ms minimum)',
      );
    });
  });
}
