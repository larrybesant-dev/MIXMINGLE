# Push Notifications Setup Guide

## ✅ Implementation Complete

This guide covers the complete push notification system using Firebase Cloud Messaging (FCM).

## 📁 Files Created

### Services
- `lib/services/push_notification_service.dart` - Core FCM service
  - Token management
  - Foreground/background message handling
  - Topic subscriptions
  - Local notifications

### UI
- `lib/features/notifications/notification_center_page.dart` - In-app notification center
  - Read/unread filtering
  - Mark all as read
  - Individual notification actions
  - Navigation to related content

### Backend
- `functions/push_notifications.js` - Cloud Functions
  - Queue processor for sending notifications
  - Auto-notifications for messages, follows, events
  - Daily event reminders
  - Cleanup old notifications

## 🔧 Setup Instructions

### 1. Firebase Console Setup

#### Android
1. Go to Firebase Console → Project Settings → Cloud Messaging
2. Under "Cloud Messaging API (Legacy)", copy the Server Key
3. Download `google-services.json` and place in `android/app/`
4. In `android/app/build.gradle`, ensure you have:
   ```gradle
   apply plugin: 'com.google.gms.google-services'
   ```

#### iOS
1. Download `GoogleService-Info.plist` and place in `ios/Runner/`
2. In Xcode, enable "Push Notifications" capability
3. Upload APNs Authentication Key to Firebase Console

#### Web
1. Firebase Console → Project Settings → Cloud Messaging → Web Push certificates
2. Generate key pair and copy the VAPID key
3. Update `web/firebase-messaging-sw.js` with your config

### 2. Initialize in App

In your `main.dart`, initialize the service:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/push_notification_service.dart';

// Top-level background handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await firebaseMessagingBackgroundHandler(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Register background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize push notifications
  await PushNotificationService().initialize();

  runApp(const MyApp());
}
```

### 3. Update AuthService

Add FCM token management to login/logout:

```dart
// On login
Future<void> signIn() async {
  // ... existing auth code
  await PushNotificationService().initialize();
}

// On logout
Future<void> signOut() async {
  await PushNotificationService().deleteFCMToken();
  // ... existing signout code
}
```

### 4. Deploy Cloud Functions

```bash
cd functions
npm install firebase-functions firebase-admin
firebase deploy --only functions
```

### 5. Firestore Security Rules

Add these rules to allow notification access:

```
match /notifications/{notificationId} {
  allow read: if request.auth != null &&
              resource.data.userId == request.auth.uid;
  allow write: if false; // Only Cloud Functions can write
}

match /notificationQueue/{queueId} {
  allow read, write: if false; // Only Cloud Functions
}
```

### 6. Test Notifications

#### Send Test Notification
```dart
// In your app code
await PushNotificationService().sendNotificationToUser(
  userId: 'targetUserId',
  title: 'Test Notification',
  body: 'This is a test message',
  type: NotificationType.systemAlert,
  data: {'key': 'value'},
);
```

#### FCM Console Test
1. Firebase Console → Cloud Messaging → Send your first message
2. Enter title, body, and select target (app or topic)
3. Click "Test on device" and select your FCM token

## 📱 Notification Types

The system supports these notification types:

| Type | Trigger | Action |
|------|---------|--------|
| **message** | New direct message | Opens chat conversation |
| **eventInvite** | Event invitation | Opens event details |
| **match** | New match | Opens matches page |
| **follow** | New follower | Opens follower's profile |
| **like** | Profile liked | Opens matches/likes page |
| **eventReminder** | Event starting soon | Opens event details |
| **systemAlert** | Admin message | Opens notification center |

## 🔔 User Experience Flow

### Foreground (App Open)
1. Message received → Local notification shown
2. User taps → Navigates to relevant screen
3. Notification saved to Firestore

### Background (App Closed)
1. Message received → System notification shown
2. User taps → App opens to relevant screen
3. Notification marked as read

### In-App Notification Center
- Badge count on notification icon
- Read/unread filtering
- Swipe actions (mark read, delete)
- Clear all option
- Auto-navigation on tap

## 🎨 Customization

### Notification Channels (Android)

Add custom channels in `push_notification_service.dart`:

```dart
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'This channel is used for important notifications.',
  importance: Importance.high,
);

await _localNotifications
  .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
  ?.createNotificationChannel(channel);
```

### Custom Notification Sounds

1. Add sound file to:
   - Android: `android/app/src/main/res/raw/notification.mp3`
   - iOS: Add to Xcode project → Build Phases → Copy Bundle Resources

2. Update notification details:
```dart
AndroidNotificationDetails(
  'channel_id',
  'Channel Name',
  sound: RawResourceAndroidNotificationSound('notification'),
)
```

### Rich Notifications

Add images/actions:
```dart
AndroidNotificationDetails(
  'channel_id',
  'Channel Name',
  styleInformation: BigPictureStyleInformation(
    FilePathAndroidBitmap(imagePath),
  ),
  actions: [
    AndroidNotificationAction('reply', 'Reply'),
    AndroidNotificationAction('dismiss', 'Dismiss'),
  ],
)
```

## 🔐 Privacy & Permissions

### iOS Info.plist
```xml
<key>UIBackgroundModes</key>
<array>
  <string>remote-notification</string>
</array>
```

### Android Permissions
Already included in `firebase_messaging` plugin:
- `android.permission.INTERNET`
- `android.permission.RECEIVE_BOOT_COMPLETED`
- `com.google.android.c2dm.permission.RECEIVE`

## 📊 Analytics

Track notification engagement:

```dart
void _handleNotificationTap(Map<String, dynamic> data) {
  FirebaseAnalytics.instance.logEvent(
    name: 'notification_opened',
    parameters: {
      'notification_type': data['type'],
      'notification_id': data['id'],
    },
  );
  // ... navigation code
}
```

## 🚨 Troubleshooting

### Notifications Not Received

**Check:**
1. FCM token is saved in Firestore (`users/{userId}/fcmTokens`)
2. Cloud Functions are deployed (`firebase functions:list`)
3. App has notification permissions
4. Device has internet connection
5. Check Cloud Functions logs: `firebase functions:log`

### iOS Issues

**Common fixes:**
1. Enable "Push Notifications" capability in Xcode
2. Upload APNs certificate to Firebase Console
3. Test with production build (not debug)
4. Check Provisioning Profile includes Push Notifications

### Android Issues

**Common fixes:**
1. Verify `google-services.json` is in `android/app/`
2. Check `build.gradle` has Google Services plugin
3. Ensure minimum SDK version ≥ 21
4. Verify app package name matches Firebase

### Token Not Saving

**Check:**
1. User is authenticated (`FirebaseAuth.instance.currentUser != null`)
2. Firestore security rules allow token write
3. No errors in console logs
4. Network connection is stable

## 📈 Monitoring

### Firebase Console Metrics
- Cloud Messaging → Delivery metrics
- Analytics → Events → notification_opened
- Crashlytics → Errors in notification handling

### Custom Monitoring
```dart
// Track notification performance
await FirebaseAnalytics.instance.logEvent(
  name: 'notification_performance',
  parameters: {
    'delivery_time': deliveryTime.inMilliseconds,
    'notification_type': type,
    'opened': true,
  },
);
```

## 🎯 Next Steps

1. **Test on Real Devices** - Test iOS and Android separately
2. **A/B Test Messages** - Use Firebase Remote Config for notification text
3. **Optimize Timing** - Send notifications at optimal times
4. **Segment Users** - Use topics for targeted messaging
5. **Monitor Engagement** - Track open rates and adjust strategy

## 📚 Additional Resources

- [Firebase Cloud Messaging Docs](https://firebase.google.com/docs/cloud-messaging)
- [flutter_local_notifications Plugin](https://pub.dev/packages/flutter_local_notifications)
- [Push Notification Best Practices](https://firebase.google.com/docs/cloud-messaging/concept-options)

---

**Status:** ✅ Complete and Ready for Testing
