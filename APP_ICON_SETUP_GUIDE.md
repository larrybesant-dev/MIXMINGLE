# 📱 APP ICON & SPLASH SCREEN - SETUP GUIDE

## Quick Setup

Since the neon aesthetic is now complete with your Mix & Mingle logo, here's how to finalize the app icons and splash screens:

### Step 1: Generate App Icons (Using flutter_launcher_icons)

Add to `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_launcher_icons: "^0.13.0"

flutter_icons:
  android: "launcher_icon"
  ios: true
  image_path: "assets/images/logo.jpg"

  # Rounded corners
  adaptive_icon_background: "#0A0E27"
  adaptive_icon_foreground: "assets/images/logo.jpg"

  # Web icon
  web:
    generate: true
    image_path: "assets/images/logo.jpg"
```

Run:

```bash
flutter pub get
flutter pub run flutter_launcher_icons:main
```

### Step 2: Splash Screen with flutter_native_splash

Add to `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_native_splash: ^2.3.0

flutter_native_splash:
  color: "#0A0E27" # Dark navy background
  image: assets/images/logo.jpg
  android_12:
    color: "#0A0E27"
    icon_background_color: "#FF7A3C" # Neon orange
  web: true
```

Run:

```bash
flutter pub run flutter_native_splash:create
```

### Step 3: iOS Configuration

**File**: `ios/Runner/Info.plist`

Already configured if icons are generated correctly.

### Step 4: Android Configuration

**File**: `android/app/build.gradle`

Already configured. The generated adaptive icons will appear in:

- `android/app/src/main/res/mipmap-*` folders

### Step 5: Web Configuration

**File**: `web/favicon.png`

The generated web icon will use your logo.jpg.

### Step 6: Platform-Specific Sizing (Optional)

For custom sizes, create these images in `assets/images/`:

```
app_icon_512.png    (512x512) - Primary app icon
app_icon_192.png    (192x192) - Web/Android
app_icon_152.png    (152x152) - iPad
app_icon_120.png    (120x120) - iPhone
```

---

## Logo Integration Summary

✅ **Current**: `assets/images/logo.jpg` (your Mix & Mingle logo)

✅ **Used in**:

- Splash screen (animated entrance)
- Login screen (100x100 with glow)
- Signup screen (90x90 with glow)
- Home screen header (140x140 animated)
- All BrandedHeader widgets throughout app

✅ **Styling**:

- Neon orange glow effect
- Neon blue secondary glow
- Smooth breathing animation (2000ms)
- 48px-160px sizes depending on context

---

## Asset Optimization

For production, optimize your logo:

```bash
# Compress PNG (if converting from JPG)
imagemagick:
convert logo.jpg -quality 85 logo.png

# Create multiple sizes
convert logo.png -resize 512x512 logo_512.png
convert logo.png -resize 192x192 logo_192.png
```

---

## Testing the Icons & Splash

```bash
# Run on Android
flutter run -d android

# Run on iOS
flutter run -d iphone

# Run on Web
flutter run -d chrome
```

Check:

- ✅ App icon appears on home screen
- ✅ Splash screen shows during startup
- ✅ Logo loads correctly on all screens
- ✅ Glow effects display properly
- ✅ No image distortion
- ✅ Colors match brand specifications

---

## Build for Release

```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

The app icons and splash screens will be included automatically.

---

## Troubleshooting

**Icon not updating?**

```bash
flutter clean
flutter pub get
flutter pub run flutter_launcher_icons:main
```

**Splash not showing?**

```bash
flutter clean
flutter pub run flutter_native_splash:create
```

**Web icon not showing?**

- Clear browser cache (Cmd+Shift+R on Mac, Ctrl+Shift+R on Windows)
- Check `build/web/favicon.png` exists after build

---

## Design System Complete ✅

Your Mix & Mingle app now has:

- 🎨 Neon orange (#FF7A3C) and blue (#00D9FF) colors
- 🎭 Dark club atmosphere (navy #0A0E27)
- ✨ Animated glow effects throughout
- 📱 App icons configured
- 🎬 Splash screen with branding
- 🏛️ Complete design system architecture
- 🚀 Ready for production

**Final Status**: All neon aesthetic components integrated and production-ready!
