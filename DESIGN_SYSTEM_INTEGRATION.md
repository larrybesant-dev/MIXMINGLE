## DESIGN BIBLE → FLUTTER CODE INTEGRATION GUIDE

**Status:** BINDING SPECIFICATION
**Last Updated:** February 2026
**Reference:** DESIGN_BIBLE.md Sections A-E + Implementation Details

---

## TABLE OF CONTENTS

1. [Enforcement Rules](#enforcement-rules)
2. [Import Pattern](#import-pattern)
3. [Room Card Implementation (Example)](#room-card-example)
4. [Video Room Join Flow Integration](#video-room-join-flow)
5. [Presence Listener Integration](#presence-listener-integration)
6. [Testing Requirements](#testing-requirements)
7. [QA Enforcement Checklist](#qa-enforcement-checklist)
8. [CI/CD Integration](#cicd-integration)

---

## ENFORCEMENT RULES

### Rule 1: All Colors Must Use DesignColors

❌ **FORBIDDEN:**

```dart
// DO NOT USE hardcoded colors
Container(
  color: Color(0xFFFF4C4C),  // Magic number
  child: Text('Hello'),
)

// DO NOT USE Colors. constants
Container(
  color: Colors.red,  // Material default
  child: Text('Hello'),
)
```

✅ **REQUIRED:**

```dart
import 'package:mixmingle/core/design_system/design_constants.dart';

Container(
  color: DesignColors.accent,  // Explicit, traceable
  child: Text('Hello'),
)
```

### Rule 2: All Typography Must Use DesignTypography

❌ **FORBIDDEN:**

```dart
Text(
  'Room Name',
  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
)
```

✅ **REQUIRED:**

```dart
Text(
  'Room Name',
  style: DesignTypography.heading,
)
```

### Rule 3: All Animation Durations Must Use DesignAnimations

❌ **FORBIDDEN:**

```dart
AnimationController(
  duration: Duration(milliseconds: 150),  // Magic number
  vsync: this,
)
```

✅ **REQUIRED:**

```dart
AnimationController(
  duration: DesignAnimations.joinStage1Duration,  // 150ms per DESIGN_BIBLE
  vsync: this,
)
```

### Rule 4: All Spacing Must Use DesignSpacing

❌ **FORBIDDEN:**

```dart
Padding(
  padding: EdgeInsets.all(16),  // Magic number
  child: Text('Hello'),
)
```

✅ **REQUIRED:**

```dart
Padding(
  padding: EdgeInsets.all(DesignSpacing.lg),  // 16px, explicit intent
  child: Text('Hello'),
)
```

### Rule 5: No Material Defaults in Custom Widgets

❌ **FORBIDDEN:**

```dart
Card(  // Material Card
  child: ListTile(  // Material ListTile
    title: Text('Room'),
  ),
)
```

✅ **REQUIRED:**

```dart
Container(
  padding: EdgeInsets.all(DesignSpacing.cardPadding),
  decoration: BoxDecoration(
    border: DesignBorders.cardDefault,
    borderRadius: BorderRadius.circular(DesignSpacing.cardBorderRadius),
    color: DesignColors.white,
    boxShadow: [DesignShadows.subtle],
  ),
  child: Text('Room', style: DesignTypography.heading),
)
```

---

## IMPORT PATTERN

Every Flutter widget that uses design system values must import:

```dart
import 'package:mixmingle/core/design_system/design_constants.dart';
import 'package:mixmingle/core/design_system/design_animations.dart';  // If using animations
```

**Where:** Top of file, after `package:flutter` imports.

---

## ROOM CARD EXAMPLE

This is the canonical example for how room cards should be implemented.

### ❌ BEFORE (Non-compliant)

```dart
class RoomCard extends StatelessWidget {
  final String name;
  final int participantCount;

  const RoomCard({required this.name, required this.participantCount});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ListTile(
        title: Text(name, style: TextStyle(fontSize: 18)),
        subtitle: Text('$participantCount people', style: TextStyle(fontSize: 12)),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue,  // Material default
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('Live'),
        ),
      ),
    );
  }
}
```

### ✅ AFTER (Compliant)

```dart
import 'package:flutter/material.dart';
import 'package:mixmingle/core/design_system/design_constants.dart';

class RoomCard extends StatelessWidget {
  final String name;
  final int participantCount;
  final VoidCallback onTap;

  const RoomCard({
    required this.name,
    required this.participantCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(DesignSpacing.cardPadding),  // 16px
        decoration: BoxDecoration(
          border: DesignBorders.cardDefault,
          borderRadius: BorderRadius.circular(DesignSpacing.cardBorderRadius),
          color: DesignColors.white,
          boxShadow: [DesignShadows.subtle],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Room name
            Text(name, style: DesignTypography.heading),

            SizedBox(height: DesignSpacing.md),  // 12px

            // Footer: participant count + energy indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$participantCount people',
                  style: DesignTypography.caption,
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: DesignSpacing.md,
                    vertical: DesignSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: DesignColors.accent.withOpacity(0.1),
                    border: Border.all(
                      color: DesignColors.accent,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Live',
                    style: DesignTypography.label.copyWith(
                      color: DesignColors.accent,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

**Key Points:**

1. ✅ All colors from `DesignColors`
2. ✅ All typography from `DesignTypography`
3. ✅ All spacing from `DesignSpacing`
4. ✅ All borders from `DesignBorders`
5. ✅ All shadows from `DesignShadows`
6. ✅ No Material Card/ListTile
7. ✅ Explicit `onTap` callback
8. ✅ Custom layout, not Material defaults

---

## VIDEO ROOM JOIN FLOW INTEGRATION

The join flow **MUST** respect these timings from DESIGN_BIBLE.md:

### Join Flow State Machine

```
Initial
  ↓ (user taps Join)
Entering (150ms - "Entering room…")
  ↓
Connecting (400–1000ms - "Connecting audio & video…")
  ↓
Live (400ms - "You're live")
  ↓
Completed
```

### Implementation in VideoRoomController

```dart
import 'package:mixmingle/core/design_system/design_constants.dart';

class VideoRoomNotifier extends StateNotifier<VideoRoomState> {
  Future<void> joinRoom(String roomId) async {
    try {
      // STAGE 1: Entering room (150ms)
      state = state.copyWith(
        phase: JoinPhase.entering,
        error: null,
      );

      await Future.delayed(DesignAnimations.joinStage1Duration);

      // STAGE 2: Connecting (400–1000ms, variable)
      state = state.copyWith(phase: JoinPhase.connecting);

      // Actual join logic (might take 400–1000ms)
      final stopwatch = Stopwatch()..start();
      await _lifecycle.joinChannel(roomId);
      final elapsed = stopwatch.elapsedMilliseconds;

      // Ensure minimum visible time if join is very fast
      final remainingTime = DesignAnimations.joinStage2MinDuration.inMilliseconds - elapsed;
      if (remainingTime > 0) {
        await Future.delayed(Duration(milliseconds: remainingTime));
      }

      // STAGE 3: Live (400ms fade-in)
      state = state.copyWith(phase: JoinPhase.live);
      await Future.delayed(DesignAnimations.joinStage3Duration);

      // COMPLETE
      state = state.copyWith(
        phase: JoinPhase.initial,  // Reset for next join
        isLive: true,
      );
    } catch (e) {
      state = state.copyWith(
        phase: JoinPhase.error,
        error: e.toString(),
      );
    }
  }
}
```

### UI Widget Using Join Flow

```dart
class VideoRoomView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(videoRoomNotifierProvider.notifier);
    final state = ref.watch(videoRoomNotifierProvider);

    // Show phase-specific UI
    return Column(
      children: [
        switch (state.phase) {
          JoinPhase.initial => _buildReadyUI(controller),
          JoinPhase.entering => _buildEnteringUI(),       // 150ms
          JoinPhase.connecting => _buildConnectingUI(),   // 400–1000ms
          JoinPhase.live => _buildLiveUI(),               // 400ms fade-in
          JoinPhase.error => _buildErrorUI(state),
          JoinPhase.left => _buildLeftUI(),
        }
      ],
    );
  }

  Widget _buildEnteringUI() {
    return Column(
      children: [
        CircularProgressIndicator(),
        SizedBox(height: DesignSpacing.lg),
        Text(
          JoinPhase.entering.displayText,  // "Entering room…"
          style: DesignTypography.subheading,
        ),
      ],
    );
  }

  Widget _buildConnectingUI() {
    return Column(
      children: [
        CircularProgressIndicator(),
        SizedBox(height: DesignSpacing.lg),
        Text(
          JoinPhase.connecting.displayText,  // "Connecting audio & video…"
          style: DesignTypography.subheading,
        ),
        SizedBox(height: DesignSpacing.md),
        Text(
          'This usually takes a few seconds',
          style: DesignTypography.caption,
        ),
      ],
    );
  }

  Widget _buildLiveUI() {
    return FadeInAnimation(
      duration: DesignAnimations.joinStage3Duration,  // 400ms
      child: Column(
        children: [
          Icon(Icons.check_circle, color: DesignColors.accent),
          SizedBox(height: DesignSpacing.lg),
          Text(
            JoinPhase.live.displayText,  // "You're live"
            style: DesignTypography.heading.copyWith(
              color: DesignColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## PRESENCE LISTENER INTEGRATION

Firestore presence events should trigger animations defined in `DesignAnimations`.

### Setup

```dart
import 'package:mixmingle/core/design_system/design_animations.dart';

class RoomPresenceListener {
  final FirebaseFirestore _firestore;
  final Function(String userName) onUserArrived;
  final Function(String userName) onUserLeft;

  void listen(String roomId) {
    _firestore.collection('rooms').doc(roomId).collection('members').snapshots().listen(
      (snapshot) {
        for (final change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            _onMemberArrived(change.doc.data());
          } else if (change.type == DocumentChangeType.removed) {
            _onMemberLeft(change.doc.data());
          }
        }
      },
    );
  }

  void _onMemberArrived(Map<String, dynamic> memberData) {
    final userName = memberData['name'] as String;

    // Trigger slide-in animation with notification
    onUserArrived(userName);

    // Show notification with proper timing
    showNotification(
      message: '$userName just joined',
      type: NotificationType.userArrived,
      duration: DesignAnimations.presenceSlideInDuration,  // 250ms
    );
  }

  void _onMemberLeft(Map<String, dynamic> memberData) {
    final userName = memberData['name'] as String;

    // Trigger slide-down animation
    onUserLeft(userName);

    // Show notification
    showNotification(
      message: '$userName left the room',
      type: NotificationType.userLeft,
      duration: DesignAnimations.presenceSlideDownDuration,  // 200ms
    );
  }
}
```

---

## TESTING REQUIREMENTS

### Unit Tests

All design constants have tests in `test/design_constants_test.dart`:

```bash
flutter test test/design_constants_test.dart
```

**These tests verify:**

- ✅ Accent color is exactly `#FF4C4C`
- ✅ Join flow timings are binding (150ms, 400ms, 400ms)
- ✅ All colors are grayscale or accent (no random colors)
- ✅ Room energy thresholds are enforced
- ✅ Animation curves are correct

### Widget Tests

Animations have widget tests in `test/design_animations_test.dart`:

```bash
flutter test test/design_animations_test.dart
```

**These tests verify:**

- ✅ `SpeakingPulseAnimation` scales when isSpeaking=true
- ✅ `NotificationAnimation` auto-dismisses after proper duration
- ✅ `RoomEnergyCardAnimation` shows correct energy label
- ✅ Button feedback scales down then up
- ✅ Join flow total timing ≥ 700ms

### Golden Tests (Optional)

For visual verification, add golden tests:

```dart
testWidgets('room card matches golden', (WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: RoomCard(
          name: 'Test Room',
          participantCount: 3,
          onTap: () {},
        ),
      ),
    ),
  );

  await expectLater(
    find.byType(RoomCard),
    matchesGoldenFile('goldens/room_card.png'),
  );
});
```

Run with:

```bash
flutter test --update-goldens
```

---

## QA ENFORCEMENT CHECKLIST

Before any UI/UX merge, QA must verify:

### Color Compliance

- [ ] Only colors used are from `DesignColors`
- [ ] Accent is ONLY used for CTAs, energy indicators, errors
- [ ] Neutral palette is white/gray only
- [ ] Search codebase: no `Colors.` usage in custom widgets
- [ ] Search codebase: no `0xFF` color literals

### Typography Compliance

- [ ] All text uses `DesignTypography.*` styles
- [ ] No hardcoded `fontSize` or `fontWeight`
- [ ] No Material `TextStyle` defaults
- [ ] Search codebase: no `TextStyle(fontSize: ...)` in custom widgets

### Animation Compliance

- [ ] Join flow: Entering = 150ms, Connecting ≥ 400ms, Live = 400ms
- [ ] Presence animations: < 300ms total
- [ ] Speaking pulse: continuous, 200ms per cycle
- [ ] Notifications: 3s visible for arrival/left, 2s for "you're live"
- [ ] All `AnimationController` durations use `DesignAnimations.*`

### Spacing Compliance

- [ ] No hardcoded padding/margin values
- [ ] Cards: 16px padding (`DesignSpacing.lg`)
- [ ] Card spacing: 12px between cards (`DesignSpacing.md`)
- [ ] Button min height: 44pt minimum

### Layout Compliance

- [ ] No Material `Card` widgets (use `Container` + `BoxDecoration`)
- [ ] No Material `ListTile` (use custom layout)
- [ ] No Material `AppBar` (use custom header if needed)
- [ ] All borders from `DesignBorders.*`
- [ ] All shadows from `DesignShadows.*`

### Video Room Specific

- [ ] Room discovery cards use `RoomEnergyCardAnimation`
- [ ] Join flow shows all 3 phases (entering, connecting, live)
- [ ] Presence arrivals/departures show notifications
- [ ] Speaking participants have pulse animation
- [ ] No instant state transitions (all have animations)

---

## CI/CD INTEGRATION

### Pre-Commit Hook

Add to `.git/hooks/pre-commit`:

```bash
#!/bin/bash
# Verify design system compliance

echo "🎨 Checking design system compliance..."

# Check for forbidden Color usage
if grep -r "Colors\." lib/features lib/screens --include="*.dart" | grep -v test | grep -v "// ignore:"; then
  echo "❌ Found Material Colors.* usage in custom widgets"
  echo "   Use DesignColors.* instead"
  exit 1
fi

# Check for magic color numbers
if grep -r "0xFF[0-9A-Fa-f]\{6\}" lib/features lib/screens --include="*.dart" | grep -v test; then
  echo "❌ Found hardcoded color hex values"
  echo "   Use DesignColors.* instead"
  exit 1
fi

# Check for magic spacing numbers
if grep -r "EdgeInsets.all([0-9]\{2,\})" lib/features lib/screens --include="*.dart" | grep -v DesignSpacing | grep -v test; then
  echo "⚠️  Found hardcoded spacing values"
  echo "   Consider using DesignSpacing.* instead"
fi

echo "✅ Design system compliance check passed"
exit 0
```

### GitHub Actions CI

Add to `.github/workflows/design-compliance.yml`:

```yaml
name: Design System Compliance

on: [pull_request]

jobs:
  design-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Check design constants
        run: |
          grep -r "Colors\." lib/features lib/screens && exit 1 || exit 0
          grep -r "0xFF" lib/features lib/screens | grep -v DesignColors && exit 1 || exit 0

      - name: Run design tests
        run: flutter test test/design_constants_test.dart test/design_animations_test.dart
```

### Code Review Guidelines

#### For Code Reviewers

When reviewing UI/UX PRs, enforce:

```markdown
## Design System Compliance Checklist

- [ ] All colors use `DesignColors.*`
- [ ] All typography uses `DesignTypography.*`
- [ ] All spacing uses `DesignSpacing.*`
- [ ] All animations use `DesignAnimations.*`
- [ ] No Material default widgets (Card, ListTile, etc.)
- [ ] All borders use `DesignBorders.*`
- [ ] All shadows use `DesignShadows.*`
- [ ] Tests added for new animations
- [ ] Design constants test passes: `flutter test test/design_constants_test.dart`
- [ ] Design animations test passes: `flutter test test/design_animations_test.dart`

**If any box is unchecked:** Request changes.
**If all boxes checked:** Approve and merge.
```

---

## DOCUMENTING DEVIATIONS

If you MUST deviate from design constants, document it:

```dart
// DEVIATION: Using custom color #FF6B6B (accent light)
// Reason: This is a hover state, need lighter accent
// Approved by: @product-lead on 2026-02-08
// Reference: DESIGN_BIBLE.md Section A - Room Card Hover State
// TODO: Add DesignColors.accentLight constant after this ships
const customAccentLight = Color(0xFFFF6B6B);
```

**Never approved deviations:**

- ❌ "Just needed a different shade"
- ❌ "No time to update constants"
- ❌ "It looked better this way"

**Always requires documentation:**

- ✅ New status colors (approved by product)
- ✅ New animation timings (affects UX)
- ✅ Accessibility adjustments (contrast, sizing)

---

## SUMMARY

**THE RULE:** All Flutter widgets must reference design system constants.

**THE ENFORCEMENT:**

- ✅ Unit tests verify constant values
- ✅ Widget tests verify animation timing
- ✅ Code review checklist enforces compliance
- ✅ CI/CD blocks PRs with design violations
- ✅ Golden tests verify visual output (optional)

**THE OUTCOME:**

- Consistent design across all screens
- Binding animation timings nobody can accidentally break
- Traceable decisions (every color, spacing, timing has a reason)
- Easy onboarding (new hires just read this guide + DESIGN_BIBLE.md)
- Production-grade quality from day 1

---

**Questions?** Read DESIGN_BIBLE.md Section A, B, C, D.
**Found a bug?** File issue with reference to design constant and test name.
**Need new constant?** Update `design_constants.dart`, add test, document deviation link.
