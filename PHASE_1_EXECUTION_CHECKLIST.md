# PHASE 1: Execution Checklist

**Step-by-step guide to complete Phase 1 in 4-5 hours**

---

## 📋 Quick Reference

| Step | Action                                    | Time   | Status |
| ---- | ----------------------------------------- | ------ | ------ |
| 1    | Fix #1: Verify authServiceProvider export | 5 min  | [ ]    |
| 2    | Fix #2: Fix import paths                  | 30 min | [ ]    |
| 3    | Fix #3: Add Firestore indexes             | 30 min | [ ]    |
| 4    | Fix #4: Consolidate ChatMessage types     | 60 min | [ ]    |
| 5    | Fix #5: Fix DateTime fields               | 45 min | [ ]    |
| 6    | Fix #6: Provider export audit             | 30 min | [ ]    |
| 7    | Verification: Full test suite             | 60 min | [ ]    |

**Total: 4-5 hours**

---

## STEP 1: Verify authServiceProvider Export (5 min)

**Action:**

```bash
cd c:\Users\LARRY\MIXMINGLE
grep "authServiceProvider" lib/providers/auth_providers.dart
grep "export 'auth_providers" lib/providers/all_providers.dart
```

**Expected:**

```
✓ authServiceProvider is defined in auth_providers.dart
✓ auth_providers.dart is exported in all_providers.dart
```

**Status:** ✅ Already complete — Move to Step 2

---

## STEP 2: Fix Import Paths (30 min)

### 2a: Identify problematic imports

```bash
grep -rn "import '\.\./\.\./\.\." lib/ --include="*.dart" | wc -l
```

**Expected:** < 5 matches (usually 0-3)

### 2b: Use VS Code Find & Replace

1. Open VS Code: `code c:\Users\LARRY\MIXMINGLE`
2. Press **Ctrl+H** to open Find & Replace
3. Apply these replacements **in order:**

**Replace 1:**

- Find: `import '../../shared/`
- Replace: `import 'package:mix_and_mingle/shared/`
- Click **Replace All**

**Replace 2:**

- Find: `import '../../../shared/`
- Replace: `import 'package:mix_and_mingle/shared/`
- Click **Replace All**

**Replace 3:**

- Find: `import '../../../features/`
- Replace: `import 'package:mix_and_mingle/features/`
- Click **Replace All**

**Replace 4:**

- Find: `import '../../features/`
- Replace: `import 'package:mix_and_mingle/features/`
- Click **Replace All**

### 2c: Verify

```bash
flutter analyze
```

**Expected:** 0 "unresolved import" errors

**Status:** [ ] Check when complete

---

## STEP 3: Add Firestore Composite Indexes (30 min)

### 3a: Update firestore.indexes.json

1. Open file: `firestore.indexes.json` (at project root)
2. Copy this into the `"indexes"` array:

```json
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
```

### 3b: Deploy indexes

```bash
firebase deploy --only firestore:indexes
```

### 3c: Verify in Firebase Console

1. Go to https://console.firebase.google.com
2. Select Mix & Mingle project
3. Go to **Firestore Database** → **Indexes**
4. **Wait for all 3 indexes to show "ENABLED"** (5-10 minutes)

**Do NOT proceed until all indexes are "ENABLED"**

**Status:** [ ] Check when all 3 indexes show ENABLED

---

## STEP 4: Consolidate ChatMessage Types (60 min)

### 4a: Update ChatMessage model

1. Open: `lib/shared/models/chat_message.dart`
2. Add these fields to the class:

```dart
final String? roomId;           // Add this
final String roomType;          // Add this
final String? receiverId;       // Add this
```

3. Update the constructor to include them
4. Update `fromJson()` method (see PHASE_1_CODE_PATCHES.md)
5. Update `toJson()` method (see PHASE_1_CODE_PATCHES.md)

### 4b: Delete VoiceRoomChatMessage

```bash
grep -r "class VoiceRoomChatMessage" lib/
```

Delete that file or class definition.

### 4c: Replace all references

1. Press **Ctrl+H** in VS Code
2. Find: `VoiceRoomChatMessage`
3. Replace: `ChatMessage`
4. Click **Replace All**

### 4d: Verify

```bash
flutter analyze
```

**Expected:** 0 errors mentioning message types

**Status:** [ ] Check when complete

---

## STEP 5: Fix DateTime Fields (45 min)

### 5a: Find all String date fields

```bash
grep -rn "final String.*[Tt]ime" lib/shared/models/ --include="*.dart"
grep -rn "final String.*[Dd]ate" lib/shared/models/ --include="*.dart"
```

List of files to update: ********\_\_******** (write them down)

### 5b: For each file found, update:

1. Open the model file
2. Change `String` → `DateTime` for all time/date fields
3. Update `fromJson()` to use `Timestamp.toDate()`
4. Update `toJson()` to use `Timestamp.fromDate()`

See exact examples in PHASE_1_CODE_PATCHES.md section "Patch #5"

### 5c: Update usage sites

```bash
grep -rn "\.startTime\|\.endTime\|\.createdAt" lib/ --include="*.dart" | head -30
```

For each match, verify it's using DateTime methods, not string parsing.

### 5d: Verify

```bash
flutter analyze
```

**Expected:** 0 type-related errors with dates

**Status:** [ ] Check when complete

---

## STEP 6: Provider Export Audit (30 min)

### 6a: Check all_providers.dart

1. Open: `lib/providers/all_providers.dart`
2. Verify these are exported (should already be):

```
✓ export 'auth_providers.dart';
✓ export 'user_providers.dart';
✓ export 'chat_providers.dart';
✓ export 'messaging_providers.dart';
✓ export 'room_providers.dart';
✓ export 'event_dating_providers.dart';
✓ export 'gamification_payment_providers.dart';
✓ export 'match_providers.dart';
```

### 6b: Add any missing feature module exports

If you find providers in `lib/features/*/providers/`, add:

```dart
export '../features/[feature]/providers/[file].dart';
```

### 6c: Verify

```bash
flutter analyze
```

**Expected:** 0 "undefined provider" errors

**Status:** [ ] Check when complete

---

## STEP 7: Full Verification (60 min)

### 7a: Clean build

```bash
cd c:\Users\LARRY\MIXMINGLE
flutter clean
flutter pub get
```

### 7b: Run analysis

```bash
flutter analyze
```

**Expected:**

```
No issues found! (0 issues)
```

**If errors appear:** They'll map to one of the 6 steps above. Go back and fix.

### 7c: Run tests

Create test files if they don't exist (see PHASE_1_TESTING_PLAN.md):

```bash
flutter test test/models/chat_message_test.dart
flutter test test/models/datetime_fields_test.dart
flutter test test/providers/providers_accessibility_test.dart
```

**Expected:** All tests pass ✓

### 7d: Build test

```bash
flutter build web --web-renderer html --release
```

**Expected:** Build completes without errors

### 7e: Verify Firestore indexes one more time

Go to Firebase Console → Firestore → Indexes:

- [ ] speedDatingRounds index: ENABLED
- [ ] users index: ENABLED
- [ ] rooms index: ENABLED

---

## 🎯 Phase 1 Complete Checklist

- [ ] Step 1: authServiceProvider export verified
- [ ] Step 2: Import paths fixed (flutter analyze passes)
- [ ] Step 3: Firestore indexes deployed and ENABLED
- [ ] Step 4: ChatMessage consolidated (0 VoiceRoomChatMessage refs)
- [ ] Step 5: DateTime fields fixed (no String date fields)
- [ ] Step 6: Provider exports complete (all key providers accessible)
- [ ] Step 7: Full verification passed (build succeeds, tests pass)

---

## 📝 Time Tracking

**Start time:** ******\_\_\_\_******
**Step 1 complete:** ******\_\_\_\_****** (5 min)
**Step 2 complete:** ******\_\_\_\_****** (35 min total)
**Step 3 complete:** ******\_\_\_\_****** (65 min total)
**Step 4 complete:** ******\_\_\_\_****** (125 min total)
**Step 5 complete:** ******\_\_\_\_****** (170 min total)
**Step 6 complete:** ******\_\_\_\_****** (200 min total)
**Step 7 complete:** ******\_\_\_\_****** (260 min total / ~4.3 hours)

---

## 🚀 What's Next?

Once all 7 steps are complete:

✅ Your app is **type-safe**
✅ Your app is **properly wired**
✅ Your app is **indexable in production**

**You're ready for Phase 2: Concurrency Hardening**

Next document: `PHASE_2_CONCURRENCY_HARDENING.md` (coming next)

This is where you add transactions and eliminate race conditions.

---

## ❓ Need Help?

- **Detailed implementation:** See [PHASE_1_IMPLEMENTATION_PLAN.md](PHASE_1_IMPLEMENTATION_PLAN.md)
- **Code patches:** See [PHASE_1_CODE_PATCHES.md](PHASE_1_CODE_PATCHES.md)
- **Testing guide:** See [PHASE_1_TESTING_PLAN.md](PHASE_1_TESTING_PLAN.md)
