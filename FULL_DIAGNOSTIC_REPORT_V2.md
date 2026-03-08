# MixVy Full Diagnostic Report — V2
**Scan scope:** All 12 subsystems
**Analyzer baseline:** `dart analyze lib/` → 49 issues (2 errors, ~5 warnings, ~42 infos)
**`flutter analyze` status:** FAILS entirely — `riverpod_lint-3.1.3` missing from pub cache

---

## CRITICAL ERRORS — Compile-blocking

### C-1 · `social_feed_service.dart` — 5 compile errors (wrong call signatures)
**File:** `lib/services/social/social_feed_service.dart`
**Root cause:** Calls `ActivityFeedService.instance.onLikePost` and `onComment` using named parameters, but both methods are positional-only.

Actual signatures in `lib/services/social/activity_feed_service.dart`:
```dart
// line 201
Future<void> onLikePost(String postOwnerId, String postId)
// line 207
Future<void> onComment(String postOwnerId, String postId, String snippet)
```

**Fix — two call sites in `social_feed_service.dart`:**
```dart
// BEFORE (broken named params):
await ActivityFeedService.instance.onLikePost(
  postId: postId, postOwnerId: postOwnerId,
);
// AFTER:
await ActivityFeedService.instance.onLikePost(postOwnerId, postId);
```
```dart
// BEFORE:
await ActivityFeedService.instance.onComment(
  postId: postId, postOwnerId: postOwnerId, snippet: snippet,
);
// AFTER:
await ActivityFeedService.instance.onComment(postOwnerId, postId, snippet);
```
**Verify:** `dart analyze lib/services/social/`

---

### C-2 · `deep_link_service.dart` — 4 compile errors (wrong import path)
**File:** `lib/services/deep_link/deep_link_service.dart`
**Root cause:** Import resolves to `lib/services/routing/app_routes.dart` — that path does not exist.

**Fix (line ~4):**
```dart
// BEFORE:
import '../routing/app_routes.dart';

// AFTER:
import '../../core/routing/app_routes.dart';
```
**Verify:** `dart analyze lib/services/deep_link/`

---

### C-3 · `android/settings.gradle` + `android/settings.gradle.kts` — Dual competing Android settings
**Root cause:** Having both a Groovy `.gradle` and a Kotlin `.kts` settings file in the same Android project is unsupported. The build system treats them as competing configurations, leading to unpredictable AGP/Kotlin version resolution and `:gradle:compileKotlin` failures.

Version conflict table:

| Setting | `settings.gradle` (Groovy) | `settings.gradle.kts` (Kotlin) |
|---|---|---|
| AGP | 8.7.1 | 8.11.1 |
| Kotlin | 2.2.0 | 2.2.20 |

`gradle.properties` also contains `android.newDsl=false`, which conflicts with the `.kts` DSL file.

**Fix:**
1. Delete `android/settings.gradle` (keep only the `.kts` version at AGP 8.11.1 / Kotlin 2.2.20)
2. In `android/gradle.properties`, delete the line: `android.newDsl=false`

**Verify:** `flutter build apk --debug` completes without Kotlin compile errors.

---

### C-4 · `riverpod_lint-3.1.3` missing from pub cache — `flutter analyze` broken
**Root cause:** The `riverpod_lint-3.1.3` package directory is missing from the pub cache. Every `flutter analyze` run aborts before scanning any code with "Failed to start plugins."

**Fix:**
```powershell
flutter pub cache repair
flutter pub get
```
If `repair` doesn't restore it:
```powershell
dart pub cache clean
flutter pub get
```
**Verify:** `flutter analyze lib/` completes (shows issues instead of crashing).

---

## HIGH-PRIORITY ISSUES

### H-1 · `firebase_options.dart` — iOS/macOS/Windows/Linux all use the Web `appId`
**File:** `lib/core/config/firebase_options.dart`
**Root cause:** `flutterfire configure` was never run for native platforms. All non-web platform entries contain the web appId `1:980846719834:web:a8981485ee574b25077963` (the file even includes a comment acknowledging this).

**Impact:** Firebase Auth, Crashlytics, and FCM malfunction silently on iOS and Android.

**Fix:**
1. In Firebase Console, create iOS and Android platform apps and download their config files
2. Place `GoogleService-Info.plist` at `ios/Runner/GoogleService-Info.plist`
3. Place `google-services.json` at `android/app/google-services.json`
4. Re-run `flutterfire configure --project=<your-firebase-project-id>` to regenerate `firebase_options.dart` with correct per-platform `appId`, `apiKey`, etc.

---

### H-2 · Triplicated provider declarations (`authStateProvider`, `currentUserProvider`, `currentUserProfileProvider`)
**Root cause:** Three separate files each declare the same providers independently:

| File | Status |
|---|---|
| `lib/shared/providers/auth_providers.dart` | Canonical — keep |
| `lib/shared/providers/providers.dart` | Duplicate — ~300 line mega-file, remove the duplicates |
| `lib/providers/user_providers.dart` | Legacy — uses older `UserModel` type, delete |

`lib/shared/providers/all_providers.dart` uses `hide` directives to paper over the collision — this breaks IDE navigation and confuses the linter.

**Fix strategy:**
1. Remove duplicate declarations from `lib/shared/providers/providers.dart` (re-export from `auth_providers.dart` instead)
2. Migrate any remaining imports of `lib/providers/user_providers.dart` to `lib/shared/providers/auth_providers.dart`
3. Delete `lib/providers/user_providers.dart`
4. Remove the `hide` clauses from `all_providers.dart`

---

### H-3 · `web/firebase-messaging-sw.js` — Firebase v9.22.0 compat vs app's v10+ SDK
**File:** `web/firebase-messaging-sw.js`
**Root cause:** Service worker loads Firebase compat CDN at v9.22.0 while the Flutter app uses `firebase_core: ^4.5.0` (which wraps Firebase JS SDK v10+). The v9 compat API is deprecated and causes push notification failures.

**Fix:**
```js
// BEFORE:
importScripts('https://www.gstatic.com/firebasejs/9.22.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.22.0/firebase-messaging-compat.js');

// AFTER (use latest v10.x):
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js');
```

---

### H-4 · Nested `ProviderScope` in `live_room_screen.dart` (line ~1567)
**File:** `lib/features/room/live/live_room_screen.dart`
**Root cause:** A `ProviderScope` widget is placed inside a `builder:` callback deep within `LiveRoomScreen`. Nested scopes shadow the root scope — providers in the nested scope do not share state with the root, breaking ref invalidation and causing subtle bugs.

**Fix:** Remove the wrapping `ProviderScope`. The root `ProviderScope` in `lib/main.dart:144` covers the entire app.
```dart
// BEFORE:
builder: (context, child) {
  return ProviderScope(
    child: SomeWidget(...),
  );
},

// AFTER:
builder: (context, child) {
  return SomeWidget(...),
},
```

---

### H-5 · 6 audio files referenced in code but missing from `assets/audio/`
**Root cause:** `assets/audio/` contains only a `README.md`. All audio asset references will throw `PlatformException` at runtime.

Referenced files:
| File | Referenced in |
|---|---|
| `audio/join_room.mp3` | `lib/core/services/sound_effects_service.dart` |
| `audio/new_speaker.mp3` | `lib/core/services/sound_effects_service.dart` |
| `audio/energy_spike.mp3` | `lib/core/services/sound_effects_service.dart` |
| `audio/reaction.mp3` | `lib/core/services/sound_effects_service.dart` |
| `audio/intro_sting.mp3` | `lib/services/audio/landing_music_service.dart` |
| `audio/ambient_loop.mp3` | `lib/services/audio/landing_music_service.dart` |

**Fix:** Add the 6 MP3 files to `assets/audio/`, or wrap all `AssetSource(...)` calls in try/catch until assets are ready.

---

### H-6 · iOS — No `Podfile` found
**Root cause:** `ios/Podfile` is absent (deleted or never committed). All iOS builds and `pod install` will fail.

**Fix:**
```powershell
cd ios
flutter precache --ios
# Re-generate Podfile:
pod init
pod install
```
Commit both `ios/Podfile` and `ios/Podfile.lock`.

---

## MEDIUM-PRIORITY ISSUES

### M-1 · `auth_gate_root.dart` — auth logic bug (both branches return same widget)
**File:** `lib/app/auth_gate_root.dart`
**Root cause:** Both the `user == null` and `user != null` branches return `const AuthGate()`. Authenticated users are never routed to the home screen.

**Fix:**
```dart
// BEFORE (both branches identical):
return user == null ? const AuthGate() : const AuthGate();  // bug

// AFTER:
return user == null ? const AuthGate() : const HomePageElectric();
```
*(Confirm this file is in the active widget tree before patching — it may be unreachable dead code; see M-2.)*

---

### M-2 · 5 orphaned dead-code files in `lib/features/` and `lib/app/`
| File | Problem |
|---|---|
| `lib/app/app_routes.dart` | Navigator 2.0 stub; class name `AppRoutes` shadows canonical `lib/core/routing/app_routes.dart` |
| `lib/features/home_page.dart` | Renders only empty placeholder text; only "used" by the dead `lib/app/app_routes.dart` |
| `lib/features/chat_room_page.dart` | Top-level orphan, not navigated to |
| `lib/features/conversation_list_page.dart` | Top-level orphan |
| `lib/features/onboarding_flow.dart` | Top-level orphan |

**Fix:** Confirm no active imports, then delete all 5 files.

---

### M-3 · Duplicate/overlapping room-feature directories
The `lib/features/` folder contains at least 3 overlapping room implementations:
- `lib/features/room/` — canonical (contains active `LiveRoomScreen`)
- `lib/features/rooms/` — parallel directory (unclear relationship)
- `lib/features/voice_room/` — stub
- `lib/features/video_room/` — stub

**Fix:** Audit router to confirm which screens are actually reachable. Delete all directories not referenced by the active router.

---

### M-4 · `activity_feed_page.dart` — unused import + dead code
**File:** `lib/features/feed/activity_feed_page.dart`
**Fix:** Remove `import 'package:cloud_firestore/cloud_firestore.dart';` and delete the dead code block at line ~138.

---

### M-5 · `lottie: ^3.0.0` declared in `pubspec.yaml` but no animations exist
`assets/animations/` is empty. No `Lottie.asset(...)` calls found anywhere in `lib/`.

**Fix:** Either add Lottie `.json` animations, or remove `lottie: ^3.0.0` from `pubspec.yaml` to reduce binary size.

---

### M-6 · `assets/icons/` empty — declared in `pubspec.yaml`
`assets/icons/` contains only `README.md`. Any runtime reference to an icon asset will fail.

**Fix:** Add icon files or remove the `assets/icons/` entry from `pubspec.yaml`.

---

### M-7 · Dangling library doc comments in 4 files
**Affected files:**
- `lib/router/app_router.dart`
- `lib/router/app_routes.dart`
- `lib/dev/provider_debug_page.dart`
- `lib/dev/route_test_page.dart`

**Fix:** Add `library;` directive after the leading `///` comment in each file:
```dart
/// App router configuration.
library;          // ← add this line

import '...';
```

---

### M-8 · `web/index.html` — stale "Loading Vybe Social..." brand text
**Fix:** In `web/index.html`, change the loading spinner text from `"Loading Vybe Social..."` to `"Loading MixVy..."`.

---

### M-9 · `ios/Runner/Info.plist` — stale `CFBundleDisplayName: "Vybe Social"`
**Fix:** Set `CFBundleDisplayName` to `MixVy` (or final brand name).

---

## LOW-PRIORITY CLEANUP

### L-1 · `assets/.env` tracked in version control (security risk)
Any `.env` file inside `assets/` is bundled into the app binary and readable by anyone who extracts the APK/IPA.

**Fix:**
```powershell
git rm --cached assets/.env
# Add to .gitignore:
echo "assets/.env" >> .gitignore
```
Move secrets to environment variables injected at build time or Firebase Remote Config.

---

### L-2 · `_tapCount` local variable with leading underscore in `settings_page.dart`
```dart
int _tapCount = 0;  // triggers no_leading_underscores_for_local_identifiers
int tapCount = 0;   // fix
```

---

### L-3 · Diagnostic/backup HTML files left in `web/`
Files to delete:
- `web/index_backup_20260203_181803.html`
- `web/index_fresh.html`
- All `web/agora_*.html` test/diagnostic files

---

### L-4 · NotoSans fonts on disk but not registered in `pubspec.yaml`
`assets/fonts/NotoSans-Bold.ttf` and `NotoSans-Regular.ttf` exist on disk but are not in the `flutter.fonts` pubspec section. The app uses `google_fonts` for NotoSans — the disk copies are unused dead weight. Either register them in pubspec (and drop `google_fonts`) or delete the disk copies.

---

### L-5 · `withOpacity` deprecated + missing `const` warnings in secondary features
Affects: `lib/features/stories/`, `lib/features/videos/`, `lib/dev/`
Replace `color.withOpacity(x)` → `color.withValues(alpha: x)` and add `const` to applicable widget constructors.

---

### L-6 · Legacy `lib/providers/` directory shadowing `lib/shared/providers/`
`lib/providers/user_providers.dart`, `providers.dart`, `unread_provider.dart` are pre-Riverpod-3 leftovers. After resolving H-2, delete the entire directory.

---

### L-7 · `lib/app/` directory — legacy app scaffold (two competing `app.dart` stubs)
Both `lib/app.dart` and `lib/app/app.dart` contain a `ProviderScope` at line 16, suggesting two old competing entry points. Confirm `lib/main.dart` is the sole entry point, then delete both stubs.

---

## SUMMARY TABLE

| ID | Severity | File | Issue | Effort |
|---|---|---|---|---|
| C-1 | 🔴 CRITICAL | `social_feed_service.dart` | 5 compile errors — named params on positional methods | Small |
| C-2 | 🔴 CRITICAL | `deep_link_service.dart` | 4 compile errors — wrong import path | Trivial |
| C-3 | 🔴 CRITICAL | `android/settings.gradle[.kts]` | Dual competing settings files with version mismatch | Small |
| C-4 | 🔴 CRITICAL | pub cache | `riverpod_lint-3.1.3` missing — `flutter analyze` broken | Trivial |
| H-1 | 🟠 HIGH | `firebase_options.dart` | All native platforms use web `appId` | Medium |
| H-2 | 🟠 HIGH | 3 provider files | Triplicated auth provider declarations | Large |
| H-3 | 🟠 HIGH | `firebase-messaging-sw.js` | Firebase v9.22.0 compat vs v10+ SDK | Trivial |
| H-4 | 🟠 HIGH | `live_room_screen.dart:~1567` | Nested `ProviderScope` anti-pattern | Small |
| H-5 | 🟠 HIGH | `assets/audio/` | 6 audio MP3s missing; actively referenced in code | Medium |
| H-6 | 🟠 HIGH | `ios/Podfile` | Podfile missing | Small |
| M-1 | 🟡 MEDIUM | `auth_gate_root.dart` | Both auth branches return same widget | Trivial |
| M-2 | 🟡 MEDIUM | `lib/features/` + `lib/app/` | 5 orphaned dead-code files | Small |
| M-3 | 🟡 MEDIUM | `lib/features/room[s]/voice/video` | 4 overlapping room directories | Medium |
| M-4 | 🟡 MEDIUM | `activity_feed_page.dart` | Unused import + dead code | Trivial |
| M-5 | 🟡 MEDIUM | `pubspec.yaml` | `lottie` dep with no assets | Trivial |
| M-6 | 🟡 MEDIUM | `assets/icons/` | Empty asset directory declared in pubspec | Small |
| M-7 | 🟡 MEDIUM | 4 router/dev files | Dangling library doc comment warnings | Trivial |
| M-8 | 🟡 MEDIUM | `web/index.html` | Stale "Vybe Social" loading brand text | Trivial |
| M-9 | 🟡 MEDIUM | `ios/Runner/Info.plist` | Stale `CFBundleDisplayName` | Trivial |
| L-1 | 🔵 LOW | `assets/.env` | `.env` tracked in git + bundled in APK | Small |
| L-2 | 🔵 LOW | `settings_page.dart` | `_tapCount` leading underscore on local var | Trivial |
| L-3 | 🔵 LOW | `web/*.html` | Diagnostic + backup HTML files in web root | Trivial |
| L-4 | 🔵 LOW | `assets/fonts/` | NotoSans on disk but unused (loaded via google_fonts) | Trivial |
| L-5 | 🔵 LOW | `stories/`, `videos/`, `dev/` | `withOpacity` deprecations + missing `const` | Small |
| L-6 | 🔵 LOW | `lib/providers/` | Legacy shadow provider directory | Medium |
| L-7 | 🔵 LOW | `lib/app/` | Legacy competing app scaffold stubs | Small |

**Total: 4 Critical · 6 High · 9 Medium · 7 Low = 26 tracked issues**

---

## RECOMMENDED FIX ORDER

### Sprint 0 — Unblock compilation (est. 30 min)
1. **C-4** `flutter pub cache repair && flutter pub get` — restore riverpod_lint
2. **C-2** Fix 1-line import in `deep_link_service.dart`
3. **C-1** Fix 4 positional call sites in `social_feed_service.dart`
4. **C-3** Delete `android/settings.gradle`, remove `android.newDsl=false`

### Sprint 1 — Quick wins after clean compilation (est. 1 hr)
5. **H-3** Update Firebase service worker to v10.x CDN (2-line change)
6. **M-8** Fix loading text in `web/index.html`
7. **M-9** Fix `CFBundleDisplayName` in `ios/Runner/Info.plist`
8. **H-4** Remove nested `ProviderScope` from `live_room_screen.dart`
9. **M-1** Fix `auth_gate_root.dart` branch logic (1-line fix or confirm it's dead code)
10. **M-7** Add `library;` to 4 files with dangling doc comments
11. **L-2** Rename `_tapCount` → `tapCount`
12. **L-3** Delete diagnostic HTML files from `web/`

### Sprint 2 — Platform configuration (est. 2–4 hrs)
13. **H-1** Run `flutterfire configure` for all platforms; add `GoogleService-Info.plist`
14. **H-6** Restore `ios/Podfile` via `pod init && pod install`
15. **H-5** Add missing audio assets to `assets/audio/`

### Sprint 3 — Architecture cleanup (est. 1–2 days)
16. **H-2** Consolidate triplicated provider declarations
17. **M-2** Delete 5 orphaned dead-code files
18. **M-3** Audit and delete redundant room feature directories
19. **M-4** Clean up `activity_feed_page.dart`
20. **M-5** Remove unused `lottie` dependency (or add animations)
21. **M-6** Fix empty icons asset directory
22. **L-1** Remove `.env` from git tracking
23. **L-6** Delete `lib/providers/` after H-2 is done
24. **L-7** Delete legacy `lib/app/` stubs
25. **L-4** Decide on NotoSans fonts: register or delete disk copies
26. **L-5** Fix `withOpacity` deprecations + missing `const` across secondary features
