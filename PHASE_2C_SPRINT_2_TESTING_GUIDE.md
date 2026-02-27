# Phase 2C Sprint 2 Testing Guide - Host Controls

**Status**: 🚀 Implementation Complete - Ready for Testing

**Build**: ✅ `flutter build web --release` passes without errors

---

## Overview

Phase 2C Sprint 2 implements four sequential host/moderator control stages:

1. **Stage 1**: Remove User - Force-eject participants
2. **Stage 2**: Mute User - Silent audio without ejection
3. **Stage 3**: Lock Room - Prevent new joins
4. **Stage 4**: End Room - Close the entire room

---

## Architecture Summary

### Backend (Service Layer)

- **RoomManagerService**: Business logic with authorization checks (host/moderator required)
  - `removeUser(roomId, userId)` - Adds user to removedUsers list
  - `muteUser(roomId, userId, bool muted)` - Toggles mutedUsers list
  - `lockRoom(roomId, bool locked)` - Sets isRoomLocked flag
  - `endRoom(roomId)` - Sets isRoomEnded flag
  - `canUserJoinRoom(roomId, userId)` - Pre-join validation

### State Management (Firestore)

- **Room fields** added for Sprint 2 control:
  - `removedUsers: List<String>` - Force-removed user IDs
  - `mutedUsers: List<String>` - Muted user IDs
  - `isRoomLocked: bool` - Room join prevention flag
  - `isRoomEnded: bool` - Room closure flag

### UI Layer

- **RoomPage**:
  - Listeners for removed/locked/ended state
  - Shows dialogs informing users when control actions affect them
  - Provides handlers for all control actions

- **ParticipantListSidebar**:
  - Shows participant list with role/status icons
  - Grey out removed users with ❌ indicator
  - Show 🔇 mute indicator for muted users
  - Actions menu: Remove, Mute/Unmute, Make Moderator, etc.

- **RoomControls**:
  - 🔒 Lock toggle button (host only)
  - 🚪 End room button (host only)
  - Shows lock status in header badge

---

## Testing Procedure

### Prerequisites

- Two browser tabs/windows open, logged in as different users
- One user should be the host/moderator, one should be a regular participant
- Both in the same room (Stage 0)

### Stage 1: Remove User Testing 🚨

**Goal**: Verify force-ejection works and user gets feedback

**Test Steps**:

1. Host opens ParticipantListSidebar (click "Show Panel" button bottom-right)
2. Host clicks menu button (⋮) on participant entry
3. Host selects "❌ Remove from Room"
4. **Expected Result (Removed User)**:
   - Dialog appears: "Removed from Room" with message
   - User must click OK to close dialog
   - User is redirected to home/room list (`Navigator.popUntil(isFirst)`)
   - Removed user cannot re-enter room (blocked by `canUserJoinRoom` check)

5. **Expected Result (Host View)**:
   - Participant tile shows grey avatar with ❌ icon
   - Tile text is struck through
   - Role shows "Removed" in grey
   - Menu shows "❌ Removed" (disabled option)

**Verification Checklist**:

- [ ] Removed user sees dialog and cannot dismiss it (barrierDismissible: false)
- [ ] Removed user is auto-navigated out of room
- [ ] Removed user cannot re-join (test by joining another room from list)
- [ ] Host can see removed status in sidebar
- [ ] Other participants don't see removed user in their sidebar

**Common Issues & Fixes**:

- If removed user isn't redirected: Check `popUntil(isFirst)` logic
- If user can re-join: Verify `canUserJoinRoom` checks `removedUsers` list
- If host can't see removed indicator: Check `room.removedUsers.contains(uid)`

---

### Stage 2: Mute User Testing 🔇

**Goal**: Verify audio muting works without removing user

**Test Steps**:

1. Host clicks menu button (⋮) on participant
2. Choose "🔇 Mute Audio" (or "🔊 Unmute" if already muted)
3. **Expected Result (Technical)**:
   - User's uid added to `room.mutedUsers` list in Firestore
   - User entry in sidebar shows 🔇 mute icon (orange)
   - Menu now shows "🔊 Unmute Audio" instead of mute
   - User remains in room, not removed

4. **Expected Result (Audio - Web)**:
   - JS bridge calls `muteRemoteAudio(remoteUid, muted)`
   - Remote user's audio track is disabled (`user.audioTrack.setEnabled(false)`)
   - Muted user's own audio still works in their tab (only others can't hear them)

**Verification Checklist**:

- [ ] Muted user's tile shows 🔇 icon
- [ ] Muted user's tile role doesn't change (still Speaker/Listener, not removed)
- [ ] Host can toggle mute on/off
- [ ] Menu shows correct icon (🔇 for unmute, 🔊 for mute)
- [ ] Muted user can still see and interact (not removed)
- [ ] Audio muting works for audience (web: verify JavaScript bridge called)

**Common Issues & Fixes**:

- If 🔇 icon doesn't appear: Check `room.mutedUsers.contains(uid)`
- If toggle doesn't work: Check RoomManagerService has proper async/await
- If web audio not muting: Verify agora_web.js function is called correctly

---

### Stage 3: Lock Room Testing 🔒

**Goal**: Verify new join attempts are prevented

**Test Steps**:

1. Host clicks 🔒 icon in RoomControls
2. Icon changes to indicate locked state (highlighted in amber)
3. Open third browser tab, try to join the room
4. **Expected Result**:
   - `/join` screen shows error: "Room is locked" or similar
   - User cannot proceed to room
   - `canUserJoinRoom()` returns false due to `isRoomLocked` check

5. Unlock room by clicking 🔒 again
6. Try joining from third tab again
7. **Expected Result**: User can join successfully

**Verification Checklist**:

- [ ] Lock icon highlights when locked (amber color)
- [ ] Lock icon is unhighlighted when unlocked
- [ ] New users are blocked from joining when locked
- [ ] Existing users can still see/speak when locked
- [ ] Room can be unlocked and new users can join
- [ ] Lock status syncs across host's sidebar show/hide

**Common Issues & Fixes**:

- If lock icon doesn't change: Verify `current.isRoomLocked` binding in RoomControls
- If new users can still join: Check `canUserJoinRoom` pre-join validation
- If lock button doesn't respond: Ensure `onLockRoom` handler calls properly

---

### Stage 4: End Room Testing 🚪

**Goal**: Verify room closure and user feedback

**Test Steps**:

1. All participants in room
2. Host clicks "End Room" button
3. **Expected Result (All Users)**:
   - Dialog appears: "Room Ended" with message
   - Dialog is modal (barrierDismissible: false)
   - All users must acknowledge
   - All users redirected to home (`popUntil(isFirst)`)

4. **Expected Result (Firestore)**:
   - `room.isRoomEnded = true`
   - `room.isLive = false`
   - `room.isActive = false`
   - `room.status = 'ended'`
   - `room.participantIds = []`

5. **Expected Result (Recovery)**:
   - Room cannot be restarted (isRoomEnded is one-way)
   - New join attempts to this room ID will be blocked
   - Room shows as "Ended" in room list

**Verification Checklist**:

- [ ] All participants see "Room Ended" dialog simultaneously
- [ ] All can't dismiss dialog without clicking OK
- [ ] All are navigated to home after acknowledging
- [ ] Room appears as "Ended" in room list for all users
- [ ] Attempting to join ended room shows error
- [ ] Ending room is a one-way operation (can't restart)

**Common Issues & Fixes**:

- If only host sees dialog: Check Riverpod listener for `isRoomEnded`
- If users don't get redirected: Verify `popUntil(isFirst)` context
- If room can be rejoined: Check `canUserJoinRoom` includes `isRoomEnded` check

---

## Integration Tests

### Cross-User Synchronization 🔄

Test that controls sync properly between multiple users:

1. **Setup**: Three tabs open (Host, User A, User B)
2. **Remove User A**:
   - [ ] User A sees removal dialog in their tab
   - [ ] Host sees User A greyed out in sidebar
   - [ ] User B still sees User A (doesn't know they were removed)
   - [ ] User B's sidebar refreshes and User A disappears within 5 seconds

3. **Lock Room**:
   - [ ] Host locks room (🔒 icon highlights)
   - [ ] User B's participant tile icon updates to show lock status
   - [ ] New join from third tab is blocked immediately

4. **Mute User A** (before removal):
   - [ ] Host mutes User A
   - [ ] Host sees 🔇 icon on User A's tile
   - [ ] User B sees User A's 🔇 icon within 2 seconds
   - [ ] Menu shows "Unmute" option

### Authorization Tests 🔐

Verify only authorized users can perform actions:

1. **Non-Host/Moderator tries actions**:
   - [ ] Regular listener cannot see ParticipantListSidebar
   - [ ] No menu buttons visible on other participants
   - [ ] No lock/end controls in RoomControls

2. **Moderator Tests**:
   - [ ] Moderator can remove users
   - [ ] Moderator can mute users
   - [ ] Moderator CANNOT lock room (host-only)
   - [ ] Moderator CANNOT end room (host-only)

3. **Host-Only Actions**:
   - [ ] Non-host cannot see 🔒 lock button
   - [ ] Non-host cannot see "End Room" button
   - [ ] Attempting direct API call as non-host throws error

---

## Performance Testing

### Network Load 📊

- **Scenario**: Remove 10 users in rapid succession
  - [ ] Firestore updates complete within 2 seconds each
  - [ ] UI updates propagate within 1 second
  - [ ] No lag or freezing in sidebar

### Concurrent Operations 🔄

- **Scenario**: Mute User A, lock room, remove User B simultaneously
  - [ ] All operations succeed
  - [ ] No race conditions in Firestore
  - [ ] UI reflects all changes correctly

---

## Regression Testing

Ensure existing features still work:

- [ ] Normal room operations (join, speak, raise hand)
- [ ] Participant list displays correctly without Sprint 2 actions
- [ ] Room doesn't auto-end after Sprint 2 code
- [ ] No errors in browser console
- [ ] Agora audio/video streams continue normally
- [ ] Room metadata (capacity, duration) still tracked

---

## Test Results Template

```markdown
### Stage 1: Remove User

- [ ] PASS: Removed user sees dialog
- [ ] PASS: Host sees removed indicator
- [ ] PASS: User cannot re-join
- Status: ✅ PASS / ⚠️ ISSUES / ❌ FAIL

### Stage 2: Mute User

- [ ] PASS: Audio is muted
- [ ] PASS: Icon shows 🔇
- [ ] PASS: Can toggle mute
- Status: ✅ PASS / ⚠️ ISSUES / ❌ FAIL

### Stage 3: Lock Room

- [ ] PASS: New users blocked
- [ ] PASS: Icon indicates lock
- [ ] PASS: Can unlock
- Status: ✅ PASS / ⚠️ ISSUES / ❌ FAIL

### Stage 4: End Room

- [ ] PASS: All see dialog
- [ ] PASS: All redirected
- [ ] PASS: Room shows ended
- Status: ✅ PASS / ⚠️ ISSUES / ❌ FAIL

### Integration Tests

- [ ] Cross-user sync works
- [ ] Authorization enforced
- [ ] No regressions
- Status: ✅ PASS / ⚠️ ISSUES / ❌ FAIL

**Overall**: ✅ READY FOR PRODUCTION / ⚠️ MINOR ISSUES / ❌ BLOCKERS
```

---

## Debugging Tips

### Firestore State Inspection

```
1. Open Firebase Console → Firestore
2. Navigate to rooms/{roomId}
3. Check fields: removedUsers, mutedUsers, isRoomLocked, isRoomEnded
4. Verify Timestamp.now() updates on each action
```

### Browser Console

```
1. Open DevTools (F12)
2. Look for DebugLog messages with emoji prefixes:
   - 🗑️ Room control actions
   - 🔇 Audio mute operations
   - ⚠️ Authorization failures
3. Check for any CORS or network errors
```

### Riverpod Provider State

```
1. Install Riverpod DevTools (VSCode extension)
2. Watch agoraParticipantsProvider for participant updates
3. Watch roomStreamProvider for live room state changes
4. Verify state updates on Firestore changes within 1 second
```

---

## Known Limitations

1. **Web Platform**: Direct kickUser not supported (relies on Firestore removal)
2. **Audio Sync**: Mute state may take 1-2 seconds to sync on web
3. **One-Way Removal**: Once removed, user must restart app to rejoin (blacklist cached in `removedUsers`)
4. **End Room**: One-way operation, can't be undone (by design)

---

## Next Steps After Testing

1. **Minor Issues**: Create follow-up sprint for polish
2. **Major Issues**: Rollback and debug with test team
3. **Pass All Tests**: Mark Phase 2C Sprint 2 complete ✅
4. **Begin Phase 2C Sprint 3**: Additional features per roadmap

---

## Questions & Support

For test failures or issues:

1. Check browser console for error messages
2. Verify Firestore state matches expected
3. Confirm authorization checks in RoomManagerService
4. Review test guide section for your specific failure

---

**Testing Responsibility**: QA Test Team
**Expected Duration**: 2-3 hours for full coverage
**Blocker Severity**: High (host controls are critical for production)
