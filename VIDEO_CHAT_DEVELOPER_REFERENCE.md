# Video Chat Features - Developer Quick Reference

## 🚀 Quick Navigation

### File Locations
- **Main Page**: [lib/screens/video_chat_page.dart](lib/screens/video_chat_page.dart)
- **State Providers**: [lib/providers/](lib/providers/)
- **UI Widgets**: [lib/shared/widgets/](lib/shared/widgets/)
- **Route**: `/video-chat`

### Routes
```dart
AppRoutes.videoChat  // Navigate to video chat
```

---

## 📦 Using the Providers

### 1. Friends Management

```dart
// Watch friends list
final friends = ref.watch(friendsProvider);

// Watch filtered friends (by search)
final filtered = ref.watch(filteredFriendsProvider);

// Get online friends only
final onlineFriends = ref.watch(onlineFriendsProvider);

// Get favorite friends
final favorites = ref.watch(favoriteFriendsProvider);

// Update search query
ref.read(friendSearchQueryProvider.notifier).state = 'alex';

// Toggle favorite status
ref.read(friendsProvider.notifier).toggleFavorite('user1');

// Mark messages as read
ref.read(friendsProvider.notifier).markMessagesAsRead('user1');

// Update online status
ref.read(friendsProvider.notifier).updateOnlineStatus('user1', true);

// Add unread message
ref.read(friendsProvider.notifier).addUnreadMessage('user1');
```

### 2. Groups Management

```dart
// Watch all groups
final groups = ref.watch(groupsProvider);

// Watch user's joined groups
final myGroups = ref.watch(userJoinedGroupsProvider);

// Watch active groups
final active = ref.watch(activeGroupsProvider);

// Search groups
ref.read(groupSearchQueryProvider.notifier).state = 'game';
final filtered = ref.watch(filteredGroupsProvider);

// Join group
ref.read(groupsProvider.notifier).joinGroup('group1', 'user1');

// Leave group
ref.read(groupsProvider.notifier).leaveGroup('group1', 'user1');

// Create group
final newGroup = VideoGroup(...);
ref.read(groupsProvider.notifier).createGroup(newGroup);

// Mark group messages as read
ref.read(groupsProvider.notifier).markMessagesAsRead('group1');
```

### 3. Video Room Management

```dart
// Watch active room ID
final roomId = ref.watch(activeRoomIdProvider);

// Watch all participants
final participants = ref.watch(participantsProvider);

// Watch video-enabled participants
final videoParticipants = ref.watch(videoParticipantsProvider);

// Watch participant count
final count = ref.watch(participantsCountProvider);

// Toggle audio
ref.read(participantsProvider.notifier).toggleAudio('user1', false);

// Toggle video
ref.read(participantsProvider.notifier).toggleVideo('user1', false);

// Toggle screen share
ref.read(participantsProvider.notifier).toggleScreenShare('user1', true);

// Update camera approval
ref.read(participantsProvider.notifier)
    .updateCameraApprovalStatus('user1', 'approved');

// Add participant
final participant = VideoParticipant(...);
ref.read(participantsProvider.notifier).addParticipant(participant);

// Remove participant
ref.read(participantsProvider.notifier).removeParticipant('user1');
```

### 4. Chat Messages

```dart
// Watch messages
final messages = ref.watch(chatMessagesProvider);

// Watch last message
final lastMsg = ref.watch(lastMessageProvider);

// Send text message
ref.read(chatMessagesProvider.notifier).sendMessage(
  senderId: 'user1',
  senderName: 'You',
  senderAvatar: 'https://avatar.url',
  content: 'Hello!',
);

// Send file
ref.read(chatMessagesProvider.notifier).sendFile(
  senderId: 'user1',
  senderName: 'You',
  senderAvatar: 'https://avatar.url',
  fileName: 'document.pdf',
  fileUrl: 'https://file.url',
  fileSize: 2500000,
);

// Clear messages
ref.read(chatMessagesProvider.notifier).clearMessages();
```

### 5. Notifications

```dart
// Watch all notifications
final notifications = ref.watch(notificationsProvider);

// Watch unread only
final unread = ref.watch(unreadNotificationsProvider);

// Watch unread count
final count = ref.watch(unreadNotificationCountProvider);

// Show friend request
ref.read(notificationsProvider.notifier)
    .friendRequest('Alex Johnson', 'user1');

// Show message notification
ref.read(notificationsProvider.notifier)
    .newMessage('Sarah Chen', 'group1');

// Show video request
ref.read(notificationsProvider.notifier)
    .videoRequest('Jordan Taylor', 'user2');

// Show room invite
ref.read(notificationsProvider.notifier)
    .roomInvite('Morgan Williams', 'group2');

// Show system notification
ref.read(notificationsProvider.notifier)
    .systemNotification('App Alert', 'Something happened');

// Mark as read
ref.read(notificationsProvider.notifier).markAsRead('notif_id');

// Remove notification
ref.read(notificationsProvider.notifier).removeNotification('notif_id');
```

### 6. UI State

```dart
// Dark mode toggle
ref.read(darkModeProvider.notifier).state = !darkMode;
final darkMode = ref.watch(darkModeProvider);

// Video quality
ref.read(videoQualityProvider.notifier).state = VideoQuality.high;
final quality = ref.watch(videoQualityProvider);

// Sidebar states
ref.read(friendsSidebarCollapsedProvider.notifier).state = true;
ref.read(groupsSidebarCollapsedProvider.notifier).state = true;

// Camera approval settings
ref.read(cameraApprovalSettingsProvider.notifier)
    .setDefaultMode('allow_all');

ref.read(cameraApprovalSettingsProvider.notifier)
    .approveUser('user1');

ref.read(cameraApprovalSettingsProvider.notifier)
    .blockUser('user2');

final status = ref.read(cameraApprovalSettingsProvider.notifier)
    .getApprovalStatus('user1'); // Returns: 'approved', 'denied', 'pending'

// User preferences
ref.read(userPreferencesProvider.notifier)
    .updatePreference('show_online_status', false);
```

---

## 🎨 Using the Widgets

### Main Video Chat Page
```dart
import 'screens/video_chat_page.dart';

// Navigate to it
Navigator.pushNamed(context, AppRoutes.videoChat);

// Or use it directly
Stack(
  children: [
    VideoChatPage(),
  ],
);
```

### Individual Components

```dart
// Video Grid only
VideoGridWidget(
  onExpandChat: () {
    // Handle chat expansion
  },
);

// Top Bar only
TopBarWidget(
  onToggleDarkMode: () {
    // Handle theme toggle
  },
);

// Friends Sidebar only
FriendsSidebarWidget(
  onCollapse: () {
    // Handle collapse
  },
);

// Groups Sidebar only
GroupsSidebarWidget(
  onCollapse: () {
    // Handle collapse
  },
);

// Chat Box only
ChatBoxWidget();

// Notification Widget
NotificationWidget(
  notification: AppNotification(
    id: '1',
    title: 'Test',
    message: 'Test message',
    type: 'system',
    timestamp: DateTime.now(),
    isRead: false,
  ),
);
```

---

## 💬 Common Patterns

### Pattern 1: Update List Item
```dart
// Update specific friend
ref.read(friendsProvider.notifier).toggleFavorite(friendId);

// Watch updated list automatically rebuilds widgets
final friends = ref.watch(friendsProvider);
```

### Pattern 2: Filter Data
```dart
// Set search query
ref.read(friendSearchQueryProvider.notifier).state = 'alex';

// Watch filtered results
final filtered = ref.watch(filteredFriendsProvider).when(
  data: (data) => data,
  loading: () => [],
  error: (_, __) => [],
);
```

### Pattern 3: Combine Multiple Providers
```dart
final messages = ref.watch(chatMessagesProvider);
final darkMode = ref.watch(darkModeProvider);

return Container(
  color: darkMode ? Colors.grey[900] : Colors.white,
  child: ListView(
    children: messages.map((msg) => ...).toList(),
  ),
);
```

### Pattern 4: Family Providers
```dart
// Get notifications by type
final notificationsByType = ref.watch(
  notificationsByTypeProvider('message')
);
```

---

## 🔧 Extending Features

### Add New Filter
```dart
// In friends_provider.dart
final filteredByStatusProvider = Provider<List<Friend>>((ref) {
  final friends = ref.watch(friendsProvider);
  return friends.where((f) => f.isOnline).toList();
});

// Use it
final online = ref.watch(filteredByStatusProvider);
```

### Add New Notification Type
```dart
// In notification_provider.dart
void specialAlert(String message) {
  addNotification(
    AppNotification(
      id: 'alert_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Alert',
      message: message,
      type: 'special_alert', // New type
      timestamp: DateTime.now(),
      isRead: false,
    ),
  );
}

// Use notification_widget.dart to add color/icon for new type
```

### Add Camera Approval Status
```dart
// In participant_provider.dart
void updateCameraApprovalStatus(String userId, String status) {
  state = state.map((participant) {
    if (participant.userId == userId) {
      return participant.copyWith(
        cameraApprovalStatus: status, // 'pending', 'approved', 'denied'
      );
    }
    return participant;
  }).toList();
}
```

---

## 📊 Mock Data Reference

### Mock Friends (6 total)
```dart
Friend(
  id: '1',
  name: 'Alex Johnson',
  avatarUrl: 'https://i.pravatar.cc/150?u=alex',
  isOnline: true,
  lastSeen: DateTime.now().subtract(const Duration(minutes: 2)),
  isFavorite: true,
  unreadMessages: 0,
)
```

### Mock Groups (5 total)
```dart
VideoGroup(
  id: 'group1',
  name: 'Daily Standup',
  description: 'Team sync every morning',
  imageUrl: 'https://i.pravatar.cc/150?u=standup',
  maxParticipants: 20,
  participantIds: ['1', '2', '3', '4'],
  createdAt: DateTime.now().subtract(const Duration(days: 30)),
  unreadMessages: 0,
  ownerId: '1',
)
```

### Mock Participants (3 total)
```dart
VideoParticipant(
  userId: 'user1',
  userName: 'Alex Johnson',
  avatarUrl: 'https://i.pravatar.cc/150?u=alex',
  isAudioEnabled: true,
  isVideoEnabled: true,
  isScreenSharing: false,
  joinedAt: DateTime.now().subtract(const Duration(minutes: 5)),
  cameraApprovalStatus: 'approved',
)
```

### Mock Messages (5+ total)
```dart
ChatMessage(
  id: 'msg1',
  senderId: 'user1',
  senderName: 'Alex Johnson',
  senderAvatar: 'https://i.pravatar.cc/150?u=alex',
  content: 'Hey everyone! Ready for the meeting?',
  timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
  type: 'text',
)
```

---

## 🚨 Error Handling

### Provider Error Example
```dart
final filtered = ref.watch(filteredFriendsProvider).when(
  data: (friends) {
    if (friends.isEmpty) {
      return Center(
        child: Text('No friends found'),
      );
    }
    return ListView(
      children: friends.map((f) => FriendTile(friend: f)).toList(),
    );
  },
  loading: () => const CircularProgressIndicator(),
  error: (error, stack) {
    return Center(
      child: Text('Error loading friends: $error'),
    );
  },
);
```

### Widget Error Boundary
```dart
Container(
  child: Image.network(
    avatarUrl,
    errorBuilder: (context, error, stackTrace) {
      return Icon(Icons.person);
    },
  ),
);
```

---

## 🎯 Testing Providers

### Test Friends Filtering
```dart
test('Filter friends by search', () {
  ref.read(friendSearchQueryProvider.notifier).state = 'alex';
  final filtered = ref.read(filteredFriendsProvider);
  expect(filtered.length, 1);
  expect(filtered[0].name, 'Alex Johnson');
});
```

### Test Group Join
```dart
test('Join group', () {
  ref.read(groupsProvider.notifier).joinGroup('group1', 'user1');
  final myGroups = ref.read(userJoinedGroupsProvider);
  expect(myGroups.any((g) => g.id == 'group1'), true);
});
```

---

## 📝 Coding Standards

- **Comments**: Explain "why", not "what"
- **Naming**: Clear, descriptive variable names
- **Formatting**: `flutter format lib/`
- **Analysis**: `flutter analyze` - no warnings
- **Widgets**: Prefer StateNotifier over State
- **Providers**: Compose smaller providers
- **Error Handling**: Always handle exceptions

---

## 🚀 Performance Tips

1. **Use `.when()` for FutureProvider**: Handles loading/error states
2. **Scope Providers**: Only rebuild needed widgets
3. **Use `family`**: For reusable providers with parameters
4. **Avoid Circular Dependencies**: Keep provider graph clean
5. **Cache Results**: Don't recalculate expensive operations
6. **Lazy Initialize**: Load data on-demand

---

## 🔗 Related Files

- [Full Feature Guide](VIDEO_CHAT_COMPLETE_GUIDE.md)
- [Testing Guide](VIDEO_CHAT_TESTING_GUIDE.md)
- [Deployment Guide](DEPLOYMENT_AND_QUICK_START.md)
- [Implementation Summary](VIDEO_CHAT_IMPLEMENTATION_SUMMARY.md)

---

**Last Updated**: February 7, 2026
**Version**: 1.0.0
