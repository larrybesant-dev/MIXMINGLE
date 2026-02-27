# App Icon Requirements

This directory should contain the source app icon for generating platform-specific icons.

## Source Icon

The source icon should be:

- **File**: `app_icon_source.png`
- **Resolution**: 1024 x 1024 pixels minimum
- **Format**: PNG with transparency (if needed)
- **Color Space**: sRGB

## iOS Icons (AppIcon.appiconset)

iOS requires multiple icon sizes. Store in `/ios/Runner/Assets.xcassets/AppIcon.appiconset/`:

| Size   | Scale | Filename         | Usage                |
| ------ | ----- | ---------------- | -------------------- |
| 20pt   | 1x    | Icon-20.png      | iPad Notifications   |
| 20pt   | 2x    | Icon-20@2x.png   | iPhone Notifications |
| 20pt   | 3x    | Icon-20@3x.png   | iPhone Notifications |
| 29pt   | 1x    | Icon-29.png      | iPad Settings        |
| 29pt   | 2x    | Icon-29@2x.png   | iPhone Settings      |
| 29pt   | 3x    | Icon-29@3x.png   | iPhone Settings      |
| 40pt   | 1x    | Icon-40.png      | iPad Spotlight       |
| 40pt   | 2x    | Icon-40@2x.png   | iPhone Spotlight     |
| 40pt   | 3x    | Icon-40@3x.png   | iPhone Spotlight     |
| 60pt   | 2x    | Icon-60@2x.png   | iPhone App           |
| 60pt   | 3x    | Icon-60@3x.png   | iPhone App           |
| 76pt   | 1x    | Icon-76.png      | iPad App             |
| 76pt   | 2x    | Icon-76@2x.png   | iPad App             |
| 83.5pt | 2x    | Icon-83.5@2x.png | iPad Pro App         |
| 1024pt | 1x    | Icon-1024.png    | App Store            |

## Android Icons (Adaptive)

Android requires adaptive icons with foreground and background layers.

### Mipmap Directories

Store in `/android/app/src/main/res/`:

| Directory      | Density | Size    |
| -------------- | ------- | ------- |
| mipmap-mdpi    | 1x      | 48x48   |
| mipmap-hdpi    | 1.5x    | 72x72   |
| mipmap-xhdpi   | 2x      | 96x96   |
| mipmap-xxhdpi  | 3x      | 144x144 |
| mipmap-xxxhdpi | 4x      | 192x192 |

### Adaptive Icon Structure

Each mipmap directory should contain:

- `ic_launcher.png` - Legacy launcher icon
- `ic_launcher_round.png` - Round launcher icon
- `ic_launcher_foreground.png` - Adaptive foreground layer
- `ic_launcher_background.png` - Adaptive background layer (or use color)

### Adaptive Icon XML

Create `/android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
```

And `/android/app/src/main/res/values/colors.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#0D0D0D</color>
</resources>
```

## Web Icons

Store in `/web/icons/`:

| File                  | Size    | Usage               |
| --------------------- | ------- | ------------------- |
| Icon-192.png          | 192x192 | Android Chrome      |
| Icon-512.png          | 512x512 | Android Chrome, PWA |
| Icon-maskable-192.png | 192x192 | PWA Maskable        |
| Icon-maskable-512.png | 512x512 | PWA Maskable        |
| favicon.png           | 16x16   | Browser tab         |
| apple-touch-icon.png  | 180x180 | iOS Safari          |

## Generation Tools

### Recommended

- **Flutter Launcher Icons**: `flutter pub run flutter_launcher_icons`
- **App Icon Generator**: https://appicon.co
- **Android Asset Studio**: https://romannurik.github.io/AndroidAssetStudio/

### Flutter Launcher Icons Config

Add to `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icons/app_icon_source.png"
  min_sdk_android: 24
  adaptive_icon_background: "#0D0D0D"
  adaptive_icon_foreground: "assets/icons/app_icon_foreground.png"
```

Run: `dart run flutter_launcher_icons`

## Design Guidelines

### Do's

- ✅ Use simple, recognizable design
- ✅ Test at small sizes (16px, 29pt)
- ✅ Use brand colors consistently
- ✅ Ensure contrast for visibility
- ✅ Leave safe zone for adaptive icons (66% of frame)

### Don'ts

- ❌ Don't use photographs
- ❌ Don't include text
- ❌ Don't use thin lines (won't be visible at small sizes)
- ❌ Don't rely on transparency for Android adaptive icons
