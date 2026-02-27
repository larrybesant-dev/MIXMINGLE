# Mix & Mingle Setup Workflow - Error Report

**Date:** February 8, 2026
**Step:** 1 - Environment Setup
**Status:** 🔴 **BLOCKED** - 140 errors found

---

## Summary

Flutter analyze revealed **140 errors** preventing progression. Code must be cleaned before Firebase, Agora, and design system setup can proceed.

### Environment Status ✅

- Flutter 3.38.9 (stable) ✅
- Dart 3.10.8 ✅
- Android SDK 36.1.0 ✅
- Chrome available ✅
- All platforms detected ✅
- **flutter pub get:** ✅ SUCCESS

### Critical Issues Found

#### 1. **FLUTTER_WEB_STARTER_TEMPLATE Directory (Active)**

**Impact:** HIGH - Breaks imports and routes

- `lib/app_routes.dart` references non-existent files
- `lib/main.dart` has broken imports to `FLUTTER_WEB_STARTER_TEMPLATE/lib`
- This appears to be leftover template code mixed with production code

**Errors:**

```
- Target of URI doesn't exist: 'FLUTTER_WEB_STARTER_TEMPLATE\lib\app_routes.dart:2:8'
- 3 errors in app_routes.dart (missing VideoChatPage, wrong directives)
- Unused imports in main.dart
- Asset directories not found (assets/images/, assets/stickers/, assets/animations/)
```

**Fix Required:** Determine correct app entry point and remove template references

---

#### 2. **Speed Dating Feature (Disabled but Still Causing Errors)**

**Impact:** MEDIUM - ~30 errors, currently in lib/\_disabled

- Speed dating code in `lib\_disabled\speed_dating\` is referenced but broken
- Missing providers: `speedDatingControllerProvider`, `speedDatingServiceProvider`
- Missing models: `SpeedDatingRound`, `SpeedDatingSession`, `UserProfile`

**Errors:** 30+ undefined class/identifier errors

**Fix Required:** Either restore speed_dating feature fully or completely remove lib/\_disabled/

---

#### 3. **firestore_schema.dart Syntax Errors**

**Impact:** HIGH - Malformed Dart syntax

```
Line 116: Expected a method, getter, setter or operator declaration
Line 116: Missing semicolon
Line 116: Undefined class 'unique'
Line 123: Library directive not in correct position
```

**Fix Required:** Review and fix syntax in [lib/core/firestore_schema.dart](lib/core/firestore_schema.dart#L116)

---

#### 4. **video_room_controller.dart - Riverpod Issues**

**Impact:** CRITICAL - 50+ errors preventing video chat

- Invalid extends: `extends StateNotifierProvider` (should be `StateNotifier`)
- All references to `state` are undefined
- Missing Riverpod provider definitions
- Wrong constructor signature

**Sample Errors:**

```
- Classes can only extend other classes (line 8)
- Extra positional arguments error
- Undefined 'state' referenced 50+ times
- Undefined 'StateNotifierProvider' and 'StateProvider'
```

**Fix Required:** Rewrite to proper Riverpod v3 StateNotifier pattern

---

#### 5. **presence_card.dart - Design System Imports Broken**

**Impact:** CRITICAL - Core widget broken

- Imports design system from `package:mixmingle` (invalid package reference)
- Missing: `DesignAnimations`, `DesignSpacing`, `DesignColors`, `DesignBorders`, `DesignTypography`, `DesignShadows`
- 50+ undefined_identifier errors

**Errors:**

```
- Target of URI doesn't exist: 'package:mixmingle/core/design_system/design_constants.dart'
- Undefined name 'DesignAnimations', 'DesignSpacing', etc.
- Missing class 'Participant'
```

**Fix Required:** Fix import paths from `package:mixmingle` to relative imports

---

#### 6. **participant_card_widget.dart**

**Impact:** MEDIUM - Missing model

- Missing [lib/models/participant.dart](lib/models/participant.dart)
- Undefined class 'Participant'

**Fix Required:** Create or restore participant model

---

#### 7. **Minor Issues (Informational)**

- Dangling library doc comments in multiple files (36 instances)
- Deprecated `.withOpacity()` calls (should use `.withValues()`) - 6 instances
- Missing `key` parameters in widget constructors - 8 instances
- Unused imports in auth_gate_root.dart, room_access_gate.dart
- Unnecessary casts in enhanced_chat_service.dart
- `BuildContext` across async gaps in video_room_view.dart

---

## Detailed Error Breakdown

| Category                | Count   | Severity | Fixable            |
| ----------------------- | ------- | -------- | ------------------ |
| Missing/Broken URIs     | 15      | HIGH     | ✅ Yes             |
| Undefined Identifiers   | 70      | HIGH     | ✅ Yes             |
| Speed Dating (Disabled) | 30      | MEDIUM   | ✅ Yes (remove)    |
| Riverpod Pattern Errors | 50      | CRITICAL | ✅ Yes             |
| Design System Imports   | 50      | CRITICAL | ✅ Yes             |
| Syntax Errors           | 5       | HIGH     | ✅ Yes             |
| Deprecated Usage        | 6       | LOW      | ✅ Yes             |
| Formatting/Style        | 44      | LOW      | ✅ Yes             |
| **TOTAL**               | **140** | —        | **✅ All fixable** |

---

## Recommended Action Plan

### Phase 1: Critical Fixes (Required to Continue)

1. **Remove FLUTTER_WEB_STARTER_TEMPLATE references**
   - Delete or rename FLUTTER_WEB_STARTER_TEMPLATE directory if exists
   - Update app_routes.dart and main.dart to proper imports

2. **Fix video_room_controller.dart**
   - Rewrite to proper Riverpod StateNotifier pattern
   - Restore provider definitions
   - Ensure all state references are valid

3. **Fix presence_card.dart imports**
   - Change `package:mixmingle` to relative imports
   - Ensure design_constants.dart is accessible

4. **Fix firestore_schema.dart**
   - Review line 116+ syntax
   - Fix library directive placement

5. **Restore participant_card_widget.dart**
   - Create missing [lib/models/participant.dart](lib/models/participant.dart)

### Phase 2: Choice Point

Choose ONE:

- **Option A:** Remove lib/\_disabled completely (loses speed dating feature)
- **Option B:** Restore speed dating feature fully (implement missing models/providers)

### Phase 3: Cleanup

- Fix deprecated .withOpacity() → .withValues()
- Add missing key parameters to widgets
- Remove unused imports
- Clean up dangling doc comments

---

## Next Steps

**BLOCKED UNTIL:** User confirms preferred action plan

**I can automatically:**

1. Remove FLUTTER_WEB_STARTER_TEMPLATE references ✅
2. Fix presence_card.dart imports ✅
3. Provide video_room_controller.dart rewrite ✅
4. Fix firestore_schema.dart ✅
5. Remove speed_dating if not needed ✅

**Please advise:**

- Should I proceed with auto-fixes?
- Delete or restore speed dating feature?
- Any other broken directories I should know about?

---

## Commands to Check

```bash
# View full error list
flutter analyze > errors_full.txt

# Check for FLUTTER_WEB_STARTER_TEMPLATE references
find . -name "*.dart" -o -name "*.yaml" | xargs grep -l "FLUTTER_WEB_STARTER_TEMPLATE"

# Check if lib/_disabled should be deleted
ls -la lib/_disabled/
```

---

**Awaiting confirmation to proceed with fixes... ⏸️**
