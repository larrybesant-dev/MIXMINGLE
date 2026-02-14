================================================================================
⭐ COPILOT MASTER PROMPT — Full App Cleanup & Optimization
================================================================================
Last Updated: February 3, 2026
Purpose: Paste this into VS Code Copilot Chat to fix your entire app like a
         senior engineer would clean it up.

Instructions:
1. Copy the entire prompt below (between the === markers)
2. Open VS Code Copilot Chat (Ctrl+Shift+I)
3. Paste it into the chat window
4. Wait for Copilot to scan and propose fixes
5. Review the diffs before accepting

================================================================================

# ⭐ **THE EXACT VS CODE COPILOT PROMPT TO FIX YOUR APP LIKE I WOULD**

You are an expert Flutter, Firebase, and Agora engineer.

Treat this codebase as if it were your own production app.
Scan the entire project and fix everything that is incorrect, fragile, duplicated, or architecturally inconsistent, while keeping all existing features and behavior intact.

**Hard rules:**
- Do NOT rewrite the app.
- Do NOT remove features.
- Do NOT introduce placeholders or TODOs.
- Do NOT change Firestore schema.
- Do NOT break working logic.
- Make safe, minimal, targeted improvements only.

---

## Your goals:

### 🔥 1. FIX AGORA COMPLETELY

- Enforce a strict platform split:
  - Web uses the JS bridge via dart:js
  - Mobile uses the Flutter Agora plugin
- Ensure web join uses:
  ```
  js.context['agoraWeb'].callMethod('joinChannel', [appId, channelName, token, uid])
  ```
- Ensure the web branch RETURNS immediately so it never falls through to the native plugin.
- Ensure initClient() is called before joinChannel() on web.
- Ensure no JS bridge calls run on mobile.
- Ensure no native plugin calls run on web.
- Move all Agora logic into AgoraService (or equivalent).
- Validate that `agora_platform_service.dart` correctly uses conditional imports.
- Ensure `agora_web_bridge.dart` never gets imported on mobile (use stub).

### 🔥 2. FIX ROOM JOIN/LEAVE FLOW

- Create or clean up a single RoomService (or consolidate into AgoraVideoService) that handles:
  - joinRoom()
  - leaveRoom()
  - sendMessage()
  - toggleAudio()
  - toggleVideo()
  - raiseHand()
- Join flow must follow this exact order:
  1. Check auth (user != null)
  2. Check room permissions (if applicable)
  3. Call backend generateAgoraToken via Cloud Functions
  4. Write participant doc to Firestore (`rooms/{roomId}/participants/{userId}`)
  5. Join Agora (web or mobile)
  6. Update UI state (`_isJoined = true`)
- Leave flow must:
  - Leave Agora channel
  - Remove participant doc from Firestore
  - Clear all listeners and subscriptions
  - Reset UI state (`_isJoined = false`, `_isInitializing = false`)
- Ensure no race conditions between join and leave.
- Ensure guards prevent duplicate join attempts.

### 🔥 3. FIX PLATFORM ISSUES

- Wrap Crashlytics calls with:
  ```dart
  if (kIsWeb) return;
  await crashlytics.setCustomKey(...);
  ```
- Ensure kIsWeb is imported correctly:
  ```dart
  import 'package:flutter/foundation.dart' show kIsWeb;
  ```
- Remove any MissingPluginException sources (Crashlytics on web).
- Ensure web platform never calls native-only plugins.
- Validate that `flutter/foundation.dart` is imported in all files using kIsWeb.

### 🔥 4. FIX ASYNC + LISTENER ISSUES

- Remove duplicate listeners (especially in ref.listen() and StreamProvider).
- Fix race conditions in join/leave by validating state before proceeding.
- Ensure all listeners are cleaned up on leave/dispose.
- Ensure no memory leaks from streams or subscriptions.
- Validate that timers are cancelled in dispose() methods.
- Check for dangling Riverpod listeners in build() method.
- Ensure no fire-and-forget async calls (all async operations should be awaited).

### 🔥 5. CLEAN UP CODE QUALITY

- Remove dead code (unused files like agora_web_service.dart if truly unused).
- Remove unused imports.
- Remove redundant null checks where Dart null safety already handles it.
- Improve readability without changing behavior.
- Keep public APIs stable.
- Consolidate similar utility functions.

---

## 🔥 OUTPUT REQUIREMENTS

After scanning and fixing the project, output:

1. **Summary of Changes:**
   - List all files modified
   - Count of changes per file
   - Total lines added/removed

2. **Detailed Changes (per file):**
   - Filename
   - What was fixed
   - Why it was fixed (1–2 sentences)
   - Before/after code snippet (if significant)

3. **Verification Checklist:**
   - [ ] No compilation errors
   - [ ] All web platform guards in place
   - [ ] All mobile platform logic intact
   - [ ] Join/leave flows clean and sequential
   - [ ] No duplicate listeners
   - [ ] Firestore schema unchanged
   - [ ] Feature parity maintained

---

## 🔥 BEGIN NOW

Scan the entire project directory recursively.
Identify and propose all fixes according to the rules above.
Output the summary and detailed changes.

================================================================================
