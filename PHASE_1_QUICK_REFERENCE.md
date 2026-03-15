# PHASE 1: Quick Reference Card

**One-page summary — Print this**

---

## The 6 Fixes

| Fix | File                   | Change                        | Time |
| --- | ---------------------- | ----------------------------- | ---- |
| 1   | auth_providers.dart    | Verify export (✓ done)        | 5m   |
| 2   | lib/\*_/_.dart         | `../../` → `package:` imports | 30m  |
| 3   | firestore.indexes.json | Add 3 composite indexes       | 30m  |
| 4   | chat_message.dart      | Add roomId, roomType fields   | 60m  |
| 5   | event.dart, etc        | `String` → `DateTime`         | 45m  |
| 6   | all_providers.dart     | Verify all exports            | 30m  |

**Total: 4-5 hours**

---

## Quick Commands

```bash
# Clean & rebuild
flutter clean && flutter pub get

# Check for errors
flutter analyze

# Run tests
flutter test

# Build web
flutter build web --release --web-renderer html

# Deploy indexes
firebase deploy --only firestore:indexes
```

---

## Import Pattern

**Wrong:**

```dart
import '../../shared/models/user.dart';
import '../../../features/room/page.dart';
```

**Right:**

```dart
import 'package:mix_and_mingle/shared/models/user.dart';
import 'package:mix_and_mingle/features/room/page.dart';
```

---

## DateTime Pattern

**Wrong:**

```dart
final String startTime;  // ❌
int.parse(event.startTime)  // ❌
```

**Right:**

```dart
final DateTime startTime;  // ✅
event.startTime.isAfter(DateTime.now())  // ✅
event.startTime.difference(event.endTime)  // ✅
```

---

## Firestore Indexes to Add

```json
speedDatingRounds: eventId ▲ + isActive ▲ + startTime ▲
users: membershipTier ▲ + coinBalance ▼
rooms: isActive ▲ + category ▲ + viewCount ▼
```

---

## ChatMessage Fields

**Add to model:**

```dart
final String? roomId;        // null for DM, room ID for room chat
final String roomType;       // 'dm' or 'room'
final String? receiverId;    // for DMs
```

---

## Test Commands

```bash
# Type safety
flutter test test/models/chat_message_test.dart
flutter test test/models/datetime_fields_test.dart

# Providers accessible
flutter test test/providers/providers_accessibility_test.dart

# Everything works
flutter analyze
flutter build web --release --web-renderer html
```

---

## Success Criteria

- ✅ `flutter analyze` = 0 errors
- ✅ All 3 Firestore indexes = ENABLED
- ✅ No `VoiceRoomChatMessage` references
- ✅ No `String` date fields
- ✅ All providers exported
- ✅ Web build succeeds

---

## If Stuck

1. **Import errors?** → Fix #2 (find & replace imports)
2. **Type errors with messages?** → Fix #4 (consolidate ChatMessage)
3. **Type errors with dates?** → Fix #5 (DateTime fields)
4. **Provider not found?** → Fix #6 (provider exports)
5. **Firestore queries fail?** → Fix #3 (verify indexes ENABLED)

---

## Timeline

- **0-30m:** Fixes #1-3 (trivial)
- **30-90m:** Fixes #4-5 (code changes)
- **90-120m:** Fix #6 + verification
- **120-240m:** Testing & troubleshooting
- **Total: 4-5 hours**

---

## What You Get After Phase 1

✅ **Type-safe code** — No serialization surprises
✅ **Correct imports** — Consistent across codebase
✅ **Production-ready queries** — Firestore indexes in place
✅ **Unified message handling** — One message type everywhere
✅ **Math-ready dates** — DateTime comparisons work
✅ **Wired providers** — All accessible from all_providers.dart

**Ready for Phase 2: Concurrency Hardening** ✨

---

## Files You're Working On

- `lib/providers/auth_providers.dart`
- `lib/providers/all_providers.dart`
- `lib/shared/models/chat_message.dart` (DELETE VoiceRoomChatMessage)
- `lib/shared/models/event.dart`
- `lib/shared/models/speed_dating_round.dart`
- `lib/shared/models/room.dart`
- `firestore.indexes.json`
- All `.dart` files in `lib/` (for import fixes)

---

## Don't Forget

1. **After Step 3:** Wait for Firestore indexes to be ENABLED (5-10 min)
2. **After each step:** Run `flutter analyze`
3. **After Step 6:** Run full test suite
4. **After everything:** Build web release to confirm it works

---

**Start with:** [PHASE_1_EXECUTION_CHECKLIST.md](PHASE_1_EXECUTION_CHECKLIST.md)
