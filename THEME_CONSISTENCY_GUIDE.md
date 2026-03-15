# Theme Consistency Guide 🎨

## Overview

All pages in the Mix & Mingle app must use the centralized theme system to ensure visual consistency across the entire application.

## Theme Architecture

### Main Theme Definition

- **File**: `lib/core/theme/neon_theme.dart`
- **Applied In**: `lib/app.dart` → `MaterialApp` theme property
- **Status**: ✅ Actively maintained and enforced globally

### Color System

- **File**: `lib/core/design_system/design_constants.dart`
- **Class**: `DesignColors`
- **Usage**: All colors should come from this centralized palette

### Typography System

- **File**: `lib/core/theme/text_styles.dart`
- **Class**: `DesignTypography` / `ClubTextStyles`
- **Usage**: All text styling should use predefined text styles

## ✅ DO: Proper Theme Usage

### 1. Inherit Theme from MaterialApp

Every page/screen automatically inherits the theme defined in `MaterialApp`. **Do not override unless absolutely necessary.**

```dart
class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ GOOD: Inherits backgroundColor from theme
      // backgroundColor property omitted - uses Theme.of(context).scaffoldBackgroundColor
      appBar: AppBar(
        title: Text('My Page'),
        // ✅ GOOD: Inherits colors from theme
      ),
      body: Center(
        child: Text('Hello'),
      ),
    );
  }
}
```

### 2. Use Design Colors

For colors needed outside of theme properties, use the centralized color system:

```dart
import 'package:mix_and_mingle/core/design_system/design_constants.dart';

// ✅ GOOD: Using named color constants
Container(
  color: DesignColors.accent,
  child: Text(
    'Featured',
    style: TextStyle(color: DesignColors.gold),
  ),
)

// ✅ GOOD: Using color with opacity
Container(
  color: DesignColors.accent.withValues(alpha: 0.2),
)
```

### 3. Use Design Typography

All text should use predefined text styles:

```dart
import 'package:mix_and_mingle/core/design_system/design_constants.dart';

// ✅ GOOD: Using predefined typography
Text(
  'Heading',
  style: DesignTypography.heading1,
)

Text(
  'Body text',
  style: DesignTypography.body,
)
```

### 4. Use Theme Context When Needed

When you need theme properties dynamically:

```dart
// ✅ GOOD: Getting colors from active theme
Container(
  color: Theme.of(context).scaffoldBackgroundColor,
  child: Text(
    'Themed text',
    style: Theme.of(context).textTheme.bodyMedium,
  ),
)
```

## ❌ DON'T: Anti-Patterns

### 1. DO NOT hardcode colors

```dart
// ❌ BAD: Hardcoded color
Container(
  color: const Color(0xFF2A2A3E),
  child: Text('This breaks theme consistency'),
)
```

**Fix**: Use `DesignColors.dialogBackground` instead

### 2. DO NOT override scaffold background without reason

```dart
// ❌ BAD: Unnecessary scaffold override
Scaffold(
  backgroundColor: const Color(0xFF000000),
  // ...
)
```

**Fix**: Omit backgroundColor and let theme handle it

```dart
// ✅ GOOD: Uses theme background
Scaffold(
  // <-- no backgroundColor
  // ...
)
```

### 3. DO NOT create custom color schemes in individual widgets

```dart
// ❌ BAD: Custom colors in widget
Button(
  color: const Color(0xFFFFD700), // Gold hardcoded
)
```

**Fix**: Use design system

```dart
// ✅ GOOD: Using design system
Button(
  color: DesignColors.gold,
)
```

### 4. DO NOT use random opacity values

```dart
// ❌ BAD: Random opacity
Color.fromARGB(128, 255, 61, 61) // Unknown transparency level
```

**Fix**: Use predefined opacity constants

```dart
// ✅ GOOD: Named opacity variants
DesignColors.accent50  // 50% opacity
DesignColors.accent30  // 30% opacity
```

## Color Reference

### Primary Colors

- **Primary Accent**: `DesignColors.accent` → `#1E90FF` (Bright Blue)
- **Secondary**: `DesignColors.secondary` → `#FF9500` (Orange)
- **Tertiary**: `DesignColors.tertiary` → `#8B1538` (Dark Purple/Magenta)

### Surface Colors

- **Background**: `DesignColors.background` → `#000000` (Pure Black)
- **Surface Light**: `DesignColors.surfaceLight` → `#1A1A1A`
- **Dialog Background**: `DesignColors.dialogBackground` → `#2A2A3E`
- **Card Background**: `DesignColors.cardBackground` → `#1E1E2F`
- **Alternative Surface**: `DesignColors.surfaceAlt` → `#151A26`
- **Dark Surface**: `DesignColors.surfaceDark` → `#0A0A0A`

### Special Colors

- **Gold Highlight**: `DesignColors.gold` → `#FFD700`
- **Success**: `DesignColors.success` → `#4CAF50`
- **Error**: `DesignColors.error` → `#FF3D3D` (accent red)
- **Warning**: `DesignColors.warning` → `#FFC107`

### Opacity Variants

All accent colors have predefined opacity levels:

- `DesignColors.accent2` (2%)
- `DesignColors.accent5` (5%)
- `DesignColors.accent10` (10%)
- `DesignColors.accent12` (12%)
- `DesignColors.accent15` (15%)
- `DesignColors.accent20` (20%)
- `DesignColors.accent24` (24%)
- `DesignColors.accent26` (26%)
- `DesignColors.accent30` (30%)
- `DesignColors.accent40` (40%)
- `DesignColors.accent50` (50%)
- `DesignColors.accent60` (60%)
- `DesignColors.accent70` (70%)
- `DesignColors.accent90` (90%)

## Spacing System ✅

Never use hardcoded padding/margin values. Use `DesignSpacing` constants:

```dart
import 'package:mix_and_mingle/core/design_system/design_constants.dart';

// ✅ GOOD: Using spacing constants
CompactWidget(
  padding: EdgeInsets.all(DesignSpacing.sm),  // 8px
  child: Text('Compact'),
)

NormalWidget(
  padding: EdgeInsets.all(DesignSpacing.lg),  // 16px
  child: Text('Normal padding'),
)

// ✅ GOOD: Asymmetric spacing
Column(
  children: [
    Text('Title'),
    SizedBox(height: DesignSpacing.md),  // 12px vertical gap
  ],
)
```

### DesignSpacing Values

| Constant | Value | Use Case                        |
| -------- | ----- | ------------------------------- |
| `xs`     | 4px   | Micro spacing, icon padding     |
| `sm`     | 8px   | Small gaps, list item padding   |
| `md`     | 12px  | Medium spacing, form fields     |
| `lg`     | 16px  | Standard padding, card padding  |
| `xl`     | 24px  | Large spacing, section dividers |
| `xxl`    | 32px  | Maximum spacing, page padding   |

### Layout Constants

```dart
// Card styling
DesignSpacing.cardPadding        // 16px (= lg)
DesignSpacing.cardSpacing        // 12px (= md) between cards
DesignSpacing.cardBorderRadius   // 12.0 rounded corners

// Button sizing
DesignSpacing.buttonMinHeight    // 44px minimum tap target
DesignSpacing.buttonMinWidth     // 100px minimum
DesignSpacing.buttonPadding      // 16px horizontal padding
DesignSpacing.buttonBorderRadius // 12.0 rounded corners

// Avatar sizes
DesignSpacing.avatarLarge        // 48px (large profile avatars)
DesignSpacing.avatarMedium       // 40px (medium avatars)
DesignSpacing.avatarSmall        // 32px (small avatars)

// Control bar
DesignSpacing.controlBarHeight   // 80px
DesignSpacing.controlSpacing     // 16px (= lg)
```

## Shadows & Elevation

Use predefined shadows instead of creating custom ones:

```dart
import 'package:mix_and_mingle/core/design_system/design_constants.dart';

// ✅ GOOD: Using design system shadows
Container(
  decoration: BoxDecoration(
    color: DesignColors.cardBackground,
    boxShadow: [DesignShadows.subtle],  // Subtle elevation
  ),
  child: Text('Card with shadow'),
)

// ✅ GOOD: Medium elevation for hover states
Container(
  decoration: BoxDecoration(
    color: DesignColors.cardBackground,
    boxShadow: [DesignShadows.medium],  // Elevated on hover
  ),
)

// ✅ GOOD: Speaking indicator glow
Container(
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    boxShadow: [DesignShadows.speakingGlow],  // Glow effect
  ),
)
```

### DesignShadows Values

| Constant       | Use Case                                         |
| -------------- | ------------------------------------------------ |
| `subtle`       | Cards, buttons (blurRadius: 4)                   |
| `medium`       | Hovered cards, elevated surfaces (blurRadius: 8) |
| `speakingGlow` | Speaking indicator, attention (blurRadius: 12)   |
| `error`        | Error states, warnings (blurRadius: 6)           |

## Borders

Use predefined border styles for consistency:

```dart
import 'package:mix_and_mingle/core/design_system/design_constants.dart';

// ✅ GOOD: Card border
Container(
  decoration: BoxDecoration(
    border: DesignBorders.cardDefault,
  ),
  child: Text('Card with border'),
)

// ✅ GOOD: Card on hover
Container(
  decoration: BoxDecoration(
    border: DesignBorders.cardHovered,
  ),
)

// ✅ GOOD: Input field
TextField(
  decoration: InputDecoration(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(DesignSpacing.cardBorderRadius),
    ),
  ),
)
```

### DesignBorders Values

| Constant       | Description                                 |
| -------------- | ------------------------------------------- |
| `cardDefault`  | Thick left border (3px) + subtle top/bottom |
| `cardHovered`  | Same as cardDefault                         |
| `inputDefault` | Bottom border only (1px)                    |
| `inputFocused` | Bottom border focused (2px)                 |

## Animations & Timing

Use predefined animation durations for consistent user experience:

```dart
import 'package:mix_and_mingle/core/design_system/design_constants.dart';

// ✅ GOOD: Button feedback animation
AnimatedContainer(
  duration: DesignAnimations.buttonFeedbackDuration,  // 100ms
  decoration: BoxDecoration(
    color: isPressed ? Colors.darker : Colors.normal,
  ),
)

// ✅ GOOD: Notification fade-in
AnimatedOpacity(
  opacity: isVisible ? 1.0 : 0.0,
  duration: DesignAnimations.notificationFadeInDuration,  // 150ms
  child: Notification(),
)

// ✅ GOOD: Presence animation
SlideTransition(
  position: animation,
  child: UserPresenceWidget(),
)
```

### DesignAnimations Values

| Constant                      | Duration | Purpose                    |
| ----------------------------- | -------- | -------------------------- |
| `joinStage1Duration`          | 150ms    | Room entry animation       |
| `joinStage2MinDuration`       | 400ms    | Audio connection min wait  |
| `joinStage2MaxDuration`       | 1000ms   | Audio connection max wait  |
| `joinStage3Duration`          | 400ms    | "You're live" fade-in      |
| `presenceSlideInDuration`     | 250ms    | User presence slide-in     |
| `presenceFadeOutDuration`     | 200ms    | User presence fade-out     |
| `presenceSlideDownDuration`   | 200ms    | User presence slide-down   |
| `speakingPulseDuration`       | 200ms    | Speaking indicator pulse   |
| `buttonFeedbackDuration`      | 100ms    | Button press feedback      |
| `cardHoverDuration`           | 150ms    | Card hover effect          |
| `notificationFadeInDuration`  | 150ms    | Notification appearance    |
| `notificationFadeOutDuration` | 200ms    | Notification disappearance |

### Animation Curves

```dart
// Use predefined easing curves
DesignAnimations.easeOutCubic  // Standard easing out
DesignAnimations.easeInCubic   // Standard easing in
DesignAnimations.easeInOut     // Ease in-out
```

## Color Reference

### Primary Colors

- **Primary Accent**: `DesignColors.accent` → `#1E90FF` (Bright Blue)
- **Secondary**: `DesignColors.secondary` → `#FF9500` (Orange)
- **Tertiary**: `DesignColors.tertiary` → `#8B1538` (Dark Purple/Magenta)

### Surface Colors

- **Background**: `DesignColors.background` → `#000000` (Pure Black)
- **Surface Light**: `DesignColors.surfaceLight` → `#1A1A1A`
- **Dialog Background**: `DesignColors.dialogBackground` → `#2A2A3E`
- **Card Background**: `DesignColors.cardBackground` → `#1E1E2F`
- **Alternative Surface**: `DesignColors.surfaceAlt` → `#151A26`

### Special Colors

- **Gold Highlight**: `DesignColors.gold` → `#FFD700`
- **Success**: `DesignColors.success` → `#4CAF50`
- **Error**: `DesignColors.error` → `#FF3D3D` (accent red)
- **Warning**: `DesignColors.warning` → `#FFC107`

### Opacity Variants

All accent colors have predefined opacity levels:

- `DesignColors.accent5` (5%)
- `DesignColors.accent10` (10%)
- `DesignColors.accent20` (20%)
- `DesignColors.accent30` (30%)
- `DesignColors.accent50` (50%)
- `DesignColors.accent70` (70%)
- `DesignColors.accent90` (90%)

## Common Use Cases

### Dialog/Alert Display

```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    backgroundColor: DesignColors.dialogBackground, // ✅ Use design system
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: DesignColors.gold, width: 2),
    ),
    title: Text('Title', style: DesignTypography.heading2),
    content: Text('Content', style: DesignTypography.body),
  ),
);
```

### Cards & Containers

```dart
Card(
  // ✅ Inherits color from theme cardTheme
  child: Container(
    // ✅ If you need explicit color:
    color: DesignColors.cardBackground,
    child: Text('Card content', style: DesignTypography.body),
  ),
)
```

### Buttons

```dart
// ✅ All button themes are defined in NeonTheme
ElevatedButton(
  onPressed: () {},
  child: Text('Button', style: DesignTypography.bodyLarge),
)

// ✅ If custom color needed:
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: DesignColors.secondary,
  ),
  onPressed: () {},
  child: Text('Orange Button'),
)
```

### Navigation/TabBar

```dart
// ✅ Inherits colors from navigationBarTheme or tabBarTheme
NavigationBar(
  // Colors come from theme automatically
  destinations: const [
    NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
    NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
  ],
)
```

## Migration Checklist

When converting a page from hardcoded values to design system:

### Colors

- [ ] Remove all `const Color(0xFF...)` declarations
- [ ] Replace with `DesignColors.*` equivalents
- [ ] Use `DesignColors.accent*` opacity variants instead of `.withOpacity()`
- [ ] Use `Theme.of(context)` for dynamic theme values

### Spacing & Layout

- [ ] Replace hardcoded `SizedBox(height: X)` with `DesignSpacing.*`
- [ ] Replace hardcoded `padding:` with `DesignSpacing.*`
- [ ] Replace hardcoded `margin:` with `DesignSpacing.*`
- [ ] Use `DesignSpacing.cardBorderRadius` for corners
- [ ] Use avatar size constants for circular avatars

### Typography

- [ ] Update text styles to use `DesignTypography.*`
- [ ] Remove custom `TextStyle(fontSize: X)` declarations
- [ ] Use wrapper widgets like `GlowText` instead of custom text styles

### Shadows & Borders

- [ ] Replace custom `BoxShadow` with `DesignShadows.*`
- [ ] Use `DesignBorders.*` for card and input borders
- [ ] Remove unnecessary `backgroundColor` properties from `Scaffold`

### Animations

- [ ] Use `DesignAnimations.*` for animation durations
- [ ] Use `DesignAnimations.easeOutCubic` etc. for animation curves
- [ ] Test with both light and dark themes (when available)

## Common Replacements

### Colors

| Hardcoded Color     | Design System Equivalent        |
| ------------------- | ------------------------------- |
| `Color(0xFF2A2A3E)` | `DesignColors.dialogBackground` |
| `Color(0xFF1E1E2F)` | `DesignColors.cardBackground`   |
| `Color(0xFF151A26)` | `DesignColors.surfaceAlt`       |
| `Color(0xFF0A0A0A)` | `DesignColors.surfaceDark`      |
| `Color(0xFFFFD700)` | `DesignColors.gold`             |
| `Color(0xFF1E90FF)` | `DesignColors.accent`           |
| `Color(0xFFFF9500)` | `DesignColors.secondary`        |
| `Color(0xFF000000)` | `DesignColors.background`       |
| `Color(0xFF1A1A1A)` | `DesignColors.surfaceLight`     |

### Spacing/Padding

| Hardcoded Value        | Design System Equivalent             |
| ---------------------- | ------------------------------------ |
| `EdgeInsets.all(4)`    | `EdgeInsets.all(DesignSpacing.xs)`   |
| `EdgeInsets.all(8)`    | `EdgeInsets.all(DesignSpacing.sm)`   |
| `EdgeInsets.all(12)`   | `EdgeInsets.all(DesignSpacing.md)`   |
| `EdgeInsets.all(16)`   | `EdgeInsets.all(DesignSpacing.lg)`   |
| `EdgeInsets.all(24)`   | `EdgeInsets.all(DesignSpacing.xl)`   |
| `EdgeInsets.all(32)`   | `EdgeInsets.all(DesignSpacing.xxl)`  |
| `SizedBox(height: 8)`  | `SizedBox(height: DesignSpacing.sm)` |
| `SizedBox(height: 12)` | `SizedBox(height: DesignSpacing.md)` |
| `SizedBox(height: 16)` | `SizedBox(height: DesignSpacing.lg)` |
| `SizedBox(height: 24)` | `SizedBox(height: DesignSpacing.xl)` |
| `SizedBox(width: 16)`  | `SizedBox(width: DesignSpacing.lg)`  |

### Border Radius

| Hardcoded Value             | Design System Equivalent                                                       |
| --------------------------- | ------------------------------------------------------------------------------ |
| `BorderRadius.circular(12)` | `BorderRadius.circular(DesignSpacing.cardBorderRadius)`                        |
| `BorderRadius.circular(8)`  | `DesignBorders.*` or `BorderRadius.circular(DesignSpacing.buttonBorderRadius)` |

### Shadows

| Hardcoded Value                  | Design System Equivalent     |
| -------------------------------- | ---------------------------- |
| `BoxShadow(blurRadius: 4, ...)`  | `DesignShadows.subtle`       |
| `BoxShadow(blurRadius: 8, ...)`  | `DesignShadows.medium`       |
| `BoxShadow(blurRadius: 12, ...)` | `DesignShadows.speakingGlow` |

## Enforcement

- The `NeonTheme` is automatically applied to all pages via `MaterialApp`
- Color constants are centralized in `DesignColors`
- Linting rules may be added to enforce this pattern
- Code reviews should verify theme consistency

## Questions?

Refer to:

- **Design Bible**: `DESIGN_BIBLE.md` - Core design principles and philosophy
- **Theme Implementation**: `lib/core/theme/neon_theme.dart` - MaterialApp theme setup
- **Design Constants**: `lib/core/design_system/design_constants.dart` - All constants defined here
  - `DesignColors` - Color palette
  - `DesignTypography` - Text styles
  - `DesignSpacing` - Spacing, padding, margins, sizes
  - `DesignAnimations` - Animation durations and curves
  - `DesignShadows` - Shadow effects
  - `DesignBorders` - Border styles
- **Refactoring Summary**: `REFACTORING_SUMMARY.md` - Recent widget refactoring work

## Complete Design System Reference

### All Available Constants

**DesignColors**

- Accent colors: `accent`, `accentLight`, `accentDark`
- Secondary: `secondary`, `secondaryLight`, `secondaryDark`
- Tertiary: `tertiary`, `tertiaryLight`, `tertiaryDark`
- Surfaces: `background`, `surfaceLight`, `surfaceDefault`, `surfaceAlt`, `surfaceDark`, `dialogBackground`, `cardBackground`
- Special: `gold`, `goldLight`, `goldDark`, `success`, `error`, `warning`
- Opacity: `accent2`, `accent5`, `accent10`, `accent12`, `accent15`, `accent20`, `accent24`, `accent26`, `accent30`, `accent40`, `accent50`, `accent60`, `accent70`, `accent90`
- Effects: `overlay`, `shadowColor`, `primaryGlow`, `secondaryGlow`

**DesignSpacing**

- Insets: `xs` (4), `sm` (8), `md` (12), `lg` (16), `xl` (24), `xxl` (32)
- Cards: `cardPadding` (16), `cardSpacing` (12), `cardBorderRadius` (12)
- Buttons: `buttonMinHeight` (44), `buttonMinWidth` (100), `buttonPadding` (16), `buttonBorderRadius` (12)
- Avatars: `avatarLarge` (48), `avatarMedium` (40), `avatarSmall` (32)
- Control: `controlBarHeight` (80), `controlSpacing` (16)

**DesignTypography**

- `heading` (18px, bold)
- `subheading` (14px, w600)
- `body` (14px, normal)
- `caption` (12px, normal)
- `label` (12px, w600)
- `button` (14px, w600)

**DesignAnimations**

- Durations: `joinStage1Duration`, `joinStage2MinDuration`, `joinStage2MaxDuration`, `joinStage3Duration`
- Presence: `presenceSlideInDuration`, `presenceFadeOutDuration`, `presenceSlideDownDuration`
- Interaction: `speakingPulseDuration`, `buttonFeedbackDuration`, `cardHoverDuration`, `notificationFadeInDuration`, `notificationFadeOutDuration`
- Curves: `easeOutCubic`, `easeInCubic`, `easeInOut`

**DesignShadows**

- `subtle` - For cards and buttons
- `medium` - For hovered surfaces
- `speakingGlow` - For speaking indicators
- `error` - For error states

**DesignBorders**

- `cardDefault` - Card style with thick left border
- `cardHovered` - Hover state
- `inputDefault` - Input field default
- `inputFocused` - Input field focused
