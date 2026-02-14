# Quick Start: Using the Theme System 🎨

> TL;DR - Always use `DesignColors.*` for colors, never hardcode `Color(0x...)`

## For Developers

### When You Need a Color

**DO THIS** ✅
```dart
import 'package:mix_and_mingle/core/design_system/design_constants.dart';

Container(
  color: DesignColors.gold,
  child: Text(
    'Content',
    style: TextStyle(color: DesignColors.accent),
  ),
)
```

**NOT THIS** ❌
```dart
Container(
  color: const Color(0xFFFFD700),  // Bad!
  child: Text(
    'Content',
    style: TextStyle(color: const Color(0xFF1E90FF)), // Bad!
  ),
)
```

### Available Colors

```dart
// Primary accent colors
DesignColors.accent        // Bright blue
DesignColors.secondary     // Orange
DesignColors.tertiary      // Dark purple

// Backgrounds
DesignColors.background    // Pure black
DesignColors.surfaceLight  // Dark gray
DesignColors.dialogBackground  // Dialog background
DesignColors.cardBackground     // Card background
DesignColors.surfaceAlt         // Alternative surface
DesignColors.surfaceDark        // Extra dark

// Special colors
DesignColors.gold      // Gold highlights
DesignColors.success   // Green
DesignColors.error     // Red
DesignColors.warning   // Yellow

// Opacity variants
DesignColors.accent5   // 5% opacity
DesignColors.accent10  // 10% opacity
DesignColors.accent20  // 20% opacity
DesignColors.accent30  // 30% opacity
DesignColors.accent50  // 50% opacity
DesignColors.accent70  // 70% opacity
DesignColors.accent90  // 90% opacity
```

### Common Patterns

#### Dialog
```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    backgroundColor: DesignColors.dialogBackground,
    title: Text('Title', style: DesignTypography.heading2),
    content: Text('Content', style: DesignTypography.body),
  ),
);
```

#### Button
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: DesignColors.gold,  // Use design color
  ),
  onPressed: () {},
  child: const Text('Button'),
)
```

#### Card
```dart
Card(
  child: Container(
    padding: const EdgeInsets.all(16),
    color: DesignColors.cardBackground,
    child: Text('Content', style: DesignTypography.body),
  ),
)
```

#### Page
```dart
class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ Let theme handle background
      appBar: AppBar(
        // ✅ Let theme handle colors
        title: const Text('My Page'),
      ),
      body: Center(
        child: Text(
          'Hello',
          style: DesignTypography.heading1,  // Use design typography
        ),
      ),
    );
  }
}
```

### Text Styles

```dart
DesignTypography.heading1      // Large title
DesignTypography.heading2      // Section header
DesignTypography.heading3      // Subsection
DesignTypography.bodyLarge     // Large body text
DesignTypography.body          // Regular body text
DesignTypography.bodySmall     // Small body text
DesignTypography.caption       // Caption text
```

### The Golden Rule

> **Never ever hardcode a color with `Color(0x...)`**

If you need a new color:
1. Check if it exists in `DesignColors`
2. If not, add it to `DesignColors` in `lib/core/design_system/design_constants.dart`
3. Use the `DesignColors` constant

## For Designers

The theme system supports:
- ✅ Easy global color changes (update `DesignColors` once)
- ✅ Consistent styling across all pages
- ✅ Opacity variants for fine-tuned colors
- ✅ Typography system with predefined styles

## Common Changes

### Change Primary Color
Edit `lib/core/design_system/design_constants.dart`:
```dart
static const Color accent = Color(0xFF1E90FF); // Change this
```

### Change Dialog Background
Edit `lib/core/design_system/design_constants.dart`:
```dart
static const Color dialogBackground = Color(0xFF2A2A3E); // Change this
```

### Add New Color
Edit `lib/core/design_system/design_constants.dart`:
```dart
class DesignColors {
  // ... existing colors ...

  // Add your new color
  static const Color myNewColor = Color(0xFFYYYYYY);
}
```

Then use it:
```dart
Container(color: DesignColors.myNewColor)
```

## Tips & Tricks

### Make Color Slightly Transparent
```dart
DesignColors.accent.withValues(alpha: 0.3)  // 30% opacity
DesignColors.accent.withOpacity(0.5)        // 50% opacity
```

### Use with Gradients
```dart
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [
        DesignColors.accent,
        DesignColors.secondary,
      ],
    ),
  ),
)
```

### Check Current Theme
```dart
Theme.of(context).scaffoldBackgroundColor
Theme.of(context).colorScheme.primary
Theme.of(context).textTheme.headlineSmall
```

## Validation

To find any remaining hardcoded colors:
```bash
grep -r "Color(0x" lib/ --include="*.dart" | grep -v "DesignColors"
```

Should return nothing! ✅

## Help?

- **How do I use colors?** → Read `THEME_CONSISTENCY_GUIDE.md`
- **What colors exist?** → Check `lib/core/design_system/design_constants.dart`
- **How does theming work?** → See `lib/core/theme/neon_theme.dart`
- **Need a new color?** → Add it to `DesignColors`

---

**Quick Reference Card**

```dart
// Import
import 'package:mix_and_mingle/core/design_system/design_constants.dart';

// Use colors
Text('Hello', style: TextStyle(color: DesignColors.accent))
Container(color: DesignColors.gold)

// Use typography
Text('Title', style: DesignTypography.heading1)

// NEVER do this ❌
Color(0xFF123456)
TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
```

**Remember**: 📌 Design System Colors over Hardcoded Colors = Consistency = Professional ✨
