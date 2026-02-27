# 🧩 COMPLETE PALTALK + MIX & MINGLE ROOM SYSTEM

## Full Architecture Blueprint (7 Modules)

**Status**: Architecture Phase
**Version**: 1.0
**Date**: January 26, 2026

---

## 📋 MODULE BREAKDOWN

| Module | Status      | LOC  | Features                                  | Priority |
| ------ | ----------- | ---- | ----------------------------------------- | -------- |
| **A**  | 🔵 Planning | 2K   | Multi-Cam, Spotlight, Cam Quality         | P0       |
| **B**  | 🔵 Planning | 1.5K | Mic Queue, Noise Filter, Gain Control     | P1       |
| **C**  | 🔵 Planning | 2K   | Chat, Whispers, Emojis, Pinned Messages   | P1       |
| **D**  | 🔵 Planning | 1.5K | Moderation, Bans, Shadow Ban, Admin Tools | P1       |
| **E**  | 🔵 Planning | 1.2K | Room Management, Themes, Capacity, MOTD   | P2       |
| **F**  | 🔵 Planning | 800  | Presence, Status, Idle Detection          | P2       |
| **G**  | 🔵 Planning | 1.5K | Gifts, XP, Badges, VIP, Room Coins        | P3       |

**Total**: ~10,500 LOC (production-ready)

---

## 🎯 EXECUTION PLAN

### **Phase 1: Foundation (Weeks 1-2)**

- Module A: Multi-Cam System
- Module B: Advanced Mic Control
- Database schema updates
- Test & Deploy

### **Phase 2: Communication (Weeks 3-4)**

- Module C: Enhanced Chat
- Module D: Moderation Tools
- Admin dashboard
- Test & Deploy

### **Phase 3: Polish (Weeks 5-6)**

- Module E: Room Management
- Module F: Presence System
- UI refinement
- Performance optimization

### **Phase 4: Growth (Weeks 7+)**

- Module G: Gamification
- Analytics
- Monetization features
- Community tools

---

## 📂 FIRESTORE SCHEMA UPDATES

### Current Structure ✅

```
users/
  {uid}/
    - displayName
    - photoUrl
    - gender
    - isOnline
    - UserProfile

rooms/
  {roomId}/
    - title
    - participantIds
    - activeBroadcasters
    - messages/
    - broadcasterQueue/
    - cameraPermissions/
```

### NEW: Complete Structure 🆕

```
users/
  {uid}/
    profile/
      - displayName
      - photoUrl
      - gender
      - isOnline

    presence/                           [MODULE F]
      - lastSeen
      - status (online/idle/away)
      - currentRoom
      - watchingCameras[]

    social/                             [MODULE G]
      - xp: number
      - level: number
      - coins: number
      - followers: []
      - following: []
      - badges: []

    settings/
      - micTimer: boolean
      - noiseSuppression: boolean
      - camQuality: string
      - chatColor: string
      - blockedUsers: []

rooms/
  {roomId}/
    metadata/
      - title
      - category
      - tags
      - description
      - banner: URL                     [MODULE E]
      - theme: JSON                     [MODULE E]
      - motd: string                    [MODULE E]
      - maxCams: number                 [MODULE A]
      - maxUsers: number                [MODULE E]
      - welcomeMessage: string          [MODULE E]

    participants/                       [MODULE A]
      {uid}/
        - displayName
        - photoUrl
        - isCameraOn: boolean
        - cameraQuality: string         [MODULE A]
        - isMicOn: boolean
        - micPriority: string           [MODULE B]
        - isSpeaking: boolean
        - xp: number                    [MODULE G]
        - level: number                 [MODULE G]
        - badges: []                    [MODULE G]
        - joinedAt: timestamp

    camera/                             [MODULE A]
      {uid}/
        - isLive: boolean
        - quality: string (low/med/high)
        - isFrozen: boolean
        - isSpotlighted: boolean
        - viewCount: number

    microphone/                         [MODULE B]
      {uid}/
        - isMuted: boolean
        - timerEnabled: boolean
        - timerDuration: number
        - priority: string (normal/vip)
        - isLocked: boolean
        - noiseLevel: number

    chat/                               [MODULE C]
      messages/
        {messageId}/
          - senderId
          - senderName
          - senderPhotoUrl
          - content
          - type: string (text/emoji/sticker/gift)
          - createdAt
          - reactions: {}
          - isPinned: boolean           [MODULE C]
          - isWhisper: boolean          [MODULE C]
          - whisperTarget: uid          [MODULE C]

      pinned/                           [MODULE C]
        - messages: []

      announcements/                    [MODULE E]
        - content
        - createdBy
        - createdAt

    moderation/                         [MODULE D]
      bans/
        {userId}/
          - bannedAt: timestamp
          - bannedBy: uid
          - reason: string
          - expiresAt: timestamp (null = permanent)
          - type: string (temporary/permanent)

      mutes/
        {userId}/
          - mutedAt: timestamp
          - mutedBy: uid
          - type: string (text/mic)
          - expiresAt: timestamp

      autoModeration/
        - spamThreshold: number
        - floodThreshold: number
        - profanityFilter: boolean
        - autoKickSpam: boolean
        - autoMuteMic: boolean

      adminChat/                        [MODULE D]
        - enabled: boolean
        - messages: []

    stats/                              [MODULE E]
      - totalViewers: number
      - totalMessages: number
      - totalCams: number
      - peakConcurrency: number
      - avgSessionLength: number

    gamification/                       [MODULE G]
      - coins: number
      - diamonds: number
      - gifts: {}
      - leaderboard: []
      - roomBadges: []

    broadcasterQueue/                   [EXISTING]
      {userId}/
        - status
        - requestedAt
        - queuePosition
        - isRecording

    cameraPermissions/                  [EXISTING]
      {userId}/
        - grantedTo: []
        - requestedBy: []
```

---

## 🏗️ SERVICE LAYER ARCHITECTURE

### Existing Services ✅

- `AgoraVideoService` - Video/Audio
- `BroadcasterService` - Broadcasting
- `ProfileService` - User profiles
- `MessagingService` - Chat

### NEW Services 🆕

```dart
// MODULE A: Multi-Cam System
class CameraService {
  - toggleCamera(roomId, userId)
  - setCameraQuality(quality: low/med/high)
  - spotlightCamera(userId)
  - removeSpotlight()
  - detectFrozenCamera(uid)
  - getCameraCount(roomId)
  - getMaxCameraLimit(roomId)
  - enforceMaxCameras(roomId)
}

// MODULE B: Mic Management
class MicrophoneService {
  - startMicTimer(duration)
  - stopMicTimer()
  - setMicPriority(uid, priority: normal/vip)
  - lockMic(hostOnly: true)
  - unlockMic()
  - suppressNoise(enabled: boolean)
  - getMicGain()
  - setMicGain(level: 0-100)
  - detectMicAbuse(uid)
  - autoMuteIfNoisy()
}

// MODULE C: Enhanced Chat
class ChatService {
  - sendWhisper(senderId, targetId, message)
  - sendEmoji(emoji)
  - sendSticker(stickerId)
  - pinMessage(messageId)
  - unpinMessage(messageId)
  - getPinnedMessages(roomId)
  - enableFloodProtection(roomId)
  - enableProfanityFilter(roomId)
  - addReactionToMessage(messageId, emoji)
  - getSlowModeStatus(roomId)
  - setSlowMode(roomId, secondsBetweenMessages)
}

// MODULE D: Moderation
class ModerationService {
  - banUser(userId, duration, reason)
  - tempBan(userId, duration, reason)
  - shadowBan(userId)
  - kick(userId)
  - muteText(userId, duration)
  - muteMic(userId, duration)
  - blockCamera(userId, duration)
  - lockdownRoom(hostOnly: true)
  - getActiveModerations(roomId)
  - getModerationLogs(roomId)
  - autoKickSpammer(userId)
  - autoMuteMicAbuser(userId)
}

// MODULE E: Room Management
class RoomService {
  - updateRoomTheme(roomId, theme: JSON)
  - setRoomBanner(roomId, imageUrl)
  - setMotd(roomId, message)
  - setWelcomeMessage(roomId, message)
  - setMaxCapacity(roomId, maxUsers)
  - setMaxCameras(roomId, maxCams)
  - getRoomStats(roomId) -> stats
  - announceToRoom(roomId, message)
  - lockRoom(hostOnly: true)
  - unlockRoom()
  - getRoomLeaderboard(roomId)
}

// MODULE F: Presence System
class PresenceService {
  - updatePresence(userId, status: online/idle/away)
  - setWatchingCameras(userId, cameraUids[])
  - getPresence(userId) -> status
  - getActiveUsers(roomId)
  - getIdleUsers(roomId)
  - streamPresenceChanges(roomId)
  - trackLastSeen(userId)
  - getWhoIsWatching(cameraUid)
}

// MODULE G: Gamification
class GamificationService {
  - sendGift(senderId, recipientId, giftId)
  - awardXP(userId, xpAmount, reason)
  - checkLevelUp(userId)
  - addBadge(userId, badgeId)
  - getUserLevel(userId)
  - getRoomCoins(userId, roomId)
  - spendCoins(userId, roomId, amount)
  - getLeaderboard(roomId, timeframe: daily/weekly/alltime)
  - getVIPStatus(userId)
  - upgradToVIP(userId)
}
```

---

## 📊 RIVERPOD PROVIDERS (NEW)

```dart
// CAMERA PROVIDERS
final cameraStateProvider = StateProvider<Map<String, CameraState>>((ref) => {});
final spotlightedCameraProvider = StateProvider<String?>((ref) => null);
final activeCamerasProvider = StreamProvider.family<List<String>, String>((ref, roomId) {
  // Stream of active camera UIDs
});
final cameraQualityProvider = StateProvider.family<String, String>((ref, userId) => 'high');

// MIC PROVIDERS
final micStateProvider = StateProvider<MicState>((ref) => MicState());
final micQueueProvider = StreamProvider.family<List<MicRequest>, String>((ref, roomId) {
  // Stream of mic requests
});
final micTimerProvider = StateProvider<Duration?>((ref) => null);
final noiseLevelProvider = StreamProvider<double>((ref) => Stream.value(0));

// CHAT PROVIDERS
final roomChatProvider = StreamProvider.family<List<ChatMessage>, String>((ref, roomId) {
  // Stream of room messages
});
final pinnedMessagesProvider = FutureProvider.family<List<ChatMessage>, String>((ref, roomId) {
  // Get pinned messages
});
final whisperCountProvider = StateProvider<int>((ref) => 0);
final slowModeProvider = StateProvider.family<bool, String>((ref, roomId) => false);

// MODERATION PROVIDERS
final moderationLogsProvider = StreamProvider.family<List<ModerationLog>, String>((ref, roomId) {
  // Stream of moderation actions
});
final bannedUsersProvider = FutureProvider.family<List<String>, String>((ref, roomId) {
  // Get list of banned users
});
final autoModerationRulesProvider = StateProvider.family<AutoModRules, String>((ref, roomId) {
  // Auto-moderation configuration
});

// ROOM PROVIDERS
final roomThemeProvider = StateProvider.family<RoomTheme?, String>((ref, roomId) => null);
final roomStatsProvider = StreamProvider.family<RoomStats, String>((ref, roomId) {
  // Real-time room statistics
});
final roomLeaderboardProvider = FutureProvider.family<List<LeaderboardEntry>, String>((ref, roomId) {
  // Room leaderboard
});

// PRESENCE PROVIDERS
final presenceProvider = StreamProvider.family<Map<String, UserPresence>, String>((ref, roomId) {
  // All users' presence in room
});
final idleDetectionProvider = StateProvider<bool>((ref) => false);
final camerasBeingWatchedProvider = StreamProvider.family<Map<String, int>, String>((ref, roomId) {
  // Map of cameraUid -> view count
});

// GAMIFICATION PROVIDERS
final userXPProvider = StreamProvider.family<int, String>((ref, userId) {
  // User's XP
});
final userLevelProvider = FutureProvider.family<int, String>((ref, userId) {
  // User's level
});
final userBadgesProvider = StreamProvider.family<List<Badge>, String>((ref, userId) {
  // User's badges
});
final leaderboardProvider = StreamProvider.family<List<LeaderboardEntry>, String>((ref, roomId) {
  // Room leaderboard (by XP)
});
final roomCoinsProvider = StateProvider.family<int, String>((ref, roomId) => 0);
```

---

## 🎨 UI COMPONENTS (NEW)

```
lib/features/room/widgets/

// MODULE A: Multi-Cam
├── camera_grid.dart           (responsive layout for 4-20 cameras)
├── camera_tile.dart           (individual camera with quality badge)
├── spotlight_view.dart        (fullscreen + 4-thumbnail layout)
├── camera_quality_selector.dart
├── freeze_detector.dart       (frozen camera overlay)
└── cam_count_indicator.dart   (X/20 cams live)

// MODULE B: Mic
├── mic_timer_display.dart     (countdown + auto-off)
├── mic_queue_panel.dart       (raise-hand queue visualization)
├── mic_priority_badge.dart    (VIP/normal indicator)
├── noise_level_meter.dart     (visual noise indicator)
└── mic_gain_control.dart      (slider)

// MODULE C: Chat
├── chat_message_tile.dart     (with whisper support)
├── whisper_panel.dart         (private messages)
├── pinned_message_bar.dart    (floating announcement)
├── emoji_picker.dart          (emoji + sticker selector)
├── sticker_pack.dart          (sticker categories)
├── chat_slowmode_timer.dart   (cooldown between messages)
└── announcement_banner.dart   (room announcements)

// MODULE D: Moderation
├── mod_tools_drawer.dart      (admin toolbar)
├── ban_dialog.dart            (ban/kick/mute options)
├── moderation_log_panel.dart  (view past actions)
├── auto_mod_settings.dart     (configure auto-moderation)
└── lockdown_banner.dart       (room lockdown indicator)

// MODULE E: Room
├── room_header_banner.dart    (room name + theme)
├── room_stats_widget.dart     (viewers/cams/msg count)
├── room_settings_panel.dart   (theme, capacity, MOTD)
├── room_announcement.dart     (scrolling text)
└── room_leaderboard.dart      (top users by XP)

// MODULE F: Presence
├── presence_indicator.dart    (green/yellow/gray dot)
├── active_users_list.dart     (who's in room)
├── idle_timer_dialog.dart     (X will be marked AFK)
└── viewer_list.dart           (who's watching camera X)

// MODULE G: Gamification
├── gift_animation.dart        (gift float animation)
├── user_level_badge.dart      (level + XP bar)
├── achievement_popup.dart     (new badge earned)
├── leaderboard_view.dart      (daily/weekly/alltime)
├── vip_badge.dart             (VIP indicator)
├── room_coins_display.dart    (coin counter)
└── gift_shop_modal.dart       (buy/send gifts)
```

---

## 🔐 FIRESTORE SECURITY RULES (NEW)

```
match /users/{userId}/presence/{document=**} {
  allow read: if isAuthenticatedAndValidUser();
  allow write: if request.auth.uid == userId;
}

match /rooms/{roomId}/chat/messages/{messageId} {
  allow read: if isRoomMember(roomId);
  allow create: if isRoomMember(roomId) &&
                   request.resource.data.senderId == request.auth.uid &&
                   request.resource.data.content.size() > 0 &&
                   request.resource.data.content.size() <= 500;
  allow delete: if request.auth.uid == resource.data.senderId ||
                   isRoomModerator(roomId);
}

match /rooms/{roomId}/moderation/{document=**} {
  allow read: if isRoomModerator(roomId);
  allow write: if isRoomModerator(roomId);
}

match /users/{userId}/gamification/{document=**} {
  allow read: if isAuthenticatedAndValidUser();
  allow write: if isAuthenticatedAndValidUser();
}
```

---

## 📈 PERFORMANCE TARGETS

| Metric                        | Target | Current |
| ----------------------------- | ------ | ------- |
| Multi-cam rendering (20 cams) | <60ms  | TBD     |
| Presence update latency       | <500ms | TBD     |
| Chat message delivery         | <1s    | ✅      |
| Mod action execution          | <100ms | TBD     |
| XP sync latency               | <2s    | TBD     |

---

## 🚀 NEXT STEPS

1. **Review this blueprint** → Feedback?
2. **Start Module A** → Multi-Cam System (this week)
3. **Implement DB schema** → Firestore updates
4. **Build services** → Core logic
5. **Create UI** → Beautiful components
6. **Deploy & test** → Production ready

---

**Questions?** Let me know and I'll start Module A immediately.
