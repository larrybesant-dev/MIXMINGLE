# Mix & Mingle - Complete Firestore Database Schema

**Version:** 1.0
**Last Updated:** January 24, 2026
**Based on:** Existing model files in /lib/shared/models, /lib/features

---

## Table of Contents

1. [Collections Overview](#collections-overview)
2. [Core Collections](#core-collections)
3. [Social & Matching](#social--matching)
4. [Communication](#communication)
5. [Events & Speed Dating](#events--speed-dating)
6. [Monetization](#monetization)
7. [Moderation & Safety](#moderation--safety)
8. [System Collections](#system-collections)
9. [Indexes](#required-indexes)
10. [Security Rules Summary](#security-rules-summary)

---

## Collections Overview

| Collection              | Document Count | Primary Use                 |
| ----------------------- | -------------- | --------------------------- |
| `users`                 | ~10K           | Core user data              |
| `user_profiles`         | ~10K           | Extended profile info       |
| `user_presence`         | ~10K           | Real-time online status     |
| `rooms`                 | ~1K            | Live video/voice/text rooms |
| `messages`              | ~1M            | Room chat messages          |
| `direct_messages`       | ~500K          | One-on-one messages         |
| `chat_rooms`            | ~50K           | DM conversations metadata   |
| `events`                | ~5K            | User-created events         |
| `speed_dating_sessions` | ~10K           | Speed dating sessions       |
| `speed_dating_rounds`   | ~30K           | Speed dating rounds         |
| `speed_dating_results`  | ~100K          | Speed dating outcomes       |
| `notifications`         | ~100K          | User notifications          |
| `subscriptions`         | ~1K            | Premium subscriptions       |
| `withdrawal_requests`   | ~500           | Payout requests             |
| `activities`            | ~50K           | Activity feed               |
| `matches`               | ~20K           | Dating matches              |
| `matching_profiles`     | ~10K           | Matching algorithm data     |
| `reports`               | ~1K            | User reports                |
| `blocks`                | ~5K            | Blocked users               |
| `media`                 | ~50K           | Media uploads               |

---

## Core Collections

### 1. users

**Path:** `/users/{userId}`

**Description:** Primary user account data with social features

**Fields:**

| Field                   | Type                | Required | Default         | Description                  |
| ----------------------- | ------------------- | -------- | --------------- | ---------------------------- |
| `id`                    | string              | ✅       | -               | User ID (matches auth UID)   |
| `email`                 | string              | ✅       | -               | User email address           |
| `displayName`           | string              | ⬜       | null            | Display name                 |
| `username`              | string              | ✅       | -               | Unique username (3-20 chars) |
| `nickname`              | string              | ⬜       | null            | Optional nickname            |
| `photoUrl`              | string              | ⬜       | null            | Profile photo URL            |
| `avatarUrl`             | string              | ✅       | ''              | Avatar image URL             |
| `bio`                   | string              | ✅       | ''              | User biography               |
| `location`              | string              | ✅       | ''              | Location string              |
| `interests`             | array<string>       | ✅       | []              | User interests/hobbies       |
| `statusMessage`         | string              | ✅       | 'Available'     | Custom status                |
| `isOnline`              | boolean             | ✅       | false           | Online status                |
| `lastSeen`              | timestamp           | ⬜       | null            | Last activity timestamp      |
| `membershipTier`        | string              | ✅       | 'free'          | Tier: free/premium/vip       |
| `badges`                | array<string>       | ✅       | []              | Achievement badges           |
| `coinBalance`           | number              | ✅       | 0               | Virtual currency balance     |
| `followersCount`        | number              | ✅       | 0               | Follower count               |
| `followingCount`        | number              | ✅       | 0               | Following count              |
| `totalTipsReceived`     | number              | ✅       | 0               | Total tips received          |
| `liveSessionsHosted`    | number              | ✅       | 0               | Rooms hosted                 |
| `socialLinks`           | map<string, string> | ✅       | {}              | Social media links           |
| `featuredRoomId`        | string              | ⬜       | null            | Featured room ID             |
| `featuredContentUrl`    | string              | ⬜       | null            | Featured content             |
| `topGifts`              | array<map>          | ✅       | []              | Top gifts received           |
| `recentMediaUrls`       | array<string>       | ✅       | []              | Recent media                 |
| `recentActivity`        | array<map>          | ✅       | []              | Recent activities            |
| `lookingFor`            | string              | ⬜       | null            | What user seeks              |
| `minAgePreference`      | number              | ⬜       | null            | Min age preference           |
| `maxAgePreference`      | number              | ⬜       | null            | Max age preference           |
| `maxDistancePreference` | number              | ⬜       | null            | Max distance (miles)         |
| `createdAt`             | timestamp           | ✅       | serverTimestamp | Account creation             |

**Example Document:**

```json
{
  "id": "user123",
  "email": "user@example.com",
  "displayName": "John Doe",
  "username": "johndoe",
  "avatarUrl": "https://...",
  "bio": "Love music and travel",
  "location": "New York, NY",
  "interests": ["music", "travel", "photography"],
  "statusMessage": "Available for chat",
  "isOnline": true,
  "lastSeen": "2026-01-24T20:00:00Z",
  "membershipTier": "premium",
  "badges": ["verified", "top_host"],
  "coinBalance": 1500,
  "followersCount": 250,
  "followingCount": 180,
  "createdAt": "2025-06-15T10:30:00Z"
}
```

**Validation Rules:**

- `email` must be valid email format
- `username` must be 3-20 characters, alphanumeric + underscore
- `membershipTier` must be one of: free, premium, vip
- `coinBalance` must be >= 0

**Required Indexes:**

- `isOnline ASC, lookingForSpeedDate ASC`
- `membershipTier ASC, createdAt DESC`

---

### 2. user_profiles

**Path:** `/user_profiles/{userId}`

**Description:** Extended user profile for matching and dating features

**Fields:**

| Field                | Type                 | Required | Default         | Description                        |
| -------------------- | -------------------- | -------- | --------------- | ---------------------------------- |
| `id`                 | string               | ✅       | -               | User ID                            |
| `email`              | string               | ✅       | -               | User email                         |
| `displayName`        | string               | ⬜       | null            | Display name                       |
| `nickname`           | string               | ⬜       | null            | Nickname                           |
| `photoUrl`           | string               | ⬜       | null            | Main photo                         |
| `galleryPhotos`      | array<string>        | ⬜       | null            | Photo gallery                      |
| `interests`          | array<string>        | ⬜       | null            | Interests                          |
| `location`           | string               | ⬜       | null            | Location string                    |
| `latitude`           | number               | ⬜       | null            | GPS latitude                       |
| `longitude`          | number               | ⬜       | null            | GPS longitude                      |
| `birthday`           | timestamp            | ⬜       | null            | Birth date                         |
| `gender`             | string               | ⬜       | null            | Gender identity                    |
| `pronouns`           | string               | ⬜       | null            | Preferred pronouns                 |
| `bio`                | string               | ⬜       | null            | Biography                          |
| `lookingFor`         | array<string>        | ⬜       | null            | What seeking: friends, dating, etc |
| `relationshipType`   | string               | ⬜       | null            | casual, serious, long-term         |
| `minAgePreference`   | number               | ⬜       | null            | Min age for matches                |
| `maxAgePreference`   | number               | ⬜       | null            | Max age for matches                |
| `preferredGenders`   | array<string>        | ⬜       | null            | Gender preferences                 |
| `personalityPrompts` | map<string, string>  | ⬜       | null            | Profile prompts                    |
| `musicTastes`        | array<string>        | ⬜       | null            | Music preferences                  |
| `lifestylePrompts`   | map<string, boolean> | ⬜       | null            | Lifestyle choices                  |
| `isPhotoVerified`    | boolean              | ⬜       | null            | Photo verification                 |
| `isPhoneVerified`    | boolean              | ⬜       | null            | Phone verification                 |
| `isEmailVerified`    | boolean              | ⬜       | null            | Email verification                 |
| `isIdVerified`       | boolean              | ⬜       | null            | ID verification                    |
| `socialLinks`        | map<string, string>  | ⬜       | null            | Social profiles                    |
| `verifiedOnlyMode`   | boolean              | ⬜       | null            | Only match verified                |
| `privateMode`        | boolean              | ⬜       | null            | Private profile                    |
| `createdAt`          | timestamp            | ✅       | serverTimestamp | Profile created                    |
| `updatedAt`          | timestamp            | ✅       | serverTimestamp | Last updated                       |

**Example Document:**

```json
{
  "id": "user123",
  "email": "user@example.com",
  "displayName": "John Doe",
  "photoUrl": "https://...",
  "galleryPhotos": ["https://...", "https://..."],
  "location": "New York, NY",
  "latitude": 40.7128,
  "longitude": -74.006,
  "birthday": "1995-06-15T00:00:00Z",
  "gender": "male",
  "pronouns": "he/him",
  "bio": "Adventure seeker and coffee enthusiast",
  "lookingFor": ["dating", "networking"],
  "relationshipType": "serious",
  "minAgePreference": 25,
  "maxAgePreference": 35,
  "preferredGenders": ["female"],
  "personalityPrompts": {
    "ideal_day": "Coffee shop in the morning, hike in the afternoon"
  },
  "musicTastes": ["indie", "rock", "jazz"],
  "lifestylePrompts": {
    "smoking": false,
    "drinking": true,
    "fitness": true,
    "pets": true
  },
  "isPhotoVerified": true,
  "verifiedOnlyMode": false,
  "createdAt": "2025-06-15T10:30:00Z",
  "updatedAt": "2026-01-20T15:45:00Z"
}
```

**Validation Rules:**

- `minAgePreference` must be >= 18 and <= maxAgePreference
- `maxAgePreference` must be >= minAgePreference and <= 100
- `latitude` must be between -90 and 90
- `longitude` must be between -180 and 180

**Required Indexes:**

- `latitude ASC, longitude ASC`
- `gender ASC, createdAt DESC`

---

### 3. user_presence

**Path:** `/user_presence/{userId}`

**Description:** Real-time user online/offline status

**Fields:**

| Field           | Type      | Required | Default         | Description              |
| --------------- | --------- | -------- | --------------- | ------------------------ |
| `userId`        | string    | ✅       | -               | User ID                  |
| `status`        | string    | ✅       | 'offline'       | online/away/offline/busy |
| `lastSeen`      | timestamp | ✅       | serverTimestamp | Last activity            |
| `currentRoomId` | string    | ⬜       | null            | Current room if in one   |
| `statusMessage` | string    | ⬜       | null            | Custom status text       |

**Example Document:**

```json
{
  "userId": "user123",
  "status": "online",
  "lastSeen": "2026-01-24T20:00:00Z",
  "currentRoomId": "room456",
  "statusMessage": "In a meeting"
}
```

**Validation Rules:**

- `status` must be one of: online, away, offline, busy
- Auto-updated via Cloud Functions on disconnect

**Required Indexes:**

- `status ASC, lastSeen DESC`

---

## Social & Matching

### 4. matching_profiles

**Path:** `/matching_profiles/{userId}`

**Description:** Extended profiles specifically for matching algorithm

**Fields:**

| Field            | Type          | Required | Default         | Description           |
| ---------------- | ------------- | -------- | --------------- | --------------------- |
| `userId`         | string        | ✅       | -               | User ID               |
| `displayName`    | string        | ✅       | -               | Display name          |
| `photoUrl`       | string        | ⬜       | null            | Profile photo         |
| `age`            | number        | ✅       | -               | User age              |
| `latitude`       | number        | ✅       | -               | GPS latitude          |
| `longitude`      | number        | ✅       | -               | GPS longitude         |
| `answers`        | map           | ✅       | -               | Questionnaire answers |
| `lastActive`     | timestamp     | ✅       | serverTimestamp | Last active           |
| `createdAt`      | timestamp     | ✅       | serverTimestamp | Created timestamp     |
| `isActive`       | boolean       | ✅       | true            | Active for matching   |
| `blockedUserIds` | array<string> | ✅       | []              | Blocked users         |
| `likedUserIds`   | array<string> | ✅       | []              | Liked users           |
| `passedUserIds`  | array<string> | ✅       | []              | Passed users          |

**Example Document:**

```json
{
  "userId": "user123",
  "displayName": "John Doe",
  "photoUrl": "https://...",
  "age": 28,
  "latitude": 40.7128,
  "longitude": -74.006,
  "answers": {
    "minAge": 25,
    "maxAge": 35,
    "distancePreference": "within25Miles",
    "interests": ["hiking", "music"]
  },
  "lastActive": "2026-01-24T20:00:00Z",
  "isActive": true,
  "blockedUserIds": [],
  "likedUserIds": ["user456", "user789"],
  "passedUserIds": ["user101"]
}
```

**Required Indexes:**

- `isActive ASC, lastActive DESC`
- `age ASC, latitude ASC, longitude ASC`

---

### 5. matches

**Path:** `/matches/{matchId}`

**Description:** Successful matches between users

**Fields:**

| Field               | Type      | Required | Default         | Description                 |
| ------------------- | --------- | -------- | --------------- | --------------------------- |
| `id`                | string    | ✅       | -               | Match ID                    |
| `userId1`           | string    | ✅       | -               | First user ID               |
| `userId2`           | string    | ✅       | -               | Second user ID              |
| `matchScore`        | number    | ✅       | 0               | Compatibility score (0-100) |
| `conversationId`    | string    | ⬜       | null            | Chat conversation ID        |
| `status`            | string    | ✅       | 'active'        | active/archived/blocked     |
| `matchedAt`         | timestamp | ✅       | serverTimestamp | Match timestamp             |
| `lastInteractionAt` | timestamp | ⬜       | null            | Last message time           |

**Example Document:**

```json
{
  "id": "match123",
  "userId1": "user123",
  "userId2": "user456",
  "matchScore": 87,
  "conversationId": "user123_user456",
  "status": "active",
  "matchedAt": "2026-01-24T18:30:00Z",
  "lastInteractionAt": "2026-01-24T19:45:00Z"
}
```

**Required Indexes:**

- `userId1 ASC, matchedAt DESC`
- `userId2 ASC, matchedAt DESC`
- `status ASC, matchedAt DESC`

---

## Communication

### 6. rooms

**Path:** `/rooms/{roomId}`

**Description:** Live video/voice/text chat rooms

**Fields:**

| Field                  | Type          | Required | Default         | Description            |
| ---------------------- | ------------- | -------- | --------------- | ---------------------- |
| `id`                   | string        | ✅       | -               | Room ID                |
| `name`                 | string        | ✅       | -               | Room name              |
| `title`                | string        | ✅       | -               | Room title             |
| `description`          | string        | ✅       | ''              | Room description       |
| `hostId`               | string        | ✅       | -               | Host user ID           |
| `hostName`             | string        | ✅       | -               | Host display name      |
| `roomType`             | string        | ✅       | 'text'          | text/voice/video       |
| `category`             | string        | ✅       | ''              | Room category          |
| `tags`                 | array<string> | ✅       | []              | Search tags            |
| `privacy`              | string        | ✅       | 'public'        | public/private         |
| `status`               | string        | ✅       | 'live'          | live/ended             |
| `isActive`             | boolean       | ✅       | false           | Active status          |
| `isLive`               | boolean       | ✅       | false           | Currently live         |
| `participantIds`       | array<string> | ✅       | []              | Current participants   |
| `speakers`             | array<string> | ✅       | []              | Speakers list          |
| `listeners`            | array<string> | ✅       | []              | Listeners list         |
| `moderators`           | array<string> | ✅       | []              | Moderator IDs          |
| `bannedUsers`          | array<string> | ✅       | []              | Banned user IDs        |
| `viewerCount`          | number        | ✅       | 0               | Current viewer count   |
| `thumbnailUrl`         | string        | ⬜       | null            | Room thumbnail         |
| `agoraChannelName`     | string        | ⬜       | null            | Agora channel name     |
| `allowSpeakerRequests` | boolean       | ✅       | true            | Allow speaker requests |
| `createdAt`            | timestamp     | ✅       | serverTimestamp | Created timestamp      |

**Example Document:**

```json
{
  "id": "room123",
  "name": "Music Lovers Lounge",
  "title": "Discussing 90s Rock",
  "description": "Join us for a discussion about 90s rock music",
  "hostId": "user123",
  "hostName": "John Doe",
  "roomType": "voice",
  "category": "music",
  "tags": ["music", "rock", "90s"],
  "privacy": "public",
  "status": "live",
  "isActive": true,
  "isLive": true,
  "participantIds": ["user123", "user456", "user789"],
  "speakers": ["user123", "user456"],
  "listeners": ["user789"],
  "moderators": ["user123"],
  "bannedUsers": [],
  "viewerCount": 3,
  "agoraChannelName": "room123_channel",
  "allowSpeakerRequests": true,
  "createdAt": "2026-01-24T19:00:00Z"
}
```

**Validation Rules:**

- `roomType` must be one of: text, voice, video
- `privacy` must be one of: public, private
- `status` must be one of: live, ended
- `hostId` must be in `participantIds`

**Required Indexes:**

- `isLive ASC, createdAt DESC`
- `category ASC, isLive ASC, createdAt DESC`
- `hostId ASC, createdAt DESC`

---

### 7. messages

**Path:** `/rooms/{roomId}/messages/{messageId}`

**Description:** Messages within rooms

**Fields:**

| Field              | Type          | Required | Default         | Description                 |
| ------------------ | ------------- | -------- | --------------- | --------------------------- |
| `id`               | string        | ✅       | -               | Message ID                  |
| `roomId`           | string        | ✅       | -               | Parent room ID              |
| `senderId`         | string        | ✅       | -               | Sender user ID              |
| `senderName`       | string        | ✅       | ''              | Sender display name         |
| `senderAvatarUrl`  | string        | ✅       | ''              | Sender avatar               |
| `content`          | string        | ✅       | -               | Message content             |
| `type`             | string        | ✅       | 'text'          | text/image/video/audio      |
| `mediaUrl`         | string        | ⬜       | null            | Media URL if applicable     |
| `thumbnailUrl`     | string        | ⬜       | null            | Thumbnail URL               |
| `metadata`         | map           | ⬜       | null            | Additional metadata         |
| `mentionedUserIds` | array<string> | ✅       | []              | Mentioned users             |
| `reactions`        | array<string> | ✅       | []              | Reaction emojis             |
| `status`           | string        | ✅       | 'sent'          | sending/sent/delivered/read |
| `replyToMessageId` | string        | ⬜       | null            | Reply to message ID         |
| `isEdited`         | boolean       | ✅       | false           | Edited flag                 |
| `editedAt`         | timestamp     | ⬜       | null            | Edit timestamp              |
| `isTyping`         | boolean       | ✅       | false           | Typing indicator            |
| `timestamp`        | timestamp     | ✅       | serverTimestamp | Message timestamp           |

**Example Document:**

```json
{
  "id": "msg123",
  "roomId": "room123",
  "senderId": "user456",
  "senderName": "Jane Smith",
  "senderAvatarUrl": "https://...",
  "content": "Great discussion!",
  "type": "text",
  "mentionedUserIds": [],
  "reactions": ["👍", "❤️"],
  "status": "read",
  "replyToMessageId": null,
  "isEdited": false,
  "timestamp": "2026-01-24T19:15:00Z"
}
```

**Required Indexes:**

- `roomId ASC, timestamp DESC`
- `senderId ASC, timestamp DESC`

---

### 8. direct_messages

**Path:** `/direct_messages/{messageId}`

**Description:** One-on-one private messages

**Fields:**

| Field            | Type                       | Required | Default         | Description                 |
| ---------------- | -------------------------- | -------- | --------------- | --------------------------- |
| `id`             | string                     | ✅       | -               | Message ID                  |
| `conversationId` | string                     | ✅       | -               | Conversation ID             |
| `senderId`       | string                     | ✅       | -               | Sender user ID              |
| `receiverId`     | string                     | ✅       | -               | Receiver user ID            |
| `type`           | string                     | ✅       | 'text'          | text/image/video/audio/file |
| `content`        | string                     | ✅       | -               | Message content             |
| `mediaUrl`       | string                     | ⬜       | null            | Media URL                   |
| `thumbnailUrl`   | string                     | ⬜       | null            | Thumbnail URL               |
| `metadata`       | map                        | ⬜       | null            | Additional data             |
| `status`         | string                     | ✅       | 'sent'          | sending/sent/delivered/read |
| `timestamp`      | timestamp                  | ✅       | serverTimestamp | Sent timestamp              |
| `readAt`         | timestamp                  | ⬜       | null            | Read timestamp              |
| `isEdited`       | boolean                    | ✅       | false           | Edited flag                 |
| `editedAt`       | timestamp                  | ⬜       | null            | Edit timestamp              |
| `reactions`      | map<string, array<string>> | ✅       | {}              | Emoji reactions             |

**Example Document:**

```json
{
  "id": "dm123",
  "conversationId": "user123_user456",
  "senderId": "user123",
  "receiverId": "user456",
  "type": "text",
  "content": "Hey, how are you?",
  "status": "read",
  "timestamp": "2026-01-24T19:30:00Z",
  "readAt": "2026-01-24T19:31:00Z",
  "isEdited": false,
  "reactions": {
    "👍": ["user456"]
  }
}
```

**Required Indexes:**

- `conversationId ASC, timestamp DESC`
- `senderId ASC, timestamp DESC`
- `receiverId ASC, timestamp DESC`

---

### 9. chat_rooms

**Path:** `/chat_rooms/{chatRoomId}`

**Description:** Metadata for direct message conversations

**Fields:**

| Field             | Type                | Required | Default         | Description           |
| ----------------- | ------------------- | -------- | --------------- | --------------------- |
| `id`              | string              | ✅       | -               | Chat room ID          |
| `participants`    | array<string>       | ✅       | -               | Participant user IDs  |
| `lastMessage`     | string              | ✅       | ''              | Last message preview  |
| `lastMessageTime` | timestamp           | ✅       | serverTimestamp | Last message time     |
| `unreadCounts`    | map<string, number> | ✅       | {}              | Unread count per user |
| `isTyping`        | boolean             | ✅       | false           | Typing indicator      |

**Example Document:**

```json
{
  "id": "user123_user456",
  "participants": ["user123", "user456"],
  "lastMessage": "Hey, how are you?",
  "lastMessageTime": "2026-01-24T19:30:00Z",
  "unreadCounts": {
    "user456": 2
  },
  "isTyping": false
}
```

**Required Indexes:**

- `participants ARRAY_CONTAINS, lastMessageTime DESC`

---

## Events & Speed Dating

### 10. events

**Path:** `/events/{eventId}`

**Description:** User-created events

**Fields:**

| Field          | Type          | Required | Default         | Description       |
| -------------- | ------------- | -------- | --------------- | ----------------- |
| `id`           | string        | ✅       | -               | Event ID          |
| `title`        | string        | ✅       | -               | Event title       |
| `description`  | string        | ✅       | -               | Event description |
| `hostId`       | string        | ✅       | -               | Host user ID      |
| `startTime`    | timestamp     | ✅       | -               | Event start time  |
| `endTime`      | timestamp     | ✅       | -               | Event end time    |
| `location`     | string        | ✅       | -               | Location string   |
| `latitude`     | number        | ✅       | -               | GPS latitude      |
| `longitude`    | number        | ✅       | -               | GPS longitude     |
| `category`     | string        | ✅       | 'General'       | Event category    |
| `imageUrl`     | string        | ✅       | ''              | Event image       |
| `attendees`    | array<string> | ✅       | []              | Attendee user IDs |
| `maxAttendees` | number        | ✅       | 10              | Max capacity      |
| `isPublic`     | boolean       | ✅       | true            | Public visibility |
| `createdAt`    | timestamp     | ✅       | serverTimestamp | Created timestamp |

**Example Document:**

```json
{
  "id": "event123",
  "title": "Coffee Meetup",
  "description": "Casual coffee meetup for app users",
  "hostId": "user123",
  "startTime": "2026-01-25T14:00:00Z",
  "endTime": "2026-01-25T16:00:00Z",
  "location": "Central Park Cafe",
  "latitude": 40.7829,
  "longitude": -73.9654,
  "category": "Social",
  "imageUrl": "https://...",
  "attendees": ["user123", "user456"],
  "maxAttendees": 10,
  "isPublic": true,
  "createdAt": "2026-01-20T10:00:00Z"
}
```

**Required Indexes:**

- `startTime ASC, isPublic ASC`
- `hostId ASC, startTime ASC`
- `category ASC, startTime ASC`

---

### 11. speed_dating_sessions

**Path:** `/speed_dating_sessions/{sessionId}`

**Description:** Speed dating sessions between two users

**Fields:**

| Field             | Type      | Required | Default         | Description                                    |
| ----------------- | --------- | -------- | --------------- | ---------------------------------------------- |
| `id`              | string    | ✅       | -               | Session ID                                     |
| `userId1`         | string    | ✅       | -               | First user ID                                  |
| `userId2`         | string    | ✅       | -               | Second user ID                                 |
| `roomId`          | string    | ✅       | -               | Video room ID                                  |
| `status`          | string    | ✅       | 'waiting'       | waiting/matched/inProgress/completed/cancelled |
| `durationMinutes` | number    | ✅       | 10              | Session duration                               |
| `user1Decision`   | string    | ✅       | 'pending'       | like/pass/pending                              |
| `user2Decision`   | string    | ✅       | 'pending'       | like/pass/pending                              |
| `isMatch`         | boolean   | ✅       | false           | Mutual match flag                              |
| `createdAt`       | timestamp | ✅       | serverTimestamp | Created timestamp                              |
| `startedAt`       | timestamp | ⬜       | null            | Started timestamp                              |
| `endedAt`         | timestamp | ⬜       | null            | Ended timestamp                                |

**Example Document:**

```json
{
  "id": "session123",
  "userId1": "user123",
  "userId2": "user456",
  "roomId": "room789",
  "status": "completed",
  "durationMinutes": 10,
  "user1Decision": "like",
  "user2Decision": "like",
  "isMatch": true,
  "createdAt": "2026-01-24T20:00:00Z",
  "startedAt": "2026-01-24T20:01:00Z",
  "endedAt": "2026-01-24T20:11:00Z"
}
```

**Required Indexes:**

- `participants ARRAY_CONTAINS, status ASC`
- `status ASC, createdAt DESC`

---

### 12. speed_dating_rounds

**Path:** `/speed_dating_rounds/{roundId}`

**Description:** Speed dating event rounds

**Fields:**

| Field                  | Type                       | Required | Default         | Description          |
| ---------------------- | -------------------------- | -------- | --------------- | -------------------- |
| `id`                   | string                     | ✅       | -               | Round ID             |
| `eventId`              | string                     | ✅       | -               | Parent event ID      |
| `participants`         | array<string>              | ✅       | -               | Participant user IDs |
| `startTime`            | timestamp                  | ✅       | -               | Round start time     |
| `roundDurationMinutes` | number                     | ✅       | 5               | Round duration       |
| `currentRound`         | number                     | ✅       | 1               | Current round number |
| `totalRounds`          | number                     | ✅       | 3               | Total rounds         |
| `matches`              | map<string, array<string>> | ✅       | {}              | User pairings        |
| `isActive`             | boolean                    | ✅       | false           | Active status        |
| `createdAt`            | timestamp                  | ✅       | serverTimestamp | Created timestamp    |

**Example Document:**

```json
{
  "id": "round123",
  "eventId": "event456",
  "participants": ["user123", "user456", "user789"],
  "startTime": "2026-01-24T20:00:00Z",
  "roundDurationMinutes": 5,
  "currentRound": 1,
  "totalRounds": 3,
  "matches": {
    "user123": ["user456"],
    "user789": []
  },
  "isActive": true,
  "createdAt": "2026-01-24T19:55:00Z"
}
```

**Required Indexes:**

- `eventId ASC, startTime ASC`
- `isActive ASC, startTime ASC`

---

### 13. speed_dating_results

**Path:** `/speed_dating_results/{resultId}`

**Description:** Speed dating match results

**Fields:**

| Field              | Type      | Required | Default         | Description      |
| ------------------ | --------- | -------- | --------------- | ---------------- |
| `id`               | string    | ✅       | -               | Result ID        |
| `roundId`          | string    | ✅       | -               | Round ID         |
| `userId`           | string    | ✅       | -               | User ID          |
| `matchedUserId`    | string    | ✅       | -               | Matched user ID  |
| `userLiked`        | boolean   | ✅       | false           | User liked match |
| `matchedUserLiked` | boolean   | ✅       | false           | Other user liked |
| `isMutual`         | boolean   | ✅       | false           | Mutual match     |
| `timestamp`        | timestamp | ✅       | serverTimestamp | Result timestamp |

**Example Document:**

```json
{
  "id": "result123",
  "roundId": "round456",
  "userId": "user123",
  "matchedUserId": "user456",
  "userLiked": true,
  "matchedUserLiked": true,
  "isMutual": true,
  "timestamp": "2026-01-24T20:10:00Z"
}
```

**Required Indexes:**

- `roundId ASC, timestamp ASC`
- `userId ASC, isMutual ASC`

---

## Monetization

### 14. subscriptions

**Path:** `/subscriptions/{subscriptionId}`

**Description:** User premium subscriptions

**Fields:**

| Field           | Type      | Required | Default | Description                     |
| --------------- | --------- | -------- | ------- | ------------------------------- |
| `id`            | string    | ✅       | -       | Subscription ID                 |
| `userId`        | string    | ✅       | -       | User ID                         |
| `tier`          | string    | ✅       | -       | basic/premium/vip               |
| `startDate`     | timestamp | ✅       | -       | Start date                      |
| `endDate`       | timestamp | ✅       | -       | End date                        |
| `status`        | string    | ✅       | -       | active/cancelled/expired/paused |
| `autoRenew`     | boolean   | ✅       | true    | Auto-renewal                    |
| `price`         | number    | ✅       | -       | Price paid                      |
| `paymentMethod` | string    | ✅       | -       | Payment method                  |
| `cancelledAt`   | timestamp | ⬜       | null    | Cancellation date               |
| `renewedAt`     | timestamp | ⬜       | null    | Last renewal date               |

**Example Document:**

```json
{
  "id": "sub123",
  "userId": "user123",
  "tier": "premium",
  "startDate": "2026-01-01T00:00:00Z",
  "endDate": "2026-02-01T00:00:00Z",
  "status": "active",
  "autoRenew": true,
  "price": 9.99,
  "paymentMethod": "stripe_card",
  "cancelledAt": null,
  "renewedAt": "2026-01-01T00:00:00Z"
}
```

**Required Indexes:**

- `userId ASC, status ASC`
- `status ASC, endDate ASC`

---

### 15. withdrawal_requests

**Path:** `/withdrawal_requests/{requestId}`

**Description:** Creator payout requests

**Fields:**

| Field              | Type      | Required | Default         | Description                                   |
| ------------------ | --------- | -------- | --------------- | --------------------------------------------- |
| `id`               | string    | ✅       | -               | Request ID                                    |
| `userId`           | string    | ✅       | -               | User ID                                       |
| `userName`         | string    | ✅       | -               | User name                                     |
| `coinAmount`       | number    | ✅       | -               | Coins to withdraw                             |
| `usdAmount`        | number    | ✅       | -               | USD value                                     |
| `platformFee`      | number    | ✅       | -               | Platform fee                                  |
| `payoutAmount`     | number    | ✅       | -               | Final payout                                  |
| `status`           | string    | ✅       | 'pending'       | pending/processing/completed/failed/cancelled |
| `stripeAccountId`  | string    | ⬜       | null            | Stripe account                                |
| `stripeTransferId` | string    | ⬜       | null            | Stripe transfer ID                            |
| `failureReason`    | string    | ⬜       | null            | Failure reason                                |
| `requestedAt`      | timestamp | ✅       | serverTimestamp | Request time                                  |
| `processedAt`      | timestamp | ⬜       | null            | Processed time                                |
| `completedAt`      | timestamp | ⬜       | null            | Completed time                                |

**Example Document:**

```json
{
  "id": "withdraw123",
  "userId": "user123",
  "userName": "John Doe",
  "coinAmount": 10000,
  "usdAmount": 100.0,
  "platformFee": 10.0,
  "payoutAmount": 90.0,
  "status": "completed",
  "stripeAccountId": "acct_123",
  "stripeTransferId": "tr_123",
  "requestedAt": "2026-01-20T10:00:00Z",
  "processedAt": "2026-01-20T10:05:00Z",
  "completedAt": "2026-01-20T10:10:00Z"
}
```

**Required Indexes:**

- `userId ASC, requestedAt DESC`
- `status ASC, requestedAt DESC`

---

## Moderation & Safety

### 16. reports

**Path:** `/reports/{reportId}`

**Description:** User reports for content/behavior violations

**Fields:**

| Field               | Type      | Required | Default         | Description                                                         |
| ------------------- | --------- | -------- | --------------- | ------------------------------------------------------------------- |
| `id`                | string    | ✅       | -               | Report ID                                                           |
| `reporterId`        | string    | ✅       | -               | Reporter user ID                                                    |
| `reportedUserId`    | string    | ✅       | -               | Reported user ID                                                    |
| `reportedMessageId` | string    | ⬜       | null            | Message ID if applicable                                            |
| `reportedRoomId`    | string    | ⬜       | null            | Room ID if applicable                                               |
| `type`              | string    | ✅       | -               | spam/harassment/inappropriateContent/hateSpeech/violence/scam/other |
| `description`       | string    | ✅       | -               | Report description                                                  |
| `status`            | string    | ✅       | 'pending'       | pending/reviewed/resolved                                           |
| `reviewedBy`        | string    | ⬜       | null            | Admin user ID                                                       |
| `reviewedAt`        | timestamp | ⬜       | null            | Review timestamp                                                    |
| `createdAt`         | timestamp | ✅       | serverTimestamp | Report timestamp                                                    |

**Example Document:**

```json
{
  "id": "report123",
  "reporterId": "user456",
  "reportedUserId": "user789",
  "reportedMessageId": "msg123",
  "reportedRoomId": "room456",
  "type": "harassment",
  "description": "User sent inappropriate messages",
  "status": "reviewed",
  "reviewedBy": "admin123",
  "reviewedAt": "2026-01-24T21:00:00Z",
  "createdAt": "2026-01-24T20:30:00Z"
}
```

**Required Indexes:**

- `reportedUserId ASC, createdAt DESC`
- `status ASC, createdAt DESC`

---

### 17. blocks

**Path:** `/blocks/{blockId}`

**Description:** User blocking relationships

**Fields:**

| Field           | Type      | Required | Default         | Description     |
| --------------- | --------- | -------- | --------------- | --------------- |
| `id`            | string    | ✅       | -               | Block ID        |
| `blockerId`     | string    | ✅       | -               | Blocker user ID |
| `blockedUserId` | string    | ✅       | -               | Blocked user ID |
| `reason`        | string    | ⬜       | null            | Block reason    |
| `blockedAt`     | timestamp | ✅       | serverTimestamp | Block timestamp |

**Example Document:**

```json
{
  "id": "block123",
  "blockerId": "user123",
  "blockedUserId": "user456",
  "reason": "Unwanted contact",
  "blockedAt": "2026-01-24T20:00:00Z"
}
```

**Required Indexes:**

- `blockerId ASC, blockedAt DESC`
- `blockedUserId ASC, blockedAt DESC`

---

## System Collections

### 18. activities

**Path:** `/activities/{activityId}`

**Description:** User activity feed items

**Fields:**

| Field          | Type      | Required | Default         | Description                             |
| -------------- | --------- | -------- | --------------- | --------------------------------------- |
| `id`           | string    | ✅       | -               | Activity ID                             |
| `userId`       | string    | ✅       | -               | User ID                                 |
| `userName`     | string    | ✅       | -               | User name                               |
| `userPhotoUrl` | string    | ⬜       | null            | User photo                              |
| `type`         | string    | ✅       | -               | joinedRoom/hostedRoom/attendedEvent/etc |
| `description`  | string    | ✅       | -               | Activity description                    |
| `timestamp`    | timestamp | ✅       | serverTimestamp | Activity timestamp                      |
| `metadata`     | map       | ⬜       | null            | Additional data                         |

**Example Document:**

```json
{
  "id": "activity123",
  "userId": "user123",
  "userName": "John Doe",
  "userPhotoUrl": "https://...",
  "type": "hostedRoom",
  "description": "Hosted 'Music Lovers Lounge'",
  "timestamp": "2026-01-24T19:00:00Z",
  "metadata": {
    "roomId": "room123",
    "roomName": "Music Lovers Lounge"
  }
}
```

**Required Indexes:**

- `userId ASC, timestamp DESC`
- `type ASC, timestamp DESC`

---

### 19. notifications

**Path:** `/notifications/{notificationId}`

**Description:** User notifications

**Fields:**

| Field        | Type      | Required | Default         | Description                                        |
| ------------ | --------- | -------- | --------------- | -------------------------------------------------- |
| `id`         | string    | ✅       | -               | Notification ID                                    |
| `userId`     | string    | ✅       | -               | Recipient user ID                                  |
| `type`       | string    | ✅       | -               | roomInvite/reaction/newFollower/tip/message/system |
| `title`      | string    | ✅       | -               | Notification title                                 |
| `message`    | string    | ✅       | -               | Notification message                               |
| `senderId`   | string    | ⬜       | null            | Sender user ID                                     |
| `senderName` | string    | ⬜       | null            | Sender name                                        |
| `roomId`     | string    | ⬜       | null            | Room ID                                            |
| `roomName`   | string    | ⬜       | null            | Room name                                          |
| `data`       | map       | ⬜       | null            | Additional data                                    |
| `isRead`     | boolean   | ✅       | false           | Read status                                        |
| `timestamp`  | timestamp | ✅       | serverTimestamp | Notification time                                  |

**Example Document:**

```json
{
  "id": "notif123",
  "userId": "user456",
  "type": "roomInvite",
  "title": "Room Invitation",
  "message": "John Doe invited you to join 'Music Lovers Lounge'",
  "senderId": "user123",
  "senderName": "John Doe",
  "roomId": "room789",
  "roomName": "Music Lovers Lounge",
  "isRead": false,
  "timestamp": "2026-01-24T19:30:00Z"
}
```

**Required Indexes:**

- `userId ASC, timestamp DESC`
- `userId ASC, isRead ASC, timestamp DESC`

---

### 20. media

**Path:** `/media/{mediaId}`

**Description:** Uploaded media files

**Fields:**

| Field          | Type      | Required | Default         | Description            |
| -------------- | --------- | -------- | --------------- | ---------------------- |
| `id`           | string    | ✅       | -               | Media ID               |
| `userId`       | string    | ✅       | -               | Uploader user ID       |
| `type`         | string    | ✅       | -               | image/video/audio/file |
| `url`          | string    | ✅       | -               | Media URL              |
| `thumbnailUrl` | string    | ⬜       | null            | Thumbnail URL          |
| `title`        | string    | ⬜       | null            | Media title            |
| `description`  | string    | ⬜       | null            | Media description      |
| `metadata`     | map       | ⬜       | null            | File metadata          |
| `uploadedAt`   | timestamp | ✅       | serverTimestamp | Upload timestamp       |

**Example Document:**

```json
{
  "id": "media123",
  "userId": "user123",
  "type": "image",
  "url": "https://storage.../image.jpg",
  "thumbnailUrl": "https://storage.../thumb.jpg",
  "title": "Sunset Photo",
  "metadata": {
    "width": 1920,
    "height": 1080,
    "size": 245632
  },
  "uploadedAt": "2026-01-24T18:00:00Z"
}
```

**Required Indexes:**

- `userId ASC, uploadedAt DESC`
- `type ASC, uploadedAt DESC`

---

## Required Indexes

### Composite Indexes

```json
{
  "indexes": [
    // Users
    {
      "collectionGroup": "users",
      "fields": [
        { "fieldPath": "isOnline", "order": "ASCENDING" },
        { "fieldPath": "lookingForSpeedDate", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "users",
      "fields": [
        { "fieldPath": "membershipTier", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },

    // Rooms
    {
      "collectionGroup": "rooms",
      "fields": [
        { "fieldPath": "isLive", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "rooms",
      "fields": [
        { "fieldPath": "category", "order": "ASCENDING" },
        { "fieldPath": "isLive", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },

    // Messages
    {
      "collectionGroup": "messages",
      "fields": [
        { "fieldPath": "roomId", "order": "ASCENDING" },
        { "fieldPath": "timestamp", "order": "DESCENDING" }
      ]
    },

    // Direct Messages
    {
      "collectionGroup": "direct_messages",
      "fields": [
        { "fieldPath": "conversationId", "order": "ASCENDING" },
        { "fieldPath": "timestamp", "order": "DESCENDING" }
      ]
    },

    // Notifications
    {
      "collectionGroup": "notifications",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "timestamp", "order": "DESCENDING" }
      ]
    },

    // Events
    {
      "collectionGroup": "events",
      "fields": [
        { "fieldPath": "startTime", "order": "ASCENDING" },
        { "fieldPath": "isPublic", "order": "ASCENDING" }
      ]
    },

    // Speed Dating
    {
      "collectionGroup": "speed_dating_sessions",
      "fields": [
        { "fieldPath": "participants", "arrayConfig": "CONTAINS" },
        { "fieldPath": "status", "order": "ASCENDING" }
      ]
    },

    // Activities
    {
      "collectionGroup": "activities",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "timestamp", "order": "DESCENDING" }
      ]
    }
  ]
}
```

---

## Security Rules Summary

### Access Control Hierarchy

1. **Admin Users** (`role: 'admin'`)
   - Full access to all collections
   - Can create events
   - Can moderate reports
   - Can update system configurations

2. **Moderators** (`role: 'moderator'`)
   - Can review and resolve reports
   - Can moderate content
   - Cannot access admin-only features

3. **Premium Users** (`membershipTier: 'premium' | 'vip'`)
   - Can send DMs to non-matched users
   - Increased media upload limits
   - Enhanced features access

4. **Authenticated Users**
   - Standard app access
   - Must complete profile for full features
   - Can only modify own data

### Collection-Specific Rules

#### User Collections

**users**

- **Create**: Own profile only, with validation (email, displayName, username required)
- **Read**: Own profile or any profile if own profile is complete
- **Update**: Own profile only, cannot change email/username, coinBalance can only increase
- **Delete**: ❌ Forbidden

**user_profiles**

- **Create**: Own profile only
- **Read**: Own profile or any if completed profile + not blocked
- **Update**: Own profile only, age preferences must be valid (18-100)
- **Delete**: ❌ Forbidden

**user_presence**

- **Read**: All authenticated users
- **Write**: Own presence only, status must be valid (online/away/offline/busy)

#### Matching & Social

**matching_profiles**

- **Create**: Own profile, age >= 18
- **Read**: Active profiles only, not blocked
- **Update**: Own profile, age must stay >= 18
- **Delete**: Own profile only

**matches**

- **Create**: Must involve self, users must be different, score 0-100
- **Read**: Only if you're one of the matched users
- **Update**: Only participants, limited fields
- **Delete**: Only participants

**blocks**

- **Create**: Own blocks only, cannot block self
- **Read**: Own blocks only
- **Delete**: Own blocks only

#### Communication

**rooms**

- **Create**: Completed profile required, must be host, full validation
- **Read**: Authenticated users not banned from room
- **Update**:
  - Moderators: Can update most fields
  - Anyone: Can join as listener if not banned and under capacity
- **Delete**: Host only

**rooms/{roomId}/messages**

- **Create**: Room members only, 500 char limit
- **Read**: Room members only
- **Update**: Own messages within 5 minutes, reactions only
- **Delete**: Own messages or room moderators

**chat_rooms**

- **Create**: Must have 2 participants, mutual not blocked
- **Read**: Participants only
- **Update**: Participants only, cannot change participants list

**direct_messages**

- **Create**: Must be matched OR premium user, not blocked, 2000 char limit
- **Read**: Sender or receiver only
- **Update**: Sender can edit (limited fields), receiver can mark as read
- **Delete**: ❌ Forbidden

#### Events & Speed Dating

**events**

- **Create**: ⚠️ **ADMIN ONLY**, full validation, capacity 1-1000, future dates
- **Read**: Public events OR host OR attendees
- **Update**: Host can update OR users can join if under capacity
- **Delete**: Host or admin only

**speed_dating_sessions**

- **Create**: Must be one of the participants, different users, duration 3-30 min
- **Read**: Participants only
- **Update**: Participants can update own decision (like/pass)
- **Delete**: Participants only

**speed_dating_rounds**

- **Create**: ⚠️ **ADMIN ONLY**, >= 2 participants
- **Read**: Event participants only
- **Update**: Event participants, cannot change core fields
- **Delete**: Admin only

**speed_dating_results**

- **Create**: Own results only, different users
- **Read**: Involved users only
- **Update/Delete**: ❌ Forbidden

#### Monetization

**subscriptions**

- **Read**: Own subscription only
- **Write**: ❌ Server-side only (Cloud Functions)

**withdrawal_requests**

- **Create**: Must have sufficient coins, pending status
- **Read**: Own requests or admin
- **Update**: Admin only, cannot change amount
- **Delete**: Own requests if pending status

**coin_transactions**

- **Read**: Own transactions only
- **Write**: ❌ Server-side only

#### Moderation & Safety

**reports**

- **Create**: Cannot report self, valid type, pending status, 1000 char limit
- **Read**: Reporter or moderators
- **Update**: Moderators only, status changes
- **Delete**: Admin only

#### Media & Uploads

**media**

- **Create**: Completed profile, valid type, 50MB limit for free users
- **Read**: Own media or any if completed profile
- **Update**: Own media, metadata/description only
- **Delete**: Own media or admin

**shared_files**

- **Create**: 50MB limit
- **Read**: All authenticated users
- **Delete**: Own files only

#### Notifications & Activities

**notifications**

- **Create**: ❌ Server-side only
- **Read**: Own notifications only
- **Update**: Own notifications, can mark as read
- **Delete**: Own notifications only

**activities**

- **Create**: Own activities, valid type
- **Read**: All authenticated users with completed profile
- **Update/Delete**: Own activities only

### Key Security Patterns

1. **Ownership Enforcement**

   ```javascript
   function isOwner(userId) {
     return request.auth.uid == userId;
   }
   ```

2. **Match-Based Access**

   ```javascript
   function isMatchedWith(otherUserId) {
     return exists(/databases/$(database)/documents/matches/$(request.auth.uid + '_' + otherUserId)) ||
            exists(/databases/$(database)/documents/matches/$(otherUserId + '_' + request.auth.uid));
   }
   ```

3. **Capacity Enforcement**

   ```javascript
   // In events update rule
   request.resource.data.attendees.size() <= resource.data.maxAttendees;
   ```

4. **Participant Verification**

   ```javascript
   function isSpeedDatingParticipant(sessionId) {
     return (
       request.auth.uid == get(...(sessions / $(sessionId))).data.userId1 ||
       request.auth.uid == get(...(sessions / $(sessionId))).data.userId2
     );
   }
   ```

5. **Admin-Only Operations**

   ```javascript
   function isAdmin() {
     return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
   }
   ```

6. **Block Detection**
   ```javascript
   function hasNotBlockedUser(userId) {
     return !exists(/databases/$(database)/documents/blocks/$(request.auth.uid + '_' + userId));
   }
   ```

### Validation Rules

- **Username**: 3-20 chars, alphanumeric + underscore
- **Email**: Valid email format via regex
- **Display Name**: 1-50 chars
- **Message Content**: 500-2000 chars depending on type
- **Age Preferences**: 18-100, min <= max
- **Room Names**: 1-100 chars
- **Event Capacity**: 1-1000 attendees
- **Speed Dating Duration**: 3-30 minutes
- **File Upload**: 50MB limit
- **Coin Balance**: Cannot decrease directly

### Admin Dashboard Access

Protected routes requiring admin role in Firestore:

- `/admin` - Admin dashboard
- Event creation functionality
- Report moderation
- User management
- System configuration

**Implementation**: Check `users/{uid}.role == 'admin'` before allowing access.

---

## Schema Version History

| Version | Date       | Changes                      |
| ------- | ---------- | ---------------------------- |
| 1.0     | 2026-01-24 | Initial comprehensive schema |

---

## Deployment Commands

```bash
# Deploy Firestore indexes
firebase deploy --only firestore:indexes

# Deploy security rules
firebase deploy --only firestore:rules

# Deploy all Firestore configurations
firebase deploy --only firestore
```

---

**Schema Status:** ✅ Production Ready
**Total Collections:** 20
**Total Indexes:** 9 composite indexes
**Last Validated:** January 24, 2026
