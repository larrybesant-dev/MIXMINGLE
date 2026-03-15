# 🚀 Launch Prep Report

> Generated: 2026-02-25 | **Status: ✅ Complete — All 6 Phases Delivered**

---

## Summary

The Launch Prep Sweep has been completed. The app is icon-configured, splash-generated, web-branded, and verified to build successfully on both Web and Android targets.

| Phase | Deliverable                                                                  | Status |
| ----- | ---------------------------------------------------------------------------- | ------ |
| 1     | App Icon — Android adaptive (`#080C14`), iOS (alpha removed), Web icons      | ✅     |
| 2     | Splash Screen — `#080C14`, `app_logo.png`, Android 12 SplashScreen API       | ✅     |
| 3     | Web Metadata — `theme-color`, `og:` block, Twitter cards, manifest corrected | ✅     |
| 4     | Builds — Web ✅ 44.1 MB / APK ✅ 277.2 MB / Analyze ✅ 0 errors              | ✅     |
| 5     | `STORE_METADATA.md` created                                                  | ✅     |
| 6     | `LAUNCH_PREP_REPORT.md` + `FULLSTACK_DEBUG_REPORT.md` updated                | ✅     |

### ⚠️ 3 Critical Manual Steps Before Store Submission

| #   | Action                                                                                                                                                              |
| --- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Replace `assets/images/app_logo.png` with final 1024×1024 production PNG, then re-run `dart run flutter_launcher_icons` and `dart run flutter_native_splash:create` |
| 2   | Build IPA on macOS: `flutter build ipa --release`                                                                                                                   |
| 3   | Swap `google-services.json` / `GoogleService-Info.plist` to **production** Firebase project before signing and submitting                                           |

---

## Phase 1 — App Icon ✅

**Generator:** `flutter_launcher_icons ^0.14.4` (auto-upgraded from 0.14.3)
**Config file created:** `flutter_launcher_icons.yaml` (standalone — supersedes inline pubspec config)
**Master asset:** `assets/images/app_logo.png` ← **ACTION REQUIRED: Replace with 1024×1024 production PNG before final store upload**

**Generated outputs:**

- Android: mipmap-mdpi / hdpi / xhdpi / xxhdpi / xxxhdpi icons
- Android adaptive icon: foreground layer = `app_logo.png`, background = `#080C14`
- iOS: all required icon sizes in `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- Web: `web/icons/Icon-192.png`, `Icon-512.png`, `Icon-maskable-192.png`, `Icon-maskable-512.png`, `favicon.png`

**Manual step:** Replace `assets/images/app_logo.png` with the final production 1024×1024 PNG, then re-run:

```powershell
dart run flutter_launcher_icons
```

---

## Phase 2 — Splash Screen ✅

**Generator:** `flutter_native_splash ^2.4.3` (newly added to dev_dependencies)
**Config file updated:** `flutter_native_splash.yaml`

**Changes from previous config:**

- Background color updated: `#0D0D0D` → `#080C14` (matches `DesignColors.background`)
- Image activated: `assets/images/app_logo.png` (was commented out)
- Android 12 splash image linked (new)
- Dark mode variants configured

**Generated outputs:**

- Android: `drawable/launch_background.xml` (+ night variant)
- Android v21: `drawable-v21/launch_background.xml` (+ night)
- Android 12 (API 31): `values-v31/styles.xml` + `values-night-v31/styles.xml` (created fresh)
- iOS: splash images in `ios/Runner/Assets.xcassets/LaunchImage.imageset/`
- iOS Info.plist: updated status bar hidden setting
- Web: splash CSS + index.html injection

---

## Phase 3 — Branding & Web Metadata ✅

### web/index.html

**Added:**

- `<meta name="theme-color" content="#080C14">`
- Improved `<meta name="description">` with full brand copy
- `<meta property="og:title">` — "Mix & Mingle"
- `<meta property="og:description">` — full tagline
- `<meta property="og:type">` — website
- `<meta property="og:image">` — `icons/Icon-512.png`
- `<meta property="og:url">` — `https://mix-and-mingle-v2.web.app`
- Twitter card meta tags (summary_large_image)

**ACTION REQUIRED:** Replace `og:url` with the production custom domain once registered.
**ACTION REQUIRED:** Replace `og:image` with a hosted 1200×630 social preview image URL.

### web/manifest.json

**Updated:**

- `short_name`: "Mix & Mingle" → "MixMingle" (avoids truncation on home screen)
- `background_color`: `#0A0A18` → `#080C14`
- `theme_color`: `#1a1a2e` → `#080C14`
- `description`: improved brand copy

### Android (confirmed — no changes needed)

- `android/app/src/main/res/values/strings.xml`: `app_name` = "Mix & Mingle" ✅
- `android/app/src/main/AndroidManifest.xml`: `android:label="@string/app_name"` ✅

### iOS (confirmed — no changes needed)

- `ios/Runner/Info.plist`: `CFBundleDisplayName` = "Mix & Mingle" ✅
- `ios/Runner/Info.plist`: `CFBundleName` = "MixMingle" ✅

### lib/main.dart (confirmed — no changes needed)

- `MaterialApp` title = "Mix & Mingle - Vibes Around the World" ✅

---

## Phase 4 — Build Validation ✅

| Step                               | Result                                                     |
| ---------------------------------- | ---------------------------------------------------------- |
| `flutter clean`                    | ✅ Success                                                 |
| `flutter pub get`                  | ✅ Success (8 packages have newer versions — non-blocking) |
| `flutter analyze --no-fatal-infos` | ✅ 0 hard errors, 24 infos only                            |
| `flutter build web --release`      | ✅ **Success**                                             |
| `flutter build apk --release`      | ✅ **Success**                                             |

**Web build output:**

- Path: `build/web/`
- Total size: ~44.1 MB
- Main JS bundle: 4.52 MB (`main.dart.js`)
- Icon tree shake: CupertinoIcons 99.4% reduced, MaterialIcons 97.4% reduced

**APK build output:**

- Path: `build/app/outputs/flutter-apk/app-release.apk`
- Size: **277.2 MB**
- Note: Kotlin binary metadata warnings (2.2.0 vs 2.0.0 expected) — these are non-fatal warnings from Firebase/Google plugin pre-built jars. The APK compiled and linked successfully. This will resolve when plugin publishers update their Kotlin versions.

---

## Phase 5 — Store Metadata ✅

**File created:** `STORE_METADATA.md`
Contains: App name, short/full descriptions, keywords, age rating recommendation, categories, privacy/support URL placeholders, screenshot checklist (8 screens), feature graphic concept, content rating notes, version info, pre-submission checklist.

---

## Manual Steps Remaining Before Store Submission

| #   | Action                                                                                    | Priority               |
| --- | ----------------------------------------------------------------------------------------- | ---------------------- |
| 1   | **Replace `assets/images/app_logo.png`** with final 1024×1024 production icon PNG         | 🔴 Critical            |
| 2   | Re-run `dart run flutter_launcher_icons` after icon replacement                           | 🔴 Critical            |
| 3   | Re-run `dart run flutter_native_splash:create` after icon replacement                     | 🔴 Critical            |
| 4   | **Build IPA** on a Mac: `flutter build ipa --release`                                     | 🔴 Critical (iOS only) |
| 5   | Configure release keystore for signed APK/AAB (currently using debug signing)             | 🔴 Critical            |
| 6   | Register production domain and update `og:url` in `web/index.html`                        | 🟡 High                |
| 7   | Create 1200×630 social preview image and update `og:image`                                | 🟡 High                |
| 8   | Set Privacy Policy, Support, and Terms URLs live before store submission                  | 🔴 Critical            |
| 9   | Create App Store Connect + Google Play Console app records                                | 🟡 High                |
| 10  | Complete store screenshot captures (8 screens per `STORE_METADATA.md`)                    | 🟡 High                |
| 11  | Create 1024×500 feature graphic for Google Play                                           | 🟡 High                |
| 12  | Swap `google-services.json` and `GoogleService-Info.plist` to production Firebase project | 🔴 Critical            |
| 13  | Enable Firebase App Check in production                                                   | 🟠 Medium              |
| 14  | Tighten Firestore security rules for production                                           | 🟠 Medium              |

---

## Files Modified in Launch Prep Sweep

| File                                                       | Action                                                                         |
| ---------------------------------------------------------- | ------------------------------------------------------------------------------ |
| `flutter_launcher_icons.yaml`                              | Created — standalone icon config with web icons + iOS alpha removal            |
| `flutter_native_splash.yaml`                               | Updated — activated image, corrected background to #080C14, Android 12 support |
| `pubspec.yaml`                                             | Updated — added `flutter_native_splash: ^2.4.3` to dev_dependencies            |
| `web/index.html`                                           | Updated — theme-color, improved description, og: meta, Twitter card meta       |
| `web/manifest.json`                                        | Updated — short_name, background_color, theme_color, description               |
| `android/app/src/main/res/mipmap-*/`                       | Generated — all Android icon sizes                                             |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/`           | Generated — all iOS icon sizes                                                 |
| `web/icons/`                                               | Generated — 192, 512, maskable variants                                        |
| `android/app/src/main/res/drawable*/launch_background.xml` | Generated — splash backgrounds                                                 |
| `android/app/src/main/res/values-v31/styles.xml`           | Generated — Android 12 splash style                                            |
| `ios/Runner/Assets.xcassets/LaunchImage.imageset/`         | Generated — iOS splash images                                                  |
| `STORE_METADATA.md`                                        | Created                                                                        |
| `LAUNCH_PREP_REPORT.md`                                    | Created (this file)                                                            |
