# 100+ Participant Broadcaster Mode Guide

## Overview

MixMingle now supports **100+ simultaneous participants** in a single room using Agora's **Interactive Live Streaming mode**. Instead of requiring all participants to stream video (which is limited to ~17 by default), the system implements a **broadcaster/audience model** where:

- **Broadcasters**: Can stream video and audio (limited to ~20 active at once)
- **Audience Members**: Can watch and listen (up to 100+ total)
- **Dynamic Role Switching**: Users can request to become broadcasters or downgrade to audience

## Architecture

### Channel Profile Changes
- **Old**: `ChannelProfileType.channelProfileCommunication` (group chat)
  - Limited to ~17 video streams
  - All participants are equal

- **New**: `ChannelProfileType.channelProfileLiveBroadcasting` (live streaming)
  - Supports unlimited participants
  - Two roles: Broadcaster and Audience

### Role System

#### Broadcaster Role
```dart
// User can stream video and audio
ClientRoleType.clientRoleBroadcaster
- publishCameraTrack: true
- publishMicrophoneTrack: true
- Can be seen and heard by audience
- Limited to ~20 active broadcasters per room
```

#### Audience Role
```dart
// User can watch and listen only
ClientRoleType.clientRoleAudience
- publishCameraTrack: false
- publishMicrophoneTrack: false
- Can watch all broadcasters
- No publishing restrictions
```

## Implementation

### 1. AgoraVideoService Methods

#### Switch to Broadcaster
```dart
// User wants to start broadcasting
await agoraService.switchToBroadcaster();
// This will:
// - Change role to broadcaster
// - Enable local video/audio
// - Notify listeners
```

#### Switch to Audience
```dart
// User wants to stop broadcasting
await agoraService.switchToAudience();
// This will:
// - Change role to audience
// - Disable local video/audio
// - Notify listeners
```

#### Check Broadcaster Capacity
```dart
bool isFull = agoraService.isAtBroadcasterCapacity();
// Returns true if 20+ broadcasters are active
// UI should show "Room at capacity" message
```

#### Update Active Broadcasters
```dart
// Called from Firestore listener to sync broadcaster list
agoraService.updateActiveBroadcasters([
  'uid_1',
  'uid_2',
  // ... up to 20
]);
```

### 2. Room Model Updates

```dart
// New fields in Room model
final List<String> activeBroadcasters;  // Current broadcaster UIDs
final int maxBroadcasters;              // Max active (default 20)
```

### 3. Firestore Structure

```
rooms/{roomId}/
  - id: string
  - title: string
  - participantIds: [array of all 100+ users]
  - activeBroadcasters: [array of current broadcaster UIDs]
  - maxBroadcasters: 20  (configurable per room)
  - isLive: boolean
  - createdAt: timestamp
  - updatedAt: timestamp
  ... other fields
```

## Broadcaster Queue System (Recommended Implementation)

To manage who becomes a broadcaster, implement a queue system:

```
rooms/{roomId}/broadcasterQueue/
  - requestedAt: timestamp
  - userId: string
  - userName: string
  - status: 'pending' | 'approved' | 'broadcasting' | 'cancelled'
```

Flow:
1. User clicks "Request to Broadcast"
2. Request added to queue with timestamp
3. When broadcaster goes offline, approve next in queue
4. Automatically switch approved user to broadcaster role

## Usage Examples

### Example 1: Basic Broadcaster Toggle

```dart
// In RoomPage build method
if (agoraService.isBroadcaster) {
  ElevatedButton(
    onPressed: () => agoraService.switchToAudience(),
    child: const Text('Stop Broadcasting'),
  );
} else {
  ElevatedButton(
    onPressed: agoraService.isAtBroadcasterCapacity()
      ? null
      : () => agoraService.switchToBroadcaster(),
    child: const Text('Start Broadcasting'),
  );
}
```

### Example 2: Broadcaster Request UI

```dart
// In participants list modal
_buildBroadcasterRequestButton(userId) {
  final isBroadcaster = widget.room.activeBroadcasters.contains(userId);
  final currentUserBroadcasting = widget.room.activeBroadcasters
    .contains(FirebaseAuth.instance.currentUser!.uid);

  if (isBroadcaster) {
    return Chip(label: const Text('🎥 Broadcasting'));
  } else if (widget.room.activeBroadcasters.length >= widget.room.maxBroadcasters) {
    return Chip(
      label: const Text('Queue (room full)'),
      onDeleted: () => _requestBroadcast(userId),
    );
  } else {
    return ElevatedButton(
      onPressed: () => _requestBroadcast(userId),
      child: const Text('Request Broadcast'),
    );
  }
}
```

### Example 3: Firestore Listener

```dart
// Listen to broadcaster changes in room
FirebaseFirestore.instance
  .collection('rooms')
  .doc(roomId)
  .snapshots()
  .listen((doc) {
    final broadcasters = List<String>.from(doc.get('activeBroadcasters') ?? []);
    agoraService.updateActiveBroadcasters(broadcasters);
  });
```

## Firestore Rules for Broadcaster Management

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /rooms/{roomId} {
      // Anyone can read room data
      allow read: if true;

      // Only admins can update room
      allow update: if request.auth.uid in resource.data.admins;

      // Update activeBroadcasters when role changes
      // Can be triggered by Cloud Function listening to Agora events
    }

    match /rooms/{roomId}/broadcasterQueue/{queueId} {
      // Users can request to broadcast
      allow create: if request.auth.uid == request.resource.data.userId;

      // Users can cancel own request
      allow delete: if request.auth.uid == resource.data.userId;

      // Only admins approve broadcasts
      allow update: if request.auth.uid in get(/databases/$(database)/documents/rooms/$(roomId)).data.admins;
    }
  }
}
```

## Performance Considerations

### Bandwidth
- **Per Broadcaster**: ~500KB-2MB/s (depends on resolution/FPS)
- **Per Audience**: ~500KB/s total (all streams combined)
- **Total for 20 broadcasters**: ~20MB/s upstream needed by server

### Network Quality
- Enable Agora's network quality monitoring
- Automatically downgrade broadcaster if connection poor
- Switch to audience mode if network degraded

### UI Rendering
- Only render video tiles for active broadcasters (max 20)
- Show participant list for all 100+ users
- Lazy-load remote video tiles on demand

## Upgrades & Extensions

### Future Features
1. **Scheduled Broadcasts**: Users can schedule when they want to broadcast
2. **Recording**: Record all broadcaster streams (requires Composite Recording setup)
3. **Interactive Features**: Polls, Q&A, audience reactions while watching
4. **Screen Sharing**: Allow broadcasters to share screens (separate track)
5. **Bitrate Adaptation**: Dynamically adjust quality based on network

### Scale to 1000+
For truly massive rooms (1000+ users):
- Use Agora's Cloud Recording with multiple hosts
- Implement RTMP streaming for broadcast to platforms like YouTube
- Use CDN for video distribution instead of peer-to-peer

## Troubleshooting

### Issue: User becomes broadcaster but video doesn't show
**Solution**:
- Ensure permissions granted (camera/microphone)
- Check that `setupLocalVideo()` called after role change
- Verify `publishCameraTrack` and `publishMicrophoneTrack` are true

### Issue: Too many broadcasters, can't add more
**Solution**:
- Check `isAtBroadcasterCapacity()` before allowing switch
- Show "Waiting for spot" UI
- Implement queue system for fairness

### Issue: Bandwidth congestion with 20 broadcasters
**Solution**:
- Reduce video resolution/FPS
- Limit to 15 broadcasters instead of 20
- Implement adaptive bitrate (built into Agora)

## Statistics

With current configuration:
- **Participants per room**: 100+
- **Active broadcasters**: ~20
- **Video streams displayed**: 20 (in video grid)
- **Total participants listed**: 100+
- **Bandwidth per broadcaster**: 500KB-2MB/s
- **Bandwidth per audience member**: 500KB/s

---

**Last Updated**: January 26, 2026
**Version**: 1.0 - Initial Broadcaster Mode Implementation
