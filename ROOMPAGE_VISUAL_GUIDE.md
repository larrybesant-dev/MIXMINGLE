# 🎨 RoomPage - Visual Guide & Quick Start

**File**: `voice_room_page.dart` (927 lines)
**Status**: ✅ **PRODUCTION READY**

---

## 🎬 What You Get

```
┌─────────────────────────────────────────────────────┐
│ Mix & Mingle    🚪        🎤  🎥               ┋┋┋ │ ← App Bar
├─────────────────────────────────────────────────────┤
│                                                    │  │
│  ┌─────────────────────────┐    ┌──────────────┐ │  │
│  │  [Video Tile 1]         │    │ Participants │ │  │
│  │  ═════════════════════  │    │  👤 John     │ │  │
│  │  🎵 You (You)           │    │  👤 Sarah    │ │  │
│  │  ⭕ (speaking ring)     │    │  👤 Mike     │ │  │
│  └─────────────────────────┘    │              │ │  │ ← Video Grid
│  ┌─────────────────────────┐    │   🎤 🎥    │ │  │   + Sidebar
│  │  [Video Tile 2]         │    │            │ │  │
│  │  ═════════════════════  │    │ 👤 John    │ │  │
│  │  Sarah                  │    │  🎤 🎥    │ │  │
│  └─────────────────────────┘    └──────────────┘ │  │
│                                                    │  │
├─────────────────────────────────────────────────────┤
│  🎤    🎥   🔄    💬    📞                           │ ← Controls
│ Mute Camera Flip  Chat  Leave                      │
└─────────────────────────────────────────────────────┘
```

---

## 🔄 How It Works

### 1. User Opens Room

```
VoiceRoomPage(room: room)
  ↓
initState() triggered
  ↓
_initializeAndJoinRoom() called
  ↓
Show spinner "Joining room..."
```

### 2. Room Loads

```
Agora engine initialized ✅
Camera permission requested ✅
Joined Agora channel ✅
Local preview appears ✅
"You joined the room" message ✅
```

### 3. Others Join

```
User joins room
  ↓
onUserJoined event fires
  ↓
Participant added to UI
  ↓
They publish video
  ↓
onUserPublished event fires
  ↓
We subscribe to their video
  ↓
Their tile appears with animation
```

### 4. Live Updates

```
User speaks
  ↓
Audio volume detected
  ↓
isSpeaking = true
  ↓
Green ring + glow appears
  ↓
Speaking indicator shows
```

### 5. User Leaves

```
User taps "Leave"
  ↓
Add system message
  ↓
Leave Agora channel
  ↓
Pop navigation
  ↓
Clean up resources
```

---

## 🎨 UI Components

### Video Tile (Active Camera)

```
┌────────────────────────┐
│                        │
│  [Live Video Stream]   │  ← AgoraVideoView
│                        │
│  ═════════════════════ │  ← Gradient (readability)
│  🎵 Sarah              │  ← Name + speaking indicator
└────────────────────────┘

Speaking State:
┌─────ⓖⓖⓖⓖⓖⓖⓖ─────┐
│  GREEN BORDER (3px) │  ← Green ring
│  + GREEN GLOW      │  ← Shadow effect
│  [Live Video]      │
│  🎵 Sarah          │
└────────────────────┘

Muted State:
┌────────────────────┐
│ 🔴                 │  ← Red mute badge
│ [Live Video]       │     (top right)
│ Sarah (Muted)      │
└────────────────────┘
```

### Participant List Item

```
┌──────────────────────────────┐
│ 👤  John Doe    🎤 🎥       │
│ (JD)  Listener               │
│ ⭕ (speaking ring if active) │
└──────────────────────────────┘

Active Speaker:
┌──────────────────────────────┐
│ 👤  John Doe    🎤 🎥       │
│ ⭕ (JD)  Speaking...         │
│ (green border + green text)  │
└──────────────────────────────┘
```

### Control Button

```
Active (Mic/Camera ON):
   ┌────┐
   │ 🎤 │  ← Pink background
   └────┘
   Mute

Inactive (Mic/Camera OFF):
   ┌────┐
   │ 🎤 │  ← Grey background
   └────┘
   Unmute

Leave (Always):
   ┌────┐
   │ 📞 │  ← Red background
   └────┘
   Leave
```

---

## 📊 Grid Layouts

### 1 Camera

```
┌────────────────────┐
│                    │
│   [Large Tile]     │
│                    │
└────────────────────┘
```

### 2-3 Cameras

```
┌──────────┬──────────┐
│  Tile 1  │  Tile 2  │
├──────────┼──────────┤
│  Tile 3  │          │
└──────────┴──────────┘
```

### 4-6 Cameras

```
┌──────────┬──────────┐
│  Tile 1  │  Tile 2  │
├──────────┼──────────┤
│  Tile 3  │  Tile 4  │
├──────────┼──────────┤
│  Tile 5  │  Tile 6  │
└──────────┴──────────┘
```

### 7-9 Cameras (3 columns)

```
┌────────┬────────┬────────┐
│ Tile 1 │ Tile 2 │ Tile 3 │
├────────┼────────┼────────┤
│ Tile 4 │ Tile 5 │ Tile 6 │
├────────┼────────┼────────┤
│ Tile 7 │ Tile 8 │ Tile 9 │
└────────┴────────┴────────┘
```

### 10+ Cameras (4 columns)

```
┌────┬────┬────┬────┐
│ T1 │ T2 │ T3 │ T4 │
├────┼────┼────┼────┤
│ T5 │ T6 │ T7 │ T8 │
├────┼────┼────┼────┤
│ T9 │T10 │T11 │T12 │
└────┴────┴────┴────┘
```

**Automatically adapts as users join/leave!**

---

## 🎬 Animations

### Tile Entry (500ms)

**Before**:

```
Tile is off-screen
Opacity: 0%
Position: Down 30px
```

**Animation**:

```
500ms easeOut
Opacity: 0% → 100%
Position: Down 30px → Normal
Result: Smooth fade in + slide up
```

**After**:

```
Tile visible
Opacity: 100%
Position: Normal
```

### Speaking Ring (Live)

**Not Speaking**:

```
┌─────────┐
│ Border  │  Grey, 1px
│ Glow    │  None
│ [Video] │
└─────────┘
```

**Speaking**:

```
┌─ ⓖⓖⓖⓖⓖ ─┐
│ Border  │  Green, 3px
│ Glow    │  Green shadow
│ [Video] │
└─ ⓖⓖⓖⓖⓖ ─┘
```

**Instant update** when audio detected!

---

## 🔗 State Management

### What Gets Watched

```dart
ref.watch(agoraParticipantsProvider);
  ↓
Returns: Map<int, AgoraParticipant>
  ├─ displayName: String
  ├─ hasAudio: bool
  ├─ hasVideo: bool
  └─ isSpeaking: bool

ref.watch(videoTileProvider);
  ↓
Returns: VideoTileState
  ├─ localUid: int?
  ├─ remoteVideoUids: Set<int>
  └─ allVideoUids: List<int>

ref.watch(agoraVideoServiceProvider);
  ↓
Returns: AgoraVideoService
  ├─ engine: RtcEngine?
  ├─ localUid: int?
  ├─ isMicMuted: bool
  ├─ isVideoMuted: bool
  └─ currentChannel: String?
```

**Any change → UI rebuilds** (reactive!)

---

## 🛠️ Control Actions

### Tap Mic Toggle

```
Mic Toggle tapped
  ↓
agoraService.toggleMic()
  ↓
Agora mutes/unmutes audio
  ↓
isMicMuted flips
  ↓
Button color changes (pink ↔ grey)
  ↓
User sees feedback instantly
```

### Tap Camera Toggle

```
Camera Toggle tapped
  ↓
agoraService.toggleVideo()
  ↓
Agora stops/starts video
  ↓
isVideoMuted flips
  ↓
Button color changes
  ↓
Local tile disappears/reappears
```

### Tap Chat

```
Chat button tapped
  ↓
showVoiceRoomChat()
  ↓
Chat overlay appears
  ↓
Can send/receive messages
  ↓
System messages shown
```

### Tap Leave

```
Leave button tapped
  ↓
Add system message "You left"
  ↓
agoraService.leaveRoom()
  ↓
Pop navigation
  ↓
dispose() cleans up
```

---

## 🎯 Quick Integration

### Step 1: Import

```dart
import 'package:mixmingle/features/room/screens/voice_room_page.dart';
```

### Step 2: Navigate

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => VoiceRoomPage(room: room),
  ),
);
```

### Step 3: Done!

```
VoiceRoomPage automatically:
✅ Initializes Agora
✅ Joins room
✅ Shows video grid
✅ Manages participants
✅ Handles controls
✅ Cleans up on exit
```

---

## 📱 Responsive Behavior

### Desktop (1920x1080)

```
┌─────────────────────────────┐
│ AppBar                   │  │
├──────────────────┬──────────┤
│                  │ Sidebar  │
│  Video Grid      │ (280px)  │
│                  │          │
├──────────────────┴──────────┤
│ Control Bar                  │
└─────────────────────────────┘
```

### Tablet (720x1024)

```
┌─────────────────────────┐
│ AppBar              │   │
├──────────────┬──────────┤
│              │ Sidebar  │
│ Video Grid   │ (250px)  │
│              │          │
├──────────────┴──────────┤
│ Control Bar              │
└─────────────────────────┘
```

### Mobile Portrait (360x800)

```
┌──────────────┐
│ AppBar    [≡]│ ← Menu toggle
├──────────────┤
│              │
│ Video Grid   │ ← Full width
│              │
├──────────────┤
│ Control Bar  │
└──────────────┘

[≡] = Sidebar overlays grid
```

---

## ✅ Working Now

- [x] Video grid (adaptive)
- [x] Live video streams
- [x] Participant tracking
- [x] Chat integration
- [x] Mic/camera controls
- [x] Speaking indicators
- [x] Smooth animations
- [x] Error handling
- [x] App lifecycle
- [x] Resource cleanup

---

## 🎉 Production Ready

All components are:

- ✅ Implemented
- ✅ Integrated
- ✅ Tested
- ✅ Documented
- ✅ Production-ready

**Ready to deploy!** 🚀

---

**Last Updated**: January 25, 2026
**File**: [voice_room_page.dart](lib/features/room/screens/voice_room_page.dart)
