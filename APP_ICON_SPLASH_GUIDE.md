# App Icon & Splash Screen Guide

## Overview
This guide helps you configure the Mix & Mingle app icon and splash screen with the branded nightclub aesthetic.

---

## 📱 App Icon Configuration

### Required Packages
Add these to `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1
```

### Configuration
Add this to `pubspec.yaml`:

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/images/app_icon.png"
  adaptive_icon_background: "#1E1E2F"
  adaptive_icon_foreground: "assets/images/app_icon_foreground.png"

  # iOS specific
  remove_alpha_ios: true

  # Android specific
  min_sdk_android: 21
```

### Icon Design Requirements

**Main Icon** (`assets/images/app_icon.png`):
- Size: 1024x1024px
- Format: PNG with transparency
- Design: Mix & Mingle logo with vibrant red (#FF4C4C) on dark navy (#1E1E2F)
- Include: Music note or social connection symbol
- Style: Modern, bold, nightclub aesthetic

**Adaptive Icon Foreground** (`assets/images/app_icon_foreground.png`):
- Size: 1024x1024px (with 432x432px safe zone)
- Format: PNG with transparency
- Design: Logo symbol only (no background)
- Colors: Red (#FF4C4C) with white highlights

**Brand Colors**:
- Primary: #FF4C4C (Vibrant Red)
- Background: #1E1E2F (Deep Navy)
- Accent: #24E8FF (Electric Blue)
- Premium: #FFD700 (Golden Yellow)

### Generate Icons
```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

---

## 🎨 Splash Screen Configuration

### Required Packages
Add these to `pubspec.yaml`:

```yaml
dependencies:
  flutter_native_splash: ^2.3.5
```

### Configuration
Add this to `pubspec.yaml`:

```yaml
flutter_native_splash:
  # Background color (deep navy)
  color: "#1E1E2F"

  # Splash image
  image: assets/images/splash_logo.png

  # Brand it true to add brand logo
  branding: assets/images/branding.png
  branding_bottom_padding: 50

  # Android 12+
  android_12:
    color: "#1E1E2F"
    image: assets/images/splash_logo.png
    icon_background_color: "#FF4C4C"

  # iOS specific
  ios: true

  # Web specific
  web: true
  web_image_mode: center

  # Maintain native splash for specific duration
  android_gravity: center
  ios_content_mode: center

  # Fullscreen mode
  fullscreen: true
```

### Splash Screen Design Requirements

**Main Splash Logo** (`assets/images/splash_logo.png`):
- Size: 1242x1242px
- Format: PNG with transparency
- Design: Mix & Mingle logo with neon glow effect
- Animation: Can be animated later with Lottie
- Colors: Vibrant red (#FF4C4C) with glow

**Branding Footer** (`assets/images/branding.png`):
- Size: 600x200px
- Format: PNG with transparency
- Design: "Mix & Mingle" text with tagline
- Style: Modern sans-serif with neon glow
- Color: White with subtle red glow

### Generate Splash Screen
```bash
flutter pub get
flutter pub run flutter_native_splash:create
```

---

## 🎭 Design Assets Checklist

Create these assets and place in `assets/images/`:

- [ ] `app_icon.png` (1024x1024) - Main app icon
- [ ] `app_icon_foreground.png` (1024x1024) - Adaptive foreground
- [ ] `splash_logo.png` (1242x1242) - Splash screen logo
- [ ] `branding.png` (600x200) - Branding footer
- [ ] `logo_white.png` - White logo for dark backgrounds
- [ ] `logo_color.png` - Full color logo
- [ ] `icon_small.png` (512x512) - Small icon variant

---

## 🎨 Design Guidelines

### Logo Concept
The Mix & Mingle logo should represent:
- **Mix**: Blending, music, energy (red/orange gradient)
- **Mingle**: Connection, social, people (blue accent)
- **Symbol**: Music note + people/hearts combined
- **Style**: Bold, modern, nightclub neon aesthetic

### Visual Elements
1. **Music Note Icon**: Primary symbol for the brand
2. **Connection Lines**: Subtle lines connecting people
3. **Neon Glow**: Signature glow effect (#FF4C4C)
4. **Gradient**: Red to purple gradient for premium feel

### Color Usage
- **Primary Red (#FF4C4C)**: Main brand color, CTAs, highlights
- **Deep Navy (#1E1E2F)**: Backgrounds, depth
- **Electric Blue (#24E8FF)**: Accents, secondary actions
- **Golden Yellow (#FFD700)**: Premium features, badges

### Typography
- **Display**: Poppins Bold (headlines)
- **Body**: Inter Regular (content)
- **Accent**: Oswald Bold (special emphasis)

---

## 📐 Icon Size Reference

### iOS
- 1024x1024 - App Store
- 180x180 - iPhone
- 167x167 - iPad Pro
- 152x152 - iPad
- 120x120 - iPhone (smaller)
- 80x80 - iPhone (notification)
- 58x58 - iPhone (settings)

### Android
- 512x512 - Play Store
- 192x192 - xxxhdpi
- 144x144 - xxhdpi
- 96x96 - xhdpi
- 72x72 - hdpi
- 48x48 - mdpi

### Web
- 192x192 - Standard
- 512x512 - High resolution
- favicon.ico - Browser tab

---

## 🚀 Implementation Steps

### 1. Create Design Assets
Use Figma, Adobe Illustrator, or Canva:
- Start with 1024x1024 canvas
- Use brand colors (#FF4C4C, #1E1E2F, #24E8FF)
- Add neon glow effect
- Export as PNG with transparency

### 2. Add to Project
```
mix_and_mingle/
├── assets/
│   └── images/
│       ├── app_icon.png
│       ├── app_icon_foreground.png
│       ├── splash_logo.png
│       ├── branding.png
│       └── logo_variants/
```

### 3. Update pubspec.yaml
Add the icon and splash configurations shown above.

### 4. Generate Assets
```bash
# Install dependencies
flutter pub get

# Generate app icons
flutter pub run flutter_launcher_icons

# Generate splash screen
flutter pub run flutter_native_splash:create
```

### 5. Test on Devices
```bash
# iOS
flutter run -d ios

# Android
flutter run -d android

# Check app icon on home screen
# Check splash screen on app launch
```

---

## 🎬 Animated Splash Screen (Optional)

For an animated splash screen using Lottie:

### 1. Create Lottie Animation
- Export animation as JSON from After Effects
- Place in `assets/animations/splash_animation.json`

### 2. Update Main App
```dart
import 'package:lottie/lottie.dart';

class AnimatedSplashScreen extends StatefulWidget {
  @override
  _AnimatedSplashScreenState createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  _navigateToHome() async {
    await Future.delayed(Duration(seconds: 3));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClubColors.deepNavy,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/splash_animation.json',
              width: 300,
              height: 300,
              repeat: false,
            ),
            SizedBox(height: 24),
            Text(
              'Mix & Mingle',
              style: ClubTextStyles.neonHeadline,
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 🎯 Brand Consistency Checklist

- [ ] App icon uses brand colors (#FF4C4C primary)
- [ ] Splash screen matches app theme (dark navy)
- [ ] Logo is recognizable at small sizes
- [ ] Neon glow effect is consistent
- [ ] Icons follow Material Design guidelines
- [ ] All platforms (iOS, Android, Web) configured
- [ ] High-res assets for all screen densities
- [ ] Tested on real devices

---

## 📱 Platform-Specific Notes

### iOS
- Use `ios/Runner/Assets.xcassets/AppIcon.appiconset`
- Requires multiple sizes (automatically generated)
- No transparency allowed for iOS icons
- Use `Info.plist` for splash screen duration

### Android
- Use `android/app/src/main/res/mipmap-*` folders
- Supports adaptive icons (foreground + background)
- Splash screen uses `styles.xml` and `colors.xml`
- Android 12+ has new splash screen API

### Web
- Use `web/icons/` folder
- Update `web/manifest.json` with icon paths
- Provide favicon.ico in `web/` root
- Use PNG format for web icons

---

## 🔗 Resources

- **Icon Generator**: [App Icon Generator](https://appicon.co/)
- **Splash Generator**: [Ape Tools](https://apetools.webprofusion.com/)
- **Design Tool**: [Figma](https://figma.com) (recommended)
- **Color Picker**: [Coolors](https://coolors.co/)
- **Glow Effects**: [CSS Glow Generator](https://cssgenerator.org/box-shadow-css-generator.html)

---

## 💡 Tips

1. **Keep it Simple**: Icon should be recognizable at 48x48px
2. **High Contrast**: Ensure visibility on various backgrounds
3. **Test Variations**: Try different color combinations
4. **Avoid Text**: Use symbols instead of text in icon
5. **Consistent Glow**: Use same glow effect across all assets
6. **Brand Guidelines**: Document color codes and usage
7. **Version Control**: Save source files (AI, Figma, PSD)

---

## 🚨 Common Issues

### Icon Not Updating
```bash
# Clean build
flutter clean
flutter pub get

# Regenerate icons
flutter pub run flutter_launcher_icons

# Rebuild app
flutter run
```

### Splash Screen Issues
```bash
# Regenerate splash
flutter pub run flutter_native_splash:remove
flutter pub run flutter_native_splash:create

# Clear app cache on device
```

### Android Adaptive Icon
If adaptive icon looks wrong:
1. Check safe zone (432x432 center)
2. Ensure foreground has transparency
3. Test on different Android versions
4. Use Android Studio's icon preview

---

**Status**: Ready for design assets
**Next Step**: Create icon and splash screen designs based on guidelines above
