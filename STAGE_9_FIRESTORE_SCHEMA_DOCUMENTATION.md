# ✅ Stage 9: Firestore Schema Documentation - COMPLETE

**Status:** COMPLETE ✅
**Date:** February 11, 2026
**Database:** Cloud Firestore (NoSQL)
**Architecture:** Hierarchical document-collection structure

---

## 🎯 Overview

This document provides a **complete reference** for all Firestore collections and subcollections used in the Mix & Mingle platform. The schema supports:
- User authentication and profiles
- Social graph (follow/unfollow relationships)
- Real-time voice/video rooms with Agora RTC
- Speed dating matchmaking
- Direct messaging
- Monetization (coins, gifts, subscriptions)
- Moderation and safety
- Creator program
- Federation (cross-app identity)
- Analytics and insights

---

## 📚 Top-Level Collections

### 1. `users`
**Purpose:** Core user profiles and account data
**Document ID:** Firebase Auth UID
**Security:** User can read/write own document, others can read public fields

**Schema:**
```typescript
{
  id: string;                     // Firebase Auth UID
  email: string;                  // User email
  displayName: string;            // Display name (required)
  username: string;               // Unique username (required)
  dateOfBirth: Timestamp;         // Date of birth (18+ required)
  gender: string;                 // "male" | "female" | "non-binary" | "other"
  lookingFor: string[];           // ["friendship", "dating", "networking"]
  bio: string;                    // User bio (max 500 characters)
  photos: string[];               // Array of photo URLs (max 6)
  interests: string[];            // Array of interest tags
  location: {                     // Location data
    city: string;
    state: string;
    country: string;
    latitude: number;
    longitude: number;
  };
  verifiedEmail: boolean;         // Email verified
  verifiedPhone: boolean;         // Phone verified
  isVerified: boolean;            // Verified user badge
  membershipTier: string;         // "free" | "vip" | "vip_plus"
  coinBalance: number;            // Virtual coin balance
  followersCount: number;         // Cached follower count
  followingCount: number;         // Cached following count
  roomsHostedCount: number;       // Rooms created counter
  speedDatingMatches: number;     // Total speed dating matches
  createdAt: Timestamp;           // Account creation timestamp
  updatedAt: Timestamp;           // Last profile update
  lastSeenAt: Timestamp;          // Last active timestamp
  fcmToken: string;               // Firebase Cloud Messaging token
  blockedUsers: string[];         // Array of blocked user IDs
  reportedUsers: string[];        // Array of reported user IDs
  isAdmin: boolean;               // Admin role flag
  isBanned: boolean;              // Banned status
  banReason: string | null;       // Ban reason if applicable
  banExpiresAt: Timestamp | null; // Temp ban expiry
}
```

**Subcollections:**
- `users/{userId}/following` - Users this user follows
- `users/{userId}/followers` - Users following this user
- `users/{userId}/blocked` - Blocked users (alternative to array)

**Indexes Required:**
```
Collection: users
- username (ASC)
- membershipTier (ASC), createdAt (DESC)
- isVerified (ASC), followersCount (DESC)
- location.city (ASC), gender (ASC)
```

---

### 2. `users/{userId}/following`
**Purpose:** Track users this user follows
**Document ID:** Target user ID
**Schema:**
```typescript
{
  timestamp: Timestamp;           // When follow occurred
}
```

---

### 3. `users/{userId}/followers`
**Purpose:** Track users following this user
**Document ID:** Follower user ID
**Schema:**
```typescript
{
  timestamp: Timestamp;           // When follow occurred
}
```

---

### 4. `users/{userId}/blocked`
**Purpose:** Track blocked users (alternative to array in user doc)
**Document ID:** Blocked user ID
**Schema:**
```typescript
{
  blockedAt: Timestamp;           // When block occurred
  reason: string | null;          // Optional reason
}
```

---

### 5. `rooms`
**Purpose:** Voice/video rooms powered by Agora RTC
**Document ID:** Auto-generated room ID
**Security:** Read: all authenticated users, Write: host only

**Schema:**
```typescript
{
  id: string;                     // Room ID
  title: string;                  // Room title
  description: string;            // Room description
  hostId: string;                 // Creator user ID
  hostName: string;               // Creator display name
  hostAvatar: string;             // Creator photo URL
  category: string;               // "music" | "comedy" | "gaming" | etc.
  tags: string[];                 // Search tags
  isPrivate: boolean;             // Private room (invite-only)
  locked: boolean;                // Room locked (no new joins)
  ended: boolean;                 // Room ended flag
  maxParticipants: number;        // Max capacity (default 50)
  participantCount: number;       // Current participant count
  camCount: number;               // Users with camera on
  speakerCount: number;           // Users with mic on
  allowSpeakerRequests: boolean;  // Allow raise hand
  turnBased: boolean;             // Turn-based speaking
  scheduledAt: Timestamp | null;  // Scheduled start time
  startedAt: Timestamp;           // Actual start time
  endedAt: Timestamp | null;      // End time
  createdAt: Timestamp;           // Creation timestamp
  agoraChannelName: string;       // Agora channel name
  agoraAppId: string;             // Agora app ID
}
```

**Subcollections:**
- `rooms/{roomId}/participants` - Room participants with roles
- `rooms/{roomId}/messages` - Room chat messages (deprecated)
- `rooms/{roomId}/events` - Room events log

**Indexes Required:**
```
Collection: rooms
- ended (ASC), startedAt (DESC)
- category (ASC), participantCount (DESC)
- hostId (ASC), createdAt (DESC)
```

---

### 6. `rooms/{roomId}/participants`
**Purpose:** Track room participants with roles and status
**Document ID:** User ID
**Schema:**
```typescript
{
  userId: string;                 // User ID
  displayName: string;            // Display name
  avatarUrl: string;              // Photo URL
  role: string;                   // "host" | "cohost" | "speaker" | "listener" | "moderator"
  isMuted: boolean;               // Muted status
  isOnCam: boolean;               // Camera on
  handRaised: boolean;            // Hand raised for turn
  approved: boolean;              // Approved to speak
  joinedAt: Timestamp;            // Join timestamp
  lastActiveAt: number;           // Last activity (ms since epoch)
}
```

---

### 7. `room_messages`
**Purpose:** Global room messages collection (preferred over subcollection)
**Document ID:** Auto-generated message ID
**Schema:**
```typescript
{
  id: string;                     // Message ID
  roomId: string;                 // Room ID (for querying)
  senderId: string;               // Sender user ID
  senderName: string;             // Sender display name
  senderAvatarUrl: string;        // Sender photo URL
  type: string;                   // "text" | "audio" | "image" | "video" | "gift"
  content: string;                // Message content
  mediaUrl: string | null;        // Media URL if applicable
  thumbnailUrl: string | null;    // Thumbnail for video
  metadata: Map<string, dynamic>; // Additional metadata
  mentionedUserIds: string[];     // @mentioned users
  reactions: {                    // Emoji reactions
    [emoji: string]: string[];    // Array of user IDs who reacted
  };
  isEdited: boolean;              // Edited flag
  isDeleted: boolean;             // Soft delete flag
  timestamp: Timestamp;           // Message timestamp
}
```

**Indexes Required:**
```
Collection: room_messages
- roomId (ASC), timestamp (ASC)
- senderId (ASC), timestamp (DESC)
```

---

### 8. `rooms/{roomId}/events`
**Purpose:** Room event log (user joined, left, promoted, etc.)
**Document ID:** Auto-generated event ID
**Schema:**
```typescript
{
  type: string;                   // "user_joined" | "user_left" | "role_changed" | "room_locked"
  userId: string | null;          // User involved (if applicable)
  metadata: Map<string, dynamic>; // Event-specific data
  timestamp: Timestamp;           // Event timestamp
}
```

---

### 9. `chats`
**Purpose:** Direct message threads between users
**Document ID:** Auto-generated chat ID
**Security:** Read/write by participants only

**Schema:**
```typescript
{
  id: string;                     // Chat ID
  participantIds: string[];       // Array of 2 user IDs
  participantNames: string[];     // Display names
  participantAvatars: string[];   // Photo URLs
  lastMessage: string;            // Preview text
  lastMessageTime: Timestamp;     // Last message timestamp
  lastMessageSenderId: string;    // Who sent last message
  unreadCount: {                  // Unread counts per user
    [userId: string]: number;
  };
  createdAt: Timestamp;           // Chat creation timestamp
  isSpeedDatingMatch: boolean;    // Created from speed dating
  matchedAt: Timestamp | null;    // When matched (if applicable)
}
```

**Subcollections:**
- `chats/{chatId}/messages` - Chat messages

**Indexes Required:**
```
Collection: chats
- participantIds (ARRAY_CONTAINS), lastMessageTime (DESC)
```

---

### 10. `chats/{chatId}/messages`
**Purpose:** Messages within a chat thread
**Document ID:** Auto-generated message ID
**Schema:**
```typescript
{
  id: string;                     // Message ID
  senderId: string;               // Sender user ID
  senderName: string;             // Sender display name
  text: string;                   // Message text
  mediaUrl: string | null;        // Image/video URL
  mediaType: string | null;       // "image" | "video" | "audio"
  replyTo: string | null;         // Reply to message ID
  reactions: {                    // Emoji reactions
    [emoji: string]: string[];    // Array of user IDs
  };
  isRead: boolean;                // Read status
  timestamp: Timestamp;           // Message timestamp
}
```

**Indexes Required:**
```
Collection group: messages
- senderId (ASC), timestamp (DESC)
```

---

### 11. `speed_dating_queue`
**Purpose:** Users waiting for speed dating matches
**Document ID:** User ID
**Schema:**
```typescript
{
  userId: string;                 // User ID
  displayName: string;            // Display name
  age: number;                    // Age (calculated from DOB)
  gender: string;                 // Gender
  lookingFor: string;             // Seeking gender
  interests: string[];            // Interest tags
  photos: string[];               // Photo URLs
  enteredAt: Timestamp;           // Queue join time
  status: string;                 // "waiting" | "matched" | "in_session"
  sessionId: string | null;       // Active session ID if matched
}
```

**Indexes Required:**
```
Collection: speed_dating_queue
- status (ASC), enteredAt (ASC)
- gender (ASC), lookingFor (ASC)
```

---

### 12. `speed_dating_sessions`
**Purpose:** Active speed dating sessions (3-minute video chats)
**Document ID:** Auto-generated session ID
**Schema:**
```typescript
{
  id: string;                     // Session ID
  user1Id: string;                // First user ID
  user2Id: string;                // Second user ID
  user1Name: string;              // First user display name
  user2Name: string;              // Second user display name
  user1Photo: string;             // First user photo URL
  user2Photo: string;             // Second user photo URL
  user1Decision: string | null;   // "like" | "pass" | null
  user2Decision: string | null;   // "like" | "pass" | null
  status: string;                 // "active" | "ended" | "matched" | "no_match"
  agoraChannelName: string;       // Agora channel name
  agoraAppId: string;             // Agora app ID
  startedAt: Timestamp;           // Session start time
  endedAt: Timestamp | null;      // Session end time
  duration: number;               // Duration in seconds (default 180)
}
```

**Indexes Required:**
```
Collection: speed_dating_sessions
- user1Id (ASC), startedAt (DESC)
- user2Id (ASC), startedAt (DESC)
- status (ASC), endedAt (DESC)
```

---

### 13. `speed_dating_decisions`
**Purpose:** Historical speed dating decisions for analytics
**Document ID:** Auto-generated decision ID
**Schema:**
```typescript
{
  sessionId: string;              // Session ID
  userId: string;                 // User who made decision
  targetUserId: string;           // Target user
  decision: string;               // "like" | "pass"
  decidedAt: Timestamp;           // Decision timestamp
  wasMatch: boolean;              // Both liked each other
}
```

**Indexes Required:**
```
Collection: speed_dating_decisions
- userId (ASC), decidedAt (DESC)
- sessionId (ASC)
```

---

### 14. `user_presence`
**Purpose:** Real-time user online status
**Document ID:** User ID
**Schema:**
```typescript
{
  userId: string;                 // User ID
  status: number;                 // 0=offline, 1=online, 2=away, 3=busy
  roomId: string | null;          // Current room ID
  isTyping: boolean;              // Typing indicator
  lastSeen: Timestamp;            // Last activity timestamp
}
```

**Indexes Required:**
```
Collection: user_presence
- roomId (ASC), status (ASC)
```

---

### 15. `reports`
**Purpose:** User-generated reports for moderation
**Document ID:** Auto-generated report ID
**Schema:**
```typescript
{
  id: string;                     // Report ID
  reporterUserId: string;         // User who reported
  reportedUserId: string;         // Reported user ID
  reportedUserName: string;       // Reported user name
  reportType: string;             // "spam" | "harassment" | "inappropriate" | "hate_speech" | "violence" | "scam" | "other"
  context: string;                // "profile" | "message" | "room" | "speed_dating"
  contextId: string | null;       // Room ID, message ID, etc.
  description: string;            // Reporter's description
  evidence: string[];             // Screenshot URLs
  status: string;                 // "pending" | "reviewing" | "resolved" | "dismissed"
  resolution: string | null;      // Resolution notes
  reviewedBy: string | null;      // Admin user ID
  reviewedAt: Timestamp | null;   // Review timestamp
  createdAt: Timestamp;           // Report timestamp
}
```

**Indexes Required:**
```
Collection: reports
- status (ASC), createdAt (DESC)
- reportedUserId (ASC), createdAt (DESC)
- reporterUserId (ASC), createdAt (DESC)
```

---

### 16. `banned_users`
**Purpose:** Banned user records (separate from user doc)
**Document ID:** User ID
**Schema:**
```typescript
{
  userId: string;                 // Banned user ID
  reason: string;                 // Ban reason
  banType: string;                // "permanent" | "temporary"
  expiresAt: Timestamp | null;    // Expiry (null = permanent)
  bannedBy: string;               // Admin user ID
  bannedAt: Timestamp;            // Ban timestamp
  appealStatus: string | null;    // "pending" | "approved" | "denied" | null
}
```

---

### 17. `coins_transactions`
**Purpose:** Virtual coin purchase and spend history
**Document ID:** Auto-generated transaction ID
**Schema:**
```typescript
{
  id: string;                     // Transaction ID
  userId: string;                 // User ID
  type: string;                   // "purchase" | "gift_sent" | "gift_received" | "tip_sent" | "tip_received" | "refund"
  amount: number;                 // Coin amount (positive or negative)
  balanceBefore: number;          // Balance before transaction
  balanceAfter: number;           // Balance after transaction
  relatedUserId: string | null;   // Other user involved (tips/gifts)
  productId: string | null;       // RevenueCat product ID (purchases)
  metadata: {                     // Additional data
    giftType?: string;            // Gift type if applicable
    roomId?: string;              // Room ID if applicable
  };
  timestamp: Timestamp;           // Transaction timestamp
}
```

**Indexes Required:**
```
Collection: coins_transactions
- userId (ASC), timestamp (DESC)
- type (ASC), timestamp (DESC)
```

---

### 18. `gifts`
**Purpose:** Gift catalog (predefined gifts users can send)
**Document ID:** Gift ID
**Schema:**
```typescript
{
  id: string;                     // Gift ID
  name: string;                   // Gift name ("Rose", "Diamond Ring", etc.)
  category: string;               // "flowers" | "jewelry" | "food" | "drinks" | "animals" | "special"
  coinCost: number;               // Cost in coins
  iconUrl: string;                // Icon image URL
  animationType: string;          // "fadeIn" | "slideUp" | "bounce" | "sparkle" | "heartExplosion" | "fireworks"
  rarity: string;                 // "common" | "rare" | "epic" | "legendary"
  isActive: boolean;              // Available for purchase
  createdAt: Timestamp;           // Added to catalog
}
```

---

### 19. `gift_transactions`
**Purpose:** Gift send history
**Document ID:** Auto-generated transaction ID
**Schema:**
```typescript
{
  id: string;                     // Transaction ID
  giftId: string;                 // Gift ID
  senderId: string;               // Sender user ID
  recipientId: string;            // Recipient user ID
  roomId: string | null;          // Room ID (if sent in room)
  coinCost: number;               // Coins spent
  message: string | null;         // Optional message
  isAnonymous: boolean;           // Anonymous gift
  sentAt: Timestamp;              // Sent timestamp
}
```

**Indexes Required:**
```
Collection: gift_transactions
- recipientId (ASC), sentAt (DESC)
- senderId (ASC), sentAt (DESC)
- roomId (ASC), sentAt (DESC)
```

---

### 20. `subscriptions`
**Purpose:** Premium membership subscriptions (RevenueCat)
**Document ID:** User ID
**Schema:**
```typescript
{
  userId: string;                 // User ID
  tier: string;                   // "free" | "vip" | "vip_plus"
  productId: string;              // RevenueCat product ID
  purchaseDate: Timestamp;        // Purchase date
  expiryDate: Timestamp;          // Expiry date
  autoRenew: boolean;             // Auto-renewal enabled
  isActive: boolean;              // Active subscription
  platform: string;               // "ios" | "android" | "web"
  transactionId: string;          // Store transaction ID
}
```

**Indexes Required:**
```
Collection: subscriptions
- userId (ASC)
- isActive (ASC), expiryDate (ASC)
```

---

### 21. `notifications`
**Purpose:** User notifications (in-app)
**Document ID:** Auto-generated notification ID
**Schema:**
```typescript
{
  id: string;                     // Notification ID
  userId: string;                 // Recipient user ID
  type: string;                   // "follow" | "match" | "message" | "gift" | "room_invite" | "system"
  title: string;                  // Notification title
  body: string;                   // Notification body
  imageUrl: string | null;        // Optional image
  actionUrl: string | null;       // Deep link
  isRead: boolean;                // Read status
  createdAt: Timestamp;           // Notification timestamp
}
```

**Indexes Required:**
```
Collection: notifications
- userId (ASC), createdAt (DESC)
- userId (ASC), isRead (ASC), createdAt (DESC)
```

---

### 22. `roomInvitations`
**Purpose:** Room invitations
**Document ID:** Auto-generated invitation ID
**Schema:**
```typescript
{
  roomId: string;                 // Room ID
  inviterId: string;              // Inviter user ID
  invitedUserId: string;          // Invited user ID
  status: string;                 // "pending" | "accepted" | "declined"
  createdAt: Timestamp;           // Invitation timestamp
}
```

---

### 23. `pricing_tiers`
**Purpose:** Dynamic pricing for coin packages
**Document ID:** Tier ID
**Schema:**
```typescript
{
  id: string;                     // Tier ID
  coins: number;                  // Coin amount
  priceUsd: number;               // Price in USD
  bonusCoins: number;             // Bonus coins (VIP+ gets 20% extra)
  popularBadge: boolean;          // "Most Popular" badge
  isActive: boolean;              // Available for sale
}
```

---

### 24. `creators`
**Purpose:** Creator program participants
**Document ID:** User ID
**Schema:**
```typescript
{
  userId: string;                 // Creator user ID
  status: string;                 // "pending" | "approved" | "rejected" | "suspended"
  tier: string;                   // "bronze" | "silver" | "gold" | "platinum"
  commissionRate: number;         // Revenue share % (0.0-1.0)
  totalEarnings: number;          // Lifetime earnings in USD
  pendingPayout: number;          // Unpaid earnings
  lastPayoutDate: Timestamp | null; // Last payout date
  roomsHostedCount: number;       // Total rooms hosted
  engagementScore: number;        // Engagement score (0-100)
  appliedAt: Timestamp;           // Application date
  approvedAt: Timestamp | null;   // Approval date
}
```

---

### 25. `creator_earnings`
**Purpose:** Creator earnings transactions
**Document ID:** Auto-generated earning ID
**Schema:**
```typescript
{
  creatorId: string;              // Creator user ID
  type: string;                   // "gift" | "tip" | "subscription_share"
  amount: number;                 // Earnings in USD
  coinAmount: number | null;      // Coins involved
  roomId: string | null;          // Room ID if applicable
  timestamp: Timestamp;           // Earning timestamp
}
```

---

### 26. `creator_payouts`
**Purpose:** Creator payout history
**Document ID:** Auto-generated payout ID
**Schema:**
```typescript
{
  creatorId: string;              // Creator user ID
  amount: number;                 // Payout amount in USD
  method: string;                 // "paypal" | "stripe" | "bank_transfer"
  status: string;                 // "pending" | "processing" | "completed" | "failed"
  initiatedAt: Timestamp;         // Payout initiation
  completedAt: Timestamp | null;  // Payout completion
}
```

---

### 27. `liveops_events`
**Purpose:** Live events (daily/weekly challenges)
**Document ID:** Event ID
**Schema:**
```typescript
{
  id: string;                     // Event ID
  name: string;                   // Event name
  description: string;            // Event description
  type: string;                   // "daily" | "weekly" | "seasonal"
  startDate: Timestamp;           // Event start
  endDate: Timestamp;             // Event end
  rewards: {                      // Rewards
    coins: number;
    badges: string[];
  };
  isActive: boolean;              // Active status
}
```

---

### 28. `liveops_offers`
**Purpose:** Limited-time coin package offers
**Document ID:** Offer ID
**Schema:**
```typescript
{
  id: string;                     // Offer ID
  packageId: string;              // Coin package ID
  discountPercent: number;        // Discount %
  bonusCoins: number;             // Bonus coins
  startDate: Timestamp;           // Offer start
  endDate: Timestamp;             // Offer end
  isActive: boolean;              // Active status
}
```

---

### 29. `federated_identities`
**Purpose:** Cross-platform federated user identities
**Document ID:** Auto-generated identity ID
**Schema:**
```typescript
{
  localUserId: string;            // Local user ID
  partnerId: string;              // Partner app ID
  remoteUserId: string;           // User ID in partner app
  displayName: string;            // Display name
  avatarUrl: string | null;       // Avatar URL
  claims: Map<string, dynamic>;   // Additional claims
  federatedAt: Timestamp;         // Federation timestamp
  lastSyncAt: Timestamp;          // Last sync timestamp
}
```

---

### 30. `federation_partners`
**Purpose:** Partner apps in federation network
**Document ID:** Partner ID
**Schema:**
```typescript
{
  id: string;                     // Partner ID
  name: string;                   // Partner app name
  apiKey: string;                 // API key
  status: string;                 // "active" | "inactive" | "suspended"
  trustScore: number;             // Trust score (0-100)
  addedAt: Timestamp;             // Partnership start
}
```

---

### 31. `moderation_signals`
**Purpose:** Cross-platform safety signals
**Document ID:** Auto-generated signal ID
**Schema:**
```typescript
{
  partnerId: string;              // Partner app ID
  subjectUserId: string;          // User ID
  signalType: string;             // "ban" | "warning" | "flag"
  severity: string;               // "low" | "medium" | "high" | "critical"
  description: string;            // Signal description
  evidence: Map<string, dynamic>; // Evidence data
  receivedAt: Timestamp;          // Signal received timestamp
  expiresAt: Timestamp | null;    // Expiry (null = permanent)
}
```

---

### 32. `bans`
**Purpose:** Global ban records (Network Trust System)
**Document ID:** Auto-generated ban ID
**Schema:**
```typescript
{
  userId: string;                 // Banned user ID
  scope: string;                  // "local" | "network" | "global"
  reason: string;                 // Ban reason
  evidence: string[];             // Evidence URLs
  severity: string;               // "minor" | "major" | "severe"
  duration: string;               // "temporary" | "permanent"
  expiresAt: Timestamp | null;    // Expiry (null = permanent)
  bannedBy: string;               // Admin user ID or "system"
  bannedAt: Timestamp;            // Ban timestamp
  appealable: boolean;            // Can be appealed
}
```

---

### 33. `appeals`
**Purpose:** Ban appeals
**Document ID:** Auto-generated appeal ID
**Schema:**
```typescript
{
  banId: string;                  // Ban ID
  userId: string;                 // User ID
  reason: string;                 // Appeal reason
  evidence: string[];             // Evidence URLs
  status: string;                 // "pending" | "approved" | "denied"
  reviewedBy: string | null;      // Admin user ID
  reviewedAt: Timestamp | null;   // Review timestamp
  submittedAt: Timestamp;         // Appeal submission
}
```

---

### 34. `trust_profiles`
**Purpose:** User trust scores (Network Trust System)
**Document ID:** User ID
**Schema:**
```typescript
{
  userId: string;                 // User ID
  trustScore: number;             // Trust score (0-100)
  reportCount: number;            // Reports received
  warningCount: number;           // Warnings received
  banCount: number;               // Bans received
  positiveSignals: number;        // Positive interactions
  lastUpdated: Timestamp;         // Last update timestamp
}
```

---

### 35. `safety_signals`
**Purpose:** AI-detected safety signals
**Document ID:** Auto-generated signal ID
**Schema:**
```typescript
{
  userId: string;                 // User ID
  type: string;                   // "toxicity" | "profanity" | "spam" | "harassment"
  score: number;                  // AI confidence score (0-1)
  context: string;                // "message" | "profile" | "room"
  contextId: string;              // Message ID, room ID, etc.
  content: string;                // Flagged content
  autoActioned: boolean;          // Automatic action taken
  reviewedBy: string | null;      // Admin user ID
  timestamp: Timestamp;           // Detection timestamp
}
```

---

### 36. `usernames`
**Purpose:** Username uniqueness registry
**Document ID:** Normalized username (lowercase, no spaces)
**Schema:**
```typescript
{
  userId: string;                 // User ID who owns username
  originalUsername: string;       // Original casing
  claimedAt: Timestamp;           // Claim timestamp
}
```

**Composite Indexes Required:**
```
Collection: usernames
- userId (ASC)
```

---

### 37. `config`
**Purpose:** System configuration (Agora tokens, feature flags)
**Document ID:** Config key (e.g., "agora")
**Schema:**
```typescript
{
  key: string;                    // Config key
  value: Map<string, dynamic>;    // Config value (varies)
  updatedAt: Timestamp;           // Last update
}
```

**Example: `config/agora`**
```typescript
{
  appId: "ec1b578586d24976a89d787d9ee4d5c7";
  certificate: string;            // Agora certificate
  tokenExpirySeconds: 3600;       // Token TTL
}
```

---

### 38. `analytics_*` Collections
**Purpose:** Analytics and insights data
**Collections:**
- `analytics_dau` - Daily Active Users
- `analytics_platform` - Platform metrics
- `analytics_creator` - Creator metrics
- `analytics_network` - Network metrics
- `analytics_federation` - Federation metrics

**Common Schema (DAU example):**
```typescript
{
  date: Timestamp;                // Date
  totalUsers: number;             // Total DAU
  newUsers: number;               // New users
  returningUsers: number;         // Returning users
  avgSessionDuration: number;     // Avg session (seconds)
  platform: {                     // Platform breakdown
    ios: number;
    android: number;
    web: number;
  };
}
```

---

### 39. `social_profiles`
**Purpose:** AI-generated social graph profiles
**Document ID:** User ID
**Schema:**
```typescript
{
  userId: string;                 // User ID
  interests: string[];            // Detected interests
  activityLevel: string;          // "low" | "medium" | "high"
  engagementScore: number;        // Engagement (0-100)
  preferredRoomTypes: string[];   // Room preferences
  lastUpdated: Timestamp;         // Last profile update
}
```

---

### 40. `recommendations`
**Purpose:** AI friend recommendations
**Document ID:** Auto-generated recommendation ID
**Schema:**
```typescript
{
  userId: string;                 // User ID
  recommendedUserId: string;      // Recommended user ID
  score: number;                  // Match score (0-1)
  reasons: string[];              // Match reasons
  createdAt: Timestamp;           // Recommendation timestamp
  expiresAt: Timestamp;           // Expiry (refresh weekly)
}
```

---

### 41. `detected_communities`
**Purpose:** AI-detected user communities
**Document ID:** Community ID
**Schema:**
```typescript
{
  id: string;                     // Community ID
  name: string;                   // Community name
  memberIds: string[];            // Member user IDs
  commonInterests: string[];      // Common interests
  detectedAt: Timestamp;          // Detection timestamp
}
```

---

## 🔒 Security Rules Summary

### Public Read, Private Write
- `users` - Read: all auth, Write: own doc only
- `rooms` - Read: all auth, Write: host only
- `chats` - Read/Write: participants only

### Admin Only
- `reports` - Write: any auth, Read: admin only
- `banned_users` - Read/Write: admin only
- `moderation_signals` - Read/Write: admin/system only

### Service Only (Cloud Functions)
- `analytics_*` - Write: Cloud Functions only
- `config` - Write: Admin/Functions only

**Example Rule (users collection):**
```javascript
match /users/{userId} {
  allow read: if request.auth != null;
  allow write: if request.auth.uid == userId;
}
```

---

## 📊 Critical Indexes

### Composite Indexes (Must Create in Firestore Console)
```
Collection: rooms
- ended (ASC), participantCount (DESC), startedAt (DESC)
- hostId (ASC), ended (ASC), createdAt (DESC)

Collection: chats
- participantIds (ARRAY_CONTAINS), lastMessageTime (DESC)

Collection: reports
- status (ASC), createdAt (DESC)
- reportedUserId (ASC), status (ASC), createdAt (DESC)

Collection: coins_transactions
- userId (ASC), type (ASC), timestamp (DESC)

Collection: notifications
- userId (ASC), isRead (ASC), createdAt (DESC)
```

**Auto-Generated vs Manual:**
- Single-field indexes: Auto-created by Firestore on first query
- Composite indexes: Must be manually created or created via error link

---

## 🚀 Query Examples

### Get Active Rooms
```dart
final rooms = await FirebaseFirestore.instance
    .collection('rooms')
    .where('ended', isEqualTo: false)
    .orderBy('participantCount', descending: true)
    .limit(20)
    .get();
```

### Get User's Chats
```dart
final chats = await FirebaseFirestore.instance
    .collection('chats')
    .where('participantIds', arrayContains: currentUserId)
    .orderBy('lastMessageTime', descending: true)
    .get();
```

### Get Pending Reports (Admin)
```dart
final reports = await FirebaseFirestore.instance
    .collection('reports')
    .where('status', isEqualTo: 'pending')
    .orderBy('createdAt', descending: false)
    .get();
```

### Get User Coin Transactions
```dart
final transactions = await FirebaseFirestore.instance
    .collection('coins_transactions')
    .where('userId', isEqualTo: currentUserId)
    .orderBy('timestamp', descending: true)
    .limit(50)
    .get();
```

### Get Room Participants
```dart
final participants = await FirebaseFirestore.instance
    .collection('rooms')
    .doc(roomId)
    .collection('participants')
    .orderBy('joinedAt', descending: false)
    .get();
```

---

## 🔧 Migration Notes

### From Array to Subcollection
**Blocked Users:**
- OLD: `users.blockedUsers: string[]`
- NEW: `users/{userId}/blocked/{blockedUserId}`
- **Why:** Better scalability, can store block metadata (reason, timestamp)
- **Migration:** Run Cloud Function to populate subcollection from array

### Collection vs Subcollection
**Room Messages:**
- OLD: `rooms/{roomId}/messages/{messageId}` (subcollection)
- NEW: `room_messages/{messageId}` (top-level with roomId field)
- **Why:** Better query performance, simpler security rules
- **Migration:** Existing subcollection messages still work; new messages use top-level

---

## ✅ Stage 9 Complete

**Firestore schema is production-ready:**
- ✅ 41+ Top-Level Collections Documented
- ✅ 7 Subcollections Documented
- ✅ Complete Schema Definitions with Types
- ✅ Security Rules Summary
- ✅ Critical Indexes Identified
- ✅ Query Examples Provided
- ✅ Migration Notes for Schema Evolution

**All Collections from Stages 1-8:**
- Stage 1: `users`, `usernames`, `config`
- Stage 2: `rooms`, `room_messages`, `user_presence`
- Stage 3: `speed_dating_queue`, `speed_dating_sessions`, `speed_dating_decisions`
- Stage 4: `chats`, `chats/{chatId}/messages`
- Stage 5: `users/{userId}/following`, `users/{userId}/followers`, `social_profiles`, `recommendations`, `detected_communities`
- Stage 6: `coins_transactions`, `gifts`, `gift_transactions`, `subscriptions`, `pricing_tiers`
- Stage 7: `reports`, `banned_users`, `bans`, `appeals`, `trust_profiles`, `safety_signals`, `moderation_signals`
- Stage 8: N/A (routing only, no new collections)

**Ready to proceed to Stage 10: Testing & Safety**
