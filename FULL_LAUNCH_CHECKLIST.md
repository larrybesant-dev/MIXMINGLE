# ✅ Full Launch Checklist — MixMingle

**Date:** February 25, 2026
**Track every item before submitting to any store or announcing publicly.**

Legend: ✅ Done | ⏳ In Progress | 🔲 Not Started | 🔴 Blocker

---

## 1. App Icon & Splash

| #   | Item                                                                                               | Status |
| --- | -------------------------------------------------------------------------------------------------- | ------ |
| 1.1 | Replace `assets/images/app_logo.png` with final 1024×1024 production PNG (no transparency for iOS) | 🔲     |
| 1.2 | Re-run `dart run flutter_launcher_icons`                                                           | 🔲     |
| 1.3 | Re-run `dart run flutter_native_splash:create`                                                     | 🔲     |
| 1.4 | Verify Android adaptive icon on device (background fills full circle)                              | 🔲     |
| 1.5 | Verify iOS icon on device (no black border, no transparency artifacts)                             | 🔲     |
| 1.6 | Verify web favicon in browser tab                                                                  | 🔲     |
| 1.7 | Verify splash screen on Android cold launch                                                        | 🔲     |
| 1.8 | Verify splash screen on iOS cold launch                                                            | 🔲     |
| 1.9 | Verify web splash on first PWA load                                                                | 🔲     |

---

## 2. Branding & Metadata

| #    | Item                                                                   | Status |
| ---- | ---------------------------------------------------------------------- | ------ |
| 2.1  | Android app label: "Mix & Mingle"                                      | ✅     |
| 2.2  | iOS display name: "Mix & Mingle"                                       | ✅     |
| 2.3  | Web `<title>` and `og:title`: "Mix & Mingle"                           | ✅     |
| 2.4  | `web/manifest.json` short_name: "MixMingle"                            | ✅     |
| 2.5  | `theme_color` and `background_color` in manifest: `#080C14`            | ✅     |
| 2.6  | `og:url` updated to production custom domain                           | 🔲     |
| 2.7  | `og:image` updated to hosted 1200×630 social preview image             | 🔲     |
| 2.8  | Privacy Policy URL live and correct in `index.html` and store listings | 🔲     |
| 2.9  | Terms of Service URL live                                              | 🔲     |
| 2.10 | Support email / support URL live                                       | 🔲     |

---

## 3. Firebase — Production Configuration

| #    | Item                                                                     | Status |
| ---- | ------------------------------------------------------------------------ | ------ |
| 3.1  | Swap `android/app/google-services.json` → production Firebase project    | 🔴     |
| 3.2  | Swap `ios/Runner/GoogleService-Info.plist` → production Firebase project | 🔴     |
| 3.3  | Enable Firebase App Check (production)                                   | 🔲     |
| 3.4  | Firebase Auth: disable test/anonymous providers not used in production   | 🔲     |
| 3.5  | Firestore security rules deployed to production                          | 🔲     |
| 3.6  | Firestore indexes built for all active queries                           | 🔲     |
| 3.7  | Firebase Storage rules hardened (authenticated upload only)              | 🔲     |
| 3.8  | Firebase Functions deployed from main branch (not local emulator)        | 🔲     |
| 3.9  | Firebase Functions: rate limiting on `generateAgoraToken`                | 🔲     |
| 3.10 | Firebase Crashlytics enabled in production build                         | 🔲     |

---

## 4. Agora

| #   | Item                                                               | Status |
| --- | ------------------------------------------------------------------ | ------ |
| 4.1 | Agora App ID is production (not test)                              | 🔲     |
| 4.2 | Agora token server (Firebase Function) deployed and tested         | 🔲     |
| 4.3 | Token expiry handling implemented (refresh before expiry)          | 🔲     |
| 4.4 | Agora Web SDK loaded correctly (no CORS errors)                    | 🔲     |
| 4.5 | Camera/microphone permissions requested correctly on all platforms | 🔲     |

---

## 5. AdMob

| #   | Item                                                            | Status |
| --- | --------------------------------------------------------------- | ------ |
| 5.1 | AdMob App ID in `AndroidManifest.xml` is production ID          | 🔲     |
| 5.2 | AdMob App ID in `ios/Runner/Info.plist` is production ID        | 🔲     |
| 5.3 | All test ad unit IDs replaced with production ad unit IDs       | 🔲     |
| 5.4 | Age-restricted ad flag (COPPA / GDPR) implemented correctly     | 🔲     |
| 5.5 | Banner, interstitial, rewarded ad formats tested on real device | 🔲     |
| 5.6 | AdMob account approved, payment info entered                    | 🔲     |

---

## 6. Code Quality

| #   | Item                                                      | Status |
| --- | --------------------------------------------------------- | ------ |
| 6.1 | `flutter analyze --no-fatal-infos` → 0 errors, 0 warnings | ✅     |
| 6.2 | No `print()` in production paths (use `kDebugMode` guard) | 🔲     |
| 6.3 | No hardcoded API keys in source code                      | 🔲     |
| 6.4 | No test/mock data in production builds                    | 🔲     |
| 6.5 | All `TODO:` comments resolved or deferred to backlog      | 🔲     |

---

## 7. QA — Functional Testing

| #    | Area                                                           | Status |
| ---- | -------------------------------------------------------------- | ------ |
| 7.1  | Onboarding: register → profile → home                          | 🔲     |
| 7.2  | Login / logout cycle                                           | 🔲     |
| 7.3  | Room creation → join → leave                                   | 🔲     |
| 7.4  | Video on / off during room                                     | 🔲     |
| 7.5  | Audio mute / unmute during room                                | 🔲     |
| 7.6  | Chat: send, receive, real-time update                          | 🔲     |
| 7.7  | Match: like → mutual → match popup                             | 🔲     |
| 7.8  | Speed date: create → timer → advance → end                     | 🔲     |
| 7.9  | Report user flow end-to-end                                    | 🔲     |
| 7.10 | Block user: blocked user disappears from discovery             | 🔲     |
| 7.11 | Promo code: valid code → unlock                                | 🔲     |
| 7.12 | Premium upgrade flow                                           | 🔲     |
| 7.13 | Admin dashboard: login → user list → ban                       | 🔲     |
| 7.14 | Ads: banner display, interstitial trigger, rewarded completion | 🔲     |
| 7.15 | Offline: disconnect → reconnect → state restored               | 🔲     |
| 7.16 | Web pop-out window: open → use → close                         | 🔲     |
| 7.17 | Deep link navigation (if implemented)                          | 🔲     |
| 7.18 | Push notifications (if implemented)                            | 🔲     |

---

## 8. Builds

| #   | Item                                                        | Status          |
| --- | ----------------------------------------------------------- | --------------- |
| 8.1 | `flutter build web --release` → success                     | ✅ 44.1 MB      |
| 8.2 | `flutter build apk --release` → success                     | ✅ 277.2 MB     |
| 8.3 | `flutter build appbundle --release` (for Play Store)        | 🔲              |
| 8.4 | `flutter build ipa --release` on macOS (for App Store)      | 🔴 Requires Mac |
| 8.5 | APK/AAB signed with production release keystore (not debug) | 🔴              |
| 8.6 | IPA signed with Apple Distribution certificate              | 🔴 Requires Mac |
| 8.7 | Web build deployed to Firebase Hosting production channel   | 🔲              |

---

## 9. Store Listings — Google Play

| #    | Item                                                              | Status |
| ---- | ----------------------------------------------------------------- | ------ |
| 9.1  | Google Play Console app record created                            | 🔲     |
| 9.2  | App name, short description, full description uploaded            | 🔲     |
| 9.3  | Feature graphic (1024×500) uploaded                               | 🔲     |
| 9.4  | At least 2 phone screenshots uploaded                             | 🔲     |
| 9.5  | 7-inch and 10-inch tablet screenshots (or declared not supported) | 🔲     |
| 9.6  | Content rating questionnaire completed                            | 🔲     |
| 9.7  | Privacy policy URL entered                                        | 🔲     |
| 9.8  | App category, tags set                                            | 🔲     |
| 9.9  | Release track selected (internal → closed → open → production)    | 🔲     |
| 9.10 | AAB uploaded and processing complete                              | 🔲     |

---

## 10. Store Listings — App Store (iOS)

| #     | Item                                                            | Status          |
| ----- | --------------------------------------------------------------- | --------------- |
| 10.1  | App Store Connect app record created                            | 🔲              |
| 10.2  | App name, subtitle, description, keywords entered               | 🔲              |
| 10.3  | Promotional text (optional) entered                             | 🔲              |
| 10.4  | At least 3 iPhone screenshots uploaded (6.5" required)          | 🔲              |
| 10.5  | iPad screenshots (or iPad excluded)                             | 🔲              |
| 10.6  | App icon 1024×1024 PNG (no alpha) uploaded to App Store Connect | 🔲              |
| 10.7  | Age rating questionnaire completed                              | 🔲              |
| 10.8  | Privacy policy URL entered                                      | 🔲              |
| 10.9  | Support URL entered                                             | 🔲              |
| 10.10 | Category selected                                               | 🔲              |
| 10.11 | IPA uploaded via Xcode Organizer                                | 🔴 Requires Mac |
| 10.12 | Build selected in App Store Connect                             | 🔲              |
| 10.13 | Submitted for review                                            | 🔲              |

---

## 11. Web (Firebase Hosting / PWA)

| #    | Item                                                         | Status |
| ---- | ------------------------------------------------------------ | ------ |
| 11.1 | Production domain registered and DNS configured              | 🔲     |
| 11.2 | `firebase.json` hosting config verified                      | 🔲     |
| 11.3 | `firebase deploy --only hosting` run against production      | 🔲     |
| 11.4 | HTTPS certificate active                                     | 🔲     |
| 11.5 | PWA installable prompt tested in Chrome                      | 🔲     |
| 11.6 | Lighthouse score ≥ 80 (Performance, SEO, Accessibility, PWA) | 🔲     |

---

## 12. Post-Launch Monitoring

| #    | Item                                                 | Status |
| ---- | ---------------------------------------------------- | ------ |
| 12.1 | Firebase Crashlytics alerts configured               | 🔲     |
| 12.2 | Firebase Analytics dashboard bookmarked              | 🔲     |
| 12.3 | Google Play Android Vitals monitoring enabled        | 🔲     |
| 12.4 | App Store Connect crash reports monitored            | 🔲     |
| 12.5 | Firestore usage alerts set (cost runaway prevention) | 🔲     |
| 12.6 | AdMob revenue dashboard monitored                    | 🔲     |
