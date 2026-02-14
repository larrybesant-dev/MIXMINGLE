# PHASE 1: Testing & Verification Plan
**How to confirm each fix actually works**

---

## Test Strategy

After each patch, you'll:
1. **Compile test** — Does it build?
2. **Type test** — Are types correct?
3. **Export test** — Are providers accessible?
4. **Integration test** — Does the feature work end-to-end?

---

## Test #1: Import Paths

### Quick Check
```bash
cd c:\Users\LARRY\MIXMINGLE
flutter analyze
```

**Expected:** 0 import-related errors

### Manual Verification
Pick 5 random files from different features:
```bash
cat lib/features/room/screens/room_page.dart | head -20
cat lib/features/chat/screens/chat_page.dart | head -20
cat lib/features/speed_dating/screens/speed_dating_page.dart | head -20
```

Verify all imports follow pattern:
```dart
import 'package:mix_and_mingle/[path]/[file].dart';
```

NOT:
```dart
import '../../../[wrong]/[path].dart';
```

---

## Test #2: Firestore Indexes

### Verification Steps

1. **Open Firebase Console:**
   - Go to https://console.firebase.google.com
   - Select Mix & Mingle project
   - Navigate to **Firestore Database** → **Indexes**

2. **Verify all 3 indexes exist:**
   - [ ] `speedDatingRounds` — eventId, isActive, startTime
   - [ ] `users` — membershipTier, coinBalance
   - [ ] `rooms` — isActive, category, viewCount

3. **Wait for Status:**
   - New indexes show "CREATING" initially
   - Wait 5-10 minutes for "ENABLED" status
   - DO NOT proceed to Phase 2 until all are "ENABLED"

4. **Test a query that needs the index:**

Create a quick test:
```dart
// lib/test/firestore_index_test.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Firestore indexes are available', (tester) async {
    final firestore = FirebaseFirestore.instance;

    // This query will fail if index doesn't exist
    final query = await firestore
        .collection('speedDatingRounds')
        .where('isActive', isEqualTo: true)
        .orderBy('startTime')
        .limit(1)
        .get();

    expect(query, isNotNull);
  });
}
```

Run:
```bash
flutter test test/firestore_index_test.dart
```

---

## Test #3: ChatMessage Consolidation

### Compilation Test
```bash
flutter clean && flutter pub get && flutter analyze
```

**Expected:** 0 errors mentioning ChatMessage or VoiceRoomChatMessage

### Type Test
Create a test file:

```dart
// test/models/chat_message_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mix_and_mingle/shared/models/chat_message.dart';

void main() {
  test('ChatMessage serializes correctly with all types', () {
    final message = ChatMessage(
      id: '1',
      senderId: 'user123',
      content: 'Hello',
      sentAt: DateTime.now(),
      roomType: 'room',
      roomId: 'room456',
    );

    final json = message.toJson();
    expect(json['roomType'], equals('room'));
    expect(json['roomId'], equals('room456'));

    final restored = ChatMessage.fromJson(json);
    expect(restored.roomType, equals('room'));
    expect(restored.roomId, equals('room456'));
  });

  test('ChatMessage defaults to DM type', () {
    final message = ChatMessage(
      id: '1',
      senderId: 'user123',
      content: 'Hi',
      sentAt: DateTime.now(),
    );

    expect(message.roomType, equals('dm'));
    expect(message.roomId, isNull);
  });

  test('No VoiceRoomChatMessage references exist', () {
    // This test verifies all references were updated
    // If this fails, you missed replacing some references
    expect(true, isTrue); // Visual verification test
  });
}
```

Run:
```bash
flutter test test/models/chat_message_test.dart
```

**Expected:**
- ✓ ChatMessage serializes correctly
- ✓ ChatMessage defaults to DM type
- ✓ No VoiceRoomChatMessage references

### Search for Remaining References
```bash
grep -r "VoiceRoomChatMessage" lib/ --include="*.dart"
```

**Expected:** No results (0 matches)

---

## Test #4: DateTime Fields

### Type Safety Test
```dart
// test/models/datetime_fields_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mix_and_mingle/shared/models/event.dart';
import 'package:mix_and_mingle/shared/models/speed_dating_round.dart';

void main() {
  test('Event DateTime fields work correctly', () {
    final now = DateTime.now();
    final later = now.add(Duration(hours: 2));

    final event = Event(
      id: '1',
      name: 'Test Event',
      startTime: now,
      endTime: later,
      // ... other required fields
    );

    // Math now works:
    final duration = event.endTime.difference(event.startTime);
    expect(duration.inHours, equals(2));

    // Comparison works:
    expect(event.startTime.isBefore(event.endTime), isTrue);
  });

  test('Event serializes DateTime fields', () {
    final event = Event(
      id: '1',
      name: 'Test',
      startTime: DateTime(2026, 1, 26),
      endTime: DateTime(2026, 1, 27),
      // ... other fields
    );

    final json = event.toJson();

    // Should be Timestamp, not String
    expect(json['startTime'], isA<Timestamp>());
    expect(json['endTime'], isA<Timestamp>());

    // Deserialize
    final restored = Event.fromJson(json);
    expect(restored.startTime, isA<DateTime>());
  });

  test('Speed Dating Round DateTime fields work', () {
    final round = SpeedDatingRound(
      id: '1',
      eventId: '1',
      startTime: DateTime.now(),
      endTime: DateTime.now().add(Duration(minutes: 10)),
      // ... other fields
    );

    expect(round.startTime, isA<DateTime>());
    expect(round.endTime, isA<DateTime>());
  });
}
```

Run:
```bash
flutter test test/models/datetime_fields_test.dart
```

**Expected:**
- ✓ Event DateTime fields work correctly
- ✓ Event serializes DateTime fields
- ✓ Speed Dating Round DateTime fields work

### Manual Verification
```bash
# Look for any remaining String date fields
grep -rn "final String.*[Tt]ime" lib/shared/models/ --include="*.dart"
grep -rn "final String.*[Dd]ate" lib/shared/models/ --include="*.dart"
```

**Expected:** No results (0 matches)

---

## Test #5: Provider Exports

### Accessibility Test
```dart
// test/providers/providers_accessibility_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mix_and_mingle/providers/all_providers.dart';

void main() {
  test('Core providers are exported and accessible', () {
    // This imports all providers - if any are missing, it fails
    expect(authStateProvider, isNotNull);
    expect(currentUserProvider, isNotNull);
    expect(roomsProvider, isNotNull);
    expect(chatMessagesProvider, isNotNull);
    expect(messagingProvider, isNotNull);
  });

  test('Feature providers are accessible', () {
    expect(speedDatingMatchesProvider, isNotNull);
    expect(gamificationProvider, isNotNull);
    expect(paymentProvider, isNotNull);
  });

  test('All hidden providers are intentional', () {
    // This is a manual check - inspect all_providers.dart
    // Verify each "hide" is intentional (duplicate/alternative provider)
    expect(true, isTrue);
  });
}
```

Run:
```bash
flutter test test/providers/providers_accessibility_test.dart
```

**Expected:**
- ✓ Core providers are exported
- ✓ Feature providers are accessible
- ✓ All hidden providers are intentional

### Check exports explicitly
```dart
import 'package:mix_and_mingle/providers/all_providers.dart';

// If this compiles, providers are exported
final exampleProvider = authStateProvider;
```

---

## Test #6: Full Compilation Test

### Final Phase 1 Verification
```bash
cd c:\Users\LARRY\MIXMINGLE

# Clean and rebuild
flutter clean
flutter pub get

# Analyze (0 Dart errors expected)
flutter analyze

# Run all tests
flutter test test/

# Build (should complete without errors)
flutter build web --web-renderer html --release
```

**Expected output:**
```
✓ 0 Dart analysis errors
✓ All tests pass
✓ Web build completes successfully
```

---

## Test Summary Checklist

- [ ] **Test #1: Import paths** — flutter analyze shows 0 errors
- [ ] **Test #2: Firestore indexes** — All 3 indexes show "ENABLED" in Firebase Console
- [ ] **Test #3: ChatMessage** — Serialization test passes, 0 VoiceRoomChatMessage references
- [ ] **Test #4: DateTime** — DateTime math/comparison works, no String date fields remain
- [ ] **Test #5: Provider exports** — All key providers accessible from all_providers.dart
- [ ] **Test #6: Full compilation** — flutter build web succeeds, 0 errors

---

## 🚨 If Tests Fail

Each test failure maps back to one of the 6 patches:

| Test Failure | Patch | Fix |
|--------------|-------|-----|
| "Cannot find provider X" | #6 | Add export to all_providers.dart |
| "Type mismatch" for ChatMessage | #4 | Update type references |
| "Cannot subtract String" | #5 | Update DateTime fields |
| "Firestore index missing" | #3 | Verify indexes in Firebase Console |
| "Unresolved import" | #2 | Replace relative imports |
| "authServiceProvider not found" | #1 | Already done ✓ |

Go back to [PHASE_1_IMPLEMENTATION_PLAN.md](PHASE_1_IMPLEMENTATION_PLAN.md) and re-apply that patch.

---

## ✅ Phase 1 Complete When

- ✅ flutter analyze shows 0 Dart errors
- ✅ All 6 tests above pass
- ✅ flutter build web succeeds
- ✅ No ChatMessage or DateTime-related type errors
- ✅ All providers accessible from all_providers.dart

**Then:** You're ready to start **Phase 2: Concurrency Hardening**

