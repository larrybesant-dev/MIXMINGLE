# Advanced Voice Room Features - Quick Reference Guide

## 🎯 Quick Implementation Guide

### For Room Page Integration

Add these widgets to your room_page.dart layout:

```dart
// Module B - Advanced Mic Control
AdvancedMicControlWidget(
  onClose: () { setState(() => _showAdvancedMic = false); }
)

// Module C - Enhanced Chat
EnhancedChatWidget(
  roomId: widget.room.id,
  currentUserId: FirebaseAuth.instance.currentUser!.uid,
  currentUserName: currentUserProfile?.displayName ?? 'User',
  currentUserAvatarUrl: currentUserProfile?.photoUrl ?? '',
)

// Module D - Recording
RoomRecordingWidget(
  roomId: widget.room.id,
  userId: FirebaseAuth.instance.currentUser!.uid,
  onRecordingStarted: () => print('Recording started'),
  onRecordingStopped: () => print('Recording stopped'),
)

// Module E - Presence Indicators
RoomPresencePanelWidget(
  roomId: widget.room.id,
)

// Module F - Moderation
RoomModerationWidget(
  roomId: widget.room.id,
  currentUserId: FirebaseAuth.instance.currentUser!.uid,
  isModerator: userRole == 'moderator',
  onClose: () { setState(() => _showModeration = false); }
)

// Module G - Analytics
AnalyticsDashboardWidget(
  roomId: widget.room.id,
  onClose: () { setState(() => _showAnalytics = false); }
)
```

---

## 📦 Available Services & Providers

### Module B: Advanced Mic
```dart
// Service
final advancedMicServiceProvider = StateNotifierProvider<
    AdvancedMicServiceNotifier,
    AdvancedMicServiceState>((ref) => AdvancedMicServiceNotifier());

// Usage in widget
final micState = ref.watch(advancedMicServiceProvider);
final micNotifier = ref.read(advancedMicServiceProvider.notifier);

// Methods
micNotifier.setVolumeLevel(75.0);
micNotifier.toggleEchoCancellation();
micNotifier.setSoundMode(1); // 0: Default, 1: Enhanced, 2: Speech
```

### Module C: Enhanced Chat
```dart
// Providers
final chatMessagesProvider = StreamProvider.family<List<ChatMessage>, String>((ref, roomId) => ...);
final pinnedChatMessagesProvider = StreamProvider.family<List<ChatMessage>, String>((ref, roomId) => ...);

// Service methods
await chatService.sendMessage(
  roomId: roomId,
  userId: userId,
  userName: userName,
  userAvatarUrl: avatarUrl,
  content: message,
);

await chatService.pinMessage(roomId, messageId);
await chatService.deleteMessage(roomId, messageId);
await chatService.addReaction(roomId, messageId, emoji);
```

### Module D: Recording
```dart
// Provider
final roomRecordingServiceProvider = StateNotifierProvider<
    RoomRecordingServiceNotifier,
    RecordingInfo?>((ref) => RoomRecordingServiceNotifier());

// Usage
final recordingState = ref.watch(roomRecordingServiceProvider);
final recordingNotifier = ref.read(roomRecordingServiceProvider.notifier);

// Methods
await recordingNotifier.startRecording(
  roomId: roomId,
  userId: userId,
);
await recordingNotifier.pauseRecording();
await recordingNotifier.resumeRecording();
await recordingNotifier.stopRecording(finalFileSize: 0);
recordingNotifier.setRecordingPublic(true);
```

### Module E: Presence
```dart
// Providers
final roomPresenceProvider = StreamProvider.family<List<UserPresence>, String>((ref, roomId) => ...);
final onlineUsersInRoomProvider = StreamProvider.family<List<UserPresence>, String>((ref, roomId) => ...);
final typingUsersProvider = StreamProvider.family<List<UserPresence>, String>((ref, roomId) => ...);

// Service methods
await presenceService.updatePresenceStatus(userId, PresenceStatus.online);
await presenceService.updateRoomPresence(userId, roomId);
await presenceService.setTypingStatus(userId, true);
```

### Module F: Moderation
```dart
// Providers
final moderationLogsProvider = StreamProvider.family<List<ModerationLog>, String>((ref, roomId) => ...);
final mutedUsersProvider = StreamProvider.family<List<String>, String>((ref, roomId) => ...);
final bannedUsersProvider = StreamProvider.family<List<String>, String>((ref, roomId) => ...);

// Service methods
await moderationService.warnUser(
  roomId: roomId,
  moderatorId: moderatorId,
  targetUserId: targetUserId,
  reason: reason,
);

await moderationService.muteUser(
  roomId: roomId,
  moderatorId: moderatorId,
  targetUserId: targetUserId,
  reason: reason,
  duration: Duration(hours: 1), // optional
);

await moderationService.kickUser(
  roomId: roomId,
  moderatorId: moderatorId,
  targetUserId: targetUserId,
  reason: reason,
);

await moderationService.banUser(
  roomId: roomId,
  moderatorId: moderatorId,
  targetUserId: targetUserId,
  reason: reason,
  duration: Duration(days: 7), // optional
);
```

### Module G: Analytics
```dart
// Providers
final roomStatisticsProvider = StreamProvider.family<RoomStatistics?, String>((ref, roomId) => ...);
final topUsersInRoomProvider = StreamProvider.family<List<UserEngagement>, String>((ref, roomId) => ...);
final recentActivityProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, roomId) => ...);

// Service methods
await analyticsService.recordUserJoin(roomId, userId);
await analyticsService.recordUserLeave(roomId, userId);
await analyticsService.recordMessageSent(roomId, userId);
await analyticsService.recordRecordingCreated(roomId, userId, fileSize);
```

---

## 🎨 UI Components

### Module B Widgets
- `AdvancedMicControlWidget` - Main control panel

### Module C Widgets
- `EnhancedChatWidget` - Chat interface with message display

### Module D Widgets
- `RoomRecordingWidget` - Recording controls and timer

### Module E Widgets
- `UserPresenceIndicator` - Individual status dot
- `TypingIndicator` - Animated typing animation
- `RoomPresencePanelWidget` - Complete presence panel

### Module F Widgets
- `RoomModerationWidget` - Moderation control panel

### Module G Widgets
- `AnalyticsDashboardWidget` - Analytics dashboard

---

## 🔌 Firebase Integration Points

### Firestore Collections Used
```
rooms/{roomId}/chat_messages
rooms/{roomId}/moderation_logs
rooms/{roomId}/user_presence
rooms/{roomId}/events
rooms/{roomId}/muted_users
rooms/{roomId}/banned_users
rooms/{roomId}/user_engagement
room_statistics/{roomId}
```

### Data Models
- `ChatMessage` - Module C
- `RecordingInfo` - Module D
- `UserPresence` - Module E
- `ModerationLog` - Module F
- `RoomStatistics` - Module G
- `UserEngagement` - Module G

---

## ⚙️ Configuration

### Video Quality Settings (Module A)
```dart
// High Quality: 1280x720@30fps, 3200kbps
// Medium Quality: 640x480@24fps, 1200kbps
// Low Quality: 320x240@15fps, 200kbps
```

### Presence Statuses (Module E)
- `PresenceStatus.online` (Green 🟢)
- `PresenceStatus.away` (Yellow 🟡)
- `PresenceStatus.offline` (Gray ⚫)
- `PresenceStatus.doNotDisturb` (Red 🔴)

### Moderation Actions (Module F)
- `ModerationAction.warn`
- `ModerationAction.mute`
- `ModerationAction.kick`
- `ModerationAction.ban`
- `ModerationAction.unban`

### Recording States (Module D)
- `RecordingState.idle`
- `RecordingState.recording`
- `RecordingState.paused`
- `RecordingState.completed`

---

## 🎯 Common Use Cases

### Display Live Chat in Room
```dart
EnhancedChatWidget(
  roomId: roomId,
  currentUserId: userId,
  currentUserName: userName,
  currentUserAvatarUrl: avatarUrl,
)
```

### Show Who's Online
```dart
RoomPresencePanelWidget(roomId: roomId)
```

### Allow Room Recording
```dart
RoomRecordingWidget(
  roomId: roomId,
  userId: userId,
  onRecordingStarted: () => analyticsService.recordRecordingCreated(...),
)
```

### Monitor Room Health (Moderators Only)
```dart
if (isModerator) {
  RoomModerationWidget(
    roomId: roomId,
    currentUserId: userId,
    isModerator: true,
  )
}
```

### View Room Statistics
```dart
AnalyticsDashboardWidget(roomId: roomId)
```

### Fine-Tune Audio Quality
```dart
AdvancedMicControlWidget()
```

---

## 🚨 Error Handling

All widgets include error handling:
- Loading states while fetching Firestore data
- Error messages displayed to users
- Graceful fallbacks for missing data
- Try-catch blocks in all async operations

---

## 📊 State Management Pattern

All modules follow Riverpod patterns:

```dart
// For mutable state
final provider = StateNotifierProvider<Notifier, State>((ref) => Notifier());

// For real-time Firestore data
final provider = StreamProvider.family<Model, String>((ref, param) => ...);

// For services
final provider = Provider<Service>((ref) => Service());
```

---

## 🔐 Security Features

- ✅ Moderator-only moderation actions
- ✅ User can only delete their own messages
- ✅ Recording ownership tracking
- ✅ Presence updates only for current user
- ✅ Type-safe enum-based states

Implement Firestore security rules as shown in ADVANCED_MODULES_DELIVERY.md

---

## 📱 Responsive Design

All widgets are responsive:
- Adapts to different screen sizes
- Touch-friendly controls
- Proper padding and spacing
- Overflow handling

---

## ⚡ Performance Tips

1. **Limit Firestore Queries**: All streams use `limit()` clauses
2. **Lazy Loading**: Widgets only load data when displayed
3. **Efficient Updates**: StreamProviders only rebuild affected widgets
4. **Image Caching**: User avatars cached by Flutter
5. **Animations**: Controlled AnimationControllers disposed properly

---

## 🧪 Testing Checklist

- [ ] Module A: Quality selector changes video resolution
- [ ] Module B: Volume slider works (0-100%)
- [ ] Module B: Audio enhancements toggle independently
- [ ] Module C: Messages send and display in real-time
- [ ] Module C: Messages can be pinned/unpinned
- [ ] Module D: Recording timer counts up accurately
- [ ] Module D: Privacy toggle switches between public/private
- [ ] Module E: Presence indicators update when users join/leave
- [ ] Module E: Typing indicator animation plays correctly
- [ ] Module F: Moderation actions execute and log correctly
- [ ] Module G: Statistics display accurate numbers
- [ ] Module G: Recent activity feed updates in real-time

---

## 📖 Documentation Files

| File | Purpose |
|------|---------|
| MODULE_INTEGRATION_INDEX.md | Complete module reference |
| ADVANCED_MODULES_DELIVERY.md | Implementation summary |
| QUICK_REFERENCE.md | This file |

---

## 🆘 Troubleshooting

### Chat not loading?
- Check Firestore rules
- Verify room ID is correct
- Check Firebase connection

### Presence not updating?
- Verify user_presence collection exists
- Check StreamProvider is watching correct roomId
- Ensure current user ID is set

### Recording not working?
- Verify Agora engine is initialized
- Check permissions on device
- Verify room ID passed correctly

### Analytics data missing?
- Ensure events are being recorded
- Check room_statistics collection
- Verify timestamp fields in Firestore

---

## 📝 Version Info

- **Version**: 1.0
- **Created**: January 24, 2025
- **Status**: Production Ready
- **Modules**: 7/7 Complete

---

**Last Updated**: January 24, 2025
