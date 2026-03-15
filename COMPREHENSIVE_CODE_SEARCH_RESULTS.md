# COMPREHENSIVE CODE SEARCH RESULTS

**Date:** January 26, 2026  
**Search Scope:** Entire project (lib/, web/, build/, generated/, plugins/, node_modules/, rollback_artifacts/)

---

## 1. NATIVE AGORA ENGINE CALLS (CRITICAL FINDING)

### ✅ FOUND VALID USAGE:

#### [lib/services/agora_video_service.dart](lib/services/agora_video_service.dart) - LINE 116

```dart
_engine = createAgoraRtcEngine();
```

**Type:** Valid Agora engine creation  
**Context:** Flutter package `agora_rtc_engine:^6.2.2`  
**Status:** ✅ CORRECT - This is the proper way to initialize Agora on Flutter

#### [lib/services/agora_service.dart.deprecated](lib/services/agora_service.dart.deprecated) - LINE 55

```dart
_engine = createAgoraRtcEngine();
```

**Type:** DEPRECATED CODE  
**Status:** ⚠️ FILE IS DEPRECATED - Should be ignored  
**Note:** Marked as `.deprecated` file, not active

---

## 2. HTTP CALLS / DIRECT URL ACCESS SEARCH

### ✅ RESULT: ZERO DIRECT HTTP CALLS FOUND IN lib/

**Patterns Searched:**

- `http.get(` - **NOT FOUND**
- `http.post(` - **NOT FOUND**
- `fetch(` - **NOT FOUND** (in Dart code)
- `XMLHttpRequest` - **NOT FOUND** (in Dart code)
- `cloudfunctions.net` - **NOT FOUND** (in Dart code)
- `generateAgoraToken` direct HTTP - **NOT FOUND**

---

## 3. AGORA SDK INTEGRATION POINTS

### Imports Found (ALL VALID):

| File                                                                                                                       | Line | Content                                                                          | Status   |
| -------------------------------------------------------------------------------------------------------------------------- | ---- | -------------------------------------------------------------------------------- | -------- |
| [lib/services/agora_video_service.dart](lib/services/agora_video_service.dart)                                             | 2    | `import 'package:agora_rtc_engine/agora_rtc_engine.dart'`                        | ✅ Valid |
| [lib/services/agora_video_service.dart](lib/services/agora_video_service.dart)                                             | 13   | `import 'package:agora_rtc_engine/agora_rtc_engine.dart' as agora show UserInfo` | ✅ Valid |
| [lib/features/group_chat/providers/group_chat_providers.dart](lib/features/group_chat/providers/group_chat_providers.dart) | 1    | `import 'package:agora_rtc_engine/agora_rtc_engine.dart'`                        | ✅ Valid |
| [lib/features/room/screens/room_page.dart](lib/features/room/screens/room_page.dart)                                       | 3    | `import 'package:agora_rtc_engine/agora_rtc_engine.dart'`                        | ✅ Valid |
| [lib/features/room/screens/voice_room_page.dart](lib/features/room/screens/voice_room_page.dart)                           | 4    | `import 'package:agora_rtc_engine/agora_rtc_engine.dart'`                        | ✅ Valid |
| [lib/features/speed_dating/speed_dating_room_page.dart](lib/features/speed_dating/speed_dating_room_page.dart)             | 4    | `import 'package:agora_rtc_engine/agora_rtc_engine.dart'`                        | ✅ Valid |
| [lib/shared/widgets/enhanced_stage_layout.dart](lib/shared/widgets/enhanced_stage_layout.dart)                             | 2    | `import 'package:agora_rtc_engine/agora_rtc_engine.dart'`                        | ✅ Valid |
| [lib/shared/widgets/permission_aware_video_view.dart](lib/shared/widgets/permission_aware_video_view.dart)                 | 3    | `import 'package:agora_rtc_engine/agora_rtc_engine.dart'`                        | ✅ Valid |
| [lib/shared/widgets/video_tile.dart](lib/shared/widgets/video_tile.dart)                                                   | 2    | `import 'package:agora_rtc_engine/agora_rtc_engine.dart'`                        | ✅ Valid |

---

## 4. PROJECT CONFIGURATION

### pubspec.yaml

```yaml
agora_rtc_engine: ^6.2.2
```

**Status:** ✅ Proper version specified

### .flutter-plugins-dependencies

**Agora Status:**

- ✅ iOS: Configured with iris_method_channel dependency
- ✅ Android: Configured with iris_method_channel dependency
- ✅ macOS: Configured with iris_method_channel dependency
- ✅ Windows: Configured with iris_method_channel dependency
- ✅ Web: Configured with iris_method_channel dependency

---

## 5. WEB PLATFORM ARTIFACTS

### Firebase Functions JS SDK (in web/index.html)

```javascript
import {
  getFunctions,
  connectFunctionsEmulator,
} from "https://www.gstatic.com/firebasejs/10.7.1/firebase-functions.js";
```

**Status:** ✅ PRESENT - SDK properly imported

### Third-party HTTP Libraries (node_modules - IRRELEVANT TO APP LOGIC)

- `axios` - Found in `rollup` dependencies, not used in app code
- `@100mslive/hms-video-store` - Contains fetch() for HMS SDK, not Agora
- `esbuild` - Build tool fetch for downloading binaries, not app code
- CanvasKit libraries - WebAssembly fetch, not app code

**⚠️ NOTE:** These are build/dependency artifacts, not application code

---

## 6. DEPRECATED / ROLLBACK CODE (NOT ACTIVE)

### Files in [rollback_artifacts/](rollback_artifacts/)

**Status:** ✅ IGNORE - These are backup/rollback copies from previous deployments

- `20260124_231800/` - Contains old build artifacts
- `20260124_235445/` - Contains old build artifacts

**Not part of active codebase**

---

## 7. SUMMARY: ERROR "cannot read properties of undefined createrapiengine"

### Root Cause Analysis:

**The error "cannot read properties of undefined createrapiengine" indicates:**

1. **Agora SDK library is loaded but...**
2. **The `createAgoraRtcEngine()` function is not available**
3. **This happens when:**
   - ✅ Agora SDK JS bindings not loaded on web
   - ✅ Iris method channel not properly bridged
   - ✅ Web platform initialization incomplete
   - ❌ NOT a direct HTTP call problem (audit confirmed zero HTTP calls)

### What's NOT the Problem:

❌ Direct HTTP calls to `cloudfunctions.net` - **NOT FOUND**  
❌ Bypass using `http.get()` or `http.post()` - **NOT FOUND**  
❌ Stale HTTP code - **ALL CLEANED UP**  
❌ Missing Firebase Functions SDK - **CONFIGURED**

### What IS the Problem:

✅ **Agora Web bindings unavailable** - The `createAgoraRtcEngine()` function exists in Dart code but its JavaScript implementation isn't loading properly on web platform

---

## 8. FILES REQUIRING VERIFICATION

### Critical Files (Recently Modified):

1. **[lib/services/agora_video_service.dart](lib/services/agora_video_service.dart#L116)**
   - Line 116: `createAgoraRtcEngine()` call
   - Line 457-468: Token refresh and callable invocation
   - Status: ✅ Code is correct, but web SDK bindings may not be loaded

2. **[web/index.html](web/index.html)**
   - Firebase Functions SDK initialization
   - Status: ✅ Correctly configured

3. **[functions/src/index.ts](functions/src/index.ts)**
   - Backend callable function
   - Status: ✅ Properly validates auth context

---

## 9. ACTION ITEMS

### ✅ ALREADY VERIFIED:

- HTTP audit complete - Zero direct HTTP calls
- Callable API verified - Exclusive path confirmed
- Auth pipeline configured - Token refresh implemented
- Backend deployed and active
- Firebase Web SDK initialized

### 🔴 NEEDS INVESTIGATION:

1. **Agora Web JS bindings loading** - Where is `createAgoraRtcEngine` coming from?
2. **Console error trace** - Full error message and stack trace needed
3. **Network tab** - Check if Agora SDK JS library loading successfully
4. **Firefox/Safari test** - Verify it's not Chrome-specific issue

---

## CONCLUSION

**HTTP audit verdict: CLEAN** ✅  
All HTTP calls have been removed. No direct URL calls to cloudfunctions.net exist in application code.

**The actual problem:** Agora Web SDK initialization, not authentication or HTTP calls.

**Next steps:** Check browser console for full error message, verify Agora SDK JS is loading, test `createAgoraRtcEngine` availability in web platform context.
