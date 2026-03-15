# TODO Implementation Plan

_Generated: January 28, 2026_

## ✅ Completed (Just Implemented)

### Week 1: Core UX (January 28, 2026)

- ✅ Push notification navigation (4 TODOs)
  - Navigate to chat from notification
  - Navigate to event from notification
  - Navigate to profile from notification
  - Navigate to room from notification
- ✅ Event detail navigation (2 TODOs)
- ✅ Chat search functionality
- ✅ Image upload for events
- ✅ File attachments in chat

### Week 2: User Management (January 28, 2026)

- ✅ Block user functionality
- ✅ Report user functionality

## 🔴 High Priority (Blocking User Experience)

### Chat Features

1. **Create/Find Chat with User** `lib/features/chat/screens/chat_page.dart:75`

   ```dart
   // Current: Uses temp chatId
   // Solution: Implement ChatService.getOrCreateDirectChat(userId)
   ```

2. **User Search** `lib/features/chat_list_page.dart:222`

   ```dart
   // Solution: Use FirestoreService.searchUsers(query) with Algolia or Firestore
   ```

3. ✅ **Block User** - IMPLEMENTED
4. ✅ **Report User** - IMPLEMENTED

5. ✅ **File Attachment** - IMPLEMENTED

### Event Features

6. ✅ **Image Upload** - IMPLEMENTED
7. ✅ **Image Picker** - IMPLEMENTED

8. **Location Service** `lib/features/create_event_page.dart:152-153`

   ```dart
   // Solution: Use geolocator package or location picker
   ```

9. ✅ **Navigate to Event Detail** - IMPLEMENTED

### Search & Filter

10. ✅ **Chat Search** - IMPLEMENTED

11. **Event Search** `lib/features/events_page.dart:455`

    ```dart
    // Solution: Implement event search with Firestore query or Algolia
    ```

12. **Event Filter** `lib/features/events_page.dart:516`

    ```dart
    // Solution: Add filter bottom sheet with category, date, location
    ```

13. **Room Filter** `lib/features/browse/screens/browse_rooms_paginated_page.dart:52`
    ```dart
    // Solution: Add filter modal with category, type, participant count
    ```

### Account Settings

14. **Account Deletion** `lib/features/settings/account_settings_page.dart:45`

    ```dart
    // Solution: Implement AuthService.deleteAccount() with cleanup
    ```

15. **Change Email** `lib/features/settings/account_settings_page.dart:113`

    ```dart
    // Solution: Navigate to change email page with re-authentication
    ```

16. **Change Password** `lib/features/settings/account_settings_page.dart:125`

    ```dart
    // Solution: Navigate to change password page with re-authentication
    ```

17. **Facebook Linking** `lib/features/settings/account_settings_page.dart:169`

    ```dart
    // Solution: Implement firebase_auth Facebook provider linking
    ```

18. **Google Linking** `lib/features/settings/account_settings_page.dart:181`
    ```dart
    // Solution: Implement firebase_auth Google provider linking
    ```

## 🟡 Medium Priority (Feature Enhancement)

### Navigation

19. **Navigate to Edit Event** - 3 occurrences
    - `lib/features/event_details_page.dart:126`
    - `lib/features/events_page.dart:300`
    - `lib/features/events/screens/event_details_screen.dart:355`

20. **Navigate to Speed Dating** `lib/features/event_details_page.dart:292`

21. **Navigate to Notifications** `lib/features/home_page.dart:83`

### Room Features

22. **Show Participants List** `lib/features/room/room_page.dart:351`

    ```dart
    // Solution: Create ParticipantsListModal with user tiles
    ```

23. **Share Room Link** `lib/features/room/room_page.dart:359`
    ```dart
    // Solution: Use share_plus package with deep link
    ```

### Notifications

24. **Mark All as Read** `lib/features/notifications/screens/notifications_paginated_page.dart:82`

    ```dart
    // Solution: NotificationService.markAllAsRead()
    ```

25. **Delete Notification** `lib/features/notifications/screens/notifications_paginated_page.dart:94`

    ```dart
    // Solution: NotificationService.deleteNotification(id)
    ```

26. **Fix Notifications Stream** `lib/features/notifications/screens/notifications_page.dart:21`

    ```dart
    // Solution: Use NotificationService.getNotificationsStream(userId)
    ```

27. **Mark as Read and Navigate** `lib/features/notifications/notifications_page.dart:178`
    ```dart
    // Solution: Combine markAsRead + navigation based on type
    ```

### Profile

28. **Photo Picker** `lib/features/profile_page.dart:186`

    ```dart
    // Solution: Use image_picker + crop + Firebase Storage
    ```

29. **User by ID Provider** `lib/features/profile/profile_page.dart:762`
    ```dart
    // Solution: Create userByIdProvider with Firestore fetch
    ```

### UI/UX

30. **Theme Settings** `lib/features/settings/screens/settings_page.dart:208`

    ```dart
    // Solution: Implement theme mode switcher (light/dark/system)
    ```

31. **Theme Mode Provider** `lib/shared/widgets/club_background.dart:19`
    ```dart
    // Solution: Create themeModeProvider with SharedPreferences
    ```

## 🟢 Low Priority (Backend/Advanced Features)

### Payment Integration

32. **Payment Service** `lib/services/payment_service.dart:87`
    ```dart
    // Solution: Integrate Stripe SDK for actual payment processing
    // Dependencies: stripe_checkout, cloud functions for webhook
    ```

### Data Features

33. **Parse Mentions** `lib/services/messaging_service.dart:582`

    ```dart
    // Solution: Regex to extract @username mentions
    ```

34. **Location-based Events** - 2 occurrences
    - `lib/providers/event_dating_providers.dart:256`
    - `lib/providers/events_controller.dart:47`

    ```dart
    // Solution: Implement Firestore geoqueries with geoflutterfire
    ```

35. **Category Filtering** `lib/providers/events_controller.dart:53`

    ```dart
    // Solution: Add category field to Event model + Firestore query
    ```

36. **Event Search** `lib/providers/event_dating_providers.dart:305`

    ```dart
    // Solution: Algolia integration or Firestore compound queries
    ```

37. **User Created Events** `lib/providers/events_controller.dart:21`

    ```dart
    // Solution: Add getMyEvents() query filtering by hostId
    ```

38. **Fetch Leaderboard** `lib/providers/gamification_payment_providers.dart:482`
    ```dart
    // Solution: Firestore query ordered by points/xp
    ```

### Speed Dating

39. **Fix Timer Provider** `lib/features/speed_dating/speed_dating_room_page.dart:80`
40. **Get Actual User Name** `lib/features/speed_dating/speed_dating_room_page.dart:347`
41. **Fix Speed Dating Lobby** `lib/features/speed_dating/speed_dating_room_page.dart:463`

### Moderation

42. **Get Moderator ID from Auth** `lib/features/moderation/widgets/mod_actions_panel.dart:161`
    ```dart
    // Solution: Use ref.read(authServiceProvider).currentUser?.uid
    ```

## 📋 Documentation TODOs (In Markdown Files)

These are example TODOs in documentation files - not requiring code changes:

- `VOICE_ROOM_QUICK_START.md`
- `VOICE_ROOM_DEPLOYMENT_READY.md`
- `VOICE_ROOM_COMPLETE.md`
- `REAL_DIAGNOSTIC_REPORT.md`
- `QUICK_FIX_REFERENCE.md`
- `MASTER_DIAGNOSTIC_REPORT.md`
- `FULL_PROJECT_VALIDATION_REPORT.md`
- `COMPREHENSIVE_REPAIR_AUDIT.md`

## 🛠️ Implementation Priority Order

### Week 1: Core UX

1. ✅ Push notification navigation (DONE)
2. Event detail navigation
3. Chat search functionality
4. Image upload for events
5. File attachments in chat

### Week 2: User Management

6. ✅ Block user (DONE)
7. ✅ Report user (DONE)
8. Account deletion
9. Social login linking
10. Photo picker for profile
11. User search

### Week 3: Features

11. Room/Event filters
12. Notifications CRUD
13. Theme settings
14. Participants list
15. Share functionality

### Week 4: Advanced

16. Location-based events
17. Payment integration
18. Event search (Algolia)
19. Category filtering
20. Speed dating fixes

## 📦 Required Dependencies

Add these to `pubspec.yaml` as needed:

```yaml
dependencies:
  # Image handling
  image_picker: ^1.0.4
  image_cropper: ^5.0.0

  # File handling
  file_picker: ^6.0.0

  # Location
  geolocator: ^10.1.0
  geocoding: ^2.1.1
  geoflutterfire_plus: ^0.0.2

  # Sharing
  share_plus: ^7.2.1

  # Payment
  stripe_checkout: ^4.0.1

  # Search
  algolia: ^1.1.2
```

## 🔧 Quick Implementation Templates

### Image Picker Template

```dart
import 'package:image_picker/image_picker.dart';

Future<String?> pickAndUploadImage() async {
  final picker = ImagePicker();
  final image = await picker.pickImage(source: ImageSource.gallery);

  if (image == null) return null;

  // Upload to Firebase Storage
  final ref = FirebaseStorage.instance
      .ref()
      .child('images/${DateTime.now().millisecondsSinceEpoch}.jpg');
  await ref.putFile(File(image.path));
  return await ref.getDownloadURL();
}
```

### Search Implementation Template

```dart
Future<List<T>> searchItems<T>(String query, String collection) async {
  final snapshot = await FirebaseFirestore.instance
      .collection(collection)
      .where('searchTerms', arrayContains: query.toLowerCase())
      .limit(20)
      .get();

  return snapshot.docs.map((doc) => /* parse T */).toList();
}
```

### Filter Modal Template

```dart
void showFilterModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (context) => FilterBottomSheet(
      onApply: (filters) {
        // Apply filters
      },
    ),
  );
}
```

---

**Total TODOs:** 98 found
**Implemented:** 12 (Push notifications, Week 1 Core UX, Block/Report)
**Remaining:** 86
**High Priority:** ~38
**Documentation Only:** ~15
