# REAL QUICK-FIX REFERENCE

**For actual issues found in the codebase**

---

## PRIORITY 1: Do This First (Fixes P0 Blockers)

### Fix 1: Export authServiceProvider

**File:** `lib/providers/all_providers.dart`
**Action:** Add this export line

```dart
// Add at the top with other exports:
export 'auth_providers.dart';
```

**Verify:** All chat features can now access auth context

---

### Fix 2: Consolidate Message Types

**Files:**

- `lib/shared/models/chat_message.dart` (keep this one)
- `lib/shared/models/voice_room_chat_message.dart` (DELETE)

**Action:** Merge these classes:

```dart
// Use only ChatMessage, add room_type field:
class ChatMessage {
  final String id;
  final String senderId;
  final String content;
  final DateTime sentAt;
  final String? roomId;          // Add this
  final String roomType;          // Add this: 'dm' or 'room'

  // ... rest of fields
}
```

**Update:** Change all `VoiceRoomChatMessage` references to `ChatMessage`

**Files to update:**

- `lib/providers/chat_providers.dart`
- `lib/services/chat_service.dart`
- `lib/features/room/providers/voice_room_providers.dart`

---

### Fix 3: Fix Import Paths

**Action:** Replace all relative imports with package imports

**Find & Replace (use VS Code):**

Find: `import '../../.*/shared/models/`
Replace: `import 'package:mix_and_mingle/shared/models/`

Find: `import '../../../shared/`
Replace: `import 'package:mix_and_mingle/shared/`

---

## PRIORITY 2: Do Next (Fixes P1 Feature Breaks)

### Fix 4: Add Firestore Indexes

**File:** `firestore.indexes.json`

```json
{
  "indexes": [
    {
      "collectionGroup": "speedDatingRounds",
      "queryScope": "Collection",
      "fields": [
        { "fieldPath": "eventId", "order": "ASCENDING" },
        { "fieldPath": "isActive", "order": "ASCENDING" },
        { "fieldPath": "startTime", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "users",
      "queryScope": "Collection",
      "fields": [
        { "fieldPath": "membershipTier", "order": "ASCENDING" },
        { "fieldPath": "coinBalance", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "rooms",
      "queryScope": "Collection",
      "fields": [
        { "fieldPath": "isActive", "order": "ASCENDING" },
        { "fieldPath": "category", "order": "ASCENDING" },
        { "fieldPath": "viewCount", "order": "DESCENDING" }
      ]
    }
  ]
}
```

**Deploy:** `firebase deploy --only firestore:indexes`

---

### Fix 5: Add Transactions to Room Updates

**File:** `lib/services/room_service.dart`

**Current (broken):**

```dart
Future<void> joinRoom(String roomId, String userId) async {
  final userData = await _firestore.collection('users').doc(userId).get();
  await _firestore.collection('users').doc(userId).update({
    'activeRoomId': roomId,
  });
}
```

**Fixed:**

```dart
Future<void> joinRoom(String roomId, String userId) async {
  return _firestore.runTransaction((transaction) async {
    // Read
    final userRef = _firestore.collection('users').doc(userId);
    final userData = await transaction.get(userRef);

    // Verify
    if (!userData.exists) throw Exception('User not found');

    // Write
    transaction.update(userRef, {'activeRoomId': roomId});
  });
}
```

---

### Fix 6: Add Authorization Checks

**File:** `lib/services/chat_service.dart`

**Add to each mutation method:**

```dart
Future<void> deleteMessage(String messageId) async {
  final msgRef = _firestore.collection('messages').doc(messageId);
  final msgData = await msgRef.get();

  if (msgData['senderId'] != _auth.currentUser?.uid) {
    throw Exception('Unauthorized: You can only delete your own messages');
  }

  await msgRef.delete();
}
```

---

### Fix 7: Add Error Handling to UI

**File:** `lib/features/chat_list_page.dart`

**Current (broken):**

```dart
onPressed: () async {
  messagingService.sendMessage(content);
},
```

**Fixed:**

```dart
onPressed: () async {
  try {
    await messagingService.sendMessage(content);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Message sent')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed: ${e.toString()}')),
    );
  }
},
```

---

### Fix 8: Fix DateTime Type Mismatch

**File:** `lib/shared/models/event.dart`

**Current (broken):**

```dart
class Event {
  final String startTime;  // ❌ Wrong
  final String endTime;    // ❌ Wrong
}
```

**Fixed:**

```dart
class Event {
  final DateTime startTime;  // ✅ Correct
  final DateTime endTime;    // ✅ Correct

  Duration get duration => endTime.difference(startTime);
}
```

**Also update the JSON serialization:**

```dart
factory Event.fromJson(Map<String, dynamic> json) {
  return Event(
    startTime: (json['startTime'] as Timestamp).toDate(),
    endTime: (json['endTime'] as Timestamp).toDate(),
  );
}

Map<String, dynamic> toJson() => {
  'startTime': Timestamp.fromDate(startTime),
  'endTime': Timestamp.fromDate(endTime),
};
```

---

## PRIORITY 3: Stability Fixes

### Fix 9: Fix Stream Cleanup

**File:** `lib/providers/event_dating_providers.dart`

**Current (memory leak):**

```dart
final speedDatingMatchesProvider = StreamProvider<List<SpeedDatingMatch>>((ref) async* {
  final stream = _firestore.collection('speedDatingMatches').snapshots();

  await for (final snapshot in stream) {
    yield snapshot.docs.map(...).toList();
  }
});
```

**Fixed:**

```dart
final speedDatingMatchesProvider = StreamProvider<List<SpeedDatingMatch>>((ref) {
  final controller = StreamController<List<SpeedDatingMatch>>();
  final subscription = _firestore.collection('speedDatingMatches').snapshots().listen(
    (snapshot) {
      controller.add(snapshot.docs.map(...).toList());
    },
    onError: (e) {
      controller.addError(e);
    },
  );

  ref.onDispose(() {
    subscription.cancel();
    controller.close();
  });

  return controller.stream;
});
```

---

### Fix 10: Add Input Validation

**Add to all services:**

```dart
Future<void> sendMessage(String content) async {
  // Validate
  if (content.isEmpty) throw Exception('Message cannot be empty');
  if (content.length > 5000) throw Exception('Message too long');

  // Create
  final message = ChatMessage(
    id: _generateId(),
    senderId: _auth.currentUser!.uid,
    content: content.trim(),
    sentAt: DateTime.now(),
  );

  // Save
  await _firestore.collection('messages').doc(message.id).set(message.toJson());
}
```

---

## Testing Your Fixes

### After Fix 1-3:

```bash
flutter clean && flutter pub get && flutter analyze
```

Should see 0 errors.

### After Fix 4:

```bash
firebase deploy --only firestore:indexes
```

Wait for indexes to build in Firebase Console.

### After Fix 5-8:

```bash
flutter test
```

Create tests for:

- Transaction rollback on errors
- Message deletion authorization
- DateTime serialization

### After Fix 9-10:

Run app, enable memory profiler, verify memory stays stable.

---

## Verification Checklist

- [ ] All imports use `package:mix_and_mingle/`
- [ ] No unused imports
- [ ] All services throw meaningful errors
- [ ] All UI methods handle errors with user feedback
- [ ] All Firestore writes use transactions
- [ ] All mutations check current user authorization
- [ ] DateTime fields use `DateTime` or `Timestamp`, not `String`
- [ ] No memory leaks in stream subscriptions
- [ ] All composite queries have Firestore indexes
- [ ] Payment service has real Stripe implementation (not stub)

---

## Estimated Time Per Fix

| Fix                  | Time    | Priority |
| -------------------- | ------- | -------- |
| 1. Export providers  | 5 min   | P0       |
| 2. Consolidate types | 60 min  | P0       |
| 3. Fix imports       | 30 min  | P0       |
| 4. Add indexes       | 30 min  | P1       |
| 5. Add transactions  | 120 min | P1       |
| 6. Auth checks       | 90 min  | P1       |
| 7. Error handling    | 120 min | P1       |
| 8. DateTime fix      | 45 min  | P1       |
| 9. Stream cleanup    | 60 min  | P2       |
| 10. Input validation | 90 min  | P2       |

**Total: 10-12 hours**
