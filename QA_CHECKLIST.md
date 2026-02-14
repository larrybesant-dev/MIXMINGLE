================================================================================
⭐ MIX & MINGLE — FULL QA CHECKLIST (10–15 min per platform)
================================================================================
Last Updated: February 3, 2026
Status: PRODUCTION READY
Estimated Runtime: 10–15 minutes per platform (Web, Android, iOS, Desktop)

This checklist validates all critical systems with the same test flow across
all platforms. Use this before every release.

================================================================================
QUICK START
================================================================================

**Before you start:**
1. Have 2 devices ready (primary + secondary for multi-user testing)
2. Print or bookmark this file
3. Time yourself: target 10–15 minutes per platform
4. Mark ✅ as you complete each section

**Platforms to test:**
- [ ] Web (Chrome)
- [ ] Android (Emulator or Device)
- [ ] iOS (Simulator or Device)
- [ ] Desktop (Windows/Mac/Linux) — if applicable

================================================================================
1. PRE-FLIGHT CHECKS (1 minute)
================================================================================

### 1.1 Build & Lint
- [ ] Run: `flutter clean`
- [ ] Run: `flutter pub get`
- [ ] Run: `flutter analyze`
- [ ] Confirm: **0 errors** (warnings acceptable)
- [ ] Git status clean: no uncommitted changes

### 1.2 Environment Validation
- [ ] Firebase project connected and active
- [ ] Agora App ID loaded from config
- [ ] Cloud Functions deployed (`generateAgoraToken`)
- [ ] Firestore rules published
- [ ] Crashlytics enabled (mobile/desktop only)

**Status:** ⬜ NOT STARTED | ✅ PASSED | ❌ FAILED

---

================================================================================
2. AUTHENTICATION FLOW (1 minute)
================================================================================

### 2.1 Launch & Login
- [ ] Launch app on target platform
- [ ] Use test account credentials
- [ ] Wait for splash screen to complete

### 2.2 Login Verification
- [ ] Login succeeds without errors
- [ ] User document loads from Firestore
- [ ] Navigation to room lobby
- [ ] No red screens or exceptions

### 2.3 Platform-Specific Checks

**Web:**
- [ ] No Crashlytics plugin errors
- [ ] Console clean (F12 → Console)
- [ ] No `MissingPluginException` in logs

**Mobile (Android/iOS):**
- [ ] Crashlytics initialized
- [ ] No permission prompts yet (should come during room join)

**Status:** ⬜ NOT STARTED | ✅ PASSED | ❌ FAILED

---

================================================================================
3. ROOM SELECTION & NAVIGATION (1 minute)
================================================================================

### 3.1 Select a Room
- [ ] From lobby, tap a room tile
- [ ] Loading spinner appears
- [ ] No duplicate join attempts
- [ ] No immediate "Failed to join" messages

### 3.2 Pre-Join State
- [ ] `_isInitializing = true` (UI frozen during setup)
- [ ] Audio/video controls disabled (until join completes)
- [ ] Joining message or animation visible

**Status:** ⬜ NOT STARTED | ✅ PASSED | ❌ FAILED

---

================================================================================
4. TOKEN GENERATION & PERMISSIONS (1-2 minutes)
================================================================================

### 4.1 Cloud Function Execution
- [ ] Check Firebase Functions console
- [ ] Look for `generateAgoraToken` invocation
- [ ] Confirm:
  - Token generated ✅
  - UID assigned correctly ✅
  - No permission errors ✅
  - Response time < 2 seconds ✅

### 4.2 Mobile: Permission Prompts

**Android:**
- [ ] Camera permission prompt appears
- [ ] Microphone permission prompt appears
- [ ] Grant permissions to proceed

**iOS:**
- [ ] Camera permission prompt appears
- [ ] Microphone permission prompt appears
- [ ] Grant permissions to proceed

**Web:**
- [ ] Browser permission prompt appears (camera + mic)
- [ ] Grant permissions to proceed
- [ ] OR dismiss and confirm warning (optional for web testing)

**Status:** ⬜ NOT STARTED | ✅ PASSED | ❌ FAILED

---

================================================================================
5. FIRESTORE PARTICIPANT SYNC (1 minute)
================================================================================

### 5.1 Participant Document Check
Open Firebase Console → Firestore:
- [ ] Navigate to: `rooms/{roomId}/participants`
- [ ] Confirm your user document exists with fields:
  - [ ] `userId` - Your UID
  - [ ] `displayName` - Your name
  - [ ] `role` - "host" or "guest"
  - [ ] `isAudioOn` - true/false
  - [ ] `isVideoOn` - true/false
  - [ ] `joinedAt` - timestamp
  - [ ] `lastActiveAt` - recent timestamp

### 5.2 User Document Check
Open Firestore:
- [ ] Navigate to: `users/{userId}`
- [ ] Confirm:
  - [ ] `currentRoomId` = room you just joined
  - [ ] `lastRoomJoin` = recent timestamp

**Status:** ⬜ NOT STARTED | ✅ PASSED | ❌ FAILED

---

================================================================================
6. AGORA SDK JOIN VERIFICATION (2-3 minutes)
================================================================================

### 6.1 Web (Chrome) Specific

**Console Check (F12 → Console):**
- [ ] See log: `joinChannel called` (or similar)
- [ ] No JS bridge errors
- [ ] No "native plugin fallback" messages
- [ ] No `promiseToFuture` errors

**Video Verification:**
- [ ] Local video tile appears (YOUR camera)
- [ ] Video controls active (mute, video toggle)
- [ ] Remote video placeholder visible (waiting for second user)

### 6.2 Mobile (Android/iOS) Specific

**Permission State:**
- [ ] Camera permission granted ✅
- [ ] Microphone permission granted ✅
- [ ] Audio routing to speaker (not earpiece)

**Video Verification:**
- [ ] Local video tile appears (YOUR camera)
- [ ] Video controls active
- [ ] Remote video placeholder visible

### 6.3 Multi-User Test (Use Second Device)

On **second device:**
- [ ] Join same room
- [ ] On **primary device:** Remote video appears (second device's feed)
- [ ] On **secondary device:** Remote video appears (primary device's feed)
- [ ] Both tiles in sync, no lag

**Status:** ⬜ NOT STARTED | ✅ PASSED | ❌ FAILED

---

================================================================================
7. AUDIO/VIDEO CONTROLS (1-2 minutes)
================================================================================

### 7.1 Mute/Unmute Audio
- [ ] Tap mute audio icon
- [ ] UI updates instantly
- [ ] Firestore `isAudioOn = false`
- [ ] On second device: see remote participant muted
- [ ] Tap unmute icon
- [ ] Firestore `isAudioOn = true`
- [ ] On second device: see remote participant unmuted

### 7.2 Toggle Video
- [ ] Tap disable video icon
- [ ] UI updates instantly
- [ ] Firestore `isVideoOn = false`
- [ ] Local video tile goes dark (or shows placeholder)
- [ ] On second device: remote video goes dark
- [ ] Tap enable video
- [ ] Firestore `isVideoOn = true`
- [ ] Video returns

### 7.3 Hand Raise (if implemented)
- [ ] Tap hand icon
- [ ] UI shows "Hand raised"
- [ ] Firestore updated with hand state
- [ ] Second device sees hand raised status
- [ ] Tap hand again to lower
- [ ] Status clears

**Status:** ⬜ NOT STARTED | ✅ PASSED | ❌ FAILED

---

================================================================================
8. CHAT SYSTEM (1-2 minutes)
================================================================================

### 8.1 Send Message (Primary Device)
- [ ] Type a message
- [ ] Tap send
- [ ] Message appears immediately in chat
- [ ] Sender name displays correctly
- [ ] Timestamp present

### 8.2 Receive Message (Secondary Device)
- [ ] On second device, send a message
- [ ] On primary device: message appears in real-time
- [ ] No duplicates
- [ ] No missing messages
- [ ] Order correct (chronological)

### 8.3 Firestore Chat Collection
Open Firestore:
- [ ] Navigate to: `rooms/{roomId}/messages`
- [ ] Confirm:
  - [ ] All messages present
  - [ ] Sender UIDs correct
  - [ ] Timestamps in order
  - [ ] No orphaned messages

**Status:** ⬜ NOT STARTED | ✅ PASSED | ❌ FAILED

---

================================================================================
9. LEAVE ROOM FLOW (2 minutes)
================================================================================

### 9.1 Leave Room
- [ ] Tap "Leave" or "Back" button
- [ ] No errors on console (web: F12 → Console)
- [ ] No red screens
- [ ] Navigation back to lobby

### 9.2 Agora Cleanup
**Web Console Check:**
- [ ] No `leaveChannel` JS errors
- [ ] No undefined function warnings

**Mobile Logs:**
- [ ] No platform channel errors
- [ ] Clean exit from Agora engine

### 9.3 Firestore Cleanup
Open Firestore and check:
- [ ] Participant document REMOVED from `rooms/{roomId}/participants`
- [ ] `users/{userId}.currentRoomId` = empty or null
- [ ] `users/{userId}.lastRoomJoin` = still present (for history)

### 9.4 UI Reset
- [ ] Video tiles gone
- [ ] Chat history cleared from screen
- [ ] Room state reset
- [ ] No lingering listeners
- [ ] Back in lobby view

### 9.5 Second Join Test
- [ ] Join the same room again
- [ ] Confirm: **no stale Firestore documents**
- [ ] Confirm: **fresh participant document created**
- [ ] Join succeeds without conflicts

**Status:** ⬜ NOT STARTED | ✅ PASSED | ❌ FAILED

---

================================================================================
10. CRASHLYTICS VERIFICATION (1 minute) — Mobile/Desktop Only
================================================================================

### 10.1 Web Verification
- [ ] No Crashlytics initialization errors
- [ ] No `MissingPluginException` for Crashlytics
- [ ] Console shows no Crashlytics calls (expected: silent)

### 10.2 Mobile/Desktop Verification

**Trigger a Logged Event:**
- [ ] Perform an action that logs to Crashlytics
- [ ] (Example: specific error condition or navigation event)

**Check Firebase Console:**
- [ ] Open: Firebase → Crashlytics
- [ ] Look for new events in last 5 minutes
- [ ] Confirm:
  - [ ] Event logged ✅
  - [ ] Platform correct (Android/iOS/Desktop) ✅
  - [ ] Custom keys present (e.g., app_version) ✅
  - [ ] No errors in stacktrace ✅

### 10.3 Custom Context Verification
Firestore context should include:
- [ ] `app_version` = your version
- [ ] `environment` = staging/production
- [ ] Timestamp of error
- [ ] User ID

**Status:** ⬜ NOT STARTED | ✅ PASSED | ❌ FAILED

---

================================================================================
11. FINAL PASS (1 minute)
================================================================================

### 11.1 Console & Logs
- [ ] Web: F12 → Console shows no red errors
- [ ] Mobile: Logcat/Xcode logs show no fatal errors
- [ ] No `MissingPluginException` on web
- [ ] No unhandled exceptions

### 11.2 UI/UX State
- [ ] No red screens or exceptions
- [ ] No infinite spinners
- [ ] No frozen buttons
- [ ] No missing UI elements
- [ ] Back button navigation works
- [ ] Permissions clearly requested

### 11.3 Agora Integration
- [ ] No "Failed to join channel via platform service" messages
- [ ] No "kIsWeb fallback" messages (shouldn't happen)
- [ ] Web: No "native plugin" errors
- [ ] Mobile: No "permission denied" silent failures

### 11.4 Data Integrity
- [ ] No duplicate listeners
- [ ] No orphaned Firestore documents
- [ ] Join/leave cycle clean
- [ ] Multi-user sync works
- [ ] Message order preserved

**Status:** ⬜ NOT STARTED | ✅ PASSED | ❌ FAILED

---

================================================================================
PASS/FAIL CRITERIA
================================================================================

### ✅ PASS — If ALL of the following are true:

- [x] All flows work on all platforms tested
- [x] No Agora `joinChannel` errors
- [x] No JavaScript bridge errors (web)
- [x] No `MissingPluginException` (web)
- [x] Firestore participant sync correct
- [x] Join → video appears → audio controls work → leave → cleanup
- [x] Multi-user video/audio syncs in real-time
- [x] Chat messages appear instantly on all devices
- [x] Crashlytics custom context set (mobile/desktop only)
- [x] No console errors or red screens
- [x] Back button navigation works
- [x] Permissions requested and granted cleanly

### ❌ FAIL — If ANY of the following occur:

- [ ] Web join falls back to native plugin (indicates kIsWeb check failed)
- [ ] JS bridge throws "not a function" or undefined errors
- [ ] Participants don't sync to Firestore
- [ ] Video tiles don't appear after 3 seconds
- [ ] Crashlytics throws `MissingPluginException` on web
- [ ] Leave doesn't remove Firestore participant document
- [ ] Stale participant document exists after second join
- [ ] Chat messages missing or out of order
- [ ] Red screen or unhandled exception on any flow
- [ ] Multi-user video/audio doesn't sync
- [ ] Permission prompts fail or are skipped

---

================================================================================
TEST RESULTS SUMMARY
================================================================================

**Test Date:** ________________
**Tester Name:** ________________
**Platform:** ⬜ Web | ⬜ Android | ⬜ iOS | ⬜ Desktop

**Results:**

| Section | Status | Notes |
|---------|--------|-------|
| 1. Pre-Flight | ✅ PASS ❌ FAIL | |
| 2. Authentication | ✅ PASS ❌ FAIL | |
| 3. Room Selection | ✅ PASS ❌ FAIL | |
| 4. Token & Permissions | ✅ PASS ❌ FAIL | |
| 5. Firestore Sync | ✅ PASS ❌ FAIL | |
| 6. Agora SDK Join | ✅ PASS ❌ FAIL | |
| 7. Audio/Video Controls | ✅ PASS ❌ FAIL | |
| 8. Chat System | ✅ PASS ❌ FAIL | |
| 9. Leave Room | ✅ PASS ❌ FAIL | |
| 10. Crashlytics | ✅ PASS ❌ FAIL | |
| 11. Final Pass | ✅ PASS ❌ FAIL | |

**Overall Result:** ⬜ PASS | ⬜ FAIL

**Issues Found:**
1. _________________________________
2. _________________________________
3. _________________________________

**Recommended Action:**
- [ ] Ready for Release
- [ ] Fix Issues & Retest
- [ ] Escalate to Engineering

---

================================================================================
NOTES FOR QA TEAMS
================================================================================

### Timing Tips
- **Pre-Flight:** 1 min (usually cached, just confirm)
- **Auth:** 1 min (straightforward)
- **Join Flow:** 3 min (include Cloud Functions log check)
- **Firestore Sync:** 1 min (simple document check)
- **Agora SDK:** 2–3 min (multi-device: 3 min, single device: 2 min)
- **Controls:** 1–2 min (depends on how many controls to test)
- **Chat:** 1–2 min (send + receive + order verification)
- **Leave:** 2 min (cleanup verification)
- **Crashlytics:** 1 min (mobile only, quick console check)
- **Final Pass:** 1 min (summary verification)

**Total: 15–18 minutes per platform**

### When to Retest
- After any code changes to: `agora_*.dart`, `auth_service.dart`, `voice_room_page.dart`
- After Firebase Functions deployment
- After Firestore rule changes
- Before every release candidate
- After version bump

### Common Issues & Resolution

**Issue:** Web shows "Failed to join channel via platform service"
**Solution:** Check browser console for `kIsWeb` or JS bridge error. Verify agora_web_bridge.dart loaded.

**Issue:** Video doesn't appear on second device
**Solution:** Wait 3–5 seconds. Check participant Firestore document. Restart Agora engine on primary device.

**Issue:** Participants don't sync to Firestore
**Solution:** Check Cloud Functions logs. Verify Firestore rules allow write. Check user permissions.

**Issue:** Crashlytics shows MissingPluginException on web
**Solution:** This is expected! Crashlytics only logs on mobile/desktop. Web should show no Crashlytics activity.

**Issue:** Chat messages appear out of order
**Solution:** Check Firestore timestamp field. May be client clock issue. Resync time on device.

---

================================================================================
📋 CHECKLIST COMPLETED
================================================================================

**Sign Off:**
Tester: _______________________ Date: _____________

**Engineering Lead:** _______________________ Date: _____________

✅ All tests passed. Ready for:
- [ ] Internal Beta Release
- [ ] Production Release
- [ ] Public Beta Release

================================================================================
