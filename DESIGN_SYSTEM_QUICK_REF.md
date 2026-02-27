## DESIGN SYSTEM QUICK REFERENCE

**Print this. Keep it on your desk. Use it every time you write a widget.**

---

## COLORS

```dart
import 'package:mixmingle/core/design_system/design_constants.dart';

// ONLY colors allowed:
DesignColors.accent           // #FF4C4C (red/pink) - ONLY accent color
DesignColors.white            // #FFFFFF
DesignColors.background       // #FAFAFA (lightest gray)
DesignColors.divider          // #EEEEEE
DesignColors.textDark         // #212121 (for text)
DesignColors.textGray         // #757575 (for secondary text)

// For status indicators:
DesignColors.roomEnergyCalm   // #1976D2 (blue)
DesignColors.roomEnergyActive // #FFA726 (amber)
DesignColors.roomEnergyBuzzing// #FF4C4C (red = accent)
```

**Remember:** No `Colors.red`, `Colors.blue`, or magic `0xFF` values.

---

## TYPOGRAPHY

```dart
// Use EXACTLY one of these for every Text widget:
DesignTypography.heading      // 18pt bold - Room name, big titles
DesignTypography.subheading   // 14pt w600 - Participant name, section headers
DesignTypography.body         // 14pt normal - Regular text
DesignTypography.caption      // 12pt normal, gray - Timestamps, helper text
DesignTypography.label        // 12pt w600 - Badge text
DesignTypography.button       // 14pt w600, white - Button text only
```

**Example:**

```dart
Text('Room Name', style: DesignTypography.heading)
Text('3 people', style: DesignTypography.caption)
```

---

## SPACING

```dart
// Padding, margins, gaps - use ONLY these:
DesignSpacing.xs        // 4px   (rare)
DesignSpacing.sm        // 8px
DesignSpacing.md        // 12px  (gap between items)
DesignSpacing.lg        // 16px  (card padding, button padding)
DesignSpacing.xl        // 24px
DesignSpacing.xxl       // 32px

// Shortcut constants:
DesignSpacing.cardPadding       // 16px (inside cards)
DesignSpacing.cardBorderRadius  // 12px (rounded corners)
DesignSpacing.buttonMinHeight   // 44px (touch target)
DesignSpacing.avatarMedium      // 40px (participant avatars)
```

**Example:**

```dart
Padding(
  padding: EdgeInsets.all(DesignSpacing.lg),  // 16px
  child: ...
)

SizedBox(height: DesignSpacing.md)  // 12px gap
```

---

## ANIMATIONS

```dart
// Join flow (non-negotiable):
DesignAnimations.joinStage1Duration     // 150ms - "Entering room…"
DesignAnimations.joinStage2MinDuration  // 400ms - "Connecting audio…"
DesignAnimations.joinStage3Duration     // 400ms - "You're live" fade-in

// Presence animations:
DesignAnimations.presenceSlideInDuration       // 250ms (new participant)
DesignAnimations.presenceFadeOutDuration       // 200ms (participant leaves)

// Speaking:
DesignAnimations.speakingPulseDuration         // 200ms per pulse cycle

// UI feedback:
DesignAnimations.buttonPressDuration           // 100ms (press feedback)
DesignAnimations.notificationVisibleDuration   // 3000ms (show time)

// Curves:
DesignAnimations.easeOutCubic
DesignAnimations.easeInCubic
DesignAnimations.easeInOut
```

**Example:**

```dart
AnimationController(
  duration: DesignAnimations.joinStage1Duration,
  vsync: this,
)
```

---

## BORDERS & SHADOWS

```dart
// Borders:
DesignBorders.cardDefault       // 3px left accent + light sides
DesignBorders.cardHovered       // Lighter accent hover state
DesignBorders.inputDefault      // Bottom border only
DesignBorders.inputFocused      // Bottom border accent

// Shadows:
DesignShadows.subtle            // Subtle card shadow
DesignShadows.medium            // Elevated card shadow
DesignShadows.speakingGlow      // Speaking participant glow
DesignShadows.error             // Error state glow
```

**Example:**

```dart
Container(
  decoration: BoxDecoration(
    border: DesignBorders.cardDefault,
    boxShadow: [DesignShadows.subtle],
  ),
)
```

---

## BUILDING A CARD (MOST COMMON)

**Template:**

```dart
Container(
  padding: EdgeInsets.all(DesignSpacing.cardPadding),        // 16px
  decoration: BoxDecoration(
    border: DesignBorders.cardDefault,
    borderRadius: BorderRadius.circular(DesignSpacing.cardBorderRadius),
    color: DesignColors.white,
    boxShadow: [DesignShadows.subtle],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Title', style: DesignTypography.heading),
      SizedBox(height: DesignSpacing.md),
      Text('Subtitle', style: DesignTypography.caption),
    ],
  ),
)
```

---

## BUILDING A BUTTON

**Template:**

```dart
GestureDetector(
  onTap: onPressed,
  child: Container(
    padding: EdgeInsets.symmetric(
      horizontal: DesignSpacing.lg,
      vertical: DesignSpacing.md,
    ),
    decoration: BoxDecoration(
      color: DesignColors.accent,
      borderRadius: BorderRadius.circular(DesignSpacing.buttonBorderRadius),
    ),
    child: Text(
      'Join Room',
      style: DesignTypography.button,  // white text, w600
    ),
  ),
)
```

---

## JOIN FLOW PHASES

```dart
enum JoinPhase {
  initial,      // Ready to join
  entering,     // 150ms - "Entering room…"
  connecting,   // 400–1000ms - "Connecting audio & video…"
  live,         // 400ms - "You're live"
  error,        // Joined failed
  left,         // User left
}

// In controller:
state = state.copyWith(phase: JoinPhase.entering);
await Future.delayed(DesignAnimations.joinStage1Duration);
state = state.copyWith(phase: JoinPhase.connecting);
```

---

## ROOM ENERGY INDICATOR

```dart
final energy = 1.5;  // From Firestore
final color = RoomEnergyThresholds.getEnergyColor(energy);
final label = RoomEnergyThresholds.getEnergyLabel(energy);

// 0.0–0.5 = Calm (blue)
// 0.5–2.0 = Active (amber)
// 2.0+ = Buzzing (red)
```

---

## NOTIFICATIONS

```dart
showNotification(
  message: 'Emma just joined',
  type: NotificationType.userArrived,  // 3s visible
  onComplete: () { /* dismissed */ },
)

// Types:
NotificationType.userArrived    // 3s
NotificationType.userLeft       // 3s
NotificationType.youAreLive     // 2s
NotificationType.error          // 4s
```

---

## TESTS MUST PASS

Before committing, run:

```bash
# Design constants validation
flutter test test/design_constants_test.dart

# Animation validation
flutter test test/design_animations_test.dart

# All tests
flutter test
```

**If tests fail, DO NOT commit.** Fix the code to match constants.

---

## COMMON MISTAKES

❌ **DON'T:**

```dart
Container(color: Color(0xFFFF4C4C))  // Magic number
TextStyle(fontSize: 18)               // Magic number
Padding(padding: EdgeInsets.all(16))  // Magic number
Duration(milliseconds: 150)           // Magic number
```

✅ **DO:**

```dart
Container(color: DesignColors.accent)
TextStyle(fontSize: DesignTypography.heading.fontSize)
Padding(padding: EdgeInsets.all(DesignSpacing.lg))
Duration(milliseconds: DesignAnimations.joinStage1Duration.inMilliseconds)
```

---

## QUESTIONS?

1. **"What color should I use for..."** → Check DESIGN_BIBLE.md Section A
2. **"How long should this animation be..."** → Check DESIGN_BIBLE.md Section C
3. **"How much padding..."** → Check DESIGN_BIBLE.md Section B
4. **"Is this deviation OK..."** → Document it and ask code review

---

**This is BINDING. No exceptions. Every widget uses these constants.**
