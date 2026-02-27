# Riverpod 3.x Migration Status - COMPLETE (with StateProvider Issue)

## ✅ COMPLETED

### Phase 1: NotifierProvider Migration - SUCCESS

Converted all `StateNotifier`-based providers to `Notifier` pattern:

- ✅ `FriendsNotifier` (friends_provider.dart)
- ✅ `GroupsNotifier` (groups_provider.dart)
- ✅ `ParticipantsNotifier` (room_provider.dart)
- ✅ `ChatMessagesNotifier` (chat_provider.dart)
- ✅ `CameraApprovalSettingsNotifier` (ui_provider.dart)
- ✅ `UserPreferencesNotifier` (ui_provider.dart)

All `StateNotifierProvider` declarations converted to `NotifierProvider` with lambda constructors.

### Phase 2: Model Imports - SUCCESS

Added missing model imports to widgets:

- ✅ `app_models` import added to `video_grid_widget.dart`
- ✅ `app_models` import added to `friends_sidebar_widget.dart`
- ✅ `app_models` import added to `groups_sidebar_widget.dart`
- ✅ `app_models` import added to `top_bar_widget.dart`

---

## ⚠️ BLOCKING ISSUE: StateProvider Compilation Error

### Problem

StateProvider calls fail to compile with error:

```
Error: Method not found: 'StateProvider'.
final darkModeProvider = StateProvider<bool>((ref) => true);
                         ^^^^^^^^^^^^^
```

### Details

- Riverpod ^3.0.0 is properly installed (verified via `flutter pub outdated`)
- Import `package:flutter_riverpod/flutter_riverpod.dart` is present
- StateProvider syntax is standard and correct
- Issue is specific to web (dart2js) target
- Other provider types (Provider, NotifierProvider, FutureProvider) compile successfully

### Current Compilation Errors

- 13 StateProvider declarations failing
- All have same error: "Method not found"
- Affects: `ui_provider.dart`, `friends_provider.dart`, `groups_provider.dart`, `room_provider.dart`

### Attempted Fixes (unsuccessful)

1. ✗ Clean build (`flutter clean`)
2. ✗ Refresh dependencies (`flutter pub get`)
3. ✗ Changed NotifierProvider syntax from `.new` to lambda

---

## NEXT STEPS (To Unblock Build)

### Option 1: Convert StateProvider → NotifierProvider

Replace remaining `StateProvider` calls with `NotifierProvider` + simple Notifiers.
Benefits:

- Consistent with Riverpod 3.x "all state through Notifiers" philosophy
- Unblocks web compilation immediately
- Cleaner architecture long-term

Estimated time: **45 minutes**

### Option 2: Investigate Riverpod Export Issue

- Check if StateProvider needs explicit re-export
- Verify dart2js symbol visibility
- Check for Riverpod 3.x release notes about StateProvider

Estimated time: **30 minutes**

### Option 3: Downgrade to Riverpod 2.x

Would revert migration but allow immediate build.
NOT RECOMMENDED - defeats purpose of modernizing codebase.

---

## Files With StateProvider Issues

1. `lib/providers/friends_provider.dart:125` - friendSearchQueryProvider
2. `lib/providers/groups_provider.dart:162` - groupSearchQueryProvider
3. `lib/providers/room_provider.dart:7` - activeRoomIdProvider
4. `lib/providers/ui_provider.dart` - 10 providers:
   - darkModeProvider
   - videoQualityProvider
   - autoAdjustQualityProvider
   - friendsSidebarCollapsedProvider
   - groupsSidebarCollapsedProvider
   - notificationsEnabledProvider
   - soundEffectsEnabledProvider
   - reactionsEnabledProvider
   - favoriteGroupsProvider
   - pinnedFriendsProvider

---

## OTHER REMAINING ERRORS

### Model Type Mismatches (5 errors)

- `Participant` class not found (should be `VideoParticipant`)
- `Friend` type argument error (import works, but may need correction in usage)
- `ChatMessage` duplicate class in two locations

### Firebase/Notification Issues (Phase 3 - Not Yet Fixed)

- `firebaseMessagingBackgroundHandler()` not defined
- `notifyNewDirectMessage()` method missing
- AndroidNotificationChannel API changes
- BitmapSource parameter removed

---

## RECOMMENDATION

**Proceed with Option 1**: Convert StateProvider to NotifierProvider.

- Aligns with Riverpod 3.x best practices
- Unblocks build immediately
- Improves code consistency
- Clean migration path

Then move to Phase 3 with notifications (already scoped and documented).
