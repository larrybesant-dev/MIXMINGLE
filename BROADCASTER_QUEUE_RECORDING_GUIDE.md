# Broadcaster Queue System & Recording Setup Guide

## Overview

MixMingle now has a complete **broadcaster queue system** with automatic recording capability. This allows:

- ✅ Users to request to become broadcasters
- ✅ Queue management (FIFO - First In, First Out)
- ✅ Automatic approval when spots open up
- ✅ Broadcast recording to cloud storage
- ✅ "Room at Capacity" notifications

## Architecture

### Data Flow

```
User Requests Broadcast
        ↓
BroadcasterService.requestBroadcast()
        ↓
Create entry in rooms/{roomId}/broadcasterQueue/{userId}
        ↓
Status: "pending" (if at capacity) or "approved" (if spot available)
        ↓
User sees status in participants list
        ↓
User switches to broadcaster role
        ↓
Status updates to "broadcasting"
        ↓
Cloud Function triggers recording start
        ↓
User stops broadcasting
        ↓
Status updates to (original status)
        ↓
Cloud Function triggers recording stop
```

## Implementation Files

### 1. **BroadcasterQueue Model**

[lib/shared/models/broadcaster_queue.dart](lib/shared/models/broadcaster_queue.dart)

```dart
// Queue entry for tracking broadcast requests
class BroadcasterQueue {
  final String userId;
  final String userName;
  final DateTime requestedAt;
  final String status;           // 'pending', 'approved', 'broadcasting'
  final int queuePosition;
  final DateTime? approvedAt;
  final DateTime? broadcastStartedAt;
  final DateTime? broadcastEndedAt;
  // Recording fields
  final bool isRecording;        // Whether currently recording
  final String? recordingId;     // Agora recording ID
  final DateTime? recordingStartedAt;
  final DateTime? recordingEndedAt;
}
```

### 2. **BroadcasterService**

[lib/services/broadcaster_service.dart](lib/services/broadcaster_service.dart)

Key methods:

- `requestBroadcast(roomId)` - User requests to broadcast
- `cancelBroadcastRequest(roomId)` - Cancel pending request
- `approveNextInQueue(roomId)` - Approve next broadcaster
- `getActiveBroadcasterCount(roomId)` - Count current broadcasters
- `startRecording(roomId, userId)` - Trigger recording
- `stopRecording(roomId, userId)` - Stop recording

### 3. **Room Page Updates**

[lib/features/room/screens/room_page.dart](lib/features/room/screens/room_page.dart)

New UI elements:

- Broadcaster capacity indicator: `🎥 Broadcasters: 5/20`
- "Room at Broadcaster Capacity" warning when full
- "Request to Broadcast" button in participants menu
- Status badges:
  - 🎥 Currently Broadcasting
  - ✅ Approved to Broadcast
  - ⏳ Waiting in Queue (with cancel option)

### 4. **Firestore Security Rules**

[firestore.rules](firestore.rules)

```
/rooms/{roomId}/broadcasterQueue/{userId}
├── read: Any room member
├── create: User creating their own entry with status="pending"
├── update: User (own entry) or moderator (any entry)
└── delete: User (own entry) or moderator (any entry)
```

### 5. **Cloud Functions**

[functions/src/broadcasters.ts](functions/src/broadcasters.ts)

Triggers:

1. **onBroadcasterApproved** - When status changes to "broadcasting"
   - Starts recording via Agora REST API

2. **onBroadcasterOffline** - When broadcaster queue entry deleted
   - Auto-approves next pending broadcaster
   - Sends notification

3. **cleanupOldBroadcasts** - Daily maintenance
   - Removes recordings older than 30 days

## Firestore Structure

```
rooms/{roomId}/
  - activeBroadcasters: ["uid1", "uid2", ...]  (updated by listeners)
  - maxBroadcasters: 20                         (configurable)

  broadcasterQueue/
    {userId}/
      - userId: "user123"
      - userName: "John Doe"
      - userPhotoUrl: "https://..."
      - requestedAt: Timestamp
      - status: "pending" | "approved" | "broadcasting"
      - queuePosition: 5
      - approvedAt: Timestamp (if approved)
      - broadcastStartedAt: Timestamp (if broadcasting)
      - broadcastEndedAt: Timestamp (if ended)
      - isRecording: false
      - recordingId: "agora-recording-id"
      - recordingSessionId: "sid-123456"
      - recordingStartedAt: Timestamp
      - recordingEndedAt: Timestamp
      - recordingStatus: "completed" | "failed"
```

## Recording Setup (AWS + Agora)

### Prerequisites

1. **Agora Account** with API credentials
2. **AWS S3 Bucket** for storing recordings
3. **Environment Variables** configured in Cloud Functions

### Step 1: Configure Environment Variables

```bash
# In Firebase Cloud Functions
firebase functions:config:set \
  agora.app_id="YOUR_AGORA_APP_ID" \
  agora.api_key="YOUR_AGORA_API_KEY" \
  agora.api_secret="YOUR_AGORA_API_SECRET" \
  recording.bucket="your-recordings-bucket" \
  aws.access_key="YOUR_AWS_ACCESS_KEY" \
  aws.secret_key="YOUR_AWS_SECRET_KEY"
```

### Step 2: Create AWS S3 Bucket

```bash
# Using AWS CLI
aws s3 mb s3://mixmingle-agora-recordings --region us-east-1

# Enable versioning (optional)
aws s3api put-bucket-versioning \
  --bucket mixmingle-agora-recordings \
  --versioning-configuration Status=Enabled

# Set bucket lifecycle (optional - delete after 90 days)
aws s3api put-bucket-lifecycle-configuration \
  --bucket mixmingle-agora-recordings \
  --lifecycle-configuration '{
    "Rules": [{
      "Id": "DeleteOldRecordings",
      "Status": "Enabled",
      "ExpirationInDays": 90
    }]
  }'
```

### Step 3: Update Agora Recording Settings

In Agora Dashboard:

1. Go to **Project Management** → Your Project
2. Expand **Features**
3. Find **Recording**
4. Configure:
   - **Recording Mode**: Composite (records entire room view)
   - **Video Profile**: 720p, 24 fps
   - **Audio Profile**: High quality, Stereo
   - **Container Format**: MP4 or HLS (M3U8)

### Step 4: Deploy Cloud Functions

```bash
cd functions
npm install

# Deploy just broadcaster functions
firebase deploy --only functions:onBroadcasterApproved
firebase deploy --only functions:onBroadcasterOffline
firebase deploy --only functions:cleanupOldBroadcasts
```

## Usage Flow

### For End Users

#### Requesting to Broadcast

```
1. Click participants badge (top-left of video area)
2. Find desired participant or wait to request yourself
3. Click menu button (⋮) next to participant name
4. Select "Request to Broadcast"
   - If spot available: ✅ "Approved to Broadcast!"
   - If room full: ⏳ "Added to queue (position: 3)"
5. Wait for approval or opening

```

#### When Approved

```
1. Participant list shows: ✅ Approved to Broadcast
2. User clicks "Start Broadcasting" in room controls
3. User's camera/microphone go live
4. Recording starts automatically
5. Other users can watch and hear
```

#### Canceling Request

```
1. Open participants list
2. Find your entry showing "⏳ Waiting in Queue"
3. Click menu and select option to cancel
4. You're removed from queue
```

#### Auto-Approval When Spot Opens

```
1. Current broadcaster stops streaming
2. Cloud Function triggered
3. Next pending user auto-approved
4. Next user gets notification
5. They see ✅ Approved in participants list
```

## Recording Management

### How Recording Works

1. **Start Trigger**: User status changes to "broadcasting"
2. **Cloud Function**: Detects status change → calls Agora REST API
3. **Agora Records**: Entire room view (composite recording)
4. **Upload**: Video uploaded to AWS S3 after session ends
5. **Metadata**: Recording details saved in Firestore
6. **Stop Trigger**: User status changes from "broadcasting"

### Recording File Structure

```
s3://mixmingle-agora-recordings/
├── {roomId}/
│   ├── {userName}/
│   │   ├── {recordingId}.m3u8 (HLS manifest)
│   │   ├── {recordingId}-segment-0.ts
│   │   ├── {recordingId}-segment-1.ts
│   │   └── ...
│   └── {anotherUserName}/
│       └── ...
```

### Accessing Recordings

```dart
// Retrieve recording URL from Firestore
final queueDoc = await db
  .collection('rooms').doc(roomId)
  .collection('broadcasterQueue').doc(userId)
  .get();

final recordingId = queueDoc.data()?['recordingId'];
final recordingUrl = 'https://mixmingle-agora-recordings.s3.amazonaws.com/'
    '${roomId}/${userName}/${recordingId}.m3u8';
```

## Broadcaster Capacity Management

### Default Configuration

```dart
// In Room model
final int maxBroadcasters = 20;  // Max simultaneous broadcasters
```

### How Capacity Works

```
Available Spots = maxBroadcasters - activeBroadcasters.length

If available spots > 0:
  → Status: "approved" (automatically)
  → User can start broadcasting immediately

If available spots <= 0:
  → Status: "pending" (added to queue)
  → Position: Number in queue
  → Waits for next opening
  → Auto-approved when spot opens
```

### UI Feedback

```dart
if (activeBroadcasters.length >= maxBroadcasters) {
  showSnackBar("🔴 Room at Broadcaster Capacity (20/20)");
} else {
  showSnackBar("🎥 Broadcasters: 18/20");
}
```

## Troubleshooting

### Recording Not Starting

**Problem**: Broadcaster is live but recording not starting

**Solutions**:

1. Check Cloud Function logs: `firebase functions:log`
2. Verify environment variables are set correctly
3. Check Agora API credentials
4. Ensure AWS S3 bucket exists and is accessible
5. Check IAM permissions for service account

### Next Broadcaster Not Auto-Approved

**Problem**: No one gets approved when broadcaster exits

**Solutions**:

1. Check Cloud Function trigger (onBroadcasterOffline)
2. Verify queue has pending entries
3. Check Firestore security rules allow update
4. Monitor function execution logs

### Recording File Not Found

**Problem**: Recording should exist but can't find it

**Solutions**:

1. Check recording file naming: `{roomId}/{userName}/{recordingId}`
2. Verify S3 bucket exists and has proper ACLs
3. Check CloudFront or CDN if using one
4. Review recording status in Firestore: may be "failed"

## Performance Considerations

### Recording Impact

- **Bandwidth**: Recording adds ~1-2 MB/s upstream (Agora handles compression)
- **Storage**: 1 hour of HD = ~500 MB - 1 GB (depends on bitrate)
- **API Calls**: 2 per broadcast session (start + stop)

### Optimization Tips

```dart
// Limit recording to important broadcasts only
if (isImportantBroadcast) {
  await broadcasterService.startRecording(roomId, userId);
}

// Auto-delete old recordings after 30 days (handled by Cloud Function)

// Use HLS format for streaming playback (chunked, resumable)
// Use MP4 format for archival (single file)
```

## Security

### Access Control

- Only room members can see broadcaster queue
- Only room moderators can force-approve/remove broadcasters
- Recording URLs can be made private via S3 bucket policies
- CloudFront signed URLs for secure distribution

### Data Privacy

- Recording metadata includes user consent flag
- Delete recordings when user profile is deleted
- Encrypted storage recommended for sensitive content

## Future Enhancements

- [ ] Custom recording layouts (spotlight, gallery, pip)
- [ ] Real-time transcription of broadcasts
- [ ] Interactive features during broadcast (polls, Q&A)
- [ ] Broadcast scheduling/calendar
- [ ] Replay feature within app
- [ ] Monetization (paid broadcasts)
- [ ] Analytics dashboard (viewers, engagement, duration)

---

**Last Updated**: January 26, 2026
**Version**: 1.0 - Initial Broadcaster Queue & Recording Implementation
