# Error Tracking & Crashlytics Setup Guide

## ✅ Implementation Complete

Comprehensive error tracking and crash reporting with Firebase Crashlytics and custom error handling.

## 📁 Files Created/Modified

### Services
- `lib/services/error_tracking_service.dart` - Core error tracking service
  - Crashlytics integration
  - Custom error types
  - Error tracking mixin
  - Zone error guard

### Dependencies
- `pubspec.yaml` - Added `firebase_crashlytics: ^4.2.0`

## 🔧 Setup Instructions

### 1. Firebase Console Setup

1. **Enable Crashlytics**
   - Go to Firebase Console → Crashlytics
   - Click "Enable Crashlytics"
   - Accept terms and conditions

2. **Configure Platforms**
   - Android: Automatic with google-services.json
   - iOS: Automatic with GoogleService-Info.plist
   - Web: Limited support (use custom error handling)

### 2. Update main.dart

Replace your current `main()` function:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'services/error_tracking_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Run app with error tracking
  await runAppWithErrorTracking(const MyApp());
}
```

### 3. Update AuthService

Add error tracking to login/logout:

```dart
import '../services/error_tracking_service.dart';

class AuthService {
  final _errorTracking = ErrorTrackingService();

  Future<void> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Set user ID for crash reports
      if (userCredential.user != null) {
        await _errorTracking.setUserId(userCredential.user!.uid);
        await _errorTracking.setCustomKeys({
          'email': userCredential.user!.email,
          'login_method': 'email',
        });
      }
    } catch (e, stack) {
      _errorTracking.recordError(e, stack, reason: 'Sign in failed');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _errorTracking.clearUserData();
      await _auth.signOut();
    } catch (e, stack) {
      _errorTracking.recordError(e, stack, reason: 'Sign out failed');
      rethrow;
    }
  }
}
```

### 4. Android Configuration

#### android/app/build.gradle

```gradle
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
    id 'com.google.gms.google-services'  // Already added
    id 'com.google.firebase.crashlytics'  // Add this
}

dependencies {
    // ... existing dependencies
}
```

#### android/build.gradle

```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
        classpath 'com.google.firebase:firebase-crashlytics-gradle:2.9.9'  // Add this
    }
}
```

### 5. iOS Configuration

#### ios/Podfile

```ruby
# Crashlytics symbol upload
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)

    # Add Crashlytics
    target.build_configurations.each do |config|
      config.build_settings['DEBUG_INFORMATION_FORMAT'] = 'dwarf-with-dsym'
    end
  end
end
```

#### Xcode Build Phase (for symbol upload)

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner target → Build Phases
3. Click + → New Run Script Phase
4. Add this script:

```bash
"${PODS_ROOT}/FirebaseCrashlytics/run"
```

5. Input Files: `${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/${TARGET_NAME}`
6. Output Files: `${BUILT_PRODUCTS_DIR}/${INFOPLIST_PATH}`

### 6. Install Dependencies

```bash
flutter pub get
cd ios && pod install && cd ..
```

## 📊 Usage Examples

### Basic Error Logging

```dart
import 'package:mix_and_mingle/services/error_tracking_service.dart';

// Log a breadcrumb
ErrorTrackingService().log('User navigated to profile page');

// Record a non-fatal error
try {
  await riskyOperation();
} catch (e, stack) {
  await ErrorTrackingService().recordError(
    e,
    stack,
    reason: 'Failed to load user profile',
    fatal: false,
  );
}
```

### Using ErrorTrackingMixin

```dart
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> with ErrorTrackingMixin {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await trackAsync(
      () => fetchDataFromAPI(),
      operationName: 'Load profile data',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TextButton(
        onPressed: () {
          trackSync(
            () => processData(),
            operationName: 'Process user input',
          );
        },
        child: const Text('Submit'),
      ),
    );
  }
}
```

### Context Extension

```dart
class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Page'),
      ),
      body: ElevatedButton(
        onPressed: () {
          context.logBreadcrumb('Button pressed');
          try {
            // Some operation
          } catch (e, stack) {
            context.reportError(e, stack);
          }
        },
        child: const Text('Action'),
      ),
    );
  }
}
```

### Custom Error Types

```dart
// Network errors
try {
  await fetchData();
} catch (e) {
  throw NetworkError(
    'Failed to fetch data',
    code: 'NETWORK_TIMEOUT',
    originalError: e,
  );
}

// Auth errors
if (user == null) {
  throw AuthError('User not authenticated', code: 'NOT_LOGGED_IN');
}

// Validation errors
if (email.isEmpty) {
  throw ValidationError('Email is required', code: 'EMPTY_EMAIL');
}
```

### Custom Keys for Context

```dart
// Set single key
await ErrorTrackingService().setCustomKey('user_level', 'premium');

// Set multiple keys
await ErrorTrackingService().setCustomKeys({
  'screen': 'profile',
  'feature_flag_enabled': true,
  'experiment_group': 'A',
  'app_language': 'en',
  'device_type': 'mobile',
});
```

### Tracking Critical Operations

```dart
Future<void> processPayment(PaymentInfo payment) async {
  ErrorTrackingService().log('Starting payment processing');

  await ErrorTrackingService().setCustomKeys({
    'payment_amount': payment.amount,
    'payment_currency': payment.currency,
    'payment_method': payment.method,
  });

  try {
    await paymentGateway.charge(payment);
    ErrorTrackingService().log('Payment successful');
  } catch (e, stack) {
    await ErrorTrackingService().recordError(
      e,
      stack,
      reason: 'Payment processing failed',
      fatal: true,
      information: [
        'Amount: ${payment.amount}',
        'Method: ${payment.method}',
      ],
    );
    rethrow;
  }
}
```

## 🔍 Monitoring & Analytics

### Firebase Console

1. **Crashlytics Dashboard**
   - Go to Firebase Console → Crashlytics
   - View crash-free users percentage
   - See most common crashes
   - Track crash trends over time

2. **Issue Details**
   - Stack traces
   - Device info
   - OS versions
   - App versions affected
   - User identifiers (if set)
   - Custom keys
   - Breadcrumb logs

3. **Velocity Alerts**
   - Set up alerts for crash spikes
   - Email notifications
   - Slack integration

### BigQuery Integration

Export crash data to BigQuery for advanced analysis:

```sql
-- Most common crash types
SELECT
  error_type,
  COUNT(*) as crash_count
FROM
  `project.firebase_crashlytics.crashes`
WHERE
  DATE(event_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
GROUP BY
  error_type
ORDER BY
  crash_count DESC
LIMIT 10
```

## 🎯 Best Practices

### 1. Set User Context Early

```dart
// After successful login
await ErrorTrackingService().setUserId(user.uid);
await ErrorTrackingService().setCustomKeys({
  'email': user.email,
  'account_type': user.isPremium ? 'premium' : 'free',
  'signup_date': user.createdAt.toIso8601String(),
});
```

### 2. Log Breadcrumbs Strategically

```dart
// Navigation
ErrorTrackingService().log('Screen: Home → Profile');

// User actions
ErrorTrackingService().log('Action: Sent message to user123');

// State changes
ErrorTrackingService().log('State: Video call started');

// API calls
ErrorTrackingService().log('API: GET /users/profile');
```

### 3. Categorize Errors

```dart
try {
  await fetchData();
} catch (e, stack) {
  if (e is SocketException) {
    // Network error
    throw NetworkError('No internet connection', originalError: e);
  } else if (e is FirebaseAuthException) {
    // Auth error
    throw AuthError(e.message ?? 'Authentication failed', code: e.code);
  } else {
    // Unknown error
    await ErrorTrackingService().recordError(e, stack);
    rethrow;
  }
}
```

### 4. Add Context to Errors

```dart
await ErrorTrackingService().recordError(
  exception,
  stackTrace,
  reason: 'Failed to upload profile photo',
  information: [
    'File size: ${file.lengthSync()} bytes',
    'File type: ${file.path.split('.').last}',
    'User ID: ${currentUser.uid}',
  ],
);
```

### 5. Clear Sensitive Data

```dart
// Before recording error with user input
final sanitizedData = data.copyWith(
  password: '***',
  creditCard: '***',
  ssn: '***',
);

await ErrorTrackingService().recordError(
  exception,
  stackTrace,
  information: [sanitizedData.toString()],
);
```

## 🧪 Testing Crashlytics

### Force a Test Crash

```dart
// Development only!
if (kDebugMode) {
  ErrorTrackingService().testCrash();
}
```

### Test Error Reporting

```dart
// Test non-fatal error
await ErrorTrackingService().recordError(
  Exception('Test error'),
  StackTrace.current,
  reason: 'Testing Crashlytics integration',
  fatal: false,
);
```

### Verify in Console

1. Trigger test crash/error
2. Wait 5-10 minutes for data to appear
3. Check Firebase Console → Crashlytics
4. Verify crash appears with correct metadata

## 📱 Platform-Specific Notes

### Android

- **ProGuard:** Automatically handled by plugin
- **Symbol Upload:** Automatic with gradle plugin
- **NDK Crashes:** Supported for native code crashes
- **Minimum SDK:** API 21+ required

### iOS

- **dSYM Upload:** Automatic via build script
- **Bitcode:** No longer required (deprecated by Apple)
- **Symbol Stripping:** Keep DEBUG_INFORMATION_FORMAT = dwarf-with-dsym
- **Minimum iOS:** 12.0+ required

### Web

- **Limited Support:** No native Crashlytics
- **Alternative:** Use custom error handler
- **Sentry Integration:** Consider for production web

```dart
// Web-specific error tracking
import 'dart:html' as html;

void setupWebErrorTracking() {
  html.window.onError.listen((html.Event event) {
    ErrorTrackingService().log('Web error: ${event.toString()}');
  });
}
```

## 🚨 Handling Specific Error Scenarios

### Network Errors

```dart
try {
  final response = await http.get(url);
} on SocketException catch (e, stack) {
  throw NetworkError(
    'No internet connection',
    code: 'NO_CONNECTION',
    originalError: e,
  );
} on TimeoutException catch (e, stack) {
  throw NetworkError(
    'Request timeout',
    code: 'TIMEOUT',
    originalError: e,
  );
} on HttpException catch (e, stack) {
  throw NetworkError(
    'HTTP error: ${e.message}',
    code: 'HTTP_ERROR',
    originalError: e,
  );
}
```

### Firebase Errors

```dart
try {
  await FirebaseAuth.instance.signInWithEmailAndPassword(
    email: email,
    password: password,
  );
} on FirebaseAuthException catch (e, stack) {
  switch (e.code) {
    case 'user-not-found':
      throw AuthError('No user found', code: e.code);
    case 'wrong-password':
      throw AuthError('Incorrect password', code: e.code);
    case 'user-disabled':
      throw AuthError('Account disabled', code: e.code);
    default:
      throw AuthError(e.message ?? 'Authentication failed', code: e.code);
  }
}
```

### Permission Errors

```dart
final status = await Permission.camera.request();

if (!status.isGranted) {
  throw PermissionError(
    'Camera permission denied',
    code: 'CAMERA_DENIED',
  );
}
```

## 📈 Success Metrics

### Target Goals

- **Crash-Free Rate:** >99.5%
- **Fatal Crashes:** <0.1% of sessions
- **Non-Fatal Errors:** <5% of sessions
- **Mean Time to Resolution:** <24 hours

### Monitoring Dashboard

Track these metrics:
- Daily/weekly crash-free users percentage
- Most common crash types
- Crashes by app version
- Crashes by OS version
- Crashes by device model
- Error velocity (crashes per hour)

## 🔧 Troubleshooting

### Crashes Not Appearing

**Check:**
1. Crashlytics enabled in Firebase Console
2. google-services.json/GoogleService-Info.plist up to date
3. App built in release mode (not debug)
4. Wait 5-10 minutes for data to sync
5. Check Firebase Console → Project Settings → Integrations

### Symbol Upload Failing (iOS)

**Fix:**
```bash
# Manually upload dSYMs
find . -name "*.dSYM" | xargs -I {} $PODS_ROOT/FirebaseCrashlytics/upload-symbols -gsp ios/Runner/GoogleService-Info.plist -p ios {}
```

### ProGuard Issues (Android)

**Fix in android/app/build.gradle:**
```gradle
buildTypes {
    release {
        // Keep Crashlytics
        firebaseCrashlytics {
            mappingFileUploadEnabled true
        }
    }
}
```

## 📚 Additional Resources

- [Firebase Crashlytics Docs](https://firebase.google.com/docs/crashlytics)
- [flutter_crashlytics Plugin](https://pub.dev/packages/firebase_crashlytics)
- [Error Handling Best Practices](https://firebase.google.com/docs/crashlytics/customize-crash-reports)
- [Symbol Upload Guide](https://firebase.google.com/docs/crashlytics/get-deobfuscated-reports)

---

**Status:** ✅ Complete and Production Ready
**Next Priority:** Payment Integration (if applicable)
