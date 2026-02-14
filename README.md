# Mix & Mingle

A social video chat platform built with Flutter, Firebase, and Agora for live performances and global connections.

## Features

- **Real-time Video Chat**: High-quality video streaming with Agora SDK
- **Social Rooms**: Create and join public/private chat rooms
- **Live Messaging**: Real-time text chat in rooms
- **User Authentication**: Email/password and social login (Google, Apple)
- **Tipping System**: Send tips to performers and creators
- **Notifications**: Real-time push notifications
- **Media Sharing**: Share images, videos, and files
- **Responsive Design**: Works on web, Android, and iOS
- **Dark/Light Theme**: Customizable appearance

## Tech Stack

- **Frontend**: Flutter 3.x with Material 3
- **Backend**: Firebase (Auth, Firestore, Storage, Functions, Messaging)
- **State Management**: Riverpod
- **Video**: Agora RTC Engine
- **Architecture**: Clean Architecture with MVVM pattern

## Project Structure

```text
lib/
├── main.dart                 # App entry point with Firebase init
├── firebase_options.dart     # Firebase configuration
├── app.dart                  # MaterialApp with routing
├── core/                     # Core app components
│   ├── constants.dart        # App-wide constants
│   ├── utils.dart           # Utility functions
│   └── theme/               # Theme configuration
│       ├── colors.dart      # Club color palette
│       ├── text_styles.dart # Neon text styles
│       └── theme.dart       # Complete theme data
├── models/                   # Data models
│   ├── user.dart
│   ├── room.dart
│   ├── message.dart
│   ├── notification.dart
│   ├── tip.dart
│   └── media_item.dart
├── services/                 # Business logic services
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   ├── agora_service.dart    # Video chat service
│   ├── token_service.dart    # Firebase token generation
│   ├── tipping_service.dart
│   └── storage_service.dart
├── providers/                # Riverpod state providers
│   └── providers.dart
├── features/                 # Feature-based UI modules
│   ├── home/                 # Home screen
│   ├── browse_rooms/         # Room browsing
│   ├── go_live/              # Room creation
│   ├── room/                 # Live room experience
│   ├── profile/              # User profile
│   ├── settings/             # App settings
│   └── error/                # Error handling
└── shared/                   # Shared reusable widgets
    ├── club_background.dart  # Animated club background
    ├── glow_text.dart        # Neon glow text
    ├── neon_button.dart      # Pulsing neon buttons
    └── live_room_card.dart   # Room cards with animations
```

## Setup Instructions

### Prerequisites

1. **Flutter**: Install Flutter SDK 3.0+

   ```bash
   # Download from https://flutter.dev/docs/get-started/install
   flutter doctor
   ```

2. **Firebase Project**:
   - Create a Firebase project at <https://console.firebase.google.com>
   - Enable Authentication, Firestore, Storage, and Cloud Messaging
   - Add your app (Android/iOS/Web) to the project

3. **Agora Account**:
   - Sign up at <https://console.agora.io>
   - Create a project and get your App ID

### Installation

1. **Clone and setup**:

   ```bash
   git clone <repository-url>
   cd mix_and_mingle
   flutter pub get
   ```

2. **Firebase Configuration**:

   ```bash
   flutterfire configure
   # This will generate lib/firebase_options.dart
   ```

3. **Agora Setup**:
   - Replace `YOUR_AGORA_APP_ID` in `lib/services/video_service.dart`
   - Add your Agora App ID

4. **Run the app**:

   ```bash
   flutter run
   ```

### Firebase Security Rules

Add these security rules to your Firestore:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // Rooms are readable by all authenticated users
    match /rooms/{roomId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && request.auth.uid == resource.data.creatorId;
    }

    // Messages can be read by room participants
    match /rooms/{roomId}/messages/{messageId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
    }
  }
}
```

### Environment Variables

Create a `.env` file in the root directory:

```bash
# Flutter environment variables (for production builds)
AGORA_APP_ID=your_agora_app_id_here
AGORA_APP_CERTIFICATE=your_agora_app_certificate_here
```

Create a `functions/.env` file for Firebase Functions:

```bash
# Firebase Functions environment variables
AGORA_APP_ID=your_actual_agora_app_id
AGORA_APP_CERTIFICATE=your_actual_agora_certificate
FIREBASE_CONFIG={"projectId":"your-project-id","databaseURL":"https://your-project-id.firebaseio.com","storageBucket":"your-project-id.appspot.com"}
```

### Agora Setup

1. **Get Agora Credentials**:
   - Sign up at [Agora Console](https://console.agora.io)
   - Create a new project
   - Get your App ID and App Certificate
   - Enable authentication and real-time messaging

2. **Update Credentials**:
   - Replace `your_actual_agora_app_id` with your Agora App ID
   - Replace `your_actual_agora_certificate` with your Agora App Certificate
   - These values are used in both Flutter app and Firebase Functions

3. **Deploy Firebase Functions**:

   ```bash
   cd functions
   npm install
   npm run build
   firebase deploy --only functions
   ```

## Key Components

### Authentication Flow

- Splash screen checks auth state
- Login/Register with email/password
- Social login with Google and Apple
- Profile management

### Room System

- Create public/private rooms
- Real-time participant count
- Video chat integration
- Text messaging

### Video Service

- Agora RTC integration
- Permission handling
- Channel management
- Video controls

### State Management

- Riverpod providers for all state
- Async operations with AsyncValue
- Real-time data streams

## 🚀 Quick Start & Deployment

### Automated Build Script

We've created automated build scripts to simplify deployment and avoid common issues:

```powershell
# Full build and deploy (recommended)
.\build_and_deploy.ps1

# Build only (skip deployment)
.\build_and_deploy.ps1 -SkipDeploy

# Clean only
.\build_and_deploy.ps1 -CleanOnly
```

**What the script does:**

- ✅ Verifies project structure (`pubspec.yaml` exists)
- ✅ Cleans previous builds
- ✅ Installs dependencies
- ✅ Builds web app in release mode
- ✅ Deploys to Firebase Hosting (if Firebase CLI available)

### Manual Build Steps

```bash
# Navigate to project root (important!)
cd C:\Users\LARRY\MIXMINGLE

# Clean and install dependencies
flutter clean
flutter pub get

# Build for web
flutter build web --release

# Deploy to Firebase
firebase deploy --only hosting
```

## 🔧 Troubleshooting White Screen Issues

### Most Common Causes

#### 1. Wrong Working Directory

**Error:** "No pubspec.yaml file found"

**Fix:** Always run Flutter commands from `C:\Users\LARRY\MIXMINGLE\`

#### 2. Firebase Initialization Failure

**Symptoms:** White screen, Firebase errors in console

**Checks:**

- Verify `lib/firebase_options.dart` has correct config
- Check Firebase project exists and is accessible
- Ensure all Firebase services are enabled

#### 3. Authentication State Issues

**Symptoms:** Stuck on splash screen, can't access app

**Fix:**

- Clear browser localStorage/cookies
- Check browser dev tools > Application > Local Storage
- Verify Firebase Auth state

#### 4. Routing Problems

**Symptoms:** App loads but shows wrong/blank page

**Checks:**

- Browser URL should match expected route
- Check `lib/app.dart` route configuration
- Verify `AuthGuard` isn't blocking access

### Debug Steps

1. **Open Browser Dev Tools** (F12)
2. **Check Console Tab** for JavaScript/Firebase errors
3. **Check Network Tab** for failed API requests
4. **Check Application Tab** for auth tokens and storage

### Quick Fix Commands

```powershell
# Clean rebuild (fixes most issues)
flutter clean
flutter pub get
flutter build web --release

# Run locally with verbose logging
flutter run -d chrome --verbose --web-port=3000

# Check Firebase connection
firebase projects:list
```

### Build Verification

After building, check these files exist:

```text
build/web/
├── index.html
├── main.dart.js
└── assets/
```

## Additional Troubleshooting

### 1. Provider Access Error in RoomPage

**Issue**: `ref.read()` not available in `initState()` callback

**Fix**: Move Agora initialization to the `build()` method:

```dart
@override
Widget build(BuildContext context) {
  final messagesAsync = ref.watch(messagesProvider(widget.room.id));

  // Initialize Agora when the widget is first built
  if (!_hasInitializedAgora) {
    _initializeAgora();
  }

  return ClubBackground(child: /* ... */);
}
```

#### 2. Integration Tests Failing on Web

**Issue**: `flutter test integration_test` fails with "Web devices are not supported"

**Status**: Known Flutter limitation - integration tests don't work on web platforms

**Workaround**: Use unit tests and widget tests instead:

```bash
flutter test                    # Run unit tests
flutter test test/widget_test.dart  # Run widget tests
```

#### 3. Environment Variables Not Loading

**Issue**: Agora credentials not found

**Fix**: Ensure `.env` file exists and `flutter_dotenv` is initialized in `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");  // Add this line
  // ... rest of initialization
}
```

#### 4. Video Not Working in Rooms

**Issue**: Video controls don't appear or video doesn't start

**Check**:

- Ensure Agora App ID is correct in `.env`
- Check browser permissions for camera/microphone
- Verify Firebase functions are deployed
- Check browser console for Agora errors

#### 5. Firebase Functions Not Working

**Issue**: Token generation fails

**Fix**: Ensure environment variables are set in Firebase:

```bash
firebase functions:config:set agora.app_id="your_app_id"
firebase functions:config:set agora.app_certificate="your_certificate"
firebase deploy --only functions
```

### Testing Strategy

Since full integration tests don't work on Flutter web, we use:

- **Unit Tests**: Test individual functions and services
- **Widget Tests**: Test UI components in isolation
- **Manual Testing**: Test complete flows in browser
- **Build Verification**: Ensure `flutter build web --release` succeeds

## Testing & Deployment

### Local Testing

Use the provided verification scripts to ensure your setup is working:

```powershell
# PowerShell (recommended)
.\verify-setup.ps1

# Or batch file
.\verify-setup.bat
```

### Playwright E2E Tests

Run end-to-end tests locally:

```bash
cd playwright-tests
npm install
npx playwright install
npx playwright test
```

Available test commands:

- `npm run test:happy-path` - Test complete user journey
- `npm run test:auth` - Test authentication flows
- `npm run test:home` - Test home page functionality
- `npm run test:rooms` - Test room browsing and creation
- `npm run test:users` - Test user discovery
- `npm run test:messages` - Test messaging features
- `npm run test:settings` - Test settings and configuration

### Manual Deployment

Deploy to Firebase Hosting manually:

```bash
# Build for production
flutter build web --release

# Deploy to Firebase
firebase deploy --only hosting
```

### Alternative CI/CD Options

If you want automated testing and deployment without GitHub:

- **GitLab CI/CD**: Use `.gitlab-ci.yml`
- **Azure DevOps**: Use Azure Pipelines
- **Jenkins**: Configure Jenkins pipeline
- **CircleCI**: Use `.circleci/config.yml`
- **Local Scripts**: Use the verification scripts as part of your deployment process

## Development

### Running Tests

```bash
flutter test
```

### Building for Production

```bash
# Android APK
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

### Code Generation

```bash
flutter pub run build_runner build
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support, email <support@mixandmingle.com> or join our Discord community.
