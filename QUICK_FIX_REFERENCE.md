# MixMingle - Quick Fix Reference Guide

## Critical Fixes - Copy/Paste Ready

### Fix 1: spotlight_view.dart Import (Line 3)

```dart
// ❌ CURRENT (Line 3)
import '../../shared/models/camera_state.dart';

// ✅ CHANGE TO
import 'package:mix_and_mingle/shared/models/camera_state.dart';
```

**File:** `lib/features/room/widgets/spotlight_view.dart`
**Lines:** 3
**Time:** 1 minute
**Fixes:** 15 cascade errors

---

### Fix 2: Room Moderation Widget - Text Property (Line 196)

```dart
// ❌ CURRENT (Line 196)
child: Text(
  item.child.data ?? '',
  style: const TextStyle(color: Colors.white),
),

// ✅ CHANGE TO
// The DropdownMenuItem was mapped incorrectly. Fix the mapping:
.map<DropdownMenuItem<String>>((item) => DropdownMenuItem<String>(
  value: item.value,
  child: item.child,  // Just use the existing Text widget
))
```

**File:** `lib/features/voice_room/widgets/room_moderation_widget.dart`
**Lines:** 196
**Time:** 5 minutes
**Fixes:** 1 error

---

### Fix 3: Advanced Mic Service Provider (Lines 74-86)

```dart
// ❌ CURRENT (Lines 74-86)
final advancedMicServiceProvider = StateNotifierProvider<
    AdvancedMicServiceNotifier,
    AdvancedMicServiceState>((ref) {
  return AdvancedMicServiceNotifier();
});

class AdvancedMicServiceNotifier extends StateNotifier<AdvancedMicServiceState> {
  final _service = AdvancedMicService();

  AdvancedMicServiceNotifier()
      : super(
          AdvancedMicServiceState(...),
        );
```

// ✅ CHANGE TO

```dart
final advancedMicServiceProvider = StateNotifierProvider<
    AdvancedMicServiceNotifier,
    AdvancedMicServiceState>((ref) {
  return AdvancedMicServiceNotifier();
});

class AdvancedMicServiceNotifier extends StateNotifier<AdvancedMicServiceState> {
  final _service = AdvancedMicService();

  AdvancedMicServiceNotifier()
      : super(
          AdvancedMicServiceState(
            volumeLevel: 100.0,
            echoCancellationEnabled: true,
            noiseSuppressionEnabled: true,
            autoGainControlEnabled: true,
            soundMode: 0,
          ),
        );

  void setVolumeLevel(double level) {
    _service.setVolumeLevel(level);
    state = state.copyWith(volumeLevel: _service.volumeLevel);
  }

  // ... rest of methods unchanged
}
```

**File:** `lib/features/voice_room/services/advanced_mic_service.dart`
**Lines:** 74-86
**Time:** 10 minutes
**Fixes:** 20+ cascade errors

---

### Fix 4: Room Recording Service Provider (Lines 171-179)

```dart
// ❌ CURRENT
final roomRecordingServiceProvider = StateNotifierProvider<RoomRecordingServiceNotifier, RecordingInfo?>((ref) {
  return RoomRecordingServiceNotifier();
});

class RoomRecordingServiceNotifier extends StateNotifier<RecordingInfo?> {
  final _service = RoomRecordingService();

  RoomRecordingServiceNotifier() : super(null);

// ✅ ALREADY CORRECT IN YOUR FILE
// Just ensure constructor is: RoomRecordingServiceNotifier() : super(null);
```

**File:** `lib/features/voice_room/services/room_recording_service.dart`
**Lines:** 171-179
**Status:** Verify constructor signature is correct
**Time:** 5 minutes check

---

### Fix 5: Messaging Providers - Controller Architecture (Lines 25-29, 188-192)

This is the most complex fix. Here's the CORRECT pattern:

```dart
// ❌ CURRENT (BROKEN)
class RoomMessagesController {
  final Ref ref;
  final String roomId;
  RoomMessagesController(this.ref, this.roomId);
  // ... methods that reference 'state' and 'ref'
}

final roomMessagesControllerProvider = StreamProvider.autoDispose
    .family<List<Message>, String>((ref, roomId) {
  final messagingService = ref.watch(messagingServiceProvider);
  return messagingService.getRoomMessages(roomId).handleError((error) {
    return <Message>[];
  });
});

// ✅ CORRECT - Option A: Simple Provider Wrapper
class RoomMessagesController {
  final Ref ref;
  final MessagingService messagingService;

  RoomMessagesController(this.ref, this.messagingService);

  Future<void> sendMessage(
    String content, {
    String? replyToMessageId,
    String? mediaUrl,
  }) async {
    try {
      final currentUser = await ref.read(currentUserProvider.future);
      if (currentUser == null) throw Exception('User not authenticated');

      await messagingService.sendRoomMessage(
        senderId: currentUser.id,
        senderName: currentUser.displayName ?? currentUser.username,
        senderAvatarUrl: currentUser.avatarUrl,
        roomId: ref.watch(roomIdProvider),
        content: content,
        replyToMessageId: replyToMessageId,
        mediaUrl: mediaUrl,
      );
    } catch (e) {
      rethrow;
    }
  }

  // ... other methods
}

final roomMessagesControllerProvider = Provider.family<RoomMessagesController, String>(
  (ref, roomId) {
    final messagingService = ref.watch(messagingServiceProvider);
    return RoomMessagesController(ref, messagingService);
  },
);
```

**File:** `lib/providers/messaging_providers.dart`
**Lines:** 25-29, 188-192
**Time:** 30 minutes (major refactor)
**Fixes:** 50+ cascade errors

---

### Fix 6: Speed Dating Service - Stub Missing Methods

```dart
// FILE: lib/services/speed_dating_service.dart
// ADD these methods if missing:

Future<SpeedDatingSession?> findActiveSession(String userId) async {
  // TODO: Implement - Query Firestore for active session
  return null;
}

Future<User?> findPartner(String userId) async {
  // TODO: Implement - Find matched partner
  return null;
}

Future<SpeedDatingSession?> getSession(String sessionId) async {
  // TODO: Implement - Fetch session from Firestore
  return null;
}

Future<SpeedDatingSession> createSession(
  String userId,
  String partnerId,
  DateTime startTime,
) async {
  // TODO: Implement
  final session = SpeedDatingSession(
    id: 'session_${DateTime.now().millisecondsSinceEpoch}',
    initiatorId: userId,
    participantId: partnerId,
    startTime: startTime,
    status: SpeedDatingStatus.waiting,
    rounds: [],
  );
  // Save to Firestore
  return session;
}

Future<void> cancelSession(String sessionId) async {
  // TODO: Implement - Cancel and cleanup
}

Future<void> submitDecision(String sessionId, String userId, bool interested) async {
  // TODO: Implement - Save decision to Firestore
}

Future<void> startNextRound(String sessionId) async {
  // TODO: Implement - Progress to next round
}

Future<void> endSession(String sessionId) async {
  // TODO: Implement - Mark session as completed
}
```

**File:** `lib/services/speed_dating_service.dart`
**Time:** 20 minutes
**Fixes:** 8 undefined method errors

---

### Fix 7: Type Mismatch - String? to String (6 locations)

```dart
// PATTERN 1: event_details_screen.dart:353
// ❌ CURRENT
SomeWidget(stringValue)  // stringValue is String?

// ✅ FIX
SomeWidget(stringValue ?? 'default')

// PATTERN 2: matches_list_page.dart:213, 283
// ❌ CURRENT
someFunction(user?.id)  // Returns String?

// ✅ FIX
if (user?.id != null) {
  someFunction(user!.id)  // Now guaranteed non-null
}

// PATTERN 3: user_profile_page.dart:130
// ❌ CURRENT
Text(profile?.name)  // String? passed to Text

// ✅ FIX
Text(profile?.name ?? 'Unknown')

// PATTERN 4: speed_dating_decision_page.dart:108
// ❌ CURRENT
moveToNext(currentUser?.id)

// ✅ FIX
moveToNext(currentUser?.id ?? '')
// OR better yet, ensure currentUser is not null at this point
if (currentUser != null) {
  moveToNext(currentUser.id)
}
```

**Files:** 6 locations
**Time:** 15 minutes
**Fixes:** 6 type mismatch errors

---

### Fix 8: Deprecated API Replacements

```dart
// ISSUE 1: withOpacity() - 4 locations
// ❌ OLD
Colors.black.withOpacity(0.5)

// ✅ NEW
Colors.black.withValues(alpha: 0.5)

// ISSUE 2: WillPopScope - 1 location (spotlight_view.dart:25)
// ❌ OLD
WillPopScope(
  onWillPop: () async {
    onClose();
    return false;
  },
  child: Scaffold(...),
)

// ✅ NEW
PopScope(
  onPopInvoked: (didPop) {
    if (didPop) return;
    onClose();
  },
  child: Scaffold(...),
)

// ISSUE 3: Radio activeColor
// ❌ OLD
Radio(
  groupValue: selectedValue,
  value: option,
  onChanged: (value) => setState(() => selectedValue = value),
  activeColor: Colors.blue,
)

// ✅ NEW
Radio(
  groupValue: selectedValue,
  value: option,
  onChanged: (value) => setState(() => selectedValue = value),
  activeThumbColor: Colors.blue,
)

// ISSUE 4: Switch activeColor
// ❌ OLD
Switch(
  value: isEnabled,
  onChanged: (value) => setState(() => isEnabled = value),
  activeColor: Colors.green,
)

// ✅ NEW
Switch(
  value: isEnabled,
  onChanged: (value) => setState(() => isEnabled = value),
  activeThumbColor: Colors.green,
)
```

**Files:** Multiple
**Time:** 20 minutes
**Fixes:** 50+ deprecation warnings

---

## Critical Files Summary

| File                           | Issue                        | Line(s)                 | Priority |
| ------------------------------ | ---------------------------- | ----------------------- | -------- |
| `spotlight_view.dart`          | Wrong import path            | 3                       | P0       |
| `room_moderation_widget.dart`  | Invalid property access      | 196                     | P0       |
| `advanced_mic_service.dart`    | StateNotifierProvider broken | 74-128                  | P0       |
| `room_recording_service.dart`  | StateNotifierProvider broken | 171-220                 | P0       |
| `messaging_providers.dart`     | Controller architecture      | 25-313                  | P0       |
| `speed_dating_service.dart`    | Missing all methods          | All                     | P0       |
| `gamification_service.dart`    | Missing 5 methods            | Various                 | P1       |
| `payment_service.dart`         | Missing 6 methods            | Various                 | P1       |
| `speed_dating_lobby_page.dart` | Type mismatches              | Multiple                | P1       |
| `camera_tile.dart`             | withOpacity() deprecated     | 104, 105, 177, 211, 230 | P3       |

---

## Test the Fixes

After each fix batch, run:

```bash
flutter clean
flutter pub get
flutter analyze
```

Target: Get the error count down from 139 to 0.
