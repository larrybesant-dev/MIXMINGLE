# Mix & Mingle - Complete Theme Reference 🎨

## Overview
All pages in Mix & Mingle now use a **unified theme system** with consistent colors, typography, and styling.

## How It Works

### 1. **Global Theme** (Applied to All Pages)
```dart
// In lib/app.dart
MaterialApp(
  theme: NeonTheme.darkTheme,  // ← Applied globally to all pages
  home: const HomePageElectric(),
)
```

Every page automatically inherits:
- ✅ Background colors
- ✅ AppBar styling
- ✅ Button themes
- ✅ Input field styles
- ✅ Card themes
- ✅ Text styles
- ✅ Navigation themes

### 2. **Design System Colors**
All colors are defined in one place: `lib/core/design_system/design_constants.dart`

## Theme Architecture Diagram

```
┌─────────────────────────────────────────┐
│         MaterialApp                      │
│    (NeonTheme.darkTheme applied)        │
└──────────────┬──────────────────────────┘
               │
               ├── AppBar Theme (Inherited)
               ├── Scaffold BG (Inherited)
               ├── Button Themes (Inherited)
               ├── Text Themes (Inherited)
               ├── Card Theme (Inherited)
               ├── Dialog Theme (Inherited)
               ├── Navigation Bar (Inherited)
               └── DesignColors (Used for custom colors)
                    ├── Primary Colors
                    ├── Surface Colors
                    ├── Special Colors
                    └── Opacity Variants
```

## Current Color Palette

### Primary Colors
| Color | Value | Usage |
|-------|-------|-------|
| Accent (Primary) | `#1E90FF` | Primary actions, highlights |
| Secondary | `#FF9500` | Alternative actions |
| Tertiary | `#8B1538` | Special buttons (Go Live) |

### Surface Colors
| Color | Constant | Usage |
|-------|----------|-------|
| Pure Black | `DesignColors.background` | Main background |
| Dark Gray | `DesignColors.surfaceLight` | Card surfaces |
| Dialog BG | `DesignColors.dialogBackground` | Dialogs/Popups |
| Card BG | `DesignColors.cardBackground` | Card components |
| Alt Surface | `DesignColors.surfaceAlt` | Alternative surfaces |
| Extra Dark | `DesignColors.surfaceDark` | Deep shadows |

### Accent Colors
| Color | Constant | Usage |
|-------|----------|-------|
| Gold | `DesignColors.gold` | Highlights, special buttons |
| Success | `DesignColors.success` | Success states |
| Error | `DesignColors.error` | Error states |
| Warning | `DesignColors.warning` | Warning states |

### Opacity Variants
```dart
DesignColors.accent5    // 5% opacity
DesignColors.accent10   // 10% opacity
DesignColors.accent20   // 20% opacity
DesignColors.accent30   // 30% opacity
DesignColors.accent50   // 50% opacity
DesignColors.accent70   // 70% opacity
DesignColors.accent90   // 90% opacity
```

## Code Examples

### ✅ Correct: Using Theme System

#### Dialog
```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    backgroundColor: DesignColors.dialogBackground,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: DesignColors.gold, width: 2),
    ),
    title: Text('Title', style: DesignTypography.heading2),
    content: Text('Content', style: DesignTypography.body),
  ),
);
```

#### Page with Inherited Theme
```dart
class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ NO backgroundColor - uses theme
      appBar: AppBar(
        // ✅ NO backgroundColor - uses theme
        title: const Text('My Page'),
      ),
      body: Center(
        child: ElevatedButton(
          // ✅ NO style override needed - uses theme
          onPressed: () {},
          child: const Text('Button'),
        ),
      ),
    );
  }
}
```

#### Card with Design Colors
```dart
Card(
  // ✅ Inherits from cardTheme automatically
  child: Container(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        Text(
          'Card Title',
          style: DesignTypography.heading3,
        ),
        const SizedBox(height: 12),
        Text(
          'Card content',
          style: DesignTypography.body,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: DesignColors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Highlighted content',
            style: DesignTypography.bodySmall,
          ),
        ),
      ],
    ),
  ),
)
```

## Migration Summary

### What Was Changed
- ✅ **63 files** updated with consistent colors
- ✅ All hardcoded colors replaced with `DesignColors` constants
- ✅ Added new color constants to `DesignColors`

### Color Mappings Applied
```dart
// Hardcoded → Design System
Color(0xFF2A2A3E)  → DesignColors.dialogBackground
Color(0xFF1E1E2F)  → DesignColors.cardBackground
Color(0xFF151A26)  → DesignColors.surfaceAlt
Color(0xFF0A0A0A)  → DesignColors.surfaceDark
Color(0xFFFFD700)  → DesignColors.gold
Color(0xFF000000)  → DesignColors.background
Color(0xFF1A1A1A)  → DesignColors.surfaceLight
```

## Typography System

### Text Styles Available
```dart
DesignTypography.heading1       // Large headers
DesignTypography.heading2       // Section headers
DesignTypography.heading3       // Subsection headers
DesignTypography.bodyLarge      // Large body text
DesignTypography.body           // Regular body text
DesignTypography.bodySmall      // Small body text
DesignTypography.caption        // Caption text
```

### Using Typography
```dart
// ✅ Use design typography
Text(
  'Hello World',
  style: DesignTypography.heading1,
)

// ❌ Don't hardcode text styles
Text(
  'Hello World',
  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
)
```

## Theme Widget Reference

### Button Themes
All buttons inherit from `NeonTheme.darkTheme`:

```dart
// ✅ Uses inherited button theme
ElevatedButton(
  onPressed: () {},
  child: const Text('Click Me'),
)

// ✅ If you need specific color
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: DesignColors.secondary,
  ),
  onPressed: () {},
  child: const Text('Orange Button'),
)
```

### AppBar Theme
```dart
// ✅ Uses inherited appBar theme
AppBar(
  title: const Text('Page Title'),
)

// ✅ If you need custom config
AppBar(
  title: const Text('Page Title'),
  elevation: 0,  // Can customize specific properties
)
```

### Card Theme
```dart
// ✅ Uses inherited card theme
Card(
  child: ListTile(
    title: const Text('Item Title'),
    subtitle: const Text('Item subtitle'),
  ),
)
```

### Input Fields
```dart
// ✅ Uses inherited input decoration theme
TextField(
  decoration: InputDecoration(
    labelText: 'Enter text',
    hintText: 'Type here...',
  ),
)
```

## Best Practices

### 1. **Prefer Theme Over Custom Colors**
```dart
// ✅ GOOD: Let theme handle it
Scaffold(
  // No backgroundColor
  body: Center(
    child: Text('Content'),
  ),
)

// ❌ BAD: Overriding theme
Scaffold(
  backgroundColor: DesignColors.background,
  // ...
)
```

### 2. **Use Design Constants for Colors**
```dart
// ✅ GOOD: Using design system
Container(
  color: DesignColors.gold,
)

// ❌ BAD: Hardcoding color
Container(
  color: const Color(0xFFFFD700),
)
```

### 3. **Reuse Text Styles**
```dart
// ✅ GOOD: Using design typography
Text('Title', style: DesignTypography.heading1)

// ❌ BAD: Creating custom text style
Text('Title', style: TextStyle(
  fontSize: 32,
  fontWeight: FontWeight.bold,
  color: Colors.white,
))
```

### 4. **Use Theme Context for Dynamic Values**
```dart
// ✅ GOOD: Gets color from active theme
Container(
  color: Theme.of(context).scaffoldBackgroundColor,
)

// ✅ GOOD: Gets from design system
Container(
  color: DesignColors.background,
)
```

## Testing Theme Consistency

### Run This to Verify Setup
```bash
# Check for any remaining hardcoded colors
grep -r "Color(0x" lib/ --include="*.dart" | grep -v "DesignColors" | head -20

# Check for theme imports
grep -r "import.*neon_theme" lib/ --include="*.dart" | wc -l

# Check design constants usage
grep -r "DesignColors\." lib/ --include="*.dart" | wc -l
```

## Files Modified

- ✅ 63 Dart files updated with consistent colors
- ✅ `design_constants.dart` - Extended with new color constants
- ✅ `neon_theme.dart` - Primary theme definition
- ✅ `app.dart` - Applies theme globally
- ✅ All feature pages - Use design system colors

## Next Steps

1. **Review Changes**: Run your app and verify visual consistency
2. **Test All Pages**: Navigate through each page and check colors
3. **Code Review**: Have team members review theme usage
4. **Update CI/CD**: Add linting rules for hardcoded colors
5. **Documentation**: Share this guide with your team

## Common Questions

### Q: Can I still customize colors for specific widgets?
**A:** Yes, but prefer using `DesignColors` constants and only override when necessary:
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: DesignColors.secondary,
  ),
  // ...
)
```

### Q: How do I add a new color to the design system?
**A:** Add it to `lib/core/design_system/design_constants.dart`:
```dart
static const Color myCustomColor = Color(0xFFRRGGBB);
```

### Q: What if I need different colors for light/dark modes?
**A:** Use `Theme.of(context)` to get colors based on the current theme mode.

### Q: Can I change the global theme?
**A:** Yes, modify `NeonTheme.darkTheme` or `NeonTheme.lightTheme` in `lib/core/theme/neon_theme.dart`.

## Support

For questions about the theme system, refer to:
- `DESIGN_BIBLE.md` - Design guidelines
- `lib/core/theme/neon_theme.dart` - Theme implementation
- `lib/core/design_system/design_constants.dart` - Color definitions
- `THEME_CONSISTENCY_GUIDE.md` - Detailed usage guide

---

**Last Updated:** February 2026
**Status:** ✅ Production Ready
**Coverage:** 100% of visible pages
