# Build Blocking Issues - February 7, 2026

## Executive Summary
Build is blocked by **Riverpod 3.x migration incompatibility** and **notification service API changes**.

---

## Critical Issues (Blocking Web Build)

### 1. ❌ RIVERPOD API INCOMPATIBILITY (40+ Errors)
**Root Cause**: Code uses old `StateNotifier` API, but Riverpod 3.x no longer exports these.

**Affected Files**:
- `lib/providers/friends_provider.dart`
- `lib/providers/groups_provider.dart`
- `lib/providers/room_provider.dart`
- `lib/providers/chat_provider.dart`
- `lib/providers/ui_provider.dart`

**Problem**:
- `StateNotifier` class not found
- `StateNotifierProvider` not a valid method
- `StateProvider` not found
- `.state` getter/setter not available on notifiers

**Solution**: Migrate to new Riverpod 3.x `Notifier` base class

---

### 2. ❌ NOTIFICATION SERVICE API INCOMPATIBILITY (10+ Errors)
**Root Cause**: `flutter_local_notifications` API changed - constructor signatures don't match

**Affected File**: `lib/services/notification_service.dart`

**Problems**:
- `AndroidNotificationChannel` requires 2+ positional args (now named)
- `initialize()` signature changed
- `smallIconBitmapSource` parameter no longer exists
- `show()` signature changed (now requires 3 positional args)

**Solution**: Update to new `flutter_local_notifications` 20.0.0 API

---

### 3. ⚠️ MISSING MODEL IMPORTS (5 Errors)
**Root Cause**: Model classes not imported in widgets

**Affected Files**:
- `lib/shared/widgets/video_grid_widget.dart` - missing `Participant` import
- `lib/shared/widgets/friends_sidebar_widget.dart` - missing `Friend` import
- `lib/shared/widgets/groups_sidebar_widget.dart` - missing `VideoGroup` import
- `lib/shared/widgets/top_bar_widget.dart` - missing `VideoQuality` import

---

### 4. ⚠️ FIREBASE MESSAGING HANDLER (1 Error)
**File**: `lib/main.dart`

**Problem**: `firebaseMessagingBackgroundHandler()` not defined

---

### 5. ⚠️ NOTIFICATION SERVICE METHOD (1 Error)
**File**: `lib/services/messaging_service.dart:335`

**Problem**: `notifyNewDirectMessage()` method doesn't exist on `NotificationService`

---

## Impact Summary

| Category | Count | Severity |
|----------|-------|----------|
| Riverpod API | 40+ | 🔴 CRITICAL |
| Notification API | 10+ | 🔴 CRITICAL |
| Model Imports | 5 | 🟡 MEDIUM |
| Missing Methods | 2 | 🟡 MEDIUM |

**Total Blocking Errors**: 57+

---

## Recommended Action Plan

### Phase 1: Model Imports (Quick Win)
- [ ] Add `Friend` import to `friends_sidebar_widget.dart`
- [ ] Add `Participant` import to `video_grid_widget.dart`
- [ ] Add `VideoGroup` import to `groups_sidebar_widget.dart`
- [ ] Add `VideoQuality` import to `top_bar_widget.dart`

**Estimated Time**: 10 minutes

### Phase 2: Riverpod Migration (Blocking)
- [ ] Migrate `FriendsNotifier` from `StateNotifier` to `Notifier`
- [ ] Migrate `GroupsNotifier` from `StateNotifier` to `Notifier`
- [ ] Migrate `ParticipantsNotifier` from `StateNotifier` to `Notifier`
- [ ] Migrate `ChatMessagesNotifier` from `StateNotifier` to `Notifier`
- [ ] Update all provider declarations from `StateNotifierProvider` to `NotifierProvider`
- [ ] Update all `StateProvider` declarations

**Estimated Time**: 45 minutes

### Phase 3: Notification Service API Update (Blocking)
- [ ] Update `AndroidNotificationChannel` constructors to use named parameters
- [ ] Fix `initialize()` call signature
- [ ] Fix `show()` method call signature
- [ ] Remove `smallIconBitmapSource` parameter

**Estimated Time**: 30 minutes

### Phase 4: Missing Method Implementations
- [ ] Implement `notifyNewDirectMessage()` in `NotificationService`
- [ ] Implement or fix `firebaseMessagingBackgroundHandler()` reference

**Estimated Time**: 15 minutes

---

## Status
🔴 **BLOCKED** - Cannot proceed with build until Riverpod and notification APIs are updated.

**Quick Priority**: Fix notification service API first (easiest), then Riverpod migration (most critical).
