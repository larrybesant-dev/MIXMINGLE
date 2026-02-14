# Critical Fixes Action Plan
**Priority Level:** 🔴 CRITICAL BLOCKER
**Estimated Duration:** 2-3 hours
**Start Date:** Today

---

## Fix Implementation Roadmap

### PHASE 1: Riverpod Imports (45 min) 🔴 CRITICAL
These must be fixed for ANY provider to work.

#### Step 1.1: Fix lib/providers/ui_provider.dart
```dart
// ADD at top after Flutter imports:
import 'package:riverpod/riverpod.dart';
```
**Lines to update:** 7, 10, 15, 18, 19, 22, 25, 28, 96, 101, 124

#### Step 1.2: Fix lib/providers/chat_provider.dart
```dart
import 'package:riverpod/riverpod.dart';
```
**Lines to update:** 120

#### Step 1.3: Fix lib/providers/room_provider.dart
```dart
import 'package:riverpod/riverpod.dart';
```
**Lines to update:** 7, 110

#### Step 1.4: Fix lib/providers/friends_provider.dart
```dart
import 'package:riverpod/riverpod.dart';
```
**Lines to update:** 117, 122

#### Step 1.5: Fix lib/providers/groups_provider.dart
```dart
import 'package:riverpod/riverpod.dart';
```
**Lines to update:** 126, 159

#### Step 1.6: Fix lib/providers/notification_provider.dart
```dart
import 'package:riverpod/riverpod.dart';
```
**Lines to update:** 245

---

### PHASE 2: Container Widget Fixes (20 min) 🔴 CRITICAL

#### Issue: Container doesn't have `border` parameter
**Solution:** Use `decoration` parameter instead

#### Step 2.1: Fix lib/shared/widgets/friends_sidebar_widget.dart (Line 114)
```dart
// BEFORE:
Container(
  border: Border(...),
)

// AFTER:
Container(
  decoration: BoxDecoration(
    border: Border(...),
  ),
)
```

#### Step 2.2: Fix lib/shared/widgets/groups_sidebar_widget.dart (Lines 63, 74)
```dart
// Apply same pattern as 2.1
```

#### Step 2.3: Fix lib/shared/widgets/chat_box_widget.dart (Line 170)
```dart
// Apply same pattern as 2.1
```

---

### PHASE 3: Missing ChatMessage Properties (15 min) 🔴 CRITICAL

#### Step 3.1: Check lib/shared/models/chat_message.dart
**Currently missing:**
- `senderAvatar` (String) - accessed at lines 578, 622 in chat_box_widget.dart
- `type` (String) - accessed at line 658 in chat_box_widget.dart

**Add to ChatMessage class:**
```dart
class ChatMessage {
  final String id;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final String? senderName;
  final String? senderAvatar;  // ADD THIS
  final String type;  // ADD THIS (e.g., 'text', 'file', 'system')
  final String? fileUrl;
  final String? fileName;

  // ... rest of implementation
}
```

---

### PHASE 4: Model Type Definitions (30 min) 🟡 HIGH PRIORITY

#### Step 4.1: Find or Create Participant Type
**Used in:** lib/shared/widgets/video_grid_widget.dart:148

**Search for existing:**
```bash
find lib -name "*.dart" -exec grep -l "class Participant" {} \;
```

**If missing, create:** lib/shared/models/participant.dart
```dart
class Participant {
  final String userId;
  final String name;
  final String? avatarUrl;
  final bool isMuted;
  final bool isVideoOff;
  final DateTime joinedAt;
  // ... other properties
}
```

#### Step 4.2: Find or Create Friend Type
**Used in:** lib/shared/widgets/friends_sidebar_widget.dart:110, 282, 321

**Search for existing:**
```bash
find lib -name "*.dart" -exec grep -l "class Friend" {} \;
```

**If missing, create:** lib/shared/models/friend.dart
```dart
class Friend {
  final String userId;
  final String name;
  final String? avatarUrl;
  final bool isOnline;
  final DateTime lastSeen;
  // ... other properties
}
```

#### Step 4.3: Find or Create VideoGroup Type
**Used in:** lib/shared/widgets/groups_sidebar_widget.dart:310, 337

#### Step 4.4: Find or Create VideoQuality Enum
**Used in:** lib/shared/widgets/top_bar_widget.dart:223-227

**Should be:**
```dart
enum VideoQuality {
  low,
  medium,
  high,
}
```

---

### PHASE 5: JS Context Fixes (20 min) 🟡 HIGH PRIORITY

#### Step 5.1: Add analyzer suppression to agora_web_bridge_v2.dart
```dart
// At file top, after imports:
// ignore_for_file: avoid_web_libraries_in_flutter, undefined_identifier

// Then wrap js.context usage with platform check:
if (kIsWeb) {
  try {
    final bridge = js.context['agoraWeb'];
    // ... use bridge
  } catch (e) {
    debugPrint('[BRIDGE] Error: $e');
    return false;
  }
}
```

#### Step 5.2: Apply same fix to agora_web_bridge_v3.dart

---

### PHASE 6: Notification Service Updates (30 min) 🟡 HIGH PRIORITY

#### Issue: flutter_local_notifications API changed in v20.0.0

**Breaking Changes:**
- AndroidNotificationChannel now requires: id (String), name (String), description (String)
- `Importance.default_` → `Importance.none` or `Importance.low`
- Various parameter names changed

**Action:** Review and update all AndroidNotificationChannel constructors in:
`lib/services/notification_service.dart` (Lines: 136, 149, 161, 173, 186, 190)

**Reference:** Check package documentation for v20.0.0 API

---

### PHASE 7: Type Mismatches (10 min) 🟡 HIGH PRIORITY

#### Step 7.1: Fix lib/features/settings/account_settings_page.dart:384
```dart
// BEFORE:
downloadJsonOnWeb(uint8List, filename);  // uint8List is Uint8List, not String

// AFTER:
// Option 1: Convert to String
String jsonString = utf8.decode(uint8List);
downloadJsonOnWeb(jsonString, filename);

// Option 2: Update function signature to accept Uint8List
// (Check what downloadJsonOnWeb expects)
```

---

## Testing After Each Phase

```bash
# After each phase, run:
flutter test 2>&1 | grep -E "^[0-9]+\:[0-9]+ \+.*Error"

# Or full test:
flutter test
```

---

## Validation Checklist

### Pre-Fix
- [ ] Run `flutter analyze` to capture baseline
- [ ] Run `flutter test` to get baseline failure count

### Post-Phase 1
- [ ] [ ] All provider files compile
- [ ] [ ] `flutter analyze` should show fewer errors
- [ ] [ ] Test count improves

### Post-Phase 2
- [ ] [ ] No Container widget errors
- [ ] [ ] Chat box widget compiles
- [ ] [ ] Friends/Groups sidebars compile

### Post-Phase 3
- [ ] [ ] ChatMessage type fully defined
- [ ] [ ] Chat tests pass

### Post-Phase 4
- [ ] [ ] All model types found or created
- [ ] [ ] Type references resolved
- [ ] [ ] Widget tests run

### Post-Phase 5
- [ ] [ ] JS context errors suppressed
- [ ] [ ] Web build doesn't crash on analyzer

### Post-Phase 6
- [ ] [ ] Notification service compiles
- [ ] [ ] Android notification tests pass

### Post-Phase 7
- [ ] [ ] All type mismatches resolved
- [ ] [ ] Settings page compiles

### Final Validation
- [ ] `flutter test` returns: `All tests passed`
- [ ] `flutter analyze` returns clean
- [ ] App runs on Chrome: `flutter run -d chrome`
- [ ] No runtime errors in console

---

## Success Criteria

✅ **Phase 1 Complete:** 0 "StateNotifier" or "StateProvider" errors
✅ **Phase 2 Complete:** 0 "Container(border: ...)" errors
✅ **Phase 3 Complete:** ChatMessage has senderAvatar & type
✅ **Phase 4 Complete:** 4 missing types are defined
✅ **Phase 5 Complete:** JS context errors suppressed
✅ **Phase 6 Complete:** Notification service compiles
✅ **Phase 7 Complete:** No type mismatch warnings

**Overall:** Test suite runs with ≥95% pass rate (420/424 tests)

---

## Resources & References

- [Riverpod Documentation](https://riverpod.dev/docs/getting_started)
- [Flutter Container Widget](https://api.flutter.dev/flutter/widgets/Container-class.html)
- [flutter_local_notifications v20.0.0](https://pub.dev/packages/flutter_local_notifications)
- [Agora Flutter Documentation](https://docs.agora.io/en/video-calling/get-started/get-started-sdk)

---

**Owner:** QA Automation System
**Status:** Ready for Implementation
**Last Updated:** Today
