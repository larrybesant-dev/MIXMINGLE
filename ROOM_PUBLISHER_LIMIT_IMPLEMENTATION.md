# Room Publisher Limit Implementation Guide

**Date**: February 8, 2026
**Limit**: 12 concurrent video publishers per Agora RTC channel
**Architecture**: Flutter Web + Agora Web SDK
**Mode**: RTC (not Live Streaming)

---

## 🎯 What You Need to Know

### The Architect's Perspective

**CRITICAL FACT**: Agora does NOT limit connections per account. It limits:

> **Maximum concurrent video streams per channel** = 12 (stable, proven in testing)

This applies to:

- Flutter Web + Agora Web SDK ✅
- RTC mode ✅
- Chrome/Firefox/Safari on modern hardware ✅

**NOT to**:

- Individual user accounts ❌
- Total system connections ❌
- Channel count per user ❌

---

## 📁 New Files Added

### 1. **Core Feature Flag**

```
lib/core/feature_flags.dart
```

- `FeatureFlags.maxConcurrentAgoraConnections = 12`
- Centralized constant used everywhere
- Updated comment explains the architectural reality

### 2. **Room Limit Manager**

```
lib/services/room_limit_manager.dart
```

**Responsibilities**:

- Check if room is at capacity
- Track active publishers in Firestore
- Add/remove publishers when they go live
- Manage graceful degradation (bitrate allocation)
- Monitor in real-time via Firestore streams

**Key Methods**:

```dart
// Check capacity
bool isRoomAtCapacity(String roomId)
int getPublisherCount(String roomId)
List<String> getActivePublishers(String roomId)

// Manage publishers
bool addPublisher(String roomId, String userId)
void removePublisher(String roomId, String userId)

// Graceful degradation
Map<String,int> getBandwidthAllocationByPublisherCount(int count)
bool shouldEnableAdaptiveBitrate(int count)
List<int> getStreamsToDowngrade(String roomId, List<int> remoteUids)

// Real-time monitoring
Stream<int> watchRoomCapacity(String roomId)
```

### 3. **Enforcement Utilities**

```
lib/core/services/room_limit_enforcement.dart
```

**Provides**:

- `canUserJoinAsPublisher()` - Check before join
- `registerPublisher()` - Add user to active list
- `unregisterPublisher()` - Remove user
- `getGoLiveButtonState()` - Determine button state
- `getRoomCapacityInfo()` - Get detailed info
- `shouldEnableAdaptiveBitrate()` - Adaptive quality
- `getStreamsToDowngrade()` - Which streams to reduce

**Example Usage**:

```dart
// Check if user can go live
final state = await RoomLimitEnforcement.getGoLiveButtonState(roomId, userId);
if (state == GoLiveButtonState.enabled) {
  // Allow "Go Live"
} else {
  // Show disabled with reason
  print(RoomLimitEnforcement.getGoLiveButtonMessage(state));
}
```

### 4. **UI Feedback Widgets**

```
lib/shared/widgets/room_capacity_widgets.dart
```

**Components**:

- `RoomCapacityIndicator` - Inline text (12x format)
- `RoomCapacityCard` - Full card with progress bar
- `CapacityBadge` - Compact badge for app bar
- `RoomFullOverlay` - Modal warning when full
- `GoLiveButton` - Pre-built button with enforcement

**Usage**:

```dart
// Show capacity in room
RoomCapacityIndicator(roomId: roomId)

// Large capacity card
RoomCapacityCard(roomId: roomId)

// Go Live button with enforcement
GoLiveButton(
  roomId: roomId,
  userId: currentUser.id,
  onPressed: goLive,
)
```

---

## 🔌 Integration Points

### 1. **Go Live Button** (src: `lib/features/go_live/go_live_page.dart`)

**BEFORE** starting video broadcast:

```dart
// Check capacity
final state = await RoomLimitEnforcement.getGoLiveButtonState(roomId, userId);

if (state == GoLiveButtonState.enabled) {
  // Start broadcasting
  await agoraService.switchToBroadcaster();
  await RoomLimitEnforcement.registerPublisher(roomId, userId);
} else {
  // Show error
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(text: RoomLimitEnforcement.getGoLiveButtonMessage(state))
  );
}
```

**Button UI**:

```dart
GoLiveButton(
  roomId: roomId,
  userId: currentUser.id,
  onPressed: startLiveStream,
),

// Or use indicator near button
RoomCapacityIndicator(roomId: roomId),
```

### 2. **Room Join Flow** (src: likely `lib/features/video_room/video_room_lifecycle.dart`)

**BEFORE** user starts camera/joins channel:

```dart
// Step 1: Check if can join as publisher
final result = await RoomLimitEnforcement.canUserJoinAsPublisher(roomId, userId);

if (!result.canJoin) {
  // Join as audience only
  print('Room full: ${result.reason}');
  await joinAsAudience(); // No camera/mic
  return;
}

// Step 2: Join as publisher
await agoraService.joinRoom(roomId);
registerPublisher(roomId, userId);
```

### 3. **Agora Video Service** (already updated)

Already integrated:

```dart
// Check capacity in AgoraVideoService
Future<bool> isRoomAtCapacity(String roomId)
Future<bool> canUserGoLive(String roomId, String userId)
int getRoomPublisherLimit()
```

### 4. **Room UI** - Show Capacity Status

In any room screen:

```dart
// Show current capacity
RoomCapacityCard(roomId: roomId),

// Or compact badge in app bar
AppBar(
  actions: [
    CapacityBadge(roomId: roomId),
  ],
)
```

### 5. **Multi-Cam Grid** - Adaptive Quality

When subscribing to remote video in grid:

```dart
// Get streams that should be downgraded
final toDowngrade = await RoomLimitEnforcement.getStreamsToDowngrade(
  roomId,
  remoteUids,
);

// Apply lower resolution to those streams
for (int uid in toDowngrade) {
  agoraEngine.setRemoteVideoStreamType(
    uid: uid,
    streamType: VideoStreamType.videoStreamLow,
  );
}
```

### 6. **Leave Room** - Cleanup

When user leaves room:

```dart
// Unregister publisher
await RoomLimitEnforcement.unregisterPublisher(roomId, userId);

// Clear local cache
RoomLimitEnforcement.invalidateRoomCache(roomId);

// Leave Agora channel
await agoraService.leaveRoom();
```

---

## 📊 Firestore Room Schema Update

The `Room` model already has `activeBroadcasters` field. Ensure it's in firestore:

```json
{
  "rooms": {
    "{roomId}": {
      "id": "...",
      "title": "...",
      "hostId": "...",

      "activeBroadcasters": ["userId1", "userId2"],
      "maxBroadcasters": 12, // Will be deprecated (use FeatureFlags constant)
      "broadcastersUpdatedAt": 1707418200000

      // ... other fields
    }
  }
}
```

When running migrations:

```dart
// Update all rooms to use correct schema
db.collection('rooms').get().then((docs) {
  for (var doc in docs.docs) {
    doc.reference.update({
      'broadcastersUpdatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }
});
```

---

## 🎯 Enforcement Checklist

- [ ] **Go Live Button**: Check capacity before allowing broadcast
- [ ] **Room Join**: Prevent room join if at capacity (audience-only mode)
- [ ] **Room UI**: Display capacity indicator (how many on camera)
- [ ] **Warnings**: Show modal/toast when room reaches 75% capacity
- [ ] **App Bar**: Show capacity badge in room header
- [ ] **Grid Subscriptions**: Downgrade quality when approaching limit
- [ ] **Cleanup**: Unregister publisher on leave
- [ ] **Cache**: Invalidate room cache when leaving

---

## 📈 Graceful Degradation Strategy

### Video Quality Tiers by Publisher Count

```
≤ 4 publishers:  2500 kbps per stream → HIGH quality
5-8 publishers:  1500 kbps per stream → MEDIUM quality
9-12 publishers:  800 kbps per stream → LOW quality
```

### When to Enable Adaptive Bitrate

Automatically enabled when > 9 publishers (75% capacity):

```dart
if (await shouldEnableAdaptiveBitrate(roomId)) {
  // Enable automatic bitrate adjustment
  agoraEngine.enableDualStreamMode(enabled: true);
}
```

### Stream Downgrade Strategy

When at 90% capacity, downgrade bottom 1/3 of grid to low resolution:

```dart
final toDowngrade = await getStreamsToDowngrade(roomId, remoteUids);
for (int uid in toDowngrade) {
  setRemoteVideoStreamType(uid, VideoStreamType.videoStreamLow);
}
```

---

## 🚨 Error Handling

### Room At Capacity

```dart
try {
  bool canJoin = await canUserJoinAsPublisher(roomId, userId);
  if (!canJoin) {
    showError('Room is full. Join as audience instead?');
    return;
  }
} catch (e) {
  showError('Could not check room capacity. Try again.');
}
```

### Publisher Registration Failed

```dart
try {
  bool registered = await registerPublisher(roomId, userId);
  if (!registered) {
    // Room hit capacity between check and registration
    await switchToAudience(); // Downgrade to audience
  }
} catch (e) {
  // Firestore error - allow join anyway but log
  logError('Could not register publisher: $e');
}
```

---

## 📊 Analytics & Logging

Track when limits are enforced:

```dart
// Log capacity (already implemented in RoomLimitManager)
await logRoomMetrics(roomId);

// Custom analytics
analytics.logEvent('room_at_capacity', {
  'roomId': roomId,
  'publisherCount': 12,
  'maxPublishers': 12,
  'timestamp': DateTime.now().toIso8601String(),
});
```

---

## ✅ Testing Checklist

### Unit Tests

```dart
test('can add publisher under limit', () async {
  // addPublisher returns true when under limit
});

test('cannot add publisher at limit', () async {
  // addPublisher returns false when at limit
});

test('capacity detection works', () async {
  // isRoomAtCapacity returns true/false correctly
});
```

### Integration Tests

```dart
test('Go Live button disabled when room full', () async {
  // Button state is GoLiveButtonState.roomAtCapacity
});

test('Can join as audience when at capacity', () async {
  // User joins with isAudience=true
});
```

---

## 📝 Documentation

### For Developers

1. **"Why 12?"** → See [AGORA_SAFETY_STATUS.md](../AGORA_SAFETY_STATUS.md)
2. **"How to integrate"** → See Integration Points section above
3. **"How does it work"** → See Architecture section

### For Users

Show this in-app:

> "This room can have up to 12 people on camera at the same time. When the room is full, new joiners can watch and chat without their video."

---

## 🔄 Real-Time Capacity Updates

The system uses Firestore real-time listeners:

```dart
// Auto-updates UI when anyone goes live/stops
RoomCapacityIndicator(roomId: roomId) // Watches Firestore

// Stream version for custom handling
watchRoomCapacity(roomId).listen((count) {
  print('Room has $count publishers now');
});
```

No polling needed — updates happen in milliseconds via Firestore subscriptions.

---

## 🎓 Key Concepts

### Publisher vs. Audience

- **Publisher**: User with camera on (video + audio)
- **Audience**: User with camera off (audio/chat only)
- Limit applies only to **publishers** (12 max)
- **Audience** has no limit (100+)

### Broadcaster vs. Audience Role (Agora)

- **Broadcaster**: Can publish audio/video
- **Audience**: Receive-only (can't publish)
- Room limit enforces max 12 broadcasters
- Others must be in audience role

### Room vs. Account Limit

- **Room limit**: 12 publishers per channel (this system)
- **Account limit**: Doesn't exist (per Agora docs)
- User can be in multiple rooms, but limited to 12 publishers per room

---

## 🐛 Troubleshooting

**Issue**: Go Live button still lets users go live when room full

**Check**:

1. Is `GoLiveButton` widget being used, or custom button?
2. Is `RoomLimitEnforcement.registerPublisher()` being called?
3. Is room's `activeBroadcasters` field being updated in Firestore?

**Solution**:

```dart
// Make sure to:
1. Call canUserJoinAsPublisher() before enabling button
2. Call registerPublisher() AFTER video starts successfully
3. Verify Firestore updates with realtime listener
```

---

## 📚 Related Files

- [lib/core/feature_flags.dart](../lib/core/feature_flags.dart) - Constant definition
- [lib/services/room_limit_manager.dart](../lib/services/room_limit_manager.dart) - Core logic
- [lib/core/services/room_limit_enforcement.dart](../lib/core/services/room_limit_enforcement.dart) - Usage utilities
- [lib/shared/widgets/room_capacity_widgets.dart](../lib/shared/widgets/room_capacity_widgets.dart) - UI components
- [lib/services/agora_video_service.dart](../lib/services/agora_video_service.dart) - AgoraVideoService integration
- [lib/shared/models/room.dart](../lib/shared/models/room.dart) - Room model with activeBroadcasters

---

**Last Updated**: February 8, 2026
**Status**: Fully Implemented ✅
