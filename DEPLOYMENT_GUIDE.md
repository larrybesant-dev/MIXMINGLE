# Phase 14: Deployment & CI/CD Pipeline

## Overview

This guide walks through deploying Mix & Mingle to TestFlight (iOS) and Play Store Internal Testing (Android), setting up CI/CD with GitHub Actions, and preparing for production launch.

---

## 📱 iOS Deployment (TestFlight)

### Prerequisites

1. ✅ Apple Developer Account ($99/year)
2. ✅ Xcode 15+ installed on Mac
3. ✅ App Store Connect access
4. ✅ Bundle ID registered: `com.mixmingle.app`
5. ✅ Push Notification Certificate
6. ✅ Provisioning Profiles configured

### Step 1: Update iOS Configuration

Edit `ios/Runner/Info.plist`:

```xml
<key>CFBundleDisplayName</key>
<string>Mix & Mingle</string>
<key>CFBundleVersion</key>
<string>1</string>
<key>CFBundleShortVersionString</key>
<string>1.0.0</string>
<key>MinimumOSVersion</key>
<string>13.0</string>

<!-- Permissions -->
<key>NSCameraUsageDescription</key>
<string>Mix & Mingle needs camera access for video chat and profile photos</string>
<key>NSMicrophoneUsageDescription</key>
<string>Mix & Mingle needs microphone access for voice and video chat</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Mix & Mingle needs photo library access to upload profile photos</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Mix & Mingle uses your location to find nearby events</string>
```

### Step 2: Configure App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Click "My Apps" → "+" → "New App"
3. Fill in:
   - **Platform**: iOS
   - **Name**: Mix & Mingle
   - **Primary Language**: English (U.S.)
   - **Bundle ID**: com.mixmingle.app
   - **SKU**: MIXMINGLE001
   - **User Access**: Full Access

### Step 3: Create Archive in Xcode

```bash
# Open iOS project
cd ios
open Runner.xcworkspace

# In Xcode:
# 1. Select "Any iOS Device" as destination
# 2. Product → Archive
# 3. Window → Organizer
# 4. Select archive → "Distribute App"
# 5. Select "App Store Connect" → "Upload"
# 6. Select signing: "Automatically manage signing"
# 7. Upload
```

### Step 4: TestFlight Beta Testing

1. Go to App Store Connect → TestFlight tab
2. Click "+" to add internal testers
3. Add up to 100 internal testers (no review required)
4. Testers receive email invitation
5. Install TestFlight app and accept invite

### Step 5: Build with Flutter (Alternative)

```bash
# Build iOS release
flutter build ios --release

# Or build IPA directly
flutter build ipa --release

# Archive is in build/ios/archive/Runner.xcarchive
```

---

## 🤖 Android Deployment (Play Store Internal Testing)

### Prerequisites

1. ✅ Google Play Console Account ($25 one-time)
2. ✅ App signing key generated
3. ✅ Package name: `com.mixmingle.app`
4. ✅ Google Play Services configured

### Step 1: Generate Signing Key

```bash
# Generate keystore
keytool -genkey -v -keystore ~/mixmingle-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias mixmingle

# Follow prompts:
# - Keystore password: [SECURE_PASSWORD]
# - First and last name: Mix & Mingle LLC
# - Organizational unit: Engineering
# - Organization: Mix & Mingle
# - City: San Francisco
# - State: California
# - Country: US
```

### Step 2: Configure Gradle Signing

Create `android/key.properties`:

```properties
storePassword=[KEYSTORE_PASSWORD]
keyPassword=[KEY_PASSWORD]
keyAlias=mixmingle
storeFile=../mixmingle-release-key.jks
```

Edit `android/app/build.gradle`:

```gradle
// Add before android block
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // ... existing config

    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            // ... other settings
        }
    }
}
```

### Step 3: Update Android Manifest

Edit `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.mixmingle.app">

    <!-- Permissions -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="android.permission.RECORD_AUDIO"/>
    <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>

    <!-- Features -->
    <uses-feature android:name="android.hardware.camera"/>
    <uses-feature android:name="android.hardware.camera.autofocus"/>

    <application
        android:label="Mix &amp; Mingle"
        android:icon="@mipmap/ic_launcher">
        <!-- ... -->
    </application>
</manifest>
```

### Step 4: Build Release APK/AAB

```bash
# Build App Bundle (recommended for Play Store)
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab

# Or build APK (for testing)
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Step 5: Upload to Play Console

1. Go to [Google Play Console](https://play.google.com/console)
2. Create new app:
   - **App name**: Mix & Mingle
   - **Default language**: English (United States)
   - **App or game**: App
   - **Free or paid**: Free
3. Complete store listing
4. Go to "Internal testing" track
5. Create new release
6. Upload `app-release.aab`
7. Add release notes
8. Review and roll out
9. Add internal testers by email
10. Share testing link

---

## 🔄 GitHub Actions CI/CD

### Create `.github/workflows/flutter-ci.yml`

```yaml
name: Flutter CI/CD

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]
  workflow_dispatch:

jobs:
  # ========================================
  # ANALYZE & TEST
  # ========================================
  analyze-and-test:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: "3.19.0"
          channel: "stable"

      - name: Get dependencies
        run: flutter pub get

      - name: Analyze code
        run: flutter analyze

      - name: Run tests
        run: flutter test --coverage

      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/lcov.info
          token: ${{ secrets.CODECOV_TOKEN }}

  # ========================================
  # BUILD ANDROID
  # ========================================
  build-android:
    needs: analyze-and-test
    runs-on: ubuntu-latest
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: "3.19.0"
          channel: "stable"

      - name: Setup Java
        uses: actions/setup-java@v3
        with:
          distribution: "zulu"
          java-version: "17"

      - name: Get dependencies
        run: flutter pub get

      - name: Decode keystore
        run: |
          echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 --decode > android/app/keystore.jks

      - name: Create key.properties
        run: |
          cat > android/key.properties <<EOF
          storePassword=${{ secrets.ANDROID_KEYSTORE_PASSWORD }}
          keyPassword=${{ secrets.ANDROID_KEY_PASSWORD }}
          keyAlias=${{ secrets.ANDROID_KEY_ALIAS }}
          storeFile=keystore.jks
          EOF

      - name: Build Android App Bundle
        run: flutter build appbundle --release

      - name: Upload AAB artifact
        uses: actions/upload-artifact@v3
        with:
          name: app-release.aab
          path: build/app/outputs/bundle/release/app-release.aab

      - name: Deploy to Play Store Internal Testing
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.PLAY_STORE_SERVICE_ACCOUNT_JSON }}
          packageName: com.mixmingle.app
          releaseFiles: build/app/outputs/bundle/release/app-release.aab
          track: internal
          status: completed

  # ========================================
  # BUILD iOS
  # ========================================
  build-ios:
    needs: analyze-and-test
    runs-on: macos-latest
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: "3.19.0"
          channel: "stable"

      - name: Get dependencies
        run: flutter pub get

      - name: Setup Xcode
        uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: "latest-stable"

      - name: Install CocoaPods
        run: |
          cd ios
          pod install

      - name: Build iOS IPA
        run: flutter build ipa --release --export-options-plist=ios/ExportOptions.plist

      - name: Upload IPA artifact
        uses: actions/upload-artifact@v3
        with:
          name: app-release.ipa
          path: build/ios/ipa/*.ipa

      - name: Deploy to TestFlight
        uses: apple-actions/upload-testflight-build@v1
        with:
          app-path: build/ios/ipa/*.ipa
          issuer-id: ${{ secrets.APP_STORE_CONNECT_ISSUER_ID }}
          api-key-id: ${{ secrets.APP_STORE_CONNECT_API_KEY_ID }}
          api-private-key: ${{ secrets.APP_STORE_CONNECT_API_PRIVATE_KEY }}
```

### Required GitHub Secrets

Add to repository settings → Secrets → Actions:

**Android:**

- `ANDROID_KEYSTORE_BASE64` - Base64 encoded keystore file
- `ANDROID_KEYSTORE_PASSWORD` - Keystore password
- `ANDROID_KEY_PASSWORD` - Key password
- `ANDROID_KEY_ALIAS` - Key alias
- `PLAY_STORE_SERVICE_ACCOUNT_JSON` - Google Play service account JSON

**iOS:**

- `APP_STORE_CONNECT_ISSUER_ID` - App Store Connect API issuer ID
- `APP_STORE_CONNECT_API_KEY_ID` - App Store Connect API key ID
- `APP_STORE_CONNECT_API_PRIVATE_KEY` - App Store Connect API private key

**Coverage:**

- `CODECOV_TOKEN` - Codecov upload token

### Generate Secrets

**Android Keystore Base64:**

```bash
base64 -i android/app/keystore.jks | pbcopy
```

**Play Store Service Account:**

1. Go to Google Cloud Console
2. Create service account with "Service Account User" role
3. Enable Google Play Android Developer API
4. Create JSON key
5. Download and copy content

**App Store Connect API:**

1. Go to App Store Connect → Users and Access
2. Keys tab → Generate API Key
3. Download .p8 file
4. Copy Issuer ID and Key ID

---

## 📝 App Store Metadata

### iOS App Store Listing

**App Information:**

- **Name**: Mix & Mingle
- **Subtitle**: Video Chat, Events & Dating
- **Category**: Social Networking
- **Secondary Category**: Lifestyle
- **Content Rights**: Owns or has rights to all content

**Version Information:**

- **Version**: 1.0.0
- **Copyright**: © 2026 Mix & Mingle LLC
- **Trade Representative Contact**: [CONTACT_EMAIL]

**App Privacy:**

- **Privacy Policy URL**: https://mixmingle.app/privacy
- **User Privacy Choices URL**: https://mixmingle.app/privacy#choices

**Age Rating:**

- 17+ (Frequent/Intense Sexual Content or Nudity, Social Networking)

**Description** (4000 chars max):

```
Mix & Mingle - Where Video Chat Meets Real Connections

🎥 VIDEO CHAT ROOMS
Join themed video chat rooms and meet people with shared interests. From gaming to music, fitness to cooking - find your community.

🎉 SOCIAL EVENTS
Create and discover local events. From coffee meetups to group activities - make plans and meet people in real life.

💬 INSTANT MESSAGING
Connect privately through text chat. Share photos, voice messages, and stay in touch with your new friends.

🎮 GAMIFICATION & REWARDS
Earn XP, unlock achievements, and level up your profile. Complete challenges and collect rare badges.

⚡ SPEED DATING
Try our speed dating feature for quick 3-minute video chats. Match with interesting people in your area.

🎨 CUSTOMIZABLE PROFILES
Express yourself with rich profiles, photo galleries, and customizable themes.

🔒 PRIVACY & SAFETY
Block users, report inappropriate behavior, and control your privacy settings. We take safety seriously.

✨ PREMIUM FEATURES
• Priority event placement
• Custom themes and badges
• Advanced search filters
• Unlimited profile views
• Ad-free experience

Join thousands of people making real connections on Mix & Mingle!
```

**Keywords** (100 chars max):

```
video chat,social,dating,events,meetup,friends,voice,rooms,live,speed dating
```

**Screenshots** (Required):

- 6.5" iPhone: 1284 x 2778 (3 required)
- 5.5" iPhone: 1242 x 2208 (3 required)
- iPad Pro 12.9": 2048 x 2732 (2 recommended)

---

### Android Play Store Listing

**App Details:**

- **App name**: Mix & Mingle
- **Short description** (80 chars):
  ```
  Video chat, events & dating. Meet people with shared interests nearby.
  ```

**Full description** (4000 chars):

```
Mix & Mingle - Where Video Chat Meets Real Connections

🎥 VIDEO CHAT ROOMS
Join themed video chat rooms and meet people with shared interests. From gaming to music, fitness to cooking - find your community.

🎉 SOCIAL EVENTS
Create and discover local events. From coffee meetups to group activities - make plans and meet people in real life.

💬 INSTANT MESSAGING
Connect privately through text chat. Share photos, voice messages, and stay in touch with your new friends.

🎮 GAMIFICATION & REWARDS
Earn XP, unlock achievements, and level up your profile. Complete challenges and collect rare badges.

⚡ SPEED DATING
Try our speed dating feature for quick 3-minute video chats. Match with interesting people in your area.

🎨 CUSTOMIZABLE PROFILES
Express yourself with rich profiles, photo galleries, and customizable themes.

🔒 PRIVACY & SAFETY
Block users, report inappropriate behavior, and control your privacy settings. We take safety seriously.

✨ PREMIUM FEATURES
• Priority event placement
• Custom themes and badges
• Advanced search filters
• Unlimited profile views
• Ad-free experience

Join thousands of people making real connections on Mix & Mingle!

PERMISSIONS:
• Camera: For video chat and profile photos
• Microphone: For voice and video chat
• Location: To find nearby events and users
• Storage: To save photos and media
• Internet: To connect with other users

PRIVACY:
We take your privacy seriously. Read our privacy policy at https://mixmingle.app/privacy

SUPPORT:
Having issues? Contact us at support@mixmingle.app
```

**Category**: Social
**Tags**: video chat, social, events, dating, meetup

**Content Rating**: Rated for 18+

**Screenshots** (Required):

- Phone: 1080 x 1920 (2-8 required)
- 7" Tablet: 1200 x 1920 (optional)
- 10" Tablet: 1600 x 2560 (optional)

**Feature Graphic**:

- Size: 1024 x 500
- Required for Play Store

---

## 🚀 Release Process

### Version Numbering

Follow Semantic Versioning: `MAJOR.MINOR.PATCH`

- **MAJOR**: Breaking changes (e.g., 1.0.0 → 2.0.0)
- **MINOR**: New features (e.g., 1.0.0 → 1.1.0)
- **PATCH**: Bug fixes (e.g., 1.0.0 → 1.0.1)

Update in:

1. `pubspec.yaml` - `version: 1.0.0+1`
2. `ios/Runner/Info.plist` - `CFBundleShortVersionString` and `CFBundleVersion`
3. `android/app/build.gradle` - `versionCode` and `versionName`

### Release Checklist

**Pre-Release:**

- [ ] All tests passing
- [ ] Code coverage > 70%
- [ ] No analyzer warnings
- [ ] Firebase configured
- [ ] Agora credentials set
- [ ] Environment variables configured
- [ ] Privacy policy updated
- [ ] Terms of service updated
- [ ] Icons and splash screens finalized
- [ ] App store screenshots ready

**Release:**

- [ ] Bump version number
- [ ] Update CHANGELOG.md
- [ ] Create Git tag (e.g., `v1.0.0`)
- [ ] Push to main branch
- [ ] CI/CD builds successfully
- [ ] TestFlight build available
- [ ] Play Store internal testing available
- [ ] Test on real devices (iOS & Android)
- [ ] Verify all features working
- [ ] Check for crashes
- [ ] Monitor Firebase Analytics

**Post-Release:**

- [ ] Submit for App Store review
- [ ] Promote to Play Store beta
- [ ] Monitor crash reports
- [ ] Monitor user feedback
- [ ] Respond to reviews
- [ ] Track analytics
- [ ] Plan next release

---

## 📊 Monitoring & Analytics

### Firebase Crashlytics

Already configured. Monitor crashes at:
https://console.firebase.google.com/project/mixmingle/crashlytics

### Firebase Analytics

Track key events:

- User sign up
- Profile created
- Event created/joined
- Room joined
- Message sent
- Speed dating started
- Purchase completed

### App Store Analytics

iOS: https://appstoreconnect.apple.com/analytics
Android: https://play.google.com/console/u/0/developers/[DEVELOPER_ID]/app/[APP_ID]/statistics

---

## 🛠️ Troubleshooting

### iOS Build Errors

**"Provisioning profile doesn't match"**

- Solution: Run `flutter clean && cd ios && pod install && cd ..`

**"Signing certificate expired"**

- Solution: Renew certificate in Apple Developer portal

### Android Build Errors

**"Execution failed for task ':app:lintVitalRelease'"**

- Solution: Add `lintOptions { checkReleaseBuilds false }` to `android/app/build.gradle`

**"Keystore file not found"**

- Solution: Verify `key.properties` path is correct

### CI/CD Failures

**"Flutter not found"**

- Solution: Check Flutter version in workflow matches project

**"Secrets not accessible"**

- Solution: Verify secrets are set in repository settings

---

## 📚 Resources

- [Flutter Deployment Guide](https://docs.flutter.dev/deployment)
- [App Store Connect Help](https://developer.apple.com/app-store-connect/)
- [Google Play Console Help](https://support.google.com/googleplay/android-developer)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

---

**Ready for Production Deployment!** 🚀
