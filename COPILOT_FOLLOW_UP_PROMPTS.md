================================================================================
⭐ COPILOT FOLLOW-UP PROMPTS — Advanced Optimization & Refactoring
================================================================================
Last Updated: February 3, 2026

These are specialized prompts to use AFTER the master prompt, or to address
specific areas of your app.

================================================================================
FOLLOW-UP PROMPT 1: AGORA SERVICE REFACTOR
================================================================================

Use this if you want to consolidate all Agora logic into a single service.

---

You are a Flutter architect refactoring an Agora video calling service.

I want to consolidate all Agora-related logic into a single, clean AgoraService
class that handles both web and mobile platforms.

**Current state:** Multiple Agora services exist (agora_video_service.dart,
agora_web_bridge.dart, agora_platform_service.dart). They work, but can be
unified.

**Your goal:** Create a unified AgoraService that:

1. Detects platform (web vs mobile) once at startup
2. Provides a single joinChannel() method that handles both platforms
3. Provides a single leaveChannel() method that handles both platforms
4. Provides methods for toggleAudio(), toggleVideo(), toggleCamera()
5. Emits events for remoteUserJoined, remoteUserOffline, audioVolumeIndication
6. Never exposes platform-specific internals to the caller
7. Handles errors gracefully with descriptive messages
8. Works with Firebase token generation

**Output:**

- Refactored AgoraService class
- List of files that can be deleted or consolidated
- Updated call sites (files that import/use Agora)
- Migration guide (1–2 sentences per change)

Begin by scanning the current Agora implementation and proposing the unified
service.

---

================================================================================
FOLLOW-UP PROMPT 2: FIRESTORE & REAL-TIME SYNC CLEANUP
================================================================================

Use this to ensure all Firestore operations are safe, atomic, and free of
race conditions.

---

You are a Firebase architect optimizing Firestore operations in a Flutter app.

I want to ensure all Firestore operations in this app are:

- Atomic (all-or-nothing, no partial updates)
- Free of race conditions (no simultaneous writes to same document)
- Properly cleaned up (no orphaned documents)
- Efficient (batched where possible)

**Current flows:**

1. joinRoom() writes participant doc
2. leaveRoom() deletes participant doc
3. sendMessage() writes message doc
4. toggleAudio/Video updates participant doc
5. Real-time listeners sync state to UI

**Your goal:**

1. Identify any race conditions (e.g., two simultaneous writes)
2. Identify any orphaned documents (participants without cleanup)
3. Optimize with Firestore transactions where needed
4. Ensure listeners don't trigger duplicate updates
5. Ensure cleanup on app crash (TTL? Cleanup function?)

**Output:**

- List of identified issues
- Proposed fixes (code snippets for each)
- Firestore rules needed (if any)
- Cleanup strategy (TTL vs Cloud Function)

Begin by scanning join/leave/sync logic.

---

================================================================================
FOLLOW-UP PROMPT 3: WEB PLATFORM HARDENING
================================================================================

Use this to bulletproof the web platform against edge cases.

---

You are a Flutter web specialist hardening a video calling app.

I want to ensure the web platform (Chrome, Firefox, Safari) is rock-solid for
video calling.

**Current web implementation:** Uses a JavaScript bridge to call the Agora JS
SDK. Mobile uses the native plugin.

**Your goal:**

1. Ensure waitForBridgeReady() correctly polls for JS SDK availability
2. Ensure timeout handling (what if JS SDK never loads?)
3. Ensure graceful fallback if JS bridge unavailable
4. Ensure camera/microphone permissions prompt correctly
5. Ensure no console errors
6. Test on all browsers (Chrome, Firefox, Safari)
7. Handle network disconnection
8. Handle rapid join/leave cycles
9. Clean up resources on page unload

**Output:**

- Proposed improvements to JS bridge loading
- Error handling strategies
- Browser compatibility checks
- Resource cleanup on unload

Begin by scanning web-specific code (agora_web_bridge.dart, web/index.html).

---

================================================================================
FOLLOW-UP PROMPT 4: TESTING & VERIFICATION SUITE
================================================================================

Use this to generate comprehensive tests for your critical flows.

---

You are a Flutter test engineer creating a test suite for a video calling app.

I want integration tests that verify:

1. Join flow (auth → token → Agora → Firestore)
2. Leave flow (Agora → Firestore cleanup)
3. Web vs mobile platform routing
4. Real-time message sync
5. Audio/video toggle
6. Error handling (network failure, permission denied, etc.)

**Your goal:**

1. Create test_drivers for web, Android, iOS
2. Create integration test scenarios
3. Mock Firestore and Agora responses
4. Verify no memory leaks (dispose cleanup)
5. Verify Firestore cleanup on leave

**Output:**

- Test file structure
- Sample integration test (join flow)
- Mocking strategy
- CI/CD integration tips

Begin by creating an integration_test/ structure and sample tests.

---

================================================================================
FOLLOW-UP PROMPT 5: PERFORMANCE PROFILING & OPTIMIZATION
================================================================================

Use this to identify and fix performance bottlenecks.

---

You are a Flutter performance engineer optimizing a video calling app.

I want to profile and optimize:

1. App startup time (splash screen → login → lobby)
2. Join time (tap room → video appears)
3. Leave time (tap leave → back to lobby)
4. Memory usage (video tiles, listeners, subscriptions)
5. CPU usage (rendering, Agora processing)
6. Battery drain (video encoding, screen activity)

**Your goal:**

1. Identify long-running operations
2. Identify memory leaks or excessive allocations
3. Optimize Firestore queries (indexes, pagination)
4. Optimize UI rendering (StreamBuilder, RepaintBoundary)
5. Optimize Agora settings (resolution, framerate, bitrate)

**Output:**

- Profiling results (before/after timings)
- Identified bottlenecks
- Recommended optimizations (code snippets)
- Expected improvements

Begin by scanning for expensive operations and inefficient patterns.

---

================================================================================
FOLLOW-UP PROMPT 6: SECURITY & DATA PROTECTION
================================================================================

Use this to audit security and privacy.

---

You are a security engineer auditing a video calling app.

I want to verify:

1. No sensitive data in logs or Crashlytics
2. Firestore rules enforce user access (can't read other users' data)
3. Cloud Functions validate user permission
4. Agora tokens are short-lived (< 1 hour)
5. No API keys exposed in client code
6. No personal data stored in Crashlytics custom keys
7. WebRTC encryption enabled
8. HTTPS/wss used everywhere

**Your goal:**

1. Scan for hardcoded credentials
2. Verify Firestore rules are enforced
3. Check Crashlytics custom key usage
4. Verify token expiry logic
5. Audit logging (no sensitive data)
6. Check WebRTC setup

**Output:**

- Security checklist (pass/fail for each item)
- Identified vulnerabilities
- Recommended fixes
- Firestore rules template (if needed)

Begin by scanning for security issues.

---

================================================================================
HOW TO USE THESE FOLLOW-UP PROMPTS
================================================================================

**Workflow:**

1. Use MASTER PROMPT first (full scan + fixes)
2. Use FOLLOW-UP PROMPT 1-2 for architecture cleanup
3. Use FOLLOW-UP PROMPT 3 for web hardening
4. Use FOLLOW-UP PROMPT 4 for testing
5. Use FOLLOW-UP PROMPT 5 for performance
6. Use FOLLOW-UP PROMPT 6 for security

**Timing:**

- Each prompt: 5–15 minutes in Copilot
- Full sequence: 1–2 hours
- Output: actionable fixes you can implement

**Next Steps:**

1. Copy MASTER PROMPT into Copilot Chat
2. Review the output
3. Apply the fixes (or ask Copilot to implement)
4. Then use follow-ups as needed

================================================================================
