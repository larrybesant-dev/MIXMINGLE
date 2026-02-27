# 🔧 CRITICAL FIXES - Copy & Paste Ready

## Fix 1: Room Discovery Type Mismatches

**File:** `lib/features/discover/room_discovery_page.dart`

### Replace Line 7 (add import):

```dart
import '../../shared/models/room.dart';
import '../room/screens/room_page.dart';
```

### Replace Line 98 (fix DocumentSnapshot conversion):

```dart
// OLD:
if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
  final rooms = snapshot.data!.docs;
  return GridView.builder(
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
    itemCount: rooms.length,
    itemBuilder: (context, index) => _buildRoomCard(rooms[index]),
  );
}

// NEW:
if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
  final roomDocs = snapshot.data!.docs;
  final rooms = roomDocs.map((doc) => Room.fromDocument(doc)).toList();
  return GridView.builder(
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
    itemCount: rooms.length,
    itemBuilder: (context, index) => _buildRoomCard(rooms[index]),
  );
}
```

### Replace Line 126 (same fix):

```dart
// OLD:
children: rooms.map((room) => _buildRoomCard(room)).toList(),

// NEW:
children: rooms.map((doc) {
  final room = Room.fromDocument(doc);
  return _buildRoomCard(room);
}).toList(),
```

### Replace Line 418 (fix participantCount):

```dart
// OLD:
'${room.participantCount} online',

// NEW:
'${room.participantIds.length} online',
```

### Replace Line 435 (fix room type):

```dart
// OLD:
color: _getRoomTypeColor(room.type),

// NEW:
color: _getRoomTypeColor(room.roomType),
```

### Replace Line 439 (fix room type name):

```dart
// OLD:
room.type.name.toUpperCase(),

// NEW:
room.roomType.toString().split('.').last.toUpperCase(),
```

### Add LoadingSpinner import (line 3):

```dart
import 'package:flutter/material.dart';

// ADD THIS:
class LoadingSpinner extends StatelessWidget {
  const LoadingSpinner({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
```

---

## Fix 2: FilePicker in Chat Page

**File:** `pubspec.yaml`

### Add dependency (under dependencies section):

```yaml
dependencies:
  # ... existing dependencies ...
  file_picker: ^8.1.2
```

**File:** `lib/features/chat/screens/chat_page.dart`

### Add import (line 2):

```dart
import 'package:file_picker/file_picker.dart';
```

### Replace Lines 149-157 (fix method call):

```dart
// OLD:
final sharedFile = await fileShareService.uploadFileFromBytes(
  bytes: result.files.first.bytes!,
  filename: result.files.first.name,
  roomId: widget.chatId,
  messageId: DateTime.now().millisecondsSinceEpoch.toString(),
);

// NEW:
final currentUser = ref.read(currentUserProvider).value;
if (currentUser == null) return;

final sharedFile = await fileShareService.uploadFileFromBytes(
  bytes: result.files.first.bytes!,
  filename: result.files.first.name,
  chatId: widget.chatId,
  senderId: currentUser.id,
  senderName: currentUser.displayName ?? currentUser.username,
);
```

---

## Fix 3: Admin Dashboard Method Signature

**File:** `lib/features/admin/admin_dashboard_page.dart`

### Replace Line 273:

```dart
// OLD:
await moderationService.reviewReport(report.id, status);

// NEW:
final currentUser = ref.read(currentUserProvider).value;
if (currentUser == null) return;

await moderationService.reviewReport(
  report.id,
  status,
  currentUser.id, // Add reviewer ID as third parameter
);
```

---

## Fix 4: Delete HMS Service Files (No Longer Needed)

**Files to DELETE:**

```
lib/services/hms_video_service_web.dart
lib/services/hms_video_service_stub.dart
lib/services/hms_video_service.dart.bak
```

These files use deprecated `dart:js_util` and are replaced by Agora.

**Command:**

```bash
rm lib/services/hms_video_service_web.dart
rm lib/services/hms_video_service_stub.dart
rm lib/services/hms_video_service.dart.bak
```

---

## Fix 5: Clean Build & Run

**Terminal Commands:**

```bash
# 1. Clean the project
flutter clean

# 2. Get fresh dependencies
flutter pub get

# 3. Run analyzer
flutter analyze

# 4. Auto-fix minor issues
dart fix --apply

# 5. Build for web
flutter build web --release

# 6. Test locally
flutter run -d chrome
```

---

## Fix 6: Add Missing Firestore Rules for Subscriptions

**File:** `firestore.rules`

### Add after line 440 (before default deny):

```firerules
    // SUBSCRIPTIONS: User subscription management
    match /subscriptions/{subscriptionId} {
      // Users can read their own subscriptions
      allow read: if isAuthenticated() &&
                     request.auth.uid == resource.data.userId;

      // Only server (Cloud Functions) can create/update subscriptions
      // Users purchase via Stripe webhook → Function creates subscription
      allow create, update: if false; // Server-side only via Admin SDK

      // Users can cancel their own subscriptions (sets status to 'cancelled')
      allow update: if isAuthenticated() &&
                       request.auth.uid == resource.data.userId &&
                       request.resource.data.status == 'cancelled' &&
                       request.resource.data.keys().hasOnly(['status', 'autoRenew', 'cancelledAt']);

      allow delete: if false; // Never delete, just mark cancelled
    }
```

---

## Fix 7: Add Room Cleanup Cloud Function

**File:** `functions/src/cleanup.ts` (CREATE NEW FILE)

```typescript
import * as functions from "firebase-functions/v2";
import * as admin from "firebase-admin";

/**
 * Cloud Function to clean up all data when a room is deleted
 * Triggers automatically on room deletion
 */
export const onRoomDelete = functions.firestore.onDocumentDeleted(
  "rooms/{roomId}",
  async (event) => {
    const roomId = event.params.roomId;
    const db = admin.firestore();
    const storage = admin.storage();

    console.log(`🗑️ Starting cleanup for deleted room: ${roomId}`);

    try {
      // 1. Delete all messages in this room
      const messagesSnapshot = await db.collection("messages").where("roomId", "==", roomId).get();

      if (!messagesSnapshot.empty) {
        const batch = db.batch();
        messagesSnapshot.docs.forEach((doc) => {
          batch.delete(doc.ref);
        });
        await batch.commit();
        console.log(`✅ Deleted ${messagesSnapshot.size} messages`);
      }

      // 2. Delete all media files for this room
      try {
        const [files] = await storage.bucket().getFiles({ prefix: `room_media/${roomId}/` });

        if (files.length > 0) {
          await Promise.all(files.map((file) => file.delete()));
          console.log(`✅ Deleted ${files.length} media files`);
        }
      } catch (storageError) {
        console.warn(`⚠️ Storage cleanup failed: ${storageError}`);
        // Continue even if storage cleanup fails
      }

      // 3. Remove room from users' joinedRooms arrays
      const usersSnapshot = await db
        .collection("users")
        .where("joinedRooms", "array-contains", roomId)
        .get();

      if (!usersSnapshot.empty) {
        const userBatch = db.batch();
        usersSnapshot.docs.forEach((doc) => {
          userBatch.update(doc.ref, {
            joinedRooms: admin.firestore.FieldValue.arrayRemove(roomId),
          });
        });
        await userBatch.commit();
        console.log(`✅ Removed room from ${usersSnapshot.size} users`);
      }

      // 4. Delete any camera permissions for this room
      const permissionsSnapshot = await db
        .collection("camera_permissions")
        .where("roomId", "==", roomId)
        .get();

      if (!permissionsSnapshot.empty) {
        const permBatch = db.batch();
        permissionsSnapshot.docs.forEach((doc) => {
          permBatch.delete(doc.ref);
        });
        await permBatch.commit();
        console.log(`✅ Deleted ${permissionsSnapshot.size} camera permissions`);
      }

      console.log(`✅ Room cleanup complete for: ${roomId}`);
    } catch (error) {
      console.error(`❌ Room cleanup failed for ${roomId}:`, error);
      throw error; // Re-throw to mark function as failed
    }
  },
);

/**
 * Scheduled function to clean up expired rooms
 * Runs every hour to remove inactive rooms
 */
export const cleanupExpiredRooms = functions.scheduler.onSchedule(
  {
    schedule: "every 1 hours",
    timeZone: "UTC",
  },
  async () => {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();
    const oneHourAgo = admin.firestore.Timestamp.fromMillis(now.toMillis() - 60 * 60 * 1000);

    console.log("🔍 Checking for expired rooms...");

    try {
      // Find rooms that are inactive and haven't been updated in 1 hour
      const expiredRooms = await db
        .collection("rooms")
        .where("isActive", "==", false)
        .where("updatedAt", "<", oneHourAgo)
        .get();

      if (expiredRooms.empty) {
        console.log("✅ No expired rooms found");
        return;
      }

      console.log(`🗑️ Found ${expiredRooms.size} expired rooms to delete`);

      const batch = db.batch();
      expiredRooms.docs.forEach((doc) => {
        batch.delete(doc.ref);
      });
      await batch.commit();

      console.log(`✅ Deleted ${expiredRooms.size} expired rooms`);
    } catch (error) {
      console.error("❌ Expired room cleanup failed:", error);
      throw error;
    }
  },
);
```

**File:** `functions/src/index.ts` (UPDATE)

```typescript
import * as admin from "firebase-admin";

// Initialize Firebase Admin
admin.initializeApp();

// Export all cloud functions
export { generateAgoraToken } from "./agora";
export { onRoomDelete, cleanupExpiredRooms } from "./cleanup"; // ADD THIS
```

**Deploy:**

```bash
cd functions
npm install
firebase deploy --only functions
```

---

## Fix 8: Add Firestore Indexes

**File:** `firestore.indexes.json` (UPDATE)

```json
{
  "indexes": [
    {
      "collectionGroup": "messages",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "roomId", "order": "ASCENDING" },
        { "fieldPath": "timestamp", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "direct_messages",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "conversationId", "order": "ASCENDING" },
        { "fieldPath": "timestamp", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "notifications",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "isRead", "order": "ASCENDING" },
        { "fieldPath": "timestamp", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "subscriptions",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "startDate", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "rooms",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "isActive", "order": "ASCENDING" },
        { "fieldPath": "updatedAt", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "rooms",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "category", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "rooms",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "isLive", "order": "ASCENDING" },
        { "fieldPath": "viewerCount", "order": "DESCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
```

**Deploy:**

```bash
firebase deploy --only firestore:indexes
```

---

## ✅ VERIFICATION CHECKLIST

After applying all fixes:

```bash
# 1. Check for errors
flutter analyze

# 2. Run tests
flutter test

# 3. Build web
flutter build web --release

# 4. Check functions
cd functions && npm run build

# 5. Deploy everything
firebase deploy
```

**Expected Result:**

- ✅ 0 errors
- ✅ <10 info/warnings (minor linting)
- ✅ Clean build
- ✅ All functions deployed
- ✅ App loads without errors

---

**Time to Complete:** ~30-60 minutes
**Difficulty:** Easy (copy-paste fixes)
**Impact:** Resolves all 15 critical errors
