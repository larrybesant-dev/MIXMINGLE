# 🏪 Store Submission Checklist — MixMingle

**Date:** February 25, 2026
**Covers:** Google Play Store + Apple App Store + Web (Firebase Hosting)

---

## Pre-Submission Requirements (Both Stores)

Before uploading any build, confirm all of the following:

| #   | Requirement                                                           | Status |
| --- | --------------------------------------------------------------------- | ------ |
| P1  | `google-services.json` swapped to **production** Firebase project     | 🔲     |
| P2  | `GoogleService-Info.plist` swapped to **production** Firebase project | 🔲     |
| P3  | All AdMob test ad unit IDs replaced with **production** ad unit IDs   | 🔲     |
| P4  | Final 1024×1024 `app_logo.png` in place; icons re-generated           | 🔲     |
| P5  | `flutter analyze --no-fatal-infos` → 0 hard errors                    | ✅     |
| P6  | Privacy Policy URL live (required by both stores)                     | 🔲     |
| P7  | Terms of Service URL live                                             | 🔲     |
| P8  | Support email / URL live                                              | 🔲     |

---

## Google Play Store

### Step 1 — Build the Release Bundle

```powershell
# Sign with your release keystore before this step (see Step 1a below)
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

#### Step 1a — Release Signing (if not yet configured)

Add to `android/app/build.gradle`:

```groovy
android {
    signingConfigs {
        release {
            keyAlias 'your_key_alias'
            keyPassword 'your_key_password'
            storeFile file('your_release.keystore')
            storePassword 'your_store_password'
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

> ⚠️ Never commit your keystore or passwords to version control. Use environment variables or a secrets manager.

---

### Step 2 — Google Play Console Setup

1. Go to [play.google.com/console](https://play.google.com/console)
2. Click **Create app**
3. Fill in:
   - **App name:** Mix & Mingle
   - **Default language:** English (United States)
   - **App or game:** App
   - **Free or paid:** Free (or Paid if applicable)
4. Accept the Developer Program Policies

---

### Step 3 — Store Listing

| Field                  | Value                                                                     |
| ---------------------- | ------------------------------------------------------------------------- |
| **App name**           | Mix & Mingle                                                              |
| **Short description**  | (max 80 chars) e.g. "Meet people in live video rooms. Match. Chat. Vibe." |
| **Full description**   | From `STORE_METADATA.md`                                                  |
| **Feature graphic**    | 1024×500 JPG or PNG (no alpha)                                            |
| **Phone screenshots**  | Minimum 2, max 8 (16:9 or 9:16, min 320px, max 3840px)                    |
| **Tablet screenshots** | Optional (declare tablet not supported if skipping)                       |
| **Category**           | Social → Social discovery                                                 |
| **Tags**               | video chat, meeting people, social rooms, speed dating                    |
| **Email**              | Your developer support email                                              |
| **Privacy policy**     | https://your-domain.com/privacy                                           |

---

### Step 4 — Content Rating

1. In Play Console → **Policy → App content → Content rating**
2. Complete the **IARC questionnaire**
3. Declare:
   - User-generated content: **Yes**
   - Chat functionality: **Yes**
   - Video chat: **Yes**
   - Dating: **Yes** (if applicable)
4. Expected rating: **Teen (T)** or **Mature 17+** depending on dating features declared

---

### Step 5 — Data Safety Form

1. Play Console → **Policy → App content → Data safety**
2. Declare all data collected:
   - Name, email, profile photo: **User info**
   - Location (if used): **Location**
   - Audio (microphone): **Audio files**
   - Video: **Photos and videos**
   - User IDs (Firebase UID): **App activity**
3. Specify retention and sharing policies

---

### Step 6 — Upload & Release

1. Play Console → **Release → Testing → Internal testing** (start here)
2. Upload `app-release.aab`
3. Add testers (your Gmail accounts)
4. Test internally → promote to **Closed testing (Alpha)** → **Open testing (Beta)** → **Production**

---

### Step 7 — Target API Level

Ensure `targetSdkVersion` in `android/app/build.gradle` is **≥ 34** (required by Play Store for all new apps as of 2024):

```groovy
defaultConfig {
    targetSdkVersion 34
    minSdkVersion 21
}
```

---

## Apple App Store

### Step 1 — Build the IPA (requires macOS + Xcode)

```bash
# On a Mac with Xcode installed:
flutter build ipa --release
# Output: build/ios/archive/Runner.xcarchive
```

#### Step 1a — Open in Xcode Organizer

```bash
open build/ios/archive/Runner.xcarchive
```

1. In Xcode Organizer → select archive → click **Distribute App**
2. Choose **App Store Connect**
3. Choose **Upload** (direct upload to App Store Connect)
4. Select your **Distribution certificate** and **Provisioning profile** (App Store type)
5. Upload

---

### Step 2 — App Store Connect Setup

1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Click **+** → **New App**
3. Fill in:
   - **Platform:** iOS
   - **Name:** Mix & Mingle
   - **Primary language:** English (U.S.)
   - **Bundle ID:** (matches `io.flutter.mixmingle` or your actual bundle ID)
   - **SKU:** mixmingle-ios-001

---

### Step 3 — App Information

| Field                  | Value                                                       |
| ---------------------- | ----------------------------------------------------------- |
| **Name**               | Mix & Mingle                                                |
| **Subtitle**           | (max 30 chars) e.g. "Meet. Vibe. Connect."                  |
| **Category**           | Primary: Social Networking                                  |
| **Secondary category** | Entertainment (optional)                                    |
| **Content rights**     | Declare you own all content rights                          |
| **Age rating**         | Complete questionnaire (expect 17+ for chat/video features) |

---

### Step 4 — App Store Listing

| Field                  | Spec                                                   |
| ---------------------- | ------------------------------------------------------ |
| **Description**        | Max 4,000 chars — from `STORE_METADATA.md`             |
| **Keywords**           | Max 100 chars, comma-separated, no spaces after commas |
| **Promotional text**   | Max 170 chars (can be updated without new submission)  |
| **Support URL**        | https://your-domain.com/support                        |
| **Marketing URL**      | https://your-domain.com (optional)                     |
| **Privacy Policy URL** | https://your-domain.com/privacy                        |

---

### Step 5 — Screenshots

| Device                 | Size Required          | Count                         |
| ---------------------- | ---------------------- | ----------------------------- |
| iPhone 6.9" (Pro Max)  | 1320×2868 or 1290×2796 | Min 3, max 10                 |
| iPhone 6.5" (Plus/Max) | 1242×2688              | Required if 6.9" not provided |
| iPad Pro 12.9"         | 2048×2732              | Required if iPad supported    |
| iPad Pro 11"           | 1668×2388              | Optional                      |

> Screenshots can be device frames or plain. App Store Connect auto-scales for smaller sizes.

**App icon for App Store Connect:** 1024×1024 PNG, no alpha, no rounded corners (App Store applies rounding automatically).

---

### Step 6 — Build & Submit

1. In App Store Connect → **TestFlight** tab: confirm uploaded build is processed (usually 5–30 min)
2. Go to **App Store** tab → select your version → scroll to **Build** section → click **+** → select build
3. Fill in **What's New in This Version** (release notes)
4. Click **Add for Review**
5. Answer export compliance questions (select **No** if no encryption beyond HTTPS)
6. Click **Submit to App Review**

> ⏱ Apple review typically takes 1–3 business days for new apps.

---

### Step 7 — After Approval

- Set **release date**: manual or automatic upon approval
- Enable **Phased release** (recommended for first launch: rolls out over 7 days to 100% of users)
- Monitor **App Analytics** and **Crashes** in App Store Connect

---

## Web — Firebase Hosting

### Step 1 — Build

```powershell
flutter build web --release
```

### Step 2 — Configure Custom Domain (optional but recommended)

1. Firebase Console → Hosting → **Add custom domain**
2. Enter your domain (e.g. `mixmingle.app`)
3. Follow DNS verification steps (add TXT + A records at your registrar)
4. Wait for SSL certificate provisioning (usually 1–24 hours)
5. Update `og:url` in `web/index.html` to match

### Step 3 — Deploy

```powershell
firebase deploy --only hosting
```

### Step 4 — Verify

- Open production URL in Chrome
- Verify PWA install prompt appears
- Run Lighthouse audit (Chrome DevTools → Lighthouse tab):
  - Target: Performance ≥ 80, PWA ✅, SEO ≥ 90, Accessibility ≥ 80
- Verify `og:image` loads in [opengraph.xyz](https://opengraph.xyz)
- Verify Twitter card preview at [cards-dev.twitter.com/validator](https://cards-dev.twitter.com/validator)

---

## Post-Submission Monitoring

| Platform    | Where to Monitor                                       |
| ----------- | ------------------------------------------------------ |
| Google Play | Play Console → Android Vitals → Crashes & ANRs         |
| App Store   | App Store Connect → Analytics → Crashes                |
| Firebase    | Firebase Console → Crashlytics, Analytics, Performance |
| AdMob       | AdMob Console → Apps → Ad Units → Earnings             |
| Web         | Firebase Hosting → Usage, Firebase Analytics           |
