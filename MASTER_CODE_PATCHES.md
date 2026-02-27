# MASTER CODE PATCHES - MixMingle Project

**Date:** January 26, 2025
**Based on:** MASTER_DIAGNOSTIC_REPORT.md + MASTER_FIX_PLAN.md
**Total Patches:** 115 code fixes organized by phase

---

## HOW TO USE THIS DOCUMENT

Each patch follows this format:

````
### PATCH-XXX: [Description]
**File:** path/to/file.dart:line
**Severity:** P0/P1/P2/P3
**Phase:** 1/2/3/4
**Time:** X minutes

**Problem:**
[What's broken]

**Before:**
```dart
// Old code
````

**After:**

```dart
// Fixed code
```

**Why This Works:**
[Explanation]

**Dependencies:**
[What must be fixed before/after]

````

---

## PHASE 1 PATCHES: FOUNDATION FIXES

### PATCH-001: Fix ModerationService VoiceRoomChatMessage (Line 79)
**File:** [lib/features/room/services/room_moderation_service.dart](lib/features/room/services/room_moderation_service.dart#L79)
**Severity:** 🔴 P0
**Phase:** 1
**Time:** 3 minutes

**Problem:**
- Line 79 uses VoiceRoomChatMessage.system() but sendMessage() expects ChatMessage
- Type mismatch causes compilation error

**Before:**
```dart
// Line 70-82
// Add system message
final participantDoc =
    await _firestore.collection('rooms').doc(roomId).collection('participants').doc(targetUserId).get();

final targetName = participantDoc.exists ? (participantDoc.data()?['displayName'] as String? ?? 'User') : 'User';

await _repository.sendMessage(
  roomId: roomId,
  message: VoiceRoomChatMessage.system(
    message: '$targetName was kicked${reason != null ? ": $reason" : ""}',
    timestamp: DateTime.now(),
  ),
);
````

**After:**

```dart
// Line 70-82
// Add system message
final participantDoc =
    await _firestore.collection('rooms').doc(roomId).collection('participants').doc(targetUserId).get();

final targetName = participantDoc.exists ? (participantDoc.data()?['displayName'] as String? ?? 'User') : 'User';

await _repository.sendMessage(
  roomId: roomId,
  message: ChatMessage.system(
    content: '$targetName was kicked${reason != null ? ": $reason" : ""}',
    roomId: roomId,
    timestamp: DateTime.now(),
  ),
);
```

**Why This Works:**

- ChatMessage has a factory constructor `ChatMessage.system()` defined at shared/models/chat_message.dart lines 43-54
- Uses `content` field instead of `message`
- Requires `roomId` parameter (which we have)
- sendMessage() accepts ChatMessage type

**Dependencies:** None (ChatMessage already exists)

---

### PATCH-002: Fix ModerationService VoiceRoomChatMessage (Line 126)

**File:** [lib/features/room/services/room_moderation_service.dart](lib/features/room/services/room_moderation_service.dart#L126)
**Severity:** 🔴 P0
**Phase:** 1
**Time:** 3 minutes

**Problem:**

- Line 126 uses VoiceRoomChatMessage.system() (same issue as PATCH-001)

**Before:**

```dart
// Line 123-130
// Add system message
await _repository.sendMessage(
  roomId: roomId,
  message: VoiceRoomChatMessage.system(
    message: '$targetName was banned${reason != null ? ": $reason" : ""}',
    timestamp: DateTime.now(),
  ),
);
```

**After:**

```dart
// Line 123-130
// Add system message
await _repository.sendMessage(
  roomId: roomId,
  message: ChatMessage.system(
    content: '$targetName was banned${reason != null ? ": $reason" : ""}',
    roomId: roomId,
    timestamp: DateTime.now(),
  ),
);
```

**Why This Works:**

- Same reasoning as PATCH-001
- ChatMessage.system() factory constructor handles system messages
- Uses correct field names (content instead of message)

**Dependencies:** PATCH-001 (both in same file, fix together)

---

### PATCH-003: Fix ProfileController Ambiguous Export

**File:** [lib/providers/all_providers.dart](lib/providers/all_providers.dart#L59)
**Severity:** 🔴 P0
**Phase:** 1
**Time:** 2 minutes

**Problem:**

- ProfileController exported from both user_providers.dart and profile_controller.dart
- Hide clause incomplete (hides 5 providers but not ProfileController class)

**Before:**

```dart
// Line 59-64
// Profile controller (hide providers to avoid conflicts with user_providers)
export 'profile_controller.dart'
    hide
        profileServiceProvider,
        currentUserProfileProvider,
        userProfileProvider,
        nearbyUsersProvider,
        searchUsersByInterestsProvider;
```

**After:**

```dart
// Line 59-65
// Profile controller (hide providers to avoid conflicts with user_providers)
export 'profile_controller.dart'
    hide
        profileServiceProvider,
        currentUserProfileProvider,
        userProfileProvider,
        nearbyUsersProvider,
        searchUsersByInterestsProvider,
        ProfileController;  // Add this line
```

**Why This Works:**

- Hides the ProfileController class from profile_controller.dart
- Allows user_providers.dart version to be the canonical export
- Resolves ambiguous export error

**Dependencies:** None

---

### PATCH-004: Fix analytics_dashboard Invalid Constant (REQUIRES INVESTIGATION)

**File:** [lib/features/analytics/widgets/analytics_dashboard_widget.dart](lib/features/analytics/widgets/analytics_dashboard_widget.dart#L394)
**Severity:** 🟠 P1
**Phase:** 1
**Time:** 10 minutes

**Problem:**

- Invalid constant value on line 394
- Need to read file to determine exact issue

**Investigation Steps:**

1. Read file lines 390-400
2. Identify what's marked `const` but contains non-const value
3. Either remove `const` keyword or make value const

**Possible Pattern 1: Non-const widget marked const**

```dart
// WRONG:
const MyWidget(
  child: someComputedValue,  // Not const!
)

// FIX:
MyWidget(  // Remove const
  child: someComputedValue,
)
```

**Possible Pattern 2: Const list with non-const elements**

```dart
// WRONG:
const items = [
  widget1,  // Not const!
  widget2,
];

// FIX:
final items = [  // Change to final
  widget1,
  widget2,
];
```

**Why This Works:**

- const requires all nested values to be const
- If value is computed at runtime, use final instead
- If widget takes non-const parameters, remove const

**Dependencies:** Requires reading file first

**Action Required:** Read file and apply appropriate fix

---

### PATCH-005: Fix room_moderation_widget Undefined Getter (REQUIRES INVESTIGATION)

**File:** [lib/features/moderation/widgets/room_moderation_widget.dart](lib/features/moderation/widgets/room_moderation_widget.dart#L196)
**Severity:** 🟠 P1
**Phase:** 1
**Time:** 10 minutes

**Problem:**

- Accessing `.data` property on a Widget (which doesn't have .data)
- Likely wrong variable reference or missing AsyncValue pattern

**Investigation Steps:**

1. Read file lines 190-200
2. Identify what variable is being used
3. Check if should be using AsyncValue.when() instead

**Possible Pattern 1: Wrong variable**

```dart
// WRONG:
final widget = SomeWidget();
final value = widget.data;  // Widget has no 'data' property

// FIX:
final asyncValue = ref.watch(someProvider);
final value = asyncValue.value;  // Or use .when()
```

**Possible Pattern 2: Missing AsyncValue handling**

```dart
// WRONG:
final data = someProvider;
return Text(data.data.toString());  // someProvider is AsyncValue

// FIX:
final dataAsync = ref.watch(someProvider);
return dataAsync.when(
  data: (data) => Text(data.toString()),
  loading: () => CircularProgressIndicator(),
  error: (err, stack) => Text('Error: $err'),
);
```

**Why This Works:**

- AsyncValue has .value, .asData, .when() methods
- Widget does not have .data property
- Must use correct type for each variable

**Dependencies:** Requires reading file first

**Action Required:** Read file and apply appropriate fix

---

## PHASE 2 PATCHES: CONCURRENCY HARDENING

### PATCH-006 to PATCH-020: Fix BuildContext Async Gaps (15 patches)

**Severity:** 🟡 P2
**Phase:** 2
**Time:** 5-10 minutes each

**Problem:**

- Using BuildContext after async operations without checking if widget is mounted
- Can cause crashes if widget disposed during async operation

**Pattern (applies to all 15 occurrences):**

```dart
// WRONG:
Future<void> _doSomething() async {
  await someAsyncOperation();
  Navigator.of(context).push(...);  // ❌ May crash if widget unmounted
}

// CORRECT:
Future<void> _doSomething() async {
  await someAsyncOperation();
  if (!mounted) return;  // ✅ Check if still mounted
  Navigator.of(context).push(...);
}
```

**Files to Fix (15 total - see flutter analyze output):**
Search for pattern: `await.*\n.*context\.` to find all occurrences

**Why This Works:**

- mounted property is true while widget is in tree
- After async operation, widget may have been disposed
- Checking mounted prevents using stale BuildContext

**Dependencies:** None

---

### PATCH-021: Add Transaction to SpeedDatingService.assignPartners()

**File:** [lib/services/speed_dating_service.dart](lib/services/speed_dating_service.dart)
**Severity:** 🟡 P2
**Phase:** 2
**Time:** 15 minutes

**Problem:**

- Partner assignment not atomic
- Race condition if two rounds try to assign same partner

**Before:**

```dart
Future<void> assignPartners(String sessionId, Map<String, String> assignments) async {
  final docRef = _firestore.collection('speedDatingSessions').doc(sessionId);
  final snapshot = await docRef.get();

  if (!snapshot.exists) throw Exception('Session not found');

  final data = Map<String, dynamic>.from(snapshot.data()!);
  data['partnerAssignments'] = assignments;
  data['updatedAt'] = FieldValue.serverTimestamp();

  await docRef.update(data);
  // ❌ Race condition: Another update could happen between get and update
}
```

**After:**

```dart
Future<void> assignPartners(String sessionId, Map<String, String> assignments) async {
  final docRef = _firestore.collection('speedDatingSessions').doc(sessionId);

  await _firestore.runTransaction((transaction) async {
    final snapshot = await transaction.get(docRef);

    if (!snapshot.exists) {
      throw Exception('Session not found');
    }

    final data = Map<String, dynamic>.from(snapshot.data()!);
    data['partnerAssignments'] = assignments;
    data['updatedAt'] = FieldValue.serverTimestamp();

    transaction.update(docRef, data);
  });
  // ✅ Safe: Atomic operation, no race conditions
}
```

**Why This Works:**

- runTransaction() ensures atomicity
- Read and write happen in same transaction
- Firestore handles concurrent writes correctly
- If another transaction modifies document, this one retries

**Dependencies:** None (Firestore transactions built-in)

---

### PATCH-022: Add Transaction to RoomService.addParticipant()

**File:** [lib/services/room_service.dart](lib/services/room_service.dart)
**Severity:** 🟡 P2
**Phase:** 2
**Time:** 15 minutes

**Problem:**

- Participant count not updated atomically
- Could exceed max participants if multiple users join simultaneously

**Before:**

```dart
Future<void> addParticipant(String roomId, String userId) async {
  final roomRef = _firestore.collection('rooms').doc(roomId);
  final room = await roomRef.get();

  final participantCount = room.data()?['participantCount'] as int? ?? 0;
  final maxParticipants = room.data()?['maxParticipants'] as int? ?? 200;

  if (participantCount >= maxParticipants) {
    throw Exception('Room is full');
  }

  await roomRef.update({
    'participantCount': participantCount + 1,
  });

  await roomRef.collection('participants').doc(userId).set({
    'userId': userId,
    'joinedAt': FieldValue.serverTimestamp(),
  });
  // ❌ Race condition: Two users could join at same time and exceed max
}
```

**After:**

```dart
Future<void> addParticipant(String roomId, String userId) async {
  final roomRef = _firestore.collection('rooms').doc(roomId);

  await _firestore.runTransaction((transaction) async {
    final room = await transaction.get(roomRef);

    final participantCount = room.data()?['participantCount'] as int? ?? 0;
    final maxParticipants = room.data()?['maxParticipants'] as int? ?? 200;

    if (participantCount >= maxParticipants) {
      throw Exception('Room is full');
    }

    transaction.update(roomRef, {
      'participantCount': participantCount + 1,
    });
  });

  // Add participant doc outside transaction (not critical for atomicity)
  await roomRef.collection('participants').doc(userId).set({
    'userId': userId,
    'joinedAt': FieldValue.serverTimestamp(),
  });
  // ✅ Safe: Participant count updated atomically
}
```

**Why This Works:**

- Ensures max participants check and increment are atomic
- Multiple simultaneous joins won't exceed limit
- Firestore retries transaction if conflict detected

**Dependencies:** None

---

### PATCH-023: Add Transaction to CoinEconomyService.addCoins()

**File:** [lib/services/coin_economy_service.dart](lib/services/coin_economy_service.dart)
**Severity:** 🟡 P2
**Phase:** 2
**Time:** 15 minutes

**Problem:**

- Coin balance updates not atomic
- Could lose coins if concurrent additions occur

**Before:**

```dart
Future<void> addCoins(String userId, int amount, String source) async {
  final userRef = _firestore.collection('users').doc(userId);
  final user = await userRef.get();

  final currentBalance = user.data()?['coinBalance'] as int? ?? 0;
  final newBalance = currentBalance + amount;

  await userRef.update({'coinBalance': newBalance});

  // Record transaction
  await _firestore.collection('transactions').add({
    'userId': userId,
    'amount': amount,
    'type': 'credit',
    'source': source,
    'timestamp': FieldValue.serverTimestamp(),
  });
  // ❌ Race condition: Concurrent additions could lose coins
}
```

**After:**

```dart
Future<void> addCoins(String userId, int amount, String source) async {
  final userRef = _firestore.collection('users').doc(userId);

  await _firestore.runTransaction((transaction) async {
    final user = await transaction.get(userRef);

    final currentBalance = user.data()?['coinBalance'] as int? ?? 0;
    final newBalance = currentBalance + amount;

    transaction.update(userRef, {'coinBalance': newBalance});
  });

  // Record transaction outside (can be eventually consistent)
  await _firestore.collection('transactions').add({
    'userId': userId,
    'amount': amount,
    'type': 'credit',
    'source': source,
    'timestamp': FieldValue.serverTimestamp(),
  });
  // ✅ Safe: Balance updated atomically
}
```

**Why This Works:**

- Balance read and write are atomic
- No coins lost in concurrent operations
- Transaction log outside transaction is acceptable (eventual consistency)

**Dependencies:** None

---

### PATCH-024: Add Transaction to CoinEconomyService.spendCoins()

**File:** [lib/services/coin_economy_service.dart](lib/services/coin_economy_service.dart)
**Severity:** 🟡 P2
**Phase:** 2
**Time:** 15 minutes

**Problem:**

- Could spend more coins than available if concurrent spends

**Before:**

```dart
Future<void> spendCoins(String userId, int amount, String purpose) async {
  final userRef = _firestore.collection('users').doc(userId);
  final user = await userRef.get();

  final currentBalance = user.data()?['coinBalance'] as int? ?? 0;

  if (currentBalance < amount) {
    throw Exception('Insufficient coins');
  }

  final newBalance = currentBalance - amount;
  await userRef.update({'coinBalance': newBalance});
  // ❌ Could spend more than available in race condition
}
```

**After:**

```dart
Future<void> spendCoins(String userId, int amount, String purpose) async {
  final userRef = _firestore.collection('users').doc(userId);

  await _firestore.runTransaction((transaction) async {
    final user = await transaction.get(userRef);

    final currentBalance = user.data()?['coinBalance'] as int? ?? 0;

    if (currentBalance < amount) {
      throw Exception('Insufficient coins');
    }

    final newBalance = currentBalance - amount;
    transaction.update(userRef, {'coinBalance': newBalance});
  });

  // Record transaction
  await _firestore.collection('transactions').add({
    'userId': userId,
    'amount': -amount,
    'type': 'debit',
    'purpose': purpose,
    'timestamp': FieldValue.serverTimestamp(),
  });
  // ✅ Safe: Balance check and update are atomic
}
```

**Why This Works:**

- Prevents negative balance from concurrent spends
- Balance check and decrement are atomic
- Firestore retries if conflict

**Dependencies:** None

---

### PATCH-025: Add Transaction to TippingService.sendTip()

**File:** [lib/services/tipping_service.dart](lib/services/tipping_service.dart)
**Severity:** 🟡 P2
**Phase:** 2
**Time:** 20 minutes

**Problem:**

- Tip transfers not atomic (sender and receiver balance updates separate)
- Could lose coins if failure between operations

**Before:**

```dart
Future<void> sendTip(String senderId, String receiverId, int amount) async {
  // Deduct from sender
  await coinEconomyService.spendCoins(senderId, amount, 'Tip sent');

  // Add to receiver
  await coinEconomyService.addCoins(receiverId, amount, 'Tip received');

  // Record tip
  await _firestore.collection('tips').add({
    'senderId': senderId,
    'receiverId': receiverId,
    'amount': amount,
    'timestamp': FieldValue.serverTimestamp(),
  });
  // ❌ Not atomic: Could fail between operations
}
```

**After:**

```dart
Future<void> sendTip(String senderId, String receiverId, int amount) async {
  final senderRef = _firestore.collection('users').doc(senderId);
  final receiverRef = _firestore.collection('users').doc(receiverId);

  await _firestore.runTransaction((transaction) async {
    // Get both balances
    final sender = await transaction.get(senderRef);
    final receiver = await transaction.get(receiverRef);

    final senderBalance = sender.data()?['coinBalance'] as int? ?? 0;
    final receiverBalance = receiver.data()?['coinBalance'] as int? ?? 0;

    if (senderBalance < amount) {
      throw Exception('Insufficient coins');
    }

    // Update both balances atomically
    transaction.update(senderRef, {'coinBalance': senderBalance - amount});
    transaction.update(receiverRef, {'coinBalance': receiverBalance + amount});
  });

  // Record tip (eventual consistency is fine)
  await _firestore.collection('tips').add({
    'senderId': senderId,
    'receiverId': receiverId,
    'amount': amount,
    'timestamp': FieldValue.serverTimestamp(),
  });
  // ✅ Safe: Both balance updates are atomic
}
```

**Why This Works:**

- Both balance updates happen in same transaction
- All-or-nothing guarantee (no partial transfers)
- Tip record outside transaction is acceptable

**Dependencies:** Replaces direct coinEconomyService calls

---

### PATCH-026 to PATCH-028: Additional Transaction Safety

**(3 more patches for other concurrent operations)**

Same pattern as above:

- PATCH-026: RoomService.removeParticipant()
- PATCH-027: SpeedDatingService.submitDecision()
- PATCH-028: GamificationService.awardXP()

All follow transaction safety pattern shown in PATCH-021 to PATCH-025.

---

### PATCH-029: Add Authorization to RoomService.deleteRoom()

**File:** [lib/services/room_service.dart](lib/services/room_service.dart)
**Severity:** 🟡 P2
**Phase:** 2
**Time:** 10 minutes

**Problem:**

- Anyone can delete any room
- No ownership check

**Before:**

```dart
Future<void> deleteRoom(String roomId) async {
  await _firestore.collection('rooms').doc(roomId).delete();
  // ❌ Anyone can delete any room
}
```

**After:**

```dart
Future<void> deleteRoom(String roomId, String callerId) async {
  // Verify caller is room owner
  final roomDoc = await _firestore.collection('rooms').doc(roomId).get();

  if (!roomDoc.exists) {
    throw Exception('Room not found');
  }

  final ownerId = roomDoc.data()?['ownerId'] as String?;

  if (ownerId != callerId) {
    throw UnauthorizedException('Only room owner can delete room');
  }

  await _firestore.collection('rooms').doc(roomId).delete();
  // ✅ Authorization enforced
}
```

**Why This Works:**

- Checks ownership before deletion
- Throws clear exception if unauthorized
- Prevents accidental or malicious deletion

**Dependencies:** Phase 4 Task 4.5 (UnauthorizedException class)
_Can use Exception for now, refactor later_

---

### PATCH-030: Add Authorization to ModerationService.kickUser()

**File:** [lib/features/room/services/room_moderation_service.dart](lib/features/room/services/room_moderation_service.dart)
**Severity:** 🟡 P2
**Phase:** 2
**Time:** 10 minutes

**Problem:**

- No moderator role check
- Any user could kick others

**Before:**

```dart
Future<void> kickUser({
  required String roomId,
  required String moderatorId,
  required String targetUserId,
  String? reason,
}) async {
  // ... kick logic
}
// ❌ No role verification
```

**After:**

```dart
Future<void> kickUser({
  required String roomId,
  required String moderatorId,
  required String targetUserId,
  String? reason,
}) async {
  // Verify moderator permission
  final roomDoc = await _firestore.collection('rooms').doc(roomId).get();
  final ownerId = roomDoc.data()?['ownerId'] as String?;
  final moderatorIds = (roomDoc.data()?['moderatorIds'] as List?)?.cast<String>() ?? [];

  if (moderatorId != ownerId && !moderatorIds.contains(moderatorId)) {
    throw UnauthorizedException('Only room owner or moderators can kick users');
  }

  // ... rest of kick logic
  // ✅ Authorization enforced
}
```

**Why This Works:**

- Checks if caller is owner or moderator
- Clear permission model
- Prevents abuse

**Dependencies:** None (can use Exception for now)

---

### PATCH-031: Add Authorization to ModerationService.banUser()

**File:** [lib/features/room/services/room_moderation_service.dart](lib/features/room/services/room_moderation_service.dart)
**Severity:** 🟡 P2
**Phase:** 2
**Time:** 10 minutes

**Same pattern as PATCH-030** - Add moderator check to banUser() method.

---

## PHASE 3 PATCHES: FEATURE COMPLETION

### PATCH-032: Implement PaymentService (OPTIONAL - 6-8 hours)

**File:** [lib/services/payment_service.dart](lib/services/payment_service.dart)
**Severity:** 🟠 P1 (if real payments needed)
**Phase:** 3
**Time:** 4-6 hours

**Note:** This is a large implementation. See MASTER_FIX_PLAN.md Task 3.1 for full details.

**Summary:**

1. Set up Firebase Cloud Function for Stripe payment intents
2. Implement PaymentService.createPaymentIntent()
3. Implement PaymentService.confirmPayment()
4. Store transaction records
5. Handle errors and edge cases

**Recommended:** Follow Stripe Flutter SDK documentation and Firebase Functions guide.

---

### PATCH-033 to PATCH-035: Speed Dating Edge Cases (OPTIONAL)

**Files:** [lib/services/speed_dating_service.dart](lib/services/speed_dating_service.dart)
**Severity:** 🟢 P3
**Phase:** 3
**Time:** 30-60 minutes each

Summary:

- PATCH-033: Handle user disconnect mid-session
- PATCH-034: Synchronize timers across clients
- PATCH-035: Validate mutual decisions

See MASTER_FIX_PLAN.md Task 3.2 for details.

---

## PHASE 4 PATCHES: STABILITY HARDENING

### PATCH-036 to PATCH-047: WillPopScope → PopScope (12 patches)

**Severity:** 🟢 P3
**Phase:** 4
**Time:** 5 minutes each

**Pattern (applies to all 12 occurrences):**

```dart
// BEFORE:
WillPopScope(
  onWillPop: () async {
    // Handle back button
    return false;  // Prevent pop
  },
  child: Scaffold(...),
)

// AFTER:
PopScope(
  canPop: false,  // Prevent pop
  onPopInvokedWithResult: (didPop, result) {
    if (!didPop) {
      // Handle back button (only if pop was prevented)
    }
  },
  child: Scaffold(...),
)
```

**Files:** Search for `WillPopScope` across codebase

---

### PATCH-048 to PATCH-055: Color.withOpacity → Color.withValues (8 patches)

**Severity:** 🟢 P3
**Phase:** 4
**Time:** 2 minutes each

**Pattern:**

```dart
// BEFORE:
Colors.blue.withOpacity(0.5)
Color(0xFF1234AB).withOpacity(0.8)

// AFTER:
Colors.blue.withValues(alpha: 0.5)
Color(0xFF1234AB).withValues(alpha: 0.8)
```

**Files:** Search for `.withOpacity(` across codebase

---

### PATCH-056 to PATCH-060: Super Parameters (5 patches)

**Severity:** 🟢 P3
**Phase:** 4
**Time:** 2 minutes each

**Pattern:**

```dart
// BEFORE:
MyWidget({Key? key, required this.title}) : super(key: key);

// AFTER:
MyWidget({super.key, required this.title});
```

---

### PATCH-061 to PATCH-080: Centralize Constants (20 patches)

**Severity:** 🟢 P3
**Phase:** 4
**Time:** 5-10 minutes each

**Step 1: Create Constants Files**

**File:** lib/core/constants/firestore_collections.dart

```dart
/// Centralized Firestore collection names
class FirestoreCollections {
  // Private constructor to prevent instantiation
  FirestoreCollections._();

  // Top-level collections
  static const users = 'users';
  static const rooms = 'rooms';
  static const events = 'events';
  static const chatRooms = 'chatRooms';
  static const speedDatingRounds = 'speedDatingRounds';
  static const notifications = 'notifications';
  static const transactions = 'transactions';
  static const subscriptions = 'subscriptions';
  static const achievements = 'achievements';
  static const leaderboard = 'leaderboard';
  static const reports = 'reports';
  static const blocks = 'blocks';

  // Sub-collections
  static const participants = 'participants';
  static const messages = 'messages';
  static const speakerRequests = 'speakerRequests';
  static const sessions = 'sessions';
  static const matches = 'matches';
  static const followers = 'followers';
  static const following = 'following';
}
```

**File:** lib/core/constants/app_limits.dart

```dart
/// Application limits and constraints
class AppLimits {
  // Private constructor
  AppLimits._();

  // Room limits
  static const int maxRoomParticipants = 200;
  static const int maxRoomNameLength = 50;
  static const int maxRoomDescriptionLength = 500;
  static const int minRoomNameLength = 3;

  // Speed dating limits
  static const int speedDatingMaxParticipants = 20;
  static const int speedDatingMinParticipants = 4;
  static const int speedDatingMinRoundMinutes = 2;
  static const int speedDatingMaxRoundMinutes = 10;
  static const int speedDatingDefaultRoundMinutes = 5;

  // Chat limits
  static const int maxMessageLength = 1000;
  static const int maxMessagesPerLoad = 50;
  static const int minMessageLength = 1;

  // Payment limits
  static const double minCoinPurchase = 1.00;
  static const double maxCoinPurchase = 500.00;
  static const double minWithdrawal = 10.00;
  static const double maxWithdrawal = 5000.00;

  // User limits
  static const int maxDisplayNameLength = 30;
  static const int minDisplayNameLength = 2;
  static const int maxBioLength = 500;
  static const int maxInterests = 20;

  // File upload limits
  static const int maxImageSizeMB = 10;
  static const int maxVideoSizeMB = 100;
  static const int maxAudioSizeMB = 50;
}
```

**Step 2: Replace Hardcoded Values**

**Example (room_service.dart):**

```dart
// BEFORE:
await _firestore.collection('rooms').doc(roomId).get();
if (name.length > 50) throw Exception('Name too long');

// AFTER:
import 'package:mix_and_mingle/core/constants/firestore_collections.dart';
import 'package:mix_and_mingle/core/constants/app_limits.dart';

await _firestore.collection(FirestoreCollections.rooms).doc(roomId).get();
if (name.length > AppLimits.maxRoomNameLength) {
  throw ValidationException('Room name too long');
}
```

**Files to Update:** 20+ service files (all that use Firestore)

---

### PATCH-081 to PATCH-095: Add Model Validation (15 patches)

**Severity:** 🟢 P3
**Phase:** 4
**Time:** 10-15 minutes each

**Example (Room model):**

```dart
// BEFORE:
class Room {
  final String id;
  final String name;
  final int maxParticipants;

  Room({required this.id, required this.name, required this.maxParticipants});

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] as String,
      name: json['name'] as String,
      maxParticipants: json['maxParticipants'] as int,
    );
  }
}

// AFTER:
class Room {
  final String id;
  final String name;
  final int maxParticipants;

  Room({required this.id, required this.name, required this.maxParticipants}) {
    // Validate on construction
    if (name.isEmpty || name.length > AppLimits.maxRoomNameLength) {
      throw ValidationException('Room name must be 1-${AppLimits.maxRoomNameLength} characters');
    }
    if (maxParticipants < 1 || maxParticipants > AppLimits.maxRoomParticipants) {
      throw ValidationException('Max participants must be 1-${AppLimits.maxRoomParticipants}');
    }
  }

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] as String,
      name: json['name'] as String,
      maxParticipants: json['maxParticipants'] as int,
    );  // Validation happens in constructor
  }
}
```

**Models to Update:**

- Room
- User
- UserProfile
- ChatMessage
- Event
- SpeedDatingSession
- Subscription
- CoinTransaction
- Tip
- Match
- Notification
- Report
- ModerationAction
- Achievement
- MediaItem

---

### PATCH-096 to PATCH-115: Standardize Error Handling (20 patches)

**Severity:** 🟢 P3
**Phase:** 4
**Time:** 5-10 minutes each

**Step 1: Create Exception Classes**

**File:** lib/core/exceptions/app_exceptions.dart

```dart
/// Base exception for all app errors
abstract class AppException implements Exception {
  final String message;
  final String code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  AppException(
    this.message,
    this.code, [
    this.originalError,
    this.stackTrace,
  ]);

  @override
  String toString() => '[$code] $message${originalError != null ? '\nCaused by: $originalError' : ''}';
}

/// Authentication errors
class AuthException extends AppException {
  AuthException(String message, [dynamic originalError, StackTrace? stackTrace])
      : super(message, 'AUTH_ERROR', originalError, stackTrace);
}

/// Firestore database errors
class FirestoreException extends AppException {
  FirestoreException(String message, [dynamic originalError, StackTrace? stackTrace])
      : super(message, 'FIRESTORE_ERROR', originalError, stackTrace);
}

/// Payment processing errors
class PaymentException extends AppException {
  PaymentException(String message, [dynamic originalError, StackTrace? stackTrace])
      : super(message, 'PAYMENT_ERROR', originalError, stackTrace);
}

/// Input validation errors
class ValidationException extends AppException {
  ValidationException(String message, [dynamic originalError, StackTrace? stackTrace])
      : super(message, 'VALIDATION_ERROR', originalError, stackTrace);
}

/// Authorization/permission errors
class UnauthorizedException extends AppException {
  UnauthorizedException(String message, [dynamic originalError, StackTrace? stackTrace])
      : super(message, 'UNAUTHORIZED', originalError, stackTrace);
}

/// Network/connectivity errors
class NetworkException extends AppException {
  NetworkException(String message, [dynamic originalError, StackTrace? stackTrace])
      : super(message, 'NETWORK_ERROR', originalError, stackTrace);
}

/// Resource not found errors
class NotFoundException extends AppException {
  NotFoundException(String message, [dynamic originalError, StackTrace? stackTrace])
      : super(message, 'NOT_FOUND', originalError, stackTrace);
}
```

**Step 2: Update Service Error Handling**

**Example (room_service.dart):**

```dart
// BEFORE:
try {
  await _firestore.collection('rooms').doc(roomId).get();
} catch (e) {
  debugPrint('❌ Error: $e');
  throw Exception('Failed to get room');
}

// AFTER:
import 'package:mix_and_mingle/core/exceptions/app_exceptions.dart';

try {
  await _firestore.collection(FirestoreCollections.rooms).doc(roomId).get();
} on FirebaseException catch (e, stack) {
  throw FirestoreException('Failed to get room', e, stack);
} catch (e, stack) {
  throw FirestoreException('Unexpected error getting room', e, stack);
}
```

**Files to Update:** All 20+ service files

---

## QUICK REFERENCE

### By Priority

- **P0 (6 errors):** PATCH-001, PATCH-002, PATCH-003, PATCH-004, PATCH-005
- **P1 (4 issues):** PATCH-029 to PATCH-032
- **P2 (21 issues):** PATCH-006 to PATCH-028
- **P3 (67 issues):** PATCH-033 to PATCH-115

### By Phase

- **Phase 1 (1.5 hours):** PATCH-001 to PATCH-005
- **Phase 2 (4 hours):** PATCH-006 to PATCH-031
- **Phase 3 (4 hours):** PATCH-032 to PATCH-035
- **Phase 4 (8-10 hours):** PATCH-036 to PATCH-115

### By File

Use MASTER_ERROR_INDEX.md for quick file-based lookup

---

**Document Complete:** January 26, 2025
**Total Patches:** 115
**Estimated Total Time:** 17-20 hours
**Next Steps:**

1. Start with Phase 1 patches (PATCH-001 to PATCH-005)
2. Validate with `flutter analyze`
3. Proceed to Phase 2-4 as needed

---
