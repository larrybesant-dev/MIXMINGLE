# MIX & MINGLE MVP DIAGNOSTIC REPORT
**Generated:** January 25, 2026
**Project:** Flutter 3.38.7 / Dart 3.10.7
**Total Issues:** 205 errors/warnings

---

## EXECUTIVE SUMMARY

**Current State:** ❌ **APPLICATION CANNOT COMPILE**

**Critical Blockers:** 3 major categories preventing compilation:
1. **Riverpod Provider Architecture Issues** - 52 errors in messaging_providers.dart
2. **Missing Service Methods** - 40+ undefined methods across 6 services
3. **Type & Signature Mismatches** - 31+ parameter/type errors

**MVP Status:** 🔴 **BLOCKED** - Cannot build, cannot test, cannot deploy

---

## 1. CRITICAL COMPILATION BLOCKERS

### 1.1 MESSAGING PROVIDERS - RIVERPOD ARCHITECTURE FAILURE
**File:** `lib/providers/messaging_providers.dart`
**Errors:** 52 instances
**Severity:** 🔴 CRITICAL - Blocks entire compilation

#### Issue: Incorrect FamilyNotifier Implementation

**What's Wrong:**
- `RoomMessagesController` extends `FamilyNotifier<AsyncValue<List<Message>>, String>` (line 29)
- `DirectMessageController` extends `FamilyNotifier<AsyncValue<List<DirectMessage>>, String>` (line 192)
- Both classes are missing proper Riverpod Notifier structure
- Causes cascading errors: undefined `ref`, `state`, `arg` properties

**Why It's Wrong:**
- Riverpod 3.x `FamilyNotifier` is not a base class you can directly extend
- Should use `AutoDisposeFamilyNotifier` or implement proper Notifier pattern
- Missing `@riverpod` annotation or proper class structure

**Specific Errors:**
```
Line 25: 'RoomMessagesController' doesn't conform to bound 'Notifier<AsyncValue<List<Message>>>'
Line 29: Classes can only extend other classes - extends_non_class
Line 38: Undefined name 'ref' - undefined_identifier (30+ occurrences)
Line 53: Undefined name 'state' - undefined_identifier (20+ occurrences)
Line 48: Undefined name 'arg' - undefined_identifier (5+ occurrences)
Line 188: Same issues repeated for DirectMessageController
```

**Affected Files:**
- `lib/features/room/screens/room_page.dart` - Cannot use roomMessagesControllerProvider
- `lib/features/messages/messages_page.dart` - Cannot use directMessageControllerProvider
- `lib/features/messages/chat_screen.dart` - Cannot render message UI

**Blocks MVP:** ✅ YES - Chat and messaging is core MVP feature

**Fix Needed:**
1. Change to `AutoDisposeFamilyNotifier` base class, OR
2. Use `@riverpod` code generation pattern, OR
3. Implement proper `FamilyAsyncNotifier<T, Arg>` with correct generic bounds
4. Ensure `build()` method signature matches Riverpod 3.x requirements
5. All 52 errors will resolve once architecture is corrected

---

### 1.2 SPEED DATING SERVICE - MISSING METHODS
**File:** `lib/services/speed_dating_service.dart`
**Referenced By:** `lib/providers/event_dating_providers.dart`
**Errors:** 8 undefined methods
**Severity:** 🔴 CRITICAL

#### Missing Methods:

| Method | Line in Provider | Expected Signature | Impact |
|--------|------------------|-------------------|--------|
| `findActiveSession` | 369 | `Future<SpeedDatingSession?> findActiveSession(String userId)` | Cannot find user's active dating session |
| `findPartner` | 378 | `Future<String?> findPartner(String sessionId)` | Cannot match users for speed dating |
| `getSession` | 382, 388, 472 | `Future<SpeedDatingSession?> getSession(String sessionId)` | Cannot load session details |
| `createSession` | 387 | `Future<SpeedDatingSession> createSession(String userId1, String userId2, int duration)` | Cannot start new dating session |
| `cancelSession` | 404 | `Future<void> cancelSession(String sessionId)` | Cannot cancel sessions |
| `submitDecision` | 426 | `Future<void> submitDecision(String sessionId, String userId, SpeedDatingDecision decision)` | Cannot record like/pass decisions |
| `startNextRound` | 445 | `Future<void> startNextRound(String sessionId)` | Cannot progress through rounds |
| `endSession` | 458 | `Future<void> endSession(String sessionId)` | Cannot complete sessions |

**What's Wrong:**
- Service file exists but only has `createSpeedDatingRound`, `getSpeedDatingRound`, `getActiveRoundsForEvent` (lines 1-100)
- Provider calls 8 different methods that don't exist
- No session management logic implemented

**Why It's Wrong:**
- Provider was built assuming full CRUD API exists
- Service was partially implemented with only Round management, not Session management
- Two different concepts: SpeedDatingRound (event-level) vs SpeedDatingSession (user-pair interaction)

**Affected Files:**
- `lib/features/speed_dating/screens/speed_dating_lobby_page.dart` - Cannot load or create sessions
- `lib/features/speed_dating/screens/speed_dating_decision_page.dart` - Cannot submit decisions

**Blocks MVP:** ✅ YES - Speed dating is core MVP feature

**Fix Needed:**
- Add all 8 methods to `SpeedDatingService`
- Implement Firestore CRUD for `speedDatingSessions` collection
- Add session state management (waiting → matched → inProgress → completed)
- Add partner matching algorithm
- Add decision recording and mutual match detection

---

### 1.3 GAMIFICATION SERVICE - MISSING METHODS
**File:** `lib/services/gamification_service.dart`
**Referenced By:** `lib/providers/gamification_payment_providers.dart`
**Errors:** 5 undefined methods
**Severity:** 🟡 MEDIUM

#### Missing Methods:

| Method | Line in Provider | Expected Signature | Impact |
|--------|------------------|-------------------|--------|
| `getAvailableAchievements` | 92 | `Future<List<Achievement>> getAvailableAchievements()` | Cannot show achievement catalog |
| `awardXP` | 141 | `Future<void> awardXP(String userId, int amount, String reason)` | Cannot give XP rewards |
| `checkDailyStreak` | 157 | `Future<void> checkDailyStreak(String userId)` | Cannot track daily login streaks |
| `unlockAchievement` | 173 | `Future<void> unlockAchievement(String userId, String achievementId)` | Cannot unlock achievements |
| `getLeaderboard` | 115 | `Future<List<Map<String, dynamic>>> getLeaderboard(String type, int limit)` | Cannot show leaderboards |

**What's Wrong:**
- Service has `getUserAchievements`, `getUserLevel`, `addXP`, `addCoins`, `trackProgress` but missing these 5
- Method names don't match provider expectations (e.g., service has `addXP`, provider calls `awardXP`)

**Why It's Wrong:**
- Inconsistent naming convention between service and provider
- Some methods partially implemented with different names

**Affected Files:**
- `lib/features/achievements/achievements_page.dart` - Cannot display achievement list
- `lib/features/leaderboards/leaderboards_page.dart` - Cannot show leaderboards

**Blocks MVP:** ❌ NO - Gamification is nice-to-have, not core MVP

**Fix Needed:**
- Add 5 missing methods OR rename existing methods to match provider calls
- Standardize naming: decide between `award`/`add`, `unlock`/`track`, etc.

---

### 1.4 PAYMENT SERVICE - MISSING METHODS
**File:** `lib/services/payment_service.dart`
**Referenced By:** `lib/providers/gamification_payment_providers.dart`
**Errors:** 6 undefined methods
**Severity:** 🟡 MEDIUM

#### Missing Methods:

| Method | Line in Provider | Expected Signature | Impact |
|--------|------------------|-------------------|--------|
| `processPayment` | 262 | `Future<Map<String, dynamic>> processPayment(String userId, int amount, String method, Map metadata)` | Cannot process purchases |
| `addPaymentMethod` | 287 | `Future<void> addPaymentMethod(String userId, Map<String, dynamic> method)` | Cannot save payment methods |
| `removePaymentMethod` | 303 | `Future<void> removePaymentMethod(String userId, String methodId)` | Cannot delete payment methods |
| `refundPayment` | 317 | `Future<void> refundPayment(String transactionId)` | Cannot issue refunds |
| `getPaymentMethods` | 213 | `Stream<List<Map<String, dynamic>>> getPaymentMethods(String userId)` | Cannot list saved payment methods |
| `getPaymentHistory` | 227 | `Future<List<Map<String, dynamic>>> getPaymentHistory(String userId, int limit)` | Cannot show transaction history |

**What's Wrong:**
- Service only has basic coin balance operations: `coinBalanceStream`, `getCoinBalance`, `addCoins`, `deductCoins`
- No payment processing, no payment method storage, no transaction history

**Why It's Wrong:**
- Service is coin balance manager, not payment processor
- Provider expects full payment gateway integration

**Affected Files:**
- `lib/features/payment/coin_purchase_page.dart` - Cannot process purchases
- User profile payment settings - Cannot manage payment methods

**Blocks MVP:** ⚠️ PARTIAL - Can use free features, but cannot monetize

**Fix Needed:**
- Add 6 methods for payment processing
- Integrate Stripe/PayPal/other payment gateway
- Add Firestore collections: `paymentMethods`, `transactions`
- Implement secure token storage for payment methods

---

### 1.5 ROOM SERVICE - MISSING METHODS
**File:** `lib/services/room_service.dart`
**Referenced By:** Multiple providers
**Errors:** 5 undefined methods
**Severity:** 🟡 MEDIUM

#### Missing Methods:

| Method | Expected Signature | Impact |
|--------|-------------------|--------|
| `deleteRoom` | `Future<void> deleteRoom(String roomId, String userId)` | Cannot delete rooms |
| `inviteUser` | `Future<void> inviteUser(String roomId, String userId, String invitedUserId)` | Cannot invite users |
| `removeParticipant` | `Future<void> removeParticipant(String roomId, String userId)` | Cannot kick users |
| `promoteToSpeaker` | `Future<void> promoteToSpeaker(String roomId, String userId)` | Cannot promote listeners |
| `demoteToListener` | `Future<void> demoteToListener(String roomId, String userId)` | Cannot demote speakers |

**What's Wrong:**
- Service has: `createVoiceRoom`, `joinVoiceRoom` (lines 1-80)
- Missing: room deletion, user management, speaker controls
- Basic CRUD incomplete

**Affected Files:**
- `lib/features/room/screens/room_page.dart` - Limited room controls
- Voice room moderation features

**Blocks MVP:** ❌ NO - Core join/create works, moderation is secondary

**Fix Needed:**
- Add 5 missing methods
- Implement Firestore updates for room state changes
- Add permission checks (only host/moderators can remove/promote)

---

### 1.6 AGORA VIDEO SERVICE - MISSING METHODS
**File:** `lib/services/agora_video_service.dart`
**Errors:** 5 undefined methods
**Severity:** 🟡 MEDIUM

#### Missing Methods:

| Method | Expected Signature | Impact |
|--------|-------------------|--------|
| `joinChannel` | `Future<void> joinChannel(String channelName, String token, int uid)` | Cannot join video calls |
| `leaveChannel` | `Future<void> leaveChannel()` | Cannot leave video calls |
| `enableLocalAudio` | `Future<void> enableLocalAudio(bool enabled)` | Cannot control mic |
| `enableLocalVideo` | `Future<void> enableLocalVideo(bool enabled)` | Cannot control camera |
| `muteRemoteAudioStream` | `Future<void> muteRemoteAudioStream(int uid, bool mute)` | Cannot mute remote users |

**What's Wrong:**
- Service has `initialize()`, `joinRoom()`, internal state management (lines 1-80)
- `joinRoom()` exists but `joinChannel()` is called by providers
- Method naming inconsistency: room vs channel

**Why It's Wrong:**
- Agora SDK uses "channel" terminology
- Service wrapper uses "room" terminology
- Providers expect "channel" methods

**Affected Files:**
- Video call screens expecting direct channel control

**Blocks MVP:** ⚠️ PARTIAL - `joinRoom()` might work, but inconsistent API

**Fix Needed:**
- Rename `joinRoom()` → `joinChannel()` OR add `joinChannel()` as alias
- Add missing audio/video control methods
- Standardize terminology across codebase

---

### 1.7 NOTIFICATION SERVICE - MISSING METHODS
**File:** `lib/services/notification_service.dart`
**Errors:** 2 undefined methods
**Severity:** 🟢 LOW

#### Missing Methods:

| Method | Line in Provider | Expected Signature |
|--------|------------------|--------------------|
| `getNotificationsStream` | Provider | `Stream<List<NotificationItem>> getNotificationsStream(String userId)` |
| `clearAllNotifications` | Provider | `Future<void> clearAllNotifications(String userId)` |

**What's Wrong:**
- Service has push notification setup, FCM token management (lines 1-80)
- Missing in-app notification feed retrieval
- No bulk clear operation

**Blocks MVP:** ❌ NO - Push notifications work, in-app feed is secondary

**Fix Needed:**
- Add stream for Firestore `notifications` collection
- Add batch delete method

---

### 1.8 MODERATION SERVICE - MISSING METHODS
**File:** `lib/services/moderation_service.dart`
**Errors:** 2 undefined methods
**Severity:** 🟢 LOW

#### Missing Methods:

| Method | Expected Signature |
|--------|--------------------|
| `banUser` | `Future<void> banUser(String moderatorId, String userId, String reason, Duration duration)` |
| `unbanUser` | `Future<void> unbanUser(String moderatorId, String userId)` |

**What's Wrong:**
- Service has `blockUser`, `unblockUser`, `reportUser` (lines 1-80)
- Missing admin-level ban operations (different from user blocking)

**Blocks MVP:** ❌ NO - User blocking works, admin bans are secondary

**Fix Needed:**
- Add ban/unban methods for admin moderation panel

---

### 1.9 ANALYTICS SERVICE - MISSING METHOD
**File:** `lib/services/analytics_service.dart`
**Errors:** 1 undefined method
**Severity:** 🟢 LOW

#### Missing Method:

| Method | Line in Provider | Expected Signature |
|--------|------------------|--------------------|
| `setCurrentScreen` | 356 | `Future<void> setCurrentScreen(String screenName)` |

**What's Wrong:**
- Service has `initialize()`, `setUserId()` (lines 1-50)
- Missing screen tracking method

**Why It's Wrong:**
- Firebase Analytics `setCurrentScreen()` is standard method
- Likely just not wrapped in service

**Blocks MVP:** ❌ NO - Analytics is nice-to-have

**Fix Needed:**
- Add: `await _analytics.setCurrentScreen(screenName: screenName);`

---

### 1.10 COIN ECONOMY SERVICE - MISSING METHOD
**File:** `lib/services/coin_economy_service.dart`
**Errors:** 1 undefined method
**Severity:** 🟢 LOW

#### Missing Method:

| Method | Line in Provider | Expected Signature |
|--------|------------------|--------------------|
| `awardCoins` | Provider | `Future<void> awardCoins(String userId, int amount, String source)` |

**What's Wrong:**
- Service has `addCoins()` with complex parameters (line 42-58)
- Provider calls simpler `awardCoins()` method

**Why It's Wrong:**
- Naming inconsistency: `add` vs `award`
- Parameter signature mismatch

**Blocks MVP:** ❌ NO - `addCoins()` can be used instead

**Fix Needed:**
- Add `awardCoins()` as alias to `addCoins()`, OR
- Update all provider calls to use `addCoins()` with full parameters

---

### 1.11 STORAGE SERVICE - MISSING METHOD
**File:** `lib/services/storage_service.dart`
**Errors:** 1 undefined method
**Severity:** 🟢 LOW

#### Missing Method:

| Method | Expected Signature |
|--------|--------------------|
| `uploadVideo` | `Future<String> uploadVideo(String filePath, {String? folder})` |

**What's Wrong:**
- Service has `uploadImage()`, `uploadImageFromXFile()`, `deleteFile()`
- Missing video upload variant

**Blocks MVP:** ❌ NO - Images work, video is secondary feature

**Fix Needed:**
- Add `uploadVideo()` method similar to `uploadImage()` but without compression

---

## 2. TYPE & SIGNATURE MISMATCHES

### 2.1 String vs String? Type Errors
**Count:** 17 instances
**Severity:** 🟡 MEDIUM

#### Errors:

| File | Line | Issue |
|------|------|-------|
| `lib/features/events/screens/event_details_screen.dart` | 353 | `String?` passed to `String` parameter |
| `lib/features/matching/screens/matches_list_page.dart` | 213, 283 | `String?` passed to `String` parameter |
| `lib/features/profile/screens/user_profile_page.dart` | 130 | `String?` passed to `String` parameter |
| `lib/features/speed_dating/screens/speed_dating_decision_page.dart` | 108 | `String?` passed to `String` parameter |

**What's Wrong:**
- Nullable strings passed to non-nullable parameters
- Missing null checks before method calls

**Fix Needed:**
- Add null checks: `if (value != null) method(value)`
- Use null coalescing: `method(value ?? '')`
- Make parameters nullable in called methods

---

### 2.2 Extra Positional Arguments
**Count:** 14 instances
**Severity:** 🟡 MEDIUM

#### Critical Examples:

| File | Line | Issue | Expected | Provided |
|------|------|-------|----------|----------|
| `lib/providers/event_dating_providers.dart` | 153 | `EventsService.createEvent()` | 1 arg (Event object) | 2 args |
| `lib/providers/event_dating_providers.dart` | 170, 186, 201 | Various event methods | 1-2 args | 3+ args |
| `lib/features/speed_dating/screens/speed_dating_lobby_page.dart` | 338, 355 | Method calls | 1 arg | 2 args |
| `lib/providers/gamification_payment_providers.dart` | 194 | Badge creation | 0 args | 2 args |

**What's Wrong:**
- Provider passes multiple positional arguments
- Service expects single object or fewer arguments

**Example - Event Creation:**
```dart
// Provider calls (line 153):
await _eventsService.createEvent(eventId, event);  // ❌ 2 args

// Service expects:
Future<String> createEvent(Event event) async { ... }  // ✅ 1 arg (returns eventId)
```

**Fix Needed:**
- Remove extra positional arguments
- Change methods to named parameters if multiple args needed
- Review service method signatures vs provider calls

---

### 2.3 Missing Required Arguments
**Count:** 8 instances
**Severity:** 🔴 CRITICAL

#### Errors:

| File | Line | Method | Missing Parameters |
|------|------|--------|-------------------|
| `lib/features/profile/screens/user_profile_page.dart` | 417 | `reportUser()` | `description`, `reportedUserId`, `type` |
| `lib/providers/gamification_payment_providers.dart` | 194 | Badge creation | `badgeId`, `userId` |

**What's Wrong:**
- Required named parameters not provided in method calls

**Example - Report User:**
```dart
// Current call (line 417):
moderationService.reportUser(userId, reason);  // ❌ Missing required params

// Service expects:
Future<void> reportUser({
  required String reporterId,
  required String reportedUserId,
  required String type,
  String? description,
}) async { ... }
```

**Fix Needed:**
- Add all required named parameters to method calls
- Ensure parameter names match service signature

---

### 2.4 Duration vs int Type Mismatch
**File:** `lib/features/speed_dating/screens/speed_dating_lobby_page.dart`
**Line:** 63
**Severity:** 🟡 MEDIUM

**What's Wrong:**
- `Duration` object passed to parameter expecting `int` (minutes)

**Fix Needed:**
- Use `duration.inMinutes` to convert Duration to int

---

### 2.5 String vs bool Type Mismatch
**File:** `lib/features/speed_dating/screens/speed_dating_lobby_page.dart`
**Lines:** 338, 355
**Severity:** 🟡 MEDIUM

**What's Wrong:**
- `String` value passed to `bool` parameter

**Fix Needed:**
- Change to boolean value: `true` / `false` instead of `'true'` / `'false'`

---

### 2.6 Event Object Type Mismatch
**File:** `lib/providers/event_dating_providers.dart`
**Line:** 153
**Severity:** 🟡 MEDIUM

**What's Wrong:**
```dart
// Line 153:
await _eventsService.updateEvent(eventId, event);  // ❌ String, Event

// Service expects:
Future<void> updateEvent(String eventId, Map<String, dynamic> updates) async
```

**Fix Needed:**
- Convert Event object to Map: `event.toMap()` OR change to event field updates

---

### 2.7 Map Type Mismatch
**File:** `lib/providers/gamification_payment_providers.dart`
**Line:** 347
**Severity:** 🟢 LOW

**What's Wrong:**
- `Map<String, dynamic>?` passed to `Map<String, Object>?`

**Fix Needed:**
- Cast: `as Map<String, Object>?` OR make parameter accept `dynamic`

---

## 3. MODEL FIELD ISSUES

### 3.1 SpeedDatingSession.participants - MISSING FIELD
**File:** `lib/shared/models/speed_dating.dart`
**Referenced:** `lib/features/speed_dating/screens/speed_dating_lobby_page.dart:133`
**Severity:** 🟡 MEDIUM

**What's Wrong:**
- UI code calls `session.participants`
- Model only has `userId1`, `userId2` (not a list)

**Why It's Wrong:**
- Model represents 1-on-1 session (2 users)
- UI expects list of participants
- Conceptual mismatch: should be `[userId1, userId2]`

**Fix Needed:**
- Add getter: `List<String> get participants => [userId1, userId2];`

---

### 3.2 UserLevel.currentXP - MISSING FIELD
**File:** `lib/shared/models/user_level.dart`
**Referenced:** `lib/providers/gamification_payment_providers.dart:98`
**Severity:** 🟢 LOW

**What's Wrong:**
- Provider calls `userLevel.currentXP`
- Model has `xp` field (not `currentXP`)

**Why It's Wrong:**
- Naming inconsistency

**Fix Needed:**
- Add getter: `int get currentXP => xp;` OR rename field to `currentXP`

---

### 3.3 SpeedDatingStatus.active - MISSING ENUM VALUE
**File:** `lib/shared/models/speed_dating.dart`
**Referenced:** `lib/features/speed_dating/screens/speed_dating_lobby_page.dart:62`
**Severity:** 🟡 MEDIUM

**What's Wrong:**
```dart
// Current enum:
enum SpeedDatingStatus {
  waiting,
  matched,
  inProgress,
  completed,
  cancelled,
}

// UI calls:
session.status == SpeedDatingStatus.active  // ❌ Doesn't exist
```

**Fix Needed:**
- Add `active` to enum OR change UI to use `inProgress`

---

## 4. CONST & SERIALIZATION ISSUES

### 4.1 Const with Non-Constant Argument
**File:** `lib/providers/event_dating_providers.dart`
**Line:** 141
**Severity:** 🟡 MEDIUM

**What's Wrong:**
```dart
state = const AsyncValue.data(event);  // ❌ event is not const
```

**Fix Needed:**
- Remove `const`: `state = AsyncValue.data(event);`

---

### 4.2 Block Model Serialization Issue
**File:** `lib/shared/models/block.dart` (referenced in errors)
**Severity:** 🟢 LOW

**What's Wrong:**
- Const constructor with non-const fields

**Fix Needed:**
- Review Block model and ensure proper const usage

---

## 5. UI NAVIGATION ISSUES

### 5.1 Undefined Named Parameter 'style'
**File:** `lib/features/onboarding_flow.dart`
**Line:** 273
**Severity:** 🟡 MEDIUM

**What's Wrong:**
- Widget doesn't accept `style` parameter

**Fix Needed:**
- Check widget signature, use correct parameter name (e.g., `textStyle`)

---

## 6. IMPORT & WIDGET ISSUES

### 6.1 LoadingSpinner Widget
**Status:** ✅ RESOLVED (added in previous session)
**File:** `lib/shared/widgets/loading_widgets.dart`

---

## 7. TEST STATUS

### 7.1 Integration Test Failure
**Terminal Output:** Exit Code 1
**Last Command:** `flutter test integration_test -d emulator-5554`
**Severity:** 🟡 MEDIUM

**What's Wrong:**
- Integration tests failing (likely due to compilation errors)

**Blocks MVP:** ⚠️ PARTIAL - Can't validate features

**Fix Needed:**
- Fix compilation errors first
- Re-run integration tests
- Address test-specific failures

---

## 8. DEPENDENCY SUMMARY

### 8.1 Recently Added
- ✅ `flutter_image_compress: ^2.3.0` - Added for storage service

### 8.2 Core Dependencies (Confirmed Working)
- ✅ Flutter: 3.38.7
- ✅ Dart: 3.10.7
- ✅ flutter_riverpod: 3.0.3
- ✅ Firebase suite: auth 6.1.2, firestore 6.1.0, storage 13.0.4
- ✅ Agora RTC Engine: 6.3.2

---

## 9. PRIORITIZED FIX ROADMAP

### PHASE 1: CRITICAL BLOCKERS (Must Fix for Compilation)
**Priority:** 🔴 CRITICAL - Do These First

1. **Fix Messaging Providers Architecture** (52 errors → 0)
   - Refactor `RoomMessagesController` to use `AutoDisposeFamilyNotifier`
   - Refactor `DirectMessageController` to use `AutoDisposeFamilyNotifier`
   - Ensure proper Riverpod 3.x pattern

2. **Add Speed Dating Session Methods** (8 errors → 0)
   - Implement all 8 missing methods in `SpeedDatingService`
   - Add Firestore session management

3. **Fix Extra Positional Arguments** (14 errors → 0)
   - Review all service method signatures
   - Remove extra arguments from provider calls

4. **Fix Missing Required Arguments** (8 errors → 0)
   - Add required parameters to method calls

---

### PHASE 2: TYPE SAFETY (Fix for Clean Compilation)
**Priority:** 🟡 MEDIUM - Do After Phase 1

5. **Fix String/String? Mismatches** (17 errors → 0)
   - Add null checks throughout UI code

6. **Fix Type Mismatches** (Duration→int, String→bool, Event→Map)
   - Convert types at call sites

7. **Add Missing Model Fields/Getters**
   - `SpeedDatingSession.participants`
   - `UserLevel.currentXP`
   - `SpeedDatingStatus.active` enum value

8. **Fix Const Issues**
   - Remove invalid `const` keywords

---

### PHASE 3: COMPLETE SERVICE APIS (MVP Polish)
**Priority:** 🟢 LOW - Do After Compilation Works

9. **Add Gamification Methods** (5 methods)
10. **Add Payment Methods** (6 methods) - If monetization is MVP
11. **Add Room Management Methods** (5 methods)
12. **Add Video Service Methods** (5 methods)
13. **Add Notification/Moderation/Analytics Methods** (5 methods)
14. **Add Storage.uploadVideo()**

---

### PHASE 4: TESTING & VALIDATION
**Priority:** 🟢 LOW - After All Compilation Errors Fixed

15. **Run `flutter analyze`** - Verify 0 errors
16. **Run `flutter build web`** - Test build process
17. **Run integration tests** - Validate feature flows
18. **Fix test-specific failures**

---

## 10. MVP BLOCKING SUMMARY

### ✅ BLOCKS MVP (MUST FIX):
1. ✅ Messaging Providers (52 errors) - Chat is core feature
2. ✅ Speed Dating Service (8 methods) - Speed dating is core feature
3. ✅ Event creation arguments (prevents creating events)
4. ✅ Missing required parameters (prevents core operations)

### ⚠️ PARTIAL MVP BLOCK:
5. ⚠️ Payment methods - Can't monetize but free features work
6. ⚠️ Video service methods - Might work via `joinRoom()` but API unclear

### ❌ DOES NOT BLOCK MVP:
7. ❌ Gamification methods - Nice-to-have
8. ❌ Room moderation - Basic join/create works
9. ❌ Analytics - Not critical for launch
10. ❌ Notification feed - Push works, feed is secondary
11. ❌ Video uploads - Images work

---

## 11. FILES REQUIRING FIXES

### Critical Files (Prevent Compilation):
1. `lib/providers/messaging_providers.dart` - Complete refactor needed
2. `lib/services/speed_dating_service.dart` - Add 8 methods
3. `lib/providers/event_dating_providers.dart` - Fix 14 argument errors
4. `lib/features/speed_dating/screens/speed_dating_lobby_page.dart` - Fix 6 errors
5. `lib/providers/gamification_payment_providers.dart` - Fix 18 errors

### High Priority Files:
6. `lib/features/events/screens/event_details_screen.dart` - Fix null safety
7. `lib/features/matching/screens/matches_list_page.dart` - Fix null safety
8. `lib/features/profile/screens/user_profile_page.dart` - Fix method calls

### Medium Priority Files:
9. `lib/services/gamification_service.dart` - Add 5 methods
10. `lib/services/payment_service.dart` - Add 6 methods
11. `lib/services/room_service.dart` - Add 5 methods
12. `lib/services/agora_video_service.dart` - Add 5 methods

### Low Priority Files:
13. `lib/shared/models/speed_dating.dart` - Add getter/enum value
14. `lib/shared/models/user_level.dart` - Add getter
15. `lib/services/notification_service.dart` - Add 2 methods
16. `lib/services/moderation_service.dart` - Add 2 methods
17. `lib/services/analytics_service.dart` - Add 1 method
18. `lib/services/coin_economy_service.dart` - Add 1 method

---

## 12. ESTIMATED FIX TIME

| Phase | Tasks | Estimated Time | Complexity |
|-------|-------|----------------|------------|
| Phase 1 | Critical blockers (4 tasks) | 2-3 hours | HIGH - Architecture changes |
| Phase 2 | Type safety (4 tasks) | 1-2 hours | MEDIUM - Systematic fixes |
| Phase 3 | Service APIs (7 tasks) | 3-4 hours | MEDIUM - Repetitive CRUD |
| Phase 4 | Testing (4 tasks) | 1-2 hours | LOW - Validation |
| **TOTAL** | **19 tasks** | **7-11 hours** | **Full compilation → MVP** |

---

## 13. CONCLUSION

**Current State:** 205 errors preventing compilation
**Root Cause:** Incomplete provider/service contract, architecture mismatch
**Critical Path:** Fix messaging providers (52 errors) → Fix speed dating service (8 methods) → Fix type safety (31 errors)
**MVP Viable After:** Phase 1 + Phase 2 completion (~4-5 hours of focused work)
**Full Feature Complete:** Phase 1-3 completion (~7-11 hours)

**Recommendation:** Execute fixes in order of priority. After Phase 1, app should compile with warnings. After Phase 2, app should compile cleanly and core MVP features (auth, chat, events, matching, speed dating) should be functional.

---

**End of Diagnostic Report**
