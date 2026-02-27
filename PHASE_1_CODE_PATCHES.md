# PHASE 1: Code Patches — Ready to Apply

**Use these exact code changes to execute Phase 1 fixes**

---

## Patch #1: authServiceProvider Export

**Status:** ✅ Already in place — No action needed

- `authServiceProvider` is defined in `auth_providers.dart` ✓
- `auth_providers.dart` is exported in `all_providers.dart` ✓

---

## Patch #2: Import Path Fixes

### Automated Fix via Find & Replace

Open **Find & Replace** in VS Code (Ctrl+H):

**Replace 1:**

- Find: `import '../../shared/`
- Replace: `import 'package:mix_and_mingle/shared/`
- Click: **Replace All**

**Replace 2:**

- Find: `import '../../../shared/`
- Replace: `import 'package:mix_and_mingle/shared/`
- Click: **Replace All**

**Replace 3:**

- Find: `import '../../../features/`
- Replace: `import 'package:mix_and_mingle/features/`
- Click: **Replace All**

**Replace 4:**

- Find: `import '../../features/`
- Replace: `import 'package:mix_and_mingle/features/`
- Click: **Replace All**

---

## Patch #3: Firestore Indexes

### Code to Add to `firestore.indexes.json`

If the file doesn't exist, create it at the root. If it exists, add these indexes to the `"indexes"` array:

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

### Deploy Indexes

```bash
firebase deploy --only firestore:indexes
```

---

## Patch #4: ChatMessage Consolidation

### Step 1: Update Model

**File:** `lib/shared/models/chat_message.dart`

Add these fields to the ChatMessage class:

```dart
class ChatMessage {
  final String id;
  final String senderId;
  final String content;
  final DateTime sentAt;

  // ADD THESE FIELDS:
  final String? roomId;           // null for DMs, room ID for room messages
  final String roomType;          // 'dm' or 'room'
  final String? receiverId;       // for DMs: who receives this message

  // ... rest of existing fields ...

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.content,
    required this.sentAt,
    this.roomId,                  // NEW
    this.roomType = 'dm',         // NEW - default to 'dm'
    this.receiverId,              // NEW
    // ... rest of existing parameters ...
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      content: json['content'] as String,
      sentAt: (json['sentAt'] as Timestamp).toDate(),
      roomId: json['roomId'] as String?,
      roomType: json['roomType'] as String? ?? 'dm',
      receiverId: json['receiverId'] as String?,
      // ... rest of existing fields ...
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'senderId': senderId,
    'content': content,
    'sentAt': Timestamp.fromDate(sentAt),
    'roomId': roomId,
    'roomType': roomType,
    'receiverId': receiverId,
    // ... rest of existing fields ...
  };
}
```

### Step 2: Replace All Type References

Open **Find & Replace** (Ctrl+H):

**Replace:**

- Find: `VoiceRoomChatMessage`
- Replace: `ChatMessage`
- Click: **Replace All**

---

## Patch #5: DateTime Field Fixes

### Find problematic fields first:

```bash
grep -rn "final String.*[Tt]ime" lib/shared/models/ --include="*.dart"
```

### Common DateTime Fixes

#### Fix in `lib/shared/models/event.dart`

**Before:**

```dart
class Event {
  final String startTime;
  final String endTime;
  // ...

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      // ...
    );
  }

  Map<String, dynamic> toJson() => {
    'startTime': startTime,
    'endTime': endTime,
    // ...
  };
}
```

**After:**

```dart
class Event {
  final DateTime startTime;
  final DateTime endTime;
  // ...

  Duration get duration => endTime.difference(startTime);

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      startTime: (json['startTime'] as Timestamp).toDate(),
      endTime: (json['endTime'] as Timestamp).toDate(),
      // ...
    );
  }

  Map<String, dynamic> toJson() => {
    'startTime': Timestamp.fromDate(startTime),
    'endTime': Timestamp.fromDate(endTime),
    // ...
  };
}
```

#### Fix in `lib/shared/models/speed_dating_round.dart`

**Pattern:** Replace all `String` time fields with `DateTime`:

```dart
// Before:
final String startTime;
final String endTime;
final String roundStartTime;

// After:
final DateTime startTime;
final DateTime endTime;
final DateTime roundStartTime;
```

And in factory:

```dart
// Before:
startTime: json['startTime'] as String,

// After:
startTime: (json['startTime'] as Timestamp).toDate(),
```

#### Fix in `lib/shared/models/room.dart`

```dart
// Before:
final String createdAt;
final String? lastActivityTime;

// After:
final DateTime createdAt;
final DateTime? lastActivityTime;
```

### Update Usage Sites

**Find usages:**

```bash
grep -rn "\.startTime\|\.endTime\|\.createdAt" lib/ --include="*.dart" | head -30
```

For each usage, convert from string parsing to DateTime methods:

**Before:**

```dart
if (int.parse(event.startTime) > 1000) { ... }
```

**After:**

```dart
if (event.startTime.millisecondsSinceEpoch > 1000) { ... }
```

Or simpler:

```dart
if (event.startTime.isAfter(DateTime.now())) { ... }
```

---

## Patch #6: Provider Export Audit

### Check these core providers are exported in `all_providers.dart`:

```dart
// lib/providers/all_providers.dart should have these exports:

export 'auth_providers.dart';                        // ✓
export 'user_providers.dart';                        // ✓
export 'chat_providers.dart';                        // ✓
export 'messaging_providers.dart';                   // ✓
export 'room_providers.dart';                        // ✓
export 'event_dating_providers.dart';                // ✓
export 'gamification_payment_providers.dart';        // ✓
export 'match_providers.dart';                       // ✓
export 'broadcaster_providers.dart';                 // ✓
export 'camera_providers.dart';                      // ✓
export 'mic_providers.dart';                         // ✓
export 'video_media_providers.dart';                 // ✓
export 'agora_participant_provider.dart';            // ✓
export 'agora_video_tile_provider.dart';             // ✓
export 'user_display_name_provider.dart';            // ✓
```

### If any feature modules define providers, add:

```dart
// For any providers in lib/features/*/providers/:
export '../features/matching/providers/matching_providers.dart';
export '../features/rooms/providers/room_providers.dart';
```

---

## 🔧 Quick Terminal Commands to Apply Patches

### Apply all import fixes at once (from project root):

```bash
cd c:\Users\LARRY\MIXMINGLE

# Find all problematic imports
grep -rn "import '\.\./\.\./\.\." lib/ --include="*.dart"

# Use VS Code Find & Replace to fix them
# (Or manually edit flagged files)
```

### Test after each patch:

```bash
flutter clean
flutter pub get
flutter analyze
```

### After all patches complete:

```bash
flutter test test/providers_accessibility_test.dart
```

---

## ✅ Patch Application Order

1. **Patch #1** — No action (already done)
2. **Patch #2** — Import fixes (VS Code Find & Replace)
3. **Patch #3** — Firestore indexes (update `firestore.indexes.json`, deploy)
4. **Patch #4** — ChatMessage consolidation (update model, replace type references)
5. **Patch #5** — DateTime fixes (update models, usage sites)
6. **Patch #6** — Provider audit (verify exports in `all_providers.dart`)

Each patch is independent — you can apply them in any order, but #1-#3 are fastest.

---

## 📝 Verification After Each Patch

After applying each patch, run:

```bash
flutter analyze
```

Expected output:

- 0 Dart errors
- (Markdown warnings are fine for this phase)

If errors appear, they'll tell you exactly which line to fix.
