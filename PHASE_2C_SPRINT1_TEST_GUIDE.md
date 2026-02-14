# Phase 2C, Sprint 1: Multi-User Stability Testing Guide

## Overview
Sprint 1 focuses on eliminating multi-user stability issues through focused fixes:
- Ghost user elimination (users leaving but tiles staying)
- Duplicate tile prevention (same user appearing twice)
- Race condition hardening (join/publish/subscribe sequence)
- Clean leave cycles (complete cleanup on exit)

---

## What Changed in Sprint 1

### 1. **Ghost User Fix** ✅
**Problem**: Users would leave but their video tile would persist.
**Root Cause**: `unpublished` events don't guarantee total disconnect; user might unpublish video but still have audio.

**Solution Implemented**:
- Added per-user media state tracking in JavaScript (`remoteUserMediaState` Map)
- Only remove user when **all media tracks** (video + audio) are gone
- Added `user-left` event handler as fallback for force-removal
- Tracks: `uid → { hasVideo: bool, hasAudio: bool }`

**Files Changed**:
- `web/agora_web.js` - Media state tracking
- `lib/services/agora_video_service.dart` - Updated `_setupWebRemoteUserCallbacks()`

---

### 2. **Duplicate Tile Prevention** ✅
**Problem**: Same user appearing in multiple tiles during rapid joins.
**Root Cause**: Race conditions in join/published events without deduplication.

**Solution Implemented**:
- Added `_remoteUsersSet` in `AgoraVideoService` for O(1) lookup
- Atomic deduplication checks before adding users
- Idempotent operations (`addRemoteVideo`, `setLocalUid`)
- Safe list-to-set conversion in room_page render

**Files Changed**:
- `lib/services/agora_video_service.dart` - Set-based deduplication
- `lib/providers/agora_video_tile_provider.dart` - Idempotent operations
- `lib/features/room/screens/room_page.dart` - Safe dedup in rendering

---

### 3. **Race Condition Hardening** ✅
**Problem**: Rapid rejoin, join→publish→subscribe out of order.
**Root Cause**: No handling for duplicate join events or incomplete state sync.

**Solution Implemented**:
- `onUserJoined` checks Set before adding (idempotent)
- Media state initialization on first join
- Proper cleanup in `onLeaveChannel` (both list and set)
- Batch removal operations

**Files Changed**:
- `lib/services/agora_video_service.dart` - Enhanced event handlers
- `lib/services/agora_web_bridge_v2.dart` - New `setOnRemoteUserLeft` callback

---

### 4. **Clean Leave Cycles** ✅
**Problem**: Incomplete cleanup when leaving, stale state remains.
**Root Cause**: Multiple cleanup paths (list clear, but not set; no media state clear).

**Solution Implemented**:
- Synchronized cleanup: clear `_remoteUsers`, `_remoteUsersSet`, `_remoteUserMediaState`
- Clear in `onLeaveChannel` (native)
- Clear in `leaveAgoraChannel` (web)
- Clear participants and video tiles atomically

**Files Changed**:
- `web/agora_web.js` - Clear `remoteUserMediaState` on leave
- `lib/services/agora_video_service.dart` - Synchronized cleanup

---

## Testing Strategy

### **Test Environment**
- Platform: **Chrome Web** (Phase 2C is web-first)
- Room Type: Create test room for multi-user scenarios
- Tools: Browser DevTools, Flutter logs, Chrome console

### **Test Scenarios**

#### **Test 1: Basic Join/Leave - No Ghost Users**
**Objective**: Verify users are properly removed on leave.

**Steps**:
1. Open room in Chrome (User A)
2. Call other user into room (User B)
3. Verify User B appears in tile with count showing 2
4. User B clicks Leave
5. **Verify**: User B tile disappears immediately, count shows 1

**Expected**: No ghost tiles; clean removal
**Related Logs**: `[BRIDGE] Remote user left`, `[BRIDGE] User completely left`

---

#### **Test 2: Duplicate Prevention - Rapid Rejoin**
**Objective**: Verify no duplicates when user rapidly rejoins.

**Steps**:
1. Room open with User A and User B
2. User B leaves
3. User B immediately rejoins within 2 seconds
4. **Verify**: User B appears once, not twice
5. Check participant count (should be 2, not 3)

**Expected**: One tile for User B, no duplicates
**Related Logs**: `[BRIDGE] User already tracked (rejoin)`, dedup checks

---

#### **Test 3: Audio-Video Separation**
**Objective**: Verify users aren't removed if only one media type unpublishes.

**Steps**:
1. Room open with both users (video + audio)
2. User B turns OFF camera (unpublish video)
3. **Verify**: User B tile stays (audio still active)
4. User B turns OFF mic (unpublish audio)
5. **Verify**: Now User B is removed completely

**Expected**: Tile persists with audio-only until both tracks gone
**Related Logs**: `hasVideo=false`, `hasAudio=true`, then both false

---

#### **Test 4: Multi-User Join Storm**
**Objective**: Verify no tiles missing or duplicated during rapid multi-joins.

**Steps**:
1. Start with User A in room
2. Invite 3 more users (B, C, D) to join simultaneously/rapidly
3. All 4 should appear correctly
4. **Verify**: Exactly 4 tiles (not 5, not 3, not duplicates)
5. Check participant count matches

**Expected**: Clean grid with all unique users
**Related Logs**: New user added events in correct order

---

#### **Test 5: Leave During Join**
**Objective**: Verify no race conditions if user leaves while others joining.

**Steps**:
1. Room: User A, User B, User C
2. User C clicks Leave
3. Simultaneously, User D tries to join
4. **Verify**: User C removed, User D added correctly (no merge/conflict)
5. Final count = 3 (A, B, D)

**Expected**: Clean state without race condition artifacts
**Related Logs**: Proper event ordering in debug logs

---

#### **Test 6: Network Interruption Simulation**
**Objective**: Verify cleanup when connection drops unexpectedly.

**Steps**:
1. Room open with User A and User B
2. Open DevTools → Network → offline (simulate loss)
3. Wait 5 seconds, reconnect
4. **Verify**: No ghost tiles from previous session
5. Rejoin room cleanly

**Expected**: Proper recovery, no stale state
**Related Logs**: `user-left` fallback event triggered

---

### **Test 7: Rapid Camera Toggle**
**Objective**: Verify video tile updates track correctly with media state changes.

**Steps**:
1. Room open with User B video active
2. User B toggles camera off/on 5 times rapidly
3. **Verify**: Tile updated each time, no duplicates
4. Final state matches actual camera state

**Expected**: Video tile provider syncs with media state
**Related Logs**: `addRemoteVideo`/`removeRemoteVideo` calls tracked

---

## Logging Checklist

**Enable Debug Mode**:
- Check Flutter console in VS Code
- Open Chrome DevTools → Console for JS logs
- Search for key patterns:

```
Pattern 1: Ghost User Detection
[BRIDGE] Remote user completely left: uid=123
[BRIDGE] User completely removed: uid=123

Pattern 2: Duplicate Prevention
[BRIDGE] User already tracked (rejoin)
Added to set, not re-added

Pattern 3: Media State Changes
[BRIDGE] hasVideo=false, hasAudio=true (user stays)
[BRIDGE] hasAudio=false → User completely removed

Pattern 4: Clean Leave
[BRIDGE] Leaving Agora channel...
[BRIDGE] Left channel
remoteUserMediaState cleared
```

---

## Success Criteria for Sprint 1

✅ **Ghost Users**: No tiles persist after user leaves
✅ **Duplicates**: No users appear twice in grid
✅ **Audio-Video Split**: Users stay if any track active
✅ **Race Conditions**: No merge/conflict state on rapid events
✅ **Clean Leave**: Complete state reset on channel leave
✅ **Multi-User**: 4+ users handled without issues
✅ **Recovery**: Proper cleanup after network loss

---

## Known Limitations (Phase 2C, not yet addressed)

- Host controls not yet implemented (Phase 2D)
- Firestore participant tracking may lag real-time state
- Display names cached, not real-time updated (separate phase)
- Bandwidth optimization for 10+ users (Phase 3)

---

## Next Steps After Sprint 1 Verification

1. Phase 2C, Sprint 2 - Host Controls
   - Mute/unmute users from host perspective
   - Remove user from room
   - Promote/demote speakers

2. Phase 2C, Sprint 3 - Stability Polish
   - Firestore sync hardening
   - Connection recovery improvements
   - Rate limiting for rapid operations

3. Phase 3 - Performance Optimization
   - Multi-device scaling
   - Bandwidth management for 100+ users
   - Grid optimization

---

## Troubleshooting

**Issue**: Tile doesn't disappear on leave
→ Check `onAgoraUserLeft` is being called in DevTools → Console
→ Verify `remoteUserMediaState.clear()` executes

**Issue**: User appears twice
→ Check `_remoteUsersSet` dedup in logs
→ Verify idempotent `addRemoteVideo` calls

**Issue**: Audio-only users removed incorrectly
→ Check media state Map: both `hasVideo` and `hasAudio` tracked
→ Verify unpublished event includes mediaType

**Issue**: MissingPluginException on leave
→ Ensure web bridge callbacks cleaned up properly
→ Check `setOnRemoteUserLeft(null)` on dispose

---

## Test Execution Timeline

**Estimated Time**: 2-3 hours for thorough testing
- Basic tests (1, 2, 3): 30 min
- Complex tests (4, 5, 6, 7): 60-90 min
- Regression verification: 30 min
- Documentation: 30 min

**Recommended Order**:
1. Test 1 (basic, fast pass/fail)
2. Test 2 (duplicate check critical)
3. Test 3 (audio-video split edge case)
4. Test 4 & 5 (race conditions)
5. Test 6 (recovery)
6. Test 7 (media updates)

---

## Document Sign-Off

**Phase 2C, Sprint 1 Completion**: Ready for web-first testing
**Date**: 2026-02-05
**Changes**: 6 files, 4 core systems
**Risk Level**: Low (backward compatible, defensive coding)
