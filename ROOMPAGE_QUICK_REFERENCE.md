# 🎨 RoomPage Quick Reference

**File**: `lib/features/room/screens/voice_room_page.dart`
**Status**: ✅ Production Ready
**Complexity**: High (927 lines)

---

## 🎯 What It Does

Complete room interface with:

- Live video grid (1-12+ users, adaptive)
- Participant list with speaking indicators
- Chat overlay
- Control bar (mic, camera, flip, chat, leave)
- Smooth animations & error handling

---

## 📐 Widget Structure

```
Scaffold
├─ AppBar
│  ├─ Back button (leave)
│  ├─ Room name + participant count
│  └─ Participant list toggle
├─ Body (Row)
│  ├─ Expanded: VideoGrid (or placeholder)
│  │  └─ GridView of VideoTiles
│  │     ├─ Video stream
│  │     ├─ Name tag
│  │     ├─ Speaking ring
│  │     ├─ Mute badges
│  │     └─ Gradient overlay
│  └─ ParticipantSidebar (if visible)
│     ├─ Header ("Participants: N")
│     └─ ListView of ParticipantItems
│        ├─ Avatar (initials)
│        ├─ Name
│        ├─ Status
│        └─ Mic/Camera indicators
└─ BottomNavigationBar
   └─ ControlBar
      ├─ Mic toggle
      ├─ Camera toggle
      ├─ Flip camera (if on)
      ├─ Chat button
      └─ Leave button
```

---

## 🔄 State Flow

### Initialization Sequence

```
1. User navigates to VoiceRoomPage(room: room)
2. initState() triggered
3. _initializeAndJoinRoom() called
4. → Check auth (Firebase)
5. → Initialize Agora engine
6. → Request permissions (camera, mic)
7. → Join Agora channel
8. → Trigger animations
9. → Add system message
10. UI shows live video grid
```

### Live Updates

```
Agora Events
  └─ Event fires (e.g., onUserPublished)
     └─ AgoraVideoService updates providers
        └─ ref.read(videoTileProvider.notifier).addRemoteVideo()
           └─ build() triggered
              └─ GridView rebuilt with new tile
                 └─ FadeTransition + SlideTransition animation
```

### Leaving

```
User taps "Leave"
  └─ _leaveRoom() called
     └─ Add system message
     └─ agoraService.leaveRoom()
     └─ Navigator.pop()
     └─ dispose() cleans up
        └─ Cancel animation controller
        └─ Dispose observers
```

---

## 🎬 Key Animations

### Tile Entry (500ms)

```dart
FadeTransition(opacity: 0→1)
SlideTransition(position: (0, 0.3)→(0, 0))
Result: Tiles fade in + slide up smoothly
```

### Speaking Ring (Live)

```dart
border: Colors.greenAccent (3px, if speaking)
boxShadow: Green glow (if speaking)
Result: Active speaker highlighted instantly
```

---

## 🛠️ Key Methods

| Method                       | Returns | Purpose                      |
| ---------------------------- | ------- | ---------------------------- |
| `_initializeAndJoinRoom()`   | Future  | Initialize Agora + join room |
| `_leaveRoom()`               | Future  | Leave room + navigate back   |
| `_buildAppBar()`             | AppBar  | Header with room info        |
| `_buildBody()`               | Widget  | Main content (grid or error) |
| `_buildVideoArea()`          | Widget  | Video grid with layout       |
| `_buildVideoTile()`          | Widget  | Single video tile            |
| `_buildParticipantSidebar()` | Widget  | Right sidebar                |
| `_buildControlBar()`         | Widget  | Bottom controls              |
| `_calculateGridColumns()`    | int     | Optimal columns (1-4)        |

---

## 📊 Providers Watched

```dart
ref.watch(agoraParticipantsProvider);      // Map<int, AgoraParticipant>
ref.watch(videoTileProvider);              // VideoTileState
ref.watch(agoraVideoServiceProvider);      // AgoraVideoService
FirebaseAuth.instance.currentUser;         // Current user
```

All update in real-time → UI auto-rebuilds

---

## 🎯 Grid Layout

| Video Count | Columns | Layout            |
| ----------- | ------- | ----------------- |
| 1           | 1       | Single large tile |
| 2-3         | 2       | 2x2 grid          |
| 4-6         | 2       | 2 columns         |
| 7-9         | 3       | 3 columns         |
| 10+         | 4       | 4 columns         |

Auto-adjusts as users join/leave.

---

## 🎨 Visual States

### Loading State

```
🔄 Spinner
Joining room...
```

### Error State

```
❌ Error
Failed to join room
[error message]
[Retry button]
```

### Success State

```
Video Grid | Participant Sidebar
[tile1]    | 👤 Name1 🎤 🎥
[tile2]    | 👤 Name2 🎤 🎥
[tile3]    | 👤 Name3 🎤 🎥
```

---

## 🎙️ Control Bar Buttons

| Button | States                 | Action              |
| ------ | ---------------------- | ------------------- |
| Mic    | Blue (on) / Grey (off) | toggleMic()         |
| Camera | Blue (on) / Grey (off) | toggleVideo()       |
| Flip   | Always (if camera on)  | switchCamera()      |
| Chat   | Always                 | showVoiceRoomChat() |
| Leave  | Always Red             | \_leaveRoom()       |

---

## 🔗 Dependencies

- `flutter_riverpod` - State management
- `agora_rtc_engine` - Video engine
- `firebase_auth` - User auth
- `agora_video_service` - Service layer
- Voice room providers (chat, roles, etc.)

---

## 🚀 Usage

```dart
// Navigate to room
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => VoiceRoomPage(room: room),
  ),
);

// That's it! VoiceRoomPage handles:
// ✅ Agora initialization
// ✅ Joining room
// ✅ Displaying video
// ✅ Chat integration
// ✅ Controls
// ✅ Leaving & cleanup
```

---

## ✅ Production Ready Checklist

- [x] No placeholders
- [x] Error handling with retry
- [x] Lifecycle management (init/join/leave)
- [x] Permission handling
- [x] Firebase auth integration
- [x] Smooth animations
- [x] Responsive layout
- [x] Color-coded UI
- [x] Speaking indicators
- [x] Mute/video badges
- [x] System messages
- [x] App lifecycle observer
- [x] Debug logging

---

## 📝 Code Statistics

| Metric       | Value                       |
| ------------ | --------------------------- |
| File         | voice_room_page.dart        |
| Lines        | 927                         |
| Methods      | 14                          |
| Widgets      | 7+                          |
| Animations   | 2                           |
| Providers    | 3                           |
| Error States | 3 (loading, error, success) |

---

## 🎯 Next (Optional)

1. **Moderation Panel** - Host controls
2. **Screen Sharing** - Share screen
3. **Recording** - Capture sessions
4. **Single-Mic Mode** - One speaker at a time
5. **Camera Grid Optimization** - 100+ users support

But for now: **Fully functional and production-ready!** 🎉

---

**Last Updated**: January 25, 2026
**Status**: ✅ COMPLETE
