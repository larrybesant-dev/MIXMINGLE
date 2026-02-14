# 📦 MODULES D-G: QUICK START GUIDE

**Status**: Architecture & Scaffolding
**Target**: 4-5 days of implementation
**Total LOC**: ~3,500

---

## 🎯 MODULE BREAKDOWN

### **Module D: Moderation Tools** (1.5K LOC)
**Priority**: P1
**Dependencies**: Room Model, User Model

#### Features
- ✅ Auto-moderation rules (keyword filters, spam detection)
- ✅ Shadow ban (user can't see/chat)
- ✅ Kick/ban users
- ✅ Moderation logs
- ✅ Warning system
- ✅ Approved user list

#### Files to Create
```
lib/shared/models/moderation_rule.dart
lib/services/moderation_service.dart
lib/providers/moderation_providers.dart
lib/features/room/widgets/moderation_panel.dart
lib/features/room/widgets/user_actions_menu.dart
```

#### Database Schema
```firestore
rooms/{roomId}/
  moderation/
    rules/
      - keywords[]
      - autoFilter: bool
      - shadowBanEnabled: bool
    logs/
      {logId}/
        - action: string (kick/ban/mute/warn)
        - targetUser: string
        - moderator: string
        - reason: string
        - timestamp: timestamp
    bannedUsers/
      {userId}
    shadowBannedUsers/
      {userId}
```

---

### **Module E: Room Management** (1.2K LOC)
**Priority**: P2
**Dependencies**: Room Model, Chat Settings

#### Features
- ✅ Room themes (dark/light/custom)
- ✅ MOTD (Message of the Day)
- ✅ Capacity management
- ✅ Auto-close inactive rooms
- ✅ Room announcements
- ✅ Welcome messages

#### Files to Create
```
lib/shared/models/room_settings.dart
lib/shared/models/room_theme.dart
lib/services/room_settings_service.dart
lib/providers/room_settings_providers.dart
lib/features/room/widgets/room_settings_panel.dart
```

#### Database Schema
```firestore
rooms/{roomId}/
  settings/
    theme: string (dark/light/custom)
    motd: string
    maxCapacity: number
    autoCloseAfter: number (minutes)
    announcements[]:
      - title: string
      - content: string
      - createdAt: timestamp
```

---

### **Module F: Presence System** (800 LOC)
**Priority**: P2
**Dependencies**: User Model, Rooms

#### Features
- ✅ Real-time user status (online/idle/away)
- ✅ Idle detection (3min → idle, 15min → away)
- ✅ Last seen timestamp
- ✅ Currently watching camera
- ✅ Typing indicators
- ✅ User activity feed

#### Files to Create
```
lib/shared/models/user_presence.dart
lib/services/presence_service.dart
lib/providers/presence_providers.dart
lib/features/room/widgets/user_status_indicator.dart
```

#### Database Schema
```firestore
users/{uid}/
  presence/
    status: string (online/idle/away)
    lastSeen: timestamp
    currentRoom: string
    watchingCamera: string
    typing: bool
    typingIn: string
```

---

### **Module G: Gamification** (1.5K LOC)
**Priority**: P3
**Dependencies**: User Model, Chat

#### Features
- ✅ XP system (message +1, speak +5, broadcast +10)
- ✅ Levels (1-100)
- ✅ Badges (Talker, Listener, VIP, Moderator, etc.)
- ✅ Leaderboards (global, room-specific)
- ✅ Room coins (currency for gifts)
- ✅ Gifts (animations + notifications)

#### Files to Create
```
lib/shared/models/user_stats.dart
lib/shared/models/badge.dart
lib/shared/models/gift.dart
lib/services/gamification_service.dart
lib/providers/gamification_providers.dart
lib/features/room/widgets/leaderboard_panel.dart
lib/features/room/widgets/gift_sender.dart
```

#### Database Schema
```firestore
users/{uid}/
  stats/
    xp: number
    level: number
    coins: number
    badges: string[]
    messagesCount: number
    broadcastsCount: number
    totalUptime: number

rooms/{roomId}/
  leaderboard/
    {uid}/
      - userName: string
      - level: number
      - xp: number
      - messagesInRoom: number
```

---

## 📋 IMPLEMENTATION ROADMAP

### **Phase 1: Moderation (Day 1-1.5)**
1. Create `moderation_rule.dart` model
2. Create `moderation_service.dart` with:
   - `addAutoModerationRule()`
   - `banUser()`
   - `shadowBanUser()`
   - `logModeration()`
3. Add to Firestore security rules
4. Deploy & test

### **Phase 2: Room Management (Day 2)**
1. Create `room_settings.dart` model
2. Create `room_settings_service.dart` with:
   - `updateTheme()`
   - `setMOTD()`
   - `addAnnouncement()`
3. Deploy & test

### **Phase 3: Presence (Day 2.5)**
1. Create `user_presence.dart` model
2. Create `presence_service.dart` with:
   - `updateStatus()`
   - `trackIdle()`
   - `recordLastSeen()`
3. Add to Firestore
4. Deploy & test

### **Phase 4: Gamification (Day 3-4)**
1. Create `user_stats.dart` and `badge.dart` models
2. Create `gamification_service.dart` with:
   - `awardXP()`
   - `checkLevelUp()`
   - `awardBadge()`
   - `getLeaderboard()`
3. Create UI components
4. Deploy & test

---

## 🔧 QUICK SCAFFOLDING

### Moderation Service Example
```dart
class ModerationService {
  Future<void> addAutoModerationRule(
    String roomId,
    List<String> keywords,
  ) async {
    await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('moderation')
        .doc('rules')
        .set({
      'keywords': keywords,
      'autoFilter': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
```

### Gamification Service Example
```dart
class GamificationService {
  Future<void> awardXP(
    String userId,
    int xpAmount,
    String reason,
  ) async {
    final userRef = _firestore.collection('users').doc(userId);

    await userRef.update({
      'stats.xp': FieldValue.increment(xpAmount),
    });

    // Check for level up
    final userData = await userRef.get();
    final currentXP = userData['stats']['xp'] as int;
    final newLevel = (currentXP ~/ 1000) + 1;

    if (newLevel > (userData['stats']['level'] as int)) {
      await userRef.update({'stats.level': newLevel});
      // Award level-up badge
    }
  }
}
```

---

## 📊 TESTING STRATEGY

For each module:
1. Create test data in Firestore
2. Test service methods locally
3. Test UI rendering
4. Test real-time updates
5. Test edge cases (errors, timeouts)
6. Deploy to production
7. Monitor performance

---

## ✅ INTEGRATION CHECKLIST

- [ ] Module D: Moderation panel in room
- [ ] Module E: Settings button in AppBar
- [ ] Module F: Status indicators on participants
- [ ] Module G: Leaderboard & gift buttons

---

## 🚀 DEPLOYMENT PLAN

**Timeline**: 5 days
**Build time**: ~120s
**Total modules**: 7 (A-G)
**Total LOC**: ~10,500

**Milestone**: Enterprise-grade Paltalk alternative ✨

---

**Next**: Begin Module D implementation with moderation_rule.dart
