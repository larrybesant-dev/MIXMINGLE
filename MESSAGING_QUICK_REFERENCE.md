# Messaging System Quick Reference Guide

## 🎯 Phase 3.2 Deliverables

### ✅ Completed Features

1. **Conversation List** - Real-time chat room list
2. **Direct Messages** - One-on-one messaging (already working)
3. **Room Chat** - In-room messaging (verified working)
4. **Typing Indicators** - Shows when user is typing
5. **Presence Indicators** - Online/offline status with green dot
6. **Read Receipts** - Infrastructure in place
7. **Message Reactions** - Infrastructure + DM UI working

### 📊 Results

```
Production Errors: 0
Production Warnings: 0
Test Warnings: 8 (unchanged)
```

---

## 🔧 Provider Usage

### Get Conversation List

```dart
final conversationListAsync = ref.watch(conversationListProvider);

conversationListAsync.when(
  data: (chatRooms) {
    // chatRooms is List<ChatRoom>
    for (final room in chatRooms) {
      print('Room: ${room.id}');
      print('Last message: ${room.lastMessage}');
      print('Unread count: ${room.unreadCounts[currentUserId]}');
    }
  },
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => Text('Error: $error'),
);
```

### Get Messages for a Chat Room

```dart
final messagesAsync = ref.watch(messagesProvider(roomId));

messagesAsync.when(
  data: (messages) {
    // messages is List<ChatMessage>
    for (final message in messages) {
      print('${message.senderName}: ${message.content}');
    }
  },
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => Text('Error: $error'),
);
```

### Check Typing Status

```dart
final typingAsync = ref.watch(typingStatusProvider(roomId));

typingAsync.when(
  data: (isTyping) {
    if (isTyping) {
      return Text('Other user is typing...');
    }
    return SizedBox.shrink();
  },
  loading: () => SizedBox.shrink(),
  error: (_, __) => SizedBox.shrink(),
);
```

### Check User Presence

```dart
final presenceAsync = ref.watch(presenceProvider(userId));

presenceAsync.when(
  data: (presence) {
    final isOnline = presence['isOnline'] as bool;
    final lastSeen = presence['lastSeen'] as DateTime?;

    if (isOnline) {
      return Icon(Icons.circle, color: Colors.green, size: 12);
    } else if (lastSeen != null) {
      return Text('Last seen: ${_formatTime(lastSeen)}');
    }
    return Text('Offline');
  },
  loading: () => SizedBox.shrink(),
  error: (_, __) => SizedBox.shrink(),
);
```

---

## 📝 Service Methods

### Send Message (DM)

```dart
final chatService = ref.read(chatServiceProvider);
await chatService.sendMessage(
  roomId,
  messageContent,
  senderName: currentUserName,
);
```

### Send Message (Room)

```dart
final repository = ref.read(roomSubcollectionRepositoryProvider);
final chatMessage = ChatMessage(
  id: '',
  senderId: currentUserId,
  senderName: currentUserName,
  content: messageContent,
  timestamp: DateTime.now(),
  context: MessageContext.room,
  roomId: roomId,
  contentType: MessageContentType.text,
);

await repository.sendMessage(
  roomId: roomId,
  message: chatMessage,
);
```

### Mark Messages as Read

```dart
final chatService = ref.read(chatServiceProvider);
await chatService.markMessagesAsRead(roomId);
```

### Update Typing Status

```dart
final chatService = ref.read(chatServiceProvider);
await chatService.updateTypingStatus(roomId, true); // Start typing
await chatService.updateTypingStatus(roomId, false); // Stop typing
```

### Update User Presence

```dart
final chatService = ref.read(chatServiceProvider);

// Set user online
await chatService.setUserOnline(userId);

// Set user offline
await chatService.setUserOffline(userId);
```

---

## 🏗️ Data Models

### ChatRoom

```dart
class ChatRoom {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageTime;
  final Map<String, int> unreadCounts;
  final bool isTyping;
}
```

### ChatMessage

```dart
class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final MessageContext context; // direct, room, group, speedDating
  final String? roomId;
  final String? receiverId;
  final MessageContentType contentType; // text, image, video, audio, system, etc.
  final MessageStatus status; // sent, delivered, read
  final bool isRead;
  final bool isPinned;
  final List<String> reactions;
}
```

### DirectMessage

```dart
class DirectMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final DirectMessageType type;
  final String content;
  final MessageStatus status;
  final DateTime timestamp;
  final DateTime? readAt;
  final Map<String, List<String>> reactions;
}
```

---

## 🎨 UI Patterns

### Conversation List Item

```dart
ListTile(
  leading: Stack(
    children: [
      CircleAvatar(/* User avatar */),
      if (isOnline)
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
    ],
  ),
  title: Text(otherUser.displayName),
  subtitle: isTyping
    ? Text('Typing...', style: TextStyle(color: Colors.green))
    : Text(lastMessage),
  trailing: Column(
    children: [
      Text(formatTime(lastMessageTime)),
      if (unreadCount > 0)
        Badge(label: Text('$unreadCount')),
    ],
  ),
);
```

### Message Bubble

```dart
Align(
  alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
  child: Container(
    padding: EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: isCurrentUser ? Colors.blue : Colors.grey,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isCurrentUser) Text(message.senderName, style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Text(message.content),
        SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(formatTime(message.timestamp), style: TextStyle(fontSize: 10)),
            if (message.isRead && isCurrentUser)
              Icon(Icons.done_all, size: 12, color: Colors.blue),
          ],
        ),
      ],
    ),
  ),
);
```

---

## 🔄 Real-Time Patterns

### Pattern 1: Watch Single Stream

```dart
final dataAsync = ref.watch(streamProvider);

dataAsync.when(
  data: (data) => /* Build UI with data */,
  loading: () => /* Loading indicator */,
  error: (error, stack) => /* Error UI */,
);
```

### Pattern 2: Watch Multiple Streams (Nested)

```dart
final stream1Async = ref.watch(provider1);

stream1Async.when(
  data: (data1) {
    final stream2Async = ref.watch(provider2(data1.id));

    return stream2Async.when(
      data: (data2) => /* Build UI with data1 + data2 */,
      loading: () => /* Loading data2 */,
      error: (error, stack) => /* Error for data2 */,
    );
  },
  loading: () => /* Loading data1 */,
  error: (error, stack) => /* Error for data1 */,
);
```

### Pattern 3: Watch with Default Fallback

```dart
final dataAsync = ref.watch(streamProvider);

final data = dataAsync.valueOrNull ?? defaultValue;
// Use 'data' with fallback to defaultValue if loading/error
```

---

## 🧪 Testing Examples

### Test Conversation List

1. Open app and navigate to messages
2. Verify list loads
3. Send a message from another device
4. Verify list updates in real-time
5. Verify unread count increases
6. Open conversation
7. Verify unread count resets

### Test Typing Indicators

1. Open conversation from device A
2. Start typing on device B
3. Verify "Typing..." appears on device A within 1 second
4. Stop typing on device B
5. Verify "Typing..." disappears on device A after 3 seconds

### Test Presence

1. User A logs in
2. Verify green dot appears on User A's avatar in User B's conversation list
3. User A closes app
4. Verify green dot disappears within 5 seconds

### Test Room Chat

1. Join voice room
2. Open chat overlay
3. Send message
4. Verify message appears for all room participants
5. Verify system messages for join/leave events

---

## 📁 File Locations

### Services

- `lib/services/chat_service.dart` - Core chat operations
- `lib/services/messaging_service.dart` - Direct message operations
- `lib/services/typing_service.dart` - Typing indicator management

### Providers

- `lib/providers/chat_providers.dart` - Chat providers
- `lib/providers/messaging_providers.dart` - DM providers
- `lib/providers/room_providers.dart` - Room providers

### Models

- `lib/shared/models/chat_message.dart` - Unified message model
- `lib/shared/models/direct_message.dart` - DM-specific model
- `lib/models/chat_room.dart` - Chat room model

### UI Components

- `lib/features/chat/screens/chat_list_page.dart` - Conversation list
- `lib/features/messages/chat_screen.dart` - Direct message screen
- `lib/features/room/widgets/voice_room_chat_overlay.dart` - Room chat

---

## 🚨 Common Issues & Solutions

### Issue: Messages not updating in real-time

**Solution:** Verify you're using `ref.watch()` not `ref.read()` in build method

### Issue: Typing indicator stuck on

**Solution:** Typing service has auto-timeout after 3 seconds. If still stuck, manually call `stopTyping()`

### Issue: Presence always shows offline

**Solution:** Ensure `setUserOnline()` is called on app start and resume

### Issue: Unread count not resetting

**Solution:** Call `markMessagesAsRead()` when conversation is opened and visible

### Issue: Duplicate messages in room chat

**Solution:** Ensure you're not creating multiple StreamProvider instances. Use `.family` for parameterized providers

---

## 📚 Additional Resources

- **Phase 3.1 Summary:** `PHASE_3.1_ROOM_REAL_TIME_COMPLETE.md`
- **Phase 3.2 Full Report:** `PHASE_3.2_MESSAGING_SYSTEM_COMPLETE.md`
- **Riverpod Documentation:** https://riverpod.dev
- **Firestore Streams:** https://firebase.google.com/docs/firestore/query-data/listen

---

**Last Updated:** 2026-01-26
**Phase:** 3.2 - Messaging System Reconnection
**Status:** ✅ Complete
