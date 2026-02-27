# 🎯 Web UI Not Showing - Root Cause Analysis

## The Problem

- ✅ Agora joins successfully (JS bridge working)
- ❌ UI doesn't transition to "in-room" state
- ❌ Video grid, chat, participant list not visible

---

## The Join Success Path (Found)

### **Step 1: Join Triggered**

**File**: [lib/features/room/screens/voice_room_page.dart](lib/features/room/screens/voice_room_page.dart#L288)

```dart
Future<void> _initializeAndJoinRoom() async {
  // ... validation ...

  // This is called after Agora init
  await agoraService.joinRoom(widget.room.id);  // Line 386

  // CRITICAL STATE UPDATE:
  if (mounted) {
    setState(() {
      _isJoined = true;        // ← This should trigger UI rebuild
      _isInitializing = false;
    });
  }
}
```

### **Step 2: State Set**

**Flag**: `_isJoined = true` (Line 390)

### **Step 3: Build Method Watches**

**File**: [lib/features/room/screens/voice_room_page.dart](lib/features/room/screens/voice_room_page.dart#L595)

```dart
@override
Widget build(BuildContext context) {
  final videoTiles = ref.watch(videoTileProvider);
  final agoraParticipants = ref.watch(agoraParticipantsProvider);

  // ...build scaffold...
  body: _buildBody(agoraParticipants, videoTiles, agoraService, ...),
}
```

### **Step 4: Body Render Logic**

**File**: [lib/features/room/screens/voice_room_page.dart](lib/features/room/screens/voice_room_page.dart#L798)

```dart
Widget _buildBody(...) {
  // If initializing → show spinner
  if (_isInitializing) {
    return Center(child: CircularProgressIndicator(...));
  }

  // If error → show error screen
  if (_errorMessage != null) {
    return Center(child: ErrorScreen(...));
  }

  // SUCCESS → Show video grid
  return Row(
    children: [
      Expanded(
        child: _buildVideoArea(videoTiles, agoraService, participants, currentUser),
      ),
      // Chat sidebar
      Container(width: 320, child: VoiceRoomChatOverlay(...)),
    ],
  );
}
```

---

## The Three Possible Bugs (Web Specific)

### **Bug #1: `_isJoined` Never Set to True**

- Join completes on JS side
- But `_isJoined` stays `false`
- Body shows spinner forever

**Why on web**: Native path sets it via `onJoinChannelSuccess` event. Web path only sets via `setState()`.

**Evidence to check**:

```
Log should show: "Setting state to initializing"
Log should show: "joinRoom completed"
Log should show: "setState(_isJoined = true)"

If "setState" log is missing → **This is the bug**
```

---

### **Bug #2: `_errorMessage` Set After Join**

- Join succeeds
- But Firestore update throws
- `setState(() { _errorMessage = e.toString(); })`
- Body shows error screen

**Why on web**: Firestore write in `_syncAgoraStateToFirestore` or missing participant registration.

**Evidence to check**:

```
Log should NOT show: "Room initialization failed"

If it does → Firestore operation failing
```

---

### **Bug #3: UI Builds But Video Tiles Empty**

- `_isJoined = true` ✅
- `_errorMessage = null` ✅
- Video grid renders ✅
- But `videoTiles` and `agoraParticipants` are empty

**Why on web**:

- Native: `onJoinChannelSuccess` fires → calls `ref.read(videoTileProvider.notifier).setLocalUid(...)`
- Web: No event handler → UI shows empty grid

**Evidence to check**:

```
videoTileProvider should contain local UID
agoraParticipantsProvider should populate on user join

If empty → Event handlers not wired for web
```

---

## 🔍 What We Need to Test

### **Test A: Check Logs**

In browser console (F12), after joining room on web:

```
[AgoraWeb] ✅ JS SDK joinChannel returned SUCCESS    ← Should appear
🔥 [JOIN] joinRoom completed                          ← Should appear
🔥 [JOIN] Setting state to initializing               ← Should appear
```

If you see all three, move to Test B.
If any missing → UI state is broken.

---

### **Test B: Check `_isJoined` State**

Add a temporary debug log:

```dart
// In _initializeAndJoinRoom, after await agoraService.joinRoom():
AppLogger.info('🔥 [DEBUG] After joinRoom - _isJoined: $_isJoined');
setState(() {
  _isJoined = true;
  _isInitializing = false;
});
AppLogger.info('🔥 [DEBUG] After setState - _isJoined: $_isJoined');
```

Look for those logs. If they appear, state IS being set.

---

### **Test C: Check Video Tile Provider**

Add debug in `_buildBody`:

```dart
Widget _buildBody(...) {
  debugPrint('📊 [DEBUG] videoTiles count: ${videoTiles.localTiles.length}');
  debugPrint('📊 [DEBUG] participants count: ${participants.length}');
  debugPrint('📊 [DEBUG] _isJoined: $_isJoined, _isInitializing: $_isInitializing');

  // ... rest of method ...
}
```

Run and check console.

---

## 🚀 Quick Fix (Likely)

**If `_isJoined` is NOT being set**, add this to web path:

### In **[lib/services/agora_video_service.dart](lib/services/agora_video_service.dart)**, after `joinChannel` completes on web:

```dart
// After: await AgoraPlatformService.joinChannel(...)
// (around line 571)

// For web, manually trigger join success since there's no event
if (kIsWeb) {
  _isInChannel = true;
  _currentChannel = channelName;
  ref.read(videoTileProvider.notifier).setLocalUid(_localUid ?? 0);
  notifyListeners();
  AppLogger.info('✅ [WEB] Manual join success handler triggered');
}
```

This mirrors what `onJoinChannelSuccess` does on mobile.

---

## 📋 Validation Checklist

- [ ] Check browser console for join success logs
- [ ] Verify `_isJoined` transitions from false → true
- [ ] Confirm video tile provider populates
- [ ] Ensure no error messages appear
- [ ] Check Firestore write succeeds (participant added)
- [ ] Validate remote user events fire

---

## Next: What Should You Do?

1. **Run on web** and open browser console (F12)
2. **Join a room** and observe logs
3. **Paste the logs** showing what appears after join
4. **Tell me if video grid shows** or if you see spinner/error

Then I'll either:

- Confirm web path is fixed (congratulate you 🎉)
- Or give you the exact code patch to wire the missing state

---

**Generated**: 2026-02-03
**Status**: Ready to debug
