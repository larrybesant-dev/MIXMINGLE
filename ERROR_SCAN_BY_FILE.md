# Error Scan Results - Quick Reference by File
**Generated:** February 7, 2026
**Total Errors:** 51 across 15 files
**Organization:** Ordered by number of errors (descending)

---

## 1. lib/services/notification_service.dart
**Error Count:** 13
**Severity:** 🔴 Critical (1) | 🟠 High (12)
**Primary Issue:** flutter_local_notifications v20 API incompatibility

| Line(s) | Type | Issue | Fix |
|---------|------|-------|-----|
| 136, 149, 161, 173, 186 | ConstructorSignature | AndroidNotificationChannel constructor incompatible with v20 API. Expected: positional parameters (id, name, description) | Change to: `AndroidNotificationChannel('id_value', 'Name', 'description', importance: ...)` |
| 190, 423 | InvalidEnumValue | `Importance.default_` doesn't exist in v20 | Replace with: `Importance.low` |
| 141, 154, 166, 178, 191, 337 | DeprecatedParameter | `enableSound` parameter doesn't exist in v20 AndroidNotificationChannel | Remove the parameter |
| 143, 339 | DeprecatedParameter | `playSound` parameter doesn't exist in v20 AndroidNotificationChannel | Remove the parameter |
| 356 | MethodSignature | `notify()` method signature changed | Verify correct signature in v20 docs |

**Fix Time:** 45 minutes
**Complexity:** Medium (requires understanding of v20 API changes)

---

## 2. lib/services/agora_web_bridge_v2.dart
**Error Count:** 12
**Severity:** 🔴 Critical
**Primary Issue:** js.context access without platform guard

| Line(s) | Type | Issue | Fix |
|---------|------|-------|-----|
| 13, 29, 73, 101, 121, 142, 162, 183, 211, 234, 271, 306 | UndefinedName | `js.context` accessed without proper guard. Analyzer doesn't recognize it during compilation | Add at file top: `// ignore: avoid_web_libraries_in_flutter`. Wrap access in: `if (kIsWeb) { try { var x = js.context['key']; } catch(e) {} }` |

**Fix Time:** 10 minutes
**Complexity:** Low (copy pattern to all locations)

---

## 3. lib/services/video_engines/agora_web_engine.dart
**Error Count:** 9
**Severity:** 🔴 Critical
**Primary Issue:** js.context access without platform guard

| Line(s) | Type | Issue | Fix |
|---------|------|-------|-----|
| 57, 102, 146, 180, 216, 254, 292, 331, 374 | UndefinedName | `js.context` accessed without proper guard | Same as above: Add directive and platform check |

**Fix Time:** 10 minutes
**Complexity:** Low (same pattern)

---

## 4. lib/services/agora_web_bridge_v3.dart
**Error Count:** 10
**Severity:** 🔴 Critical
**Primary Issue:** js.context access without platform guard

| Line(s) | Type | Issue | Fix |
|---------|------|-------|-----|
| 13, 14, 33, 70, 102, 130, 155, 179, 204, 220 | UndefinedName | `js.context` accessed without proper guard | Same fix pattern: Add directive and platform check |

**Fix Time:** 10 minutes
**Complexity:** Low (same pattern)

---

## 5. lib/services/agora_web_service.dart
**Error Count:** 6
**Severity:** 🔴 Critical
**Primary Issue:** js.context access without platform guard

| Line(s) | Type | Issue | Fix |
|---------|------|-------|-----|
| 8, 33, 39, 62, 69, 75 | UndefinedName | `js.context` accessed without proper guard | Same fix pattern: Add directive and platform check |

**Fix Time:** 5 minutes
**Complexity:** Low (same pattern)

---

## 6. lib/shared/widgets/chat_box_widget.dart
**Error Count:** 4
**Severity:** 🔴 Critical (3) | 🟡 Medium (1)
**Primary Issue:** Missing ChatMessage properties + Container widget issue

| Line(s) | Type | Issue | Fix |
|---------|------|-------|-----|
| 578, 622 | MissingProperty | Code accesses `message.senderAvatar` but property doesn't exist on ChatMessage class | Add to ChatMessage class: `final String? senderAvatar;` |
| 658 | MissingProperty | Code accesses `message.type` but property doesn't exist on ChatMessage class | Add to ChatMessage class: `final String? type;` |
| 170 | InvalidParameter | Using `border:` parameter on Container which doesn't exist | Wrap in decoration: `container(decoration: BoxDecoration(border: Border(...)))` |

**Fix Time:** 10 minutes
**Complexity:** Low-Medium

---

## 7. lib/shared/widgets/friends_sidebar_widget.dart
**Error Count:** 4
**Severity:** 🔴 Critical (3) | 🟡 Medium (1)
**Primary Issue:** Missing Friend type import + Container widget issue

| Line(s) | Type | Issue | Fix |
|---------|------|-------|-----|
| 110, 282, 321 | MissingImport | Code uses `List<Friend>` but Friend type not imported | Add import: `import '../../providers/app_models.dart';` (includes Friend, VideoGroup, VideoQuality) |
| 113-118 | InvalidParameter | Using `border:` parameter on Container directly | Wrap in decoration: `Container(decoration: BoxDecoration(border: Border(...)))` |

**Fix Time:** 5 minutes
**Complexity:** Low

---

## 8. lib/shared/widgets/groups_sidebar_widget.dart
**Error Count:** 3
**Severity:** 🔴 Critical (1) | 🟡 Medium (2)
**Primary Issue:** Missing VideoGroup import + Container widget issues

| Line(s) | Type | Issue | Fix |
|---------|------|-------|-----|
| 337 | MissingImport | Code uses `VideoGroup` type but it's not imported | Add import: `import '../../providers/app_models.dart';` |
| 63, 74 | InvalidParameter | Using `border:` parameter on Container directly (2 locations) | Wrap in decoration: `Container(decoration: BoxDecoration(border: Border(...)))` |

**Fix Time:** 5 minutes
**Complexity:** Low

---

## 9. lib/shared/widgets/top_bar_widget.dart
**Error Count:** 3
**Severity:** 🔴 Critical
**Primary Issue:** Missing VideoQuality enum import

| Line(s) | Type | Issue | Fix |
|---------|------|-------|-----|
| 223, 225, 227 | MissingImport | Code uses `VideoQuality.low`, `VideoQuality.medium`, `VideoQuality.high` but enum not imported | Add import: `import '../../providers/app_models.dart';` (includes VideoQuality enum) |

**Fix Time:** 2 minutes
**Complexity:** Low (single import)

---

## 10. lib/shared/widgets/video_grid_widget.dart
**Error Count:** 1
**Severity:** 🔴 Critical
**Primary Issue:** Undefined Participant type

| Line(s) | Type | Issue | Fix |
|---------|------|-------|-----|
| 148 | UndefinedType | Code uses `Participant` type but it doesn't exist anywhere in codebase | Use existing `AgoraParticipant` from `lib/shared/models/agora_participant.dart`. Change `final Participant participant;` to `final AgoraParticipant participant;` and add import: `import '../models/agora_participant.dart';` |

**Fix Time:** 5 minutes
**Complexity:** Medium (requires type substitution)

---

## 11. lib/services/agora_web_bridge_v2_simple.dart
**Error Count:** 2
**Severity:** 🔴 Critical
**Primary Issue:** js.context access without platform guard

| Line(s) | Type | Issue | Fix |
|---------|------|-------|-----|
| 10, 22 | UndefinedName | `js.context` accessed without proper guard | Same fix pattern: Add directive and platform check |

**Fix Time:** 5 minutes
**Complexity:** Low (same pattern)

---

## 12. lib/shared/models/chat_message.dart
**Error Count:** 2 (properties)
**Severity:** 🔴 Critical
**Primary Issue:** Missing class properties

| Line(s) | Type | Issue | Fix |
|---------|------|-------|-----|
| (add to class) | MissingProperty | ChatMessage class missing `senderAvatar` and `type` properties that are referenced elsewhere | Add to ChatMessage class definition: `final String? senderAvatar;` and `final String? type;`. Update constructor and copyWith if exists. |

**Fix Time:** 5 minutes
**Complexity:** Low

---

## No Errors (Already Correct) ✅

These files use the types/imports correctly:
- ✅ lib/providers/chat_provider.dart - StateNotifier correctly imported
- ✅ lib/providers/room_provider.dart - StateNotifier correctly imported
- ✅ lib/providers/app_models.dart - Contains correct type definitions
- ✅ lib/shared/models/agora_participant.dart - Correct definition

---

## Summary by Category

### Missing Imports (4 errors)
- Friend type - friends_sidebar_widget.dart
- VideoGroup type - groups_sidebar_widget.dart
- VideoQuality enum - top_bar_widget.dart
- ChatMessage properties - chat_message.dart

**Total Fix Time:** 10 minutes
**Complexity:** Low

---

### Undefined Types (1 error)
- Participant type - video_grid_widget.dart (substitute with AgoraParticipant)

**Total Fix Time:** 5 minutes
**Complexity:** Medium

---

### Container Widget Issues (4 errors)
- friends_sidebar_widget.dart: 1 location
- groups_sidebar_widget.dart: 2 locations
- chat_box_widget.dart: 1 location

**Total Fix Time:** 10 minutes
**Complexity:** Low (repeatable pattern)

---

### NotificationService API Issues (13 errors)
- Constructor signature changes: 5 locations
- Invalid enum value: 2 locations
- Deprecated parameters: 8 locations
- Method signature change: 1 location

**Total Fix Time:** 45 minutes
**Complexity:** Medium (API version mismatch)

---

### Agora JS Context Issues (49 errors)
- agora_web_bridge_v2.dart: 12 occurrences
- agora_web_bridge_v3.dart: 10 occurrences
- agora_web_service.dart: 6 occurrences
- agora_web_engine.dart: 9 occurrences
- agora_web_bridge_v2_simple.dart: 2 occurrences

**Total Fix Time:** 40 minutes
**Complexity:** Low (same pattern across all files)

---

## Suggested Fix Priority Timeline

### Day 1 - Morning (30 min) 🟦
1. **Friends & Groups Sidebars** (5 min) - Add imports
2. **Top Bar Widget** (2 min) - Add VideoQuality import
3. **Video Grid Widget** (5 min) - Replace Participant with AgoraParticipant
4. **Chat Box Widget & ChatMessage** (15 min) - Fix properties and Container

### Day 1 - Afternoon (50 min) 🟧
1. **NotificationService** (45 min) - Update v20 API
2. **Quick validation** (5 min) - Run flutter test subset

### Day 2 - Morning (40 min) 🔴
1. **Agora Web Bridges** (40 min) - Add platform guards to all js.context usage
2. **Full test suite** (10 min) - flutter test all

**Total Recommended Timeline:** 2 hours development + 30 min testing = 2.5 hours

---

## CSV Export

See [ERROR_SCAN_RESULTS.csv](ERROR_SCAN_RESULTS.csv) for machine-readable format.

---

**Report Generated By:** Automated Error Scanner
**Date:** February 7, 2026
**Status:** Complete - Ready for implementation
