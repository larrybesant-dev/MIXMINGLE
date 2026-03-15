# Firestore Security Rules - Quick Reference Card

**Mix & Mingle** | Version 2.0 | January 24, 2026

---

## 🔐 Access Levels

| Level         | Identifier                  | Capabilities                         |
| ------------- | --------------------------- | ------------------------------------ |
| **Admin**     | `role: 'admin'`             | Full access, create events, moderate |
| **Moderator** | `role: 'moderator'`         | Review reports, moderate content     |
| **Premium**   | `membershipTier: 'premium'` | Send DMs to anyone, enhanced limits  |
| **User**      | Authenticated               | Standard app access                  |
| **Guest**     | Unauthenticated             | ❌ No Firestore access               |

---

## 📋 Collection Quick Reference

### 👤 User Collections

| Collection          | Create   | Read                     | Update   | Delete   |
| ------------------- | -------- | ------------------------ | -------- | -------- |
| `users`             | Own only | Own + completed profiles | Own only | ❌       |
| `user_profiles`     | Own only | Own + not blocked        | Own only | ❌       |
| `user_presence`     | Own only | All auth                 | Own only | ❌       |
| `matching_profiles` | Own only | Active + not blocked     | Own only | Own only |

### 💬 Communication

| Collection        | Create             | Read              | Update       | Delete     |
| ----------------- | ------------------ | ----------------- | ------------ | ---------- |
| `rooms`           | Completed profile  | Auth + not banned | Mods or join | Host       |
| `messages`        | Room members       | Room members      | Own (5 min)  | Own or mod |
| `chat_rooms`      | 2 participants     | Participants      | Participants | ❌         |
| `direct_messages` | Matched or premium | Sender/receiver   | Limited      | ❌         |

### 📅 Events & Speed Dating

| Collection              | Create         | Read                | Update             | Delete       |
| ----------------------- | -------------- | ------------------- | ------------------ | ------------ |
| `events`                | **Admin only** | Public or attendees | Host or join       | Host/admin   |
| `speed_dating_sessions` | Participants   | Participants        | Participants       | Participants |
| `speed_dating_rounds`   | **Admin only** | Event participants  | Event participants | Admin        |
| `speed_dating_results`  | Own only       | Involved users      | ❌                 | ❌           |

### 💰 Monetization

| Collection            | Create      | Read         | Update    | Delete        |
| --------------------- | ----------- | ------------ | --------- | ------------- |
| `subscriptions`       | ❌ Server   | Own only     | ❌ Server | ❌            |
| `withdrawal_requests` | Own + coins | Own or admin | Admin     | Own (pending) |
| `coin_transactions`   | ❌ Server   | Own only     | ❌        | ❌            |

### 🛡️ Moderation

| Collection | Create             | Read             | Update | Delete   |
| ---------- | ------------------ | ---------------- | ------ | -------- |
| `reports`  | Cannot report self | Reporter or mods | Mods   | Admin    |
| `blocks`   | Own only           | Own only         | ❌     | Own only |

### 📸 Media

| Collection     | Create            | Read       | Update         | Delete       |
| -------------- | ----------------- | ---------- | -------------- | ------------ |
| `media`        | Completed profile | Own or all | Own (metadata) | Own or admin |
| `shared_files` | 50MB limit        | All auth   | ❌             | Own only     |

### 🔔 System

| Collection      | Create    | Read               | Update       | Delete   |
| --------------- | --------- | ------------------ | ------------ | -------- |
| `notifications` | ❌ Server | Own only           | Own (isRead) | Own only |
| `activities`    | Own only  | Completed profiles | Own only     | Own only |
| `presence`      | Own only  | All auth           | Own only     | ❌       |

---

## 🚨 Critical Rules

### ⚠️ Admin-Only Operations

```
✅ Event creation
✅ Speed dating round management
✅ Report moderation
✅ Withdrawal processing
✅ System configuration
```

### 🔒 Match-Based Access

```
Direct messages require:
  ✅ Matched users, OR
  ✅ Sender has premium membership
  ✅ Neither user blocked the other
```

### 👥 Event Capacity

```
Max attendees: 1-1000
Enforcement: Automatic
Check before join: attendees.size() < maxAttendees
```

### ⏱️ Speed Dating Constraints

```
Duration: 3-30 minutes
Participants: Exactly 2 users
Decisions: 'like' or 'pass'
Access: Participants only
```

### 📦 Media Restrictions

```
File size limit: 50MB
Valid types: image, video, audio, file
Owner can: Upload, update metadata, delete
Admin can: Delete any
```

---

## 🔑 Helper Functions

### Authentication

```javascript
isAuthenticated(); // Has valid auth token
hasCompletedProfile(); // Has displayName set
isAdmin(); // role == 'admin'
isModerator(); // role == 'admin' OR 'moderator'
isPremiumUser(); // membershipTier in ['premium', 'vip']
```

### Ownership

```javascript
isOwner(userId); // request.auth.uid == userId
```

### Relationships

```javascript
isMatchedWith(userId); // Mutual match exists
hasNotBlockedUser(userId); // Haven't blocked user
isNotBlocked(userId); // User hasn't blocked me
```

### Room Access

```javascript
isRoomMember(roomId); // In participantIds
isRoomModerator(roomId); // In moderators or is host
```

### Event Access

```javascript
isEventParticipant(eventId); // In attendees array
```

### Speed Dating

```javascript
isSpeedDatingParticipant(sessionId); // userId1 or userId2
```

---

## ⚡ Common Scenarios

### User Signup

```dart
1. Create auth account
2. Reserve username in /usernames
3. Create /users doc with:
   - id, email, displayName, username
   - membershipTier: 'free'
   - coinBalance: 0
```

### Join Room

```dart
Update /rooms/{roomId}:
  participantIds: arrayUnion([uid])
  listeners: arrayUnion([uid])
  viewerCount: increment(1)
// Rules enforce: not banned, add self only
```

### Send Direct Message

```dart
Check: isMatched OR isPremium
Check: not blocked
Create /direct_messages:
  senderId: current uid
  receiverId: other uid
  content: max 2000 chars
  type: text/image/video/audio/file
```

### Create Event (Admin)

```dart
Check: role == 'admin'
Create /events:
  hostId: current uid
  maxAttendees: 1-1000
  attendees: [uid]
  startTime: future
  endTime: > startTime
```

### Join Event

```dart
Update /events/{eventId}:
  attendees: arrayUnion([uid])
// Rules enforce: under capacity
```

---

## 🐛 Troubleshooting

| Error                           | Cause                     | Solution                                                                         |
| ------------------------------- | ------------------------- | -------------------------------------------------------------------------------- |
| **permission-denied on signup** | Missing required fields   | Include id, email, displayName, username, membershipTier: 'free', coinBalance: 0 |
| **Cannot send DM**              | Not matched + not premium | Upgrade to premium OR match first                                                |
| **Event join fails**            | At max capacity           | Check capacity before attempting                                                 |
| **Admin dashboard denied**      | Missing role              | Add `role: 'admin'` to user doc                                                  |
| **Speed dating access denied**  | Not a participant         | Verify userId1 or userId2 match                                                  |

---

## 📦 Deployment Order

```bash
1. firebase deploy --only firestore:indexes
   # ⏰ Wait 5-30 minutes for indexes to build

2. firebase deploy --only firestore:rules
   # ✅ Rules deploy immediately

3. Verify in Firebase Console
```

---

## 📊 Validation Checklist

Before deployment:

- [ ] All collections have rules
- [ ] Admin checks implemented
- [ ] Match-based access enforced
- [ ] Capacity limits set
- [ ] Media restrictions active
- [ ] Block detection working
- [ ] Indexes deployed first
- [ ] Tested in emulator

---

## 📞 Support

- **Schema Docs**: [FIRESTORE_SCHEMA.md](FIRESTORE_SCHEMA.md)
- **Security Guide**: [SECURITY_RULES_GUIDE.md](SECURITY_RULES_GUIDE.md)
- **Full Rules**: [firestore.rules](firestore.rules)

---

**Status:** ✅ Production Ready
**Version:** 2.0
**Updated:** January 24, 2026
