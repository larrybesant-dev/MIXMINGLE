# MixMingle - Complete Error Catalog

**Generated:** January 26, 2026
**Total Errors:** 139
**Total Warnings:** 50+

---

## Table of Contents
1. [Critical Errors (21)](#critical-errors)
2. [High Priority Errors (45)](#high-priority-errors)
3. [Medium Priority Errors (35)](#medium-priority-errors)
4. [Low Priority Warnings (50+)](#low-priority-warnings)

---

## Critical Errors

### CATEGORY: Riverpod Architecture (8 errors)

**Location:** `lib/providers/messaging_providers.dart`

| # | Line | Error | Impact | Fix Complexity |
|---|------|-------|--------|-----------------|
| 1 | 25 | `'RoomMessagesController' doesn't conform to bound 'Notifier<AsyncValue<List<Message>>>'` | Provider won't compile | HIGH |
| 2 | 25 | `Argument type 'RoomMessagesController Function(String, dynamic)' can't be assigned to 'RoomMessagesController Function(String)'` | Provider parameter mismatch | HIGH |
| 3 | 26 | `Too many positional arguments: 0 expected, but 1 found` | Constructor call wrong | HIGH |
| 4 | 29 | `Classes can only extend other classes` | RoomMessagesController extends non-class | HIGH |
| 5 | 188 | `'DirectMessageController' doesn't conform to bound 'Notifier<AsyncValue<List<DirectMessage>>>'` | Provider won't compile | HIGH |
| 6 | 188 | `Argument type 'DirectMessageController Function(String, dynamic)' can't be assigned to 'DirectMessageController Function(String)'` | Provider parameter mismatch | HIGH |
| 7 | 189 | `Too many positional arguments: 0 expected, but 1 found` | Constructor call wrong | HIGH |
| 8 | 192 | `Classes can only extend other classes` | DirectMessageController extends non-class | HIGH |

**Cascading Errors:** Lines 38-313 contain 40+ "Undefined name 'ref'" and "Undefined name 'state'" errors caused by these architecture issues.

---

**Location:** `lib/features/voice_room/services/advanced_mic_service.dart`

| # | Line | Error | Impact | Fix Complexity |
|---|------|-------|--------|-----------------|
| 9 | 74 | `The function 'StateNotifierProvider' isn't defined` | Provider not found | HIGH |
| 10 | 81 | `Classes can only extend other classes` | StateNotifier is not a class | HIGH |
| 11 | 86 | `Too many positional arguments: 0 expected, but 1 found` | Constructor signature wrong | HIGH |
| 12-20 | 97, 102, 109, 116, 123, 128 | `Undefined name 'state'` (8 errors) | State not accessible in notifier | HIGH |

**Root Cause:** Riverpod v3 API changed. StateNotifierProvider signature incorrect.

---

**Location:** `lib/features/voice_room/services/room_recording_service.dart`

| # | Line | Error | Impact | Fix Complexity |
|---|------|-------|--------|-----------------|
| 21 | 171 | `The function 'StateNotifierProvider' isn't defined` | Provider not found | HIGH |
| 22 | 176 | `Classes can only extend other classes` | StateNotifier is not a class | HIGH |
| 23-28 | 189-220 | `Undefined name 'state'` (6 errors) | State not accessible in notifier | HIGH |

---

### CATEGORY: Import & Reference Errors (4 errors)

**Location:** `lib/features/room/widgets/spotlight_view.dart`

| # | Line | Error | Message | Fix |
|---|------|-------|---------|-----|
| 29 | 3 | `uri_does_not_exist` | Target of URI doesn't exist: '../../shared/models/camera_state.dart' | Change to package import |
| 30 | 6 | `undefined_class` | Undefined class 'CameraState' | Caused by import error |
| 31 | 8 | `non_type_as_type_argument` | The name 'CameraState' isn't a type, so it can't be used as a type argument | Caused by import error |
| 32 | 9 | `undefined_class` | Undefined class 'CameraState' | Caused by import error |

**Cascading:** These 4 errors cause 15+ additional errors in the file.

---

### CATEGORY: Invalid Widget Property Access (1 error)

**Location:** `lib/features/voice_room/widgets/room_moderation_widget.dart`

| # | Line | Error | Details | Fix |
|---|------|-------|---------|-----|
| 33 | 196 | `undefined_getter` | The getter 'data' isn't defined for the type 'Widget' | Remove .data property access from Text widget |

**Details:** Trying to access `.data` on a Text widget in a DropdownMenuItem. Text widgets don't expose content as property.

---

### CATEGORY: Missing Service Methods (9 errors)

**Location:** `lib/providers/event_dating_providers.dart`

| # | Line | Error | Method | Service | Fix |
|---|------|-------|--------|---------|-----|
| 34 | 369 | `undefined_method` | 'findActiveSession' | SpeedDatingService | Implement method |
| 35 | 378 | `undefined_method` | 'findPartner' | SpeedDatingService | Implement method |
| 36 | 382 | `undefined_method` | 'getSession' | SpeedDatingService | Implement method |
| 37 | 387 | `undefined_method` | 'createSession' | SpeedDatingService | Implement method |
| 38 | 404 | `undefined_method` | 'cancelSession' | SpeedDatingService | Implement method |
| 39 | 426 | `undefined_method` | 'submitDecision' | SpeedDatingService | Implement method |
| 40 | 445 | `undefined_method` | 'startNextRound' | SpeedDatingService | Implement method |
| 41 | 458 | `undefined_method` | 'endSession' | SpeedDatingService | Implement method |
| 42 | 472 | `undefined_method` | 'getSession' (again) | SpeedDatingService | Implement method |

---

## High Priority Errors

### CATEGORY: Type Mismatches (15 errors)

**Location:** `lib/features/speed_dating/screens/speed_dating_lobby_page.dart`

| # | Line | Error | Current | Expected | Fix |
|---|------|-------|---------|----------|-----|
| 43 | 62 | `undefined_enum_constant` | No constant named 'active' in 'SpeedDatingStatus' | Add 'active' to enum | Update model |
| 44 | 63 | `argument_type_not_assignable` | Duration assigned to int | int (milliseconds) | Convert duration |
| 45 | 133 | `undefined_getter` | SpeedDatingSession has no 'participants' getter | Add getter | Update model |
| 46 | 338 | `argument_type_not_assignable` | String assigned to bool | bool | Check widget API |
| 47 | 338 | `extra_positional_arguments` | Too many positional args: 2 found, 1 expected | Review constructor | Fix call site |
| 48 | 355 | `argument_type_not_assignable` | String assigned to bool | bool | Check widget API |
| 49 | 355 | `extra_positional_arguments` | Too many positional args | Review constructor | Fix call site |

---

**Location:** `lib/features/events/screens/event_details_screen.dart`

| # | Line | Error | Current | Expected | Fix |
|---|------|-------|---------|----------|-----|
| 50 | 353 | `argument_type_not_assignable` | String? assigned to String | String | Add null coalescing |

---

**Location:** `lib/features/matching/screens/matches_list_page.dart`

| # | Line | Error | Current | Expected | Fix |
|---|------|-------|---------|----------|-----|
| 51 | 213 | `argument_type_not_assignable` | String? assigned to String | String | Add null coalescing |
| 52 | 283 | `argument_type_not_assignable` | String? assigned to String | String | Add null coalescing |

---

**Location:** `lib/features/profile/screens/user_profile_page.dart`

| # | Line | Error | Current | Expected | Fix |
|---|------|-------|---------|----------|-----|
| 53 | 130 | `argument_type_not_assignable` | String? assigned to String | String | Add null coalescing |
| 54 | 417 | `missing_required_argument` | Missing 'description' parameter | description: String | Add parameter |
| 55 | 417 | `missing_required_argument` | Missing 'reportedUserId' parameter | reportedUserId: String | Add parameter |
| 56 | 417 | `missing_required_argument` | Missing 'type' parameter | type: String | Add parameter |
| 57 | 417 | `extra_positional_arguments_could_be_named` | 2 positional args passed | Use named args | Change to named |

---

**Location:** `lib/features/speed_dating/screens/speed_dating_decision_page.dart`

| # | Line | Error | Current | Expected | Fix |
|---|------|-------|---------|----------|-----|
| 58 | 108 | `argument_type_not_assignable` | String? assigned to String | String | Add null coalescing |

---

**Location:** `lib/features/onboarding_flow.dart`

| # | Line | Error | Details | Fix |
|---|------|-------|---------|-----|
| 59 | 273 | `undefined_named_parameter` | The named parameter 'style' isn't defined | Check widget signature |

---

### CATEGORY: Event/Gaming Service Methods (20 errors)

**Location:** `lib/providers/event_dating_providers.dart`

| # | Line | Error | Type | Details |
|---|------|-------|------|---------|
| 60 | 141 | `const_with_non_constant_argument` | Constant expression | Non-constant value in const Event |
| 61 | 153 | `argument_type_not_assignable` | Type mismatch | String passed where Event expected |
| 62-65 | 153, 170, 186, 201 | `extra_positional_arguments` | Constructor | Too many positional arguments to Event |
| 66 | 475 | `argument_type_not_assignable` | Type mismatch | Object? to SpeedDatingSession? |

---

**Location:** `lib/providers/gamification_payment_providers.dart`

| # | Line | Error | Method | Service | Fix |
|---|------|-------|--------|---------|-----|
| 67 | 92 | `undefined_method` | 'getAvailableAchievements' | GamificationService | Implement |
| 68 | 98 | `undefined_getter` | 'currentXP' | UserLevel model | Add getter |
| 69 | 115 | `undefined_method` | 'getLeaderboard' | GamificationService | Implement |
| 70 | 141 | `undefined_method` | 'awardXP' | GamificationService | Implement |
| 71 | 157 | `undefined_method` | 'checkDailyStreak' | GamificationService | Implement |
| 72 | 173 | `undefined_method` | 'unlockAchievement' | GamificationService | Implement |
| 73 | 194 | `missing_required_argument` | 'badgeId' parameter | UserBadge | Add parameter |
| 74 | 194 | `missing_required_argument` | 'userId' parameter | UserBadge | Add parameter |
| 75 | 194 | `extra_positional_arguments_could_be_named` | Positional args | UserBadge constructor | Use named args |
| 76 | 213 | `undefined_method` | 'getPaymentMethods' | PaymentService | Implement |
| 77 | 227 | `undefined_method` | 'getPaymentHistory' | PaymentService | Implement |
| 78 | 262 | `undefined_method` | 'processPayment' | PaymentService | Implement |
| 79 | 287 | `undefined_method` | 'addPaymentMethod' | PaymentService | Implement |
| 80 | 303 | `undefined_method` | 'removePaymentMethod' | PaymentService | Implement |
| 81 | 317 | `undefined_method` | 'refundPayment' | PaymentService | Implement |
| 82 | 356 | `undefined_method` | 'setCurrentScreen' | AnalyticsService | Implement |
| 83 | 83 | `yield_of_invalid_type` | Type mismatch | List<UserBadge> to List<Map> | Check yield type |
| 84 | 347 | `argument_type_not_assignable` | Type mismatch | Map<String, dynamic>? to Map<String, Object>? | Fix type |

---

## Medium Priority Errors

### CATEGORY: Deprecated API Usage (50+ warnings)

**Location:** `lib/features/room/widgets/camera_tile.dart`

| # | Line | API | Replacement | Count |
|---|------|-----|-------------|-------|
| 85-88 | 104, 105, 177, 211 | `withOpacity()` | `.withValues(alpha:...)` | 4 |
| 89 | 10 | `use_super_parameters` | Add `super.` in constructor | 1 |

---

**Location:** `lib/features/room/widgets/camera_quality_selector.dart`

| # | Line | API | Replacement | Count |
|---|------|-----|-------------|-------|
| 90-91 | 139, 140 | Radio `groupValue`/`onChanged` | Use RadioGroup ancestor | 2 |
| 92 | 11 | `use_super_parameters` | Add `super.` | 1 |

---

**Location:** `lib/features/room/widgets/dynamic_video_grid.dart`

| # | Line | API | Replacement | Count |
|---|------|-----|-------------|-------|
| 93-94 | 211, 230 | `withOpacity()` | `.withValues(alpha:...)` | 2 |

---

**Location:** `lib/features/voice_room/widgets/advanced_mic_control_widget.dart`

| # | Line | API | Replacement | Count |
|---|------|-----|-------------|-------|
| 95 | 315 | `activeColor` | `activeThumbColor` | 1 |
| 96 | 16 | `use_super_parameters` | Add `super.` | 1 |

---

**Location:** `lib/features/voice_room/widgets/room_recording_widget.dart`

| # | Line | API | Replacement | Count |
|---|------|-----|-------------|-------|
| 97 | 268 | `activeColor` | `activeThumbColor` | 1 |
| 98 | 18 | `use_super_parameters` | Add `super.` | 1 |

---

**Location:** `lib/features/room/widgets/spotlight_view.dart`

| # | Line | API | Replacement | Count |
|---|------|-----|-------------|-------|
| 99 | 25 | `WillPopScope` | `PopScope` | 1 |
| 100 | 12 | `use_super_parameters` | Add `super.` | 1 |

---

**Location:** Multiple widget files

| # | Line | API | Type | Count |
|---|------|-----|------|-------|
| 101-105 | Various | `use_super_parameters` | Constructor | 15+ |
| 106 | Various | `deprecated_member_use` | Radio/Switch APIs | 2+ |

---

### CATEGORY: Unused Code (4 warnings)

| # | File | Line | Type | Variable |
|---|------|------|------|----------|
| 107 | `lib/services/agora_video_service.dart` | 44 | Field | `_isLiveStreamingMode` |
| 108 | `lib/shared/models/mic_queue_indicator.dart` | 3 | Import | `MicState` |
| 109 | `lib/shared/models/pinned_messages_bar.dart` | 3 | Import | `ChatMessage` |
| 110 | `lib/services/auto_moderation_service.dart` | 218 | Variable | `bannedUsers` |

---

### CATEGORY: Async/Context Issues (3 warnings)

| # | File | Line | Issue | Description |
|---|------|------|-------|-------------|
| 111 | `lib/features/voice_room/widgets/enhanced_chat_widget.dart` | 411 | `use_build_context_synchronously` | BuildContext used after async gap |
| 112 | `lib/features/voice_room/widgets/room_recording_widget.dart` | 343 | `use_build_context_synchronously` | BuildContext used after async gap with mounted check |
| 113 | `lib/features/voice_room/widgets/room_recording_widget.dart` | 344 | `use_build_context_synchronously` | BuildContext used after async gap with mounted check |

---

### CATEGORY: Code Quality Issues (4 warnings)

| # | File | Line | Issue | Type |
|---|------|------|-------|------|
| 114 | `lib/features/voice_room/widgets/pinned_messages_bar.dart` | 73 | `unnecessary_to_list_in_spreads` | Unnecessary toList() |
| 115 | `lib/services/chat_service.dart` | 561 | `unnecessary_cast` | Unnecessary type cast |
| 116 | `lib/features/voice_room/widgets/analytics_dashboard_widget.dart` | 394 | `invalid_constant` | Invalid const expression |
| 117 | `lib/features/voice_room/services/agora_video_service.dart` | 44 | `prefer_final_fields` | Should be final |

---

## Low Priority Warnings

### CATEGORY: Print Statements in Production (6 warnings)

**Location:** `update_agora_config.dart`

| # | Line | Issue | Severity |
|---|------|-------|----------|
| 118 | 14 | `avoid_print` | Remove print() calls |
| 119 | 26 | `avoid_print` | Remove print() calls |
| 120 | 27 | `avoid_print` | Remove print() calls |
| 121 | 28 | `avoid_print` | Remove print() calls |
| 122 | 29 | `avoid_print` | Remove print() calls |
| 123 | 30 | `avoid_print` | Remove print() calls |
| 124 | 31 | `avoid_print` | Remove print() calls |
| 125 | 35 | `avoid_print` | Remove print() calls |

---

### CATEGORY: Constructor Super Parameters (20+ warnings)

**Files:** Multiple widget files

| # | Issue | Count | Details |
|---|-------|-------|---------|
| 126 | `use_super_parameters` | 20+ | Add `super.` to constructors with `Key? key` parameter |

**Example:**
```dart
// ❌ OLD
class MyWidget extends StatelessWidget {
  const MyWidget({Key? key}) : super(key: key);
}

// ✅ NEW (Dart 3.0+)
class MyWidget extends StatelessWidget {
  const MyWidget({super.key});
}
```

---

## Summary Statistics

```
CRITICAL ERRORS:        21
├─ Riverpod errors:     8
├─ Import errors:       4
├─ Missing methods:     9

HIGH PRIORITY:          45
├─ Type mismatches:    15
├─ Missing methods:    20
├─ Missing params:      4
├─ Wrong models:        6

MEDIUM PRIORITY:        35
├─ Deprecated APIs:    30
├─ Unused code:         4
├─ Code quality:        1

WARNINGS:              50+
├─ Async/Context:       3
├─ Print statements:    8
├─ Super parameters:   20+
├─ Code quality:        4
└─ Unused code:         1

TOTAL COMPILATION BLOCKERS: 21
TOTAL FUNCTIONAL ISSUES:    45
TOTAL WARNINGS:            50+
───────────────────────────────────
TOTAL ISSUES:               139
```

---

## Error Distribution by File

| File | Critical | High | Medium | Total |
|------|----------|------|--------|-------|
| `lib/providers/messaging_providers.dart` | 8 | 50+ | 0 | 58+ |
| `lib/features/voice_room/services/advanced_mic_service.dart` | 4 | 8 | 0 | 12 |
| `lib/features/voice_room/services/room_recording_service.dart` | 4 | 0 | 0 | 4 |
| `lib/features/room/widgets/spotlight_view.dart` | 4 | 0 | 2 | 6 |
| `lib/features/voice_room/widgets/room_moderation_widget.dart` | 1 | 0 | 0 | 1 |
| `lib/providers/event_dating_providers.dart` | 0 | 9 | 0 | 9 |
| `lib/providers/gamification_payment_providers.dart` | 0 | 20 | 0 | 20 |
| `lib/features/speed_dating/screens/speed_dating_lobby_page.dart` | 0 | 7 | 0 | 7 |
| Other deprecation warnings | 0 | 0 | 50+ | 50+ |
| **TOTAL** | **21** | **45+** | **50+** | **139** |

---

## Fixing Strategy

1. **Start with Critical Errors (Day 1)** - These prevent any compilation
2. **Then High Priority (Day 2)** - These break features
3. **Then Medium Priority (Day 3)** - Deprecated APIs and warnings
4. **Finally Cleanup (Day 4)** - Code quality improvements

Estimated total fix time: **2-3 days** for one developer

