# Mix & Mingle - Dependency Map & Architecture

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        PRESENTATION                          │
│  ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌───────────┐  │
│  │   Auth    │ │   Home    │ │  Profile  │ │   Chat    │  │
│  │  Screens  │ │  Screens  │ │  Screens  │ │  Screens  │  │
│  └─────┬─────┘ └─────┬─────┘ └─────┬─────┘ └─────┬─────┘  │
│        │             │             │             │          │
└────────┼─────────────┼─────────────┼─────────────┼──────────┘
         │             │             │             │
┌────────┼─────────────┼─────────────┼─────────────┼──────────┐
│        │    RIVERPOD PROVIDERS (STATE MANAGEMENT)│          │
│        ▼             ▼             ▼             ▼          │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  authServiceProvider   │  profileControllerProvider │   │
│  │  agoraServiceProvider  │  chatControllerProvider    │   │
│  │  messagingProvider     │  eventsControllerProvider  │   │
│  └─────────────────────────────────────────────────────┘   │
└───────────────────────┬─────────────────────────────────────┘
                        │
┌───────────────────────┼─────────────────────────────────────┐
│                       │        SERVICES LAYER                │
│                       ▼                                      │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐       │
│  │ AuthService  │ │ ChatService  │ │ RoomService  │       │
│  └──────┬───────┘ └──────┬───────┘ └──────┬───────┘       │
│         │                │                │                 │
│         ▼                ▼                ▼                 │
│  ┌──────────────────────────────────────────────────┐      │
│  │          FirestoreService (Core Data Layer)      │      │
│  └──────────────────────────────────────────────────┘      │
└──────────────────────┬───────────────────────────────────── │
                       │
┌──────────────────────┼───────────────────────────────────── │
│                      │      DATA LAYER                      │
│                      ▼                                      │
│  ┌────────────────────────────────────────────────────┐    │
│  │              FIREBASE BACKEND                      │    │
│  │  • Firestore (Database)                            │    │
│  │  • Authentication                                  │    │
│  │  • Cloud Functions                                 │    │
│  │  • Cloud Storage                                   │    │
│  │  • Firebase Analytics                              │    │
│  └────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

---

## 📱 FEATURE DEPENDENCIES

### Authentication Flow
```
LoginPage/SignupPage
    ↓
AuthService
    ↓
FirebaseAuth
    ↓
AuthGate (wrapper for protected routes)
    ↓
Check Profile Completion
    ↓
HomePage or CreateProfilePage
```

### Room/Video Chat Flow
```
HomePage → BrowseRoomsPage/RoomDiscoveryPage
    ↓
Select Room
    ↓
RoomPage
    ├─→ AgoraVideoService (video/audio)
    ├─→ MessagingService (chat messages)
    ├─→ PresenceService (user status)
    └─→ CameraPermissionService (permissions)
```

### Speed Dating Flow
```
SpeedDatingPage
    ↓
SpeedDatingService
    ↓
SpeedDatingLobbyPage
    ↓
Find Partner (FirestoreService)
    ↓
Create Session
    ↓
SpeedDatingDecisionPage
    ↓
Record Decision
    ↓
Create Match (if mutual)
```

### Messaging Flow
```
MessagesPage (list conversations)
    ↓
ChatScreen (direct message)
    ↓
MessagingService
    ├─→ Send Message
    ├─→ Mark as Read
    ├─→ Handle Reactions
    └─→ File Sharing (FileShareService)
```

---

## 🔧 SERVICE DEPENDENCIES

### Core Services

**AuthService**
- Dependencies: FirebaseAuth, FirestoreService
- Used by: All authenticated features
- Providers: authServiceProvider

**FirestoreService**
- Dependencies: Cloud Firestore
- Used by: Nearly all services
- Providers: firestoreServiceProvider
- Status: ✅ Fixed with error handling

**ProfileService**
- Dependencies: FirestoreService, AuthService
- Used by: ProfilePage, EditProfilePage, UserProfilePage
- Controllers: profileControllerProvider

### Communication Services

**AgoraVideoService**
- Dependencies: Agora RTC SDK, Cloud Functions (token generation)
- Used by: RoomPage
- Providers: agoraVideoServiceProvider
- Features: Video/audio calling, muting, speaker management

**MessagingService**
- Dependencies: FirestoreService, StorageService (attachments)
- Used by: ChatScreen, MessagesPage
- Providers: messagingServiceProvider
- Features: Direct messages, read receipts, reactions

**ChatService**
- Dependencies: FirestoreService
- Used by: ChatPage, ChatListPage, ChatRoomPage
- Providers: chatServiceProvider
- Status: ✅ Best implemented service (comprehensive error handling)

**PresenceService**
- Dependencies: FirestoreService, AuthService
- Used by: All pages (via AuthGate)
- Providers: presenceServiceProvider
- Features: Online/offline status, last seen

**TypingService**
- Dependencies: FirestoreService
- Used by: Chat interfaces
- Providers: typingServiceProvider

### Social Features

**SocialService**
- Dependencies: FirestoreService
- Used by: ProfilePage, DiscoverUsersPage
- Features: Following, followers, blocking

**MatchService**
- Dependencies: FirestoreService, Matching algorithm
- Used by: MatchesPage, DiscoverUsersPage
- Providers: matchServiceProvider

**SpeedDatingService**
- Dependencies: FirestoreService, AgoraVideoService
- Used by: SpeedDatingPage, SpeedDatingLobbyPage
- Providers: speedDatingServiceProvider

### Room Management

**RoomService**
- Dependencies: FirestoreService, AgoraVideoService
- Used by: RoomPage, BrowseRoomsPage, GoLivePage
- Providers: roomServiceProvider
- Status: ⚠️ Needs error handling

**RoomDiscoveryService**
- Dependencies: FirestoreService, ModerationService
- Used by: RoomDiscoveryPage
- Providers: roomDiscoveryServiceProvider

### Gamification & Economy

**GamificationService**
- Dependencies: FirestoreService
- Used by: AchievementsPage, LeaderboardsPage, HomePage
- Providers: gamificationServiceProvider
- Features: Achievements, levels, streaks, activities

**CoinEconomyService**
- Dependencies: FirestoreService, PaymentService
- Used by: CoinPurchasePage, TippingService, GiftService
- Providers: coinEconomyServiceProvider

**SubscriptionService**
- Dependencies: FirestoreService, PaymentService
- Used by: SettingsPage, Premium features
- Providers: subscriptionServiceProvider

**TippingService**
- Dependencies: CoinEconomyService, FirestoreService
- Used by: RoomPage, ProfilePage
- Providers: tippingServiceProvider

### Content & Safety

**ModerationService**
- Dependencies: FirestoreService
- Used by: RoomPage, ChatScreen, AdminDashboardPage
- Providers: moderationServiceProvider
- Features: Reporting, blocking, banning

**CameraPermissionService**
- Dependencies: FirestoreService
- Used by: RoomPage, CameraPermissionsPage
- Features: Request/grant camera viewing permissions

### Infrastructure

**StorageService**
- Dependencies: Firebase Cloud Storage
- Used by: ProfileService, MessagingService, EventsService
- Providers: storageServiceProvider
- Features: Image/file uploads

**AnalyticsService**
- Dependencies: Firebase Analytics
- Used by: All major user actions
- Providers: analyticsServiceProvider

**NotificationService**
- Dependencies: Firebase Cloud Messaging, FirestoreService
- Used by: All features that generate notifications
- Providers: notificationServiceProvider

**TokenService**
- Dependencies: Cloud Functions
- Used by: AgoraVideoService
- Features: Generate Agora tokens

---

## 📂 MODEL DEPENDENCIES

### Core Models

**User** (`/lib/shared/models/user.dart`)
- Used by: All user-facing features
- Fields: uid, email, displayName, photoURL, bio, etc.
- Serialization: ✅ fromDocument, toMap

**Room** (`/lib/shared/models/room.dart`)
- Used by: Room features, video calling
- Fields: id, title, hostId, participants, roomType, speakers, listeners
- Serialization: ✅ fromMap, toMap
- Note: Duplicate exists in `/lib/models/room.dart` (should be deleted)

**Message** (`/lib/shared/models/message.dart`)
- Used by: Room chat, messaging
- Fields: id, senderId, text, timestamp, reactions
- Serialization: ✅ fromMap, toMap

**DirectMessage** (`/lib/shared/models/direct_message.dart`)
- Used by: One-on-one chats
- Fields: id, senderId, recipientId, content, sentAt
- Serialization: ✅ fromMap, toMap

### Feature-Specific Models

**Event** (`/lib/shared/models/event.dart`)
- Used by: EventsPage, EventDetailsPage, CreateEventPage
- Issues: ⚠️ Uses DateTime.parse instead of Timestamp handling

**SpeedDating** models
- `speed_dating.dart` - Main event data
- `speed_dating_round.dart` - Individual rounds
- `speed_dating_result.dart` - Match results

**Notification** (`/lib/shared/models/notification.dart`)
- Used by: NotificationsPage
- Issues: ⚠️ Uses enum.index instead of enum.name

**Achievement** (`/lib/shared/models/achievement.dart`)
- Used by: GamificationService, AchievementsPage
- Serialization: ✅ fromMap, toMap

**Subscription** (`/lib/shared/models/subscription.dart`)
- Used by: SubscriptionService
- Serialization: ✅ fromMap, toMap

---

## 🎯 PROVIDER USAGE PATTERNS

### Provider Hierarchy

```dart
ProviderScope (root)
  ├─ authServiceProvider
  ├─ firestoreServiceProvider
  ├─ agoraVideoServiceProvider (with onDispose)
  │
  ├─ State Notifiers
  │  ├─ themeModeProvider
  │  ├─ currentUserProvider
  │  └─ userProfileProvider
  │
  ├─ Stream Providers
  │  ├─ roomsStreamProvider
  │  ├─ messagesStreamProvider
  │  └─ notificationsStreamProvider
  │
  └─ Future Providers
     ├─ matchesProvider
     └─ eventsProvider
```

### Best Practices Observed

✅ **Good:**
- All service providers properly scoped
- AgoraVideoService has disposal logic
- StreamProviders used for real-time data
- FutureProviders for one-time data fetching

⚠️ **Needs Improvement:**
- Some pages still use StatefulWidget instead of ConsumerStatefulWidget
- Inconsistent provider usage across features
- Some direct service instantiation instead of provider injection

---

## 🔀 NAVIGATION FLOW

### Route Structure

```
/ (SplashPage)
├─ /landing (LandingPage)
├─ /login (LoginPage)
├─ /signup (SignupPage)
├─ /forgot-password (ForgotPasswordPage)
│
└─ AuthGate Protected Routes:
   ├─ /home (HomePage)
   │  ├─ /browse-rooms (BrowseRoomsPage)
   │  ├─ /discover-rooms (RoomDiscoveryPage)
   │  ├─ /go-live (GoLivePage)
   │  └─ /room (RoomPage) [requires Room argument]
   │
   ├─ /profile (ProfilePage)
   │  └─ /profile/edit (EditProfilePage)
   │
   ├─ /chats (ChatListPage)
   │  └─ /chat (ChatPage) [requires chatId]
   │
   ├─ /messages (MessagesPage)
   │  └─ /chat-screen (ChatScreen) [requires recipientId]
   │
   ├─ /events (EventsPage)
   │  ├─ /events/create (CreateEventPage)
   │  └─ /events/details (EventDetailsPage) [requires Event]
   │
   ├─ /speed-dating (SpeedDatingPage)
   │  ├─ /speed-dating-lobby (SpeedDatingLobbyPage)
   │  └─ /speed-dating-decision (SpeedDatingDecisionPage)
   │
   ├─ /matches (MatchesPage)
   ├─ /discover-users (DiscoverUsersPage)
   ├─ /match-preferences (MatchPreferencesPage)
   │
   ├─ /notifications (NotificationsPage)
   │
   ├─ /buy-coins (CoinPurchasePage)
   ├─ /withdrawal (WithdrawalPage)
   ├─ /withdrawal-history (WithdrawalHistoryPage)
   │
   ├─ /leaderboards (LeaderboardsPage)
   ├─ /achievements (AchievementsPage)
   │
   ├─ /settings (SettingsPage)
   │  ├─ /settings/privacy (PrivacySettingsPage)
   │  └─ /settings/camera-permissions (CameraPermissionsPage)
   │
   └─ /admin (AdminDashboardPage)
```

---

## 🔐 SECURITY LAYER

### Firestore Rules Structure

```
/users/{uid}
  ├─ read: authenticated + (owner OR completed profile)
  ├─ create: authenticated + owner + validation
  ├─ update: owner only
  └─ delete: false

/usernames/{username}
  ├─ read: public (for availability check)
  ├─ create: authenticated + validation
  ├─ update: false
  └─ delete: owner only

/camera_permissions/{permissionId}
  ├─ read: owner OR requester
  ├─ create: authenticated requester
  ├─ update: owner only (grant/deny)
  └─ delete: false

/rooms/{roomId}
  ├─ read: authenticated
  ├─ create: authenticated + validation
  ├─ update: room member OR creator
  └─ delete: creator only

/chats/{chatId}
  ├─ read: chat member
  ├─ create: authenticated
  ├─ update: chat member
  └─ delete: false
```

---

## 📊 INTEGRATION POINTS

### External Services

1. **Firebase Suite**
   - Authentication
   - Firestore Database
   - Cloud Storage
   - Cloud Functions
   - Analytics
   - Cloud Messaging (FCM)

2. **Agora RTC**
   - Video calling
   - Audio calling
   - Screen sharing
   - Token authentication via Cloud Functions

3. **Payment Integration** (via PaymentService)
   - Coin purchases
   - Subscriptions
   - Withdrawals

---

## 🚀 DEPLOYMENT PIPELINE

```
Developer
  ↓
Git Commit
  ↓
GitHub Actions (CI/CD)
  ├─ Run Tests
  ├─ Build Web (Flutter)
  ├─ Build Android
  ├─ Build iOS
  └─ Deploy to Firebase Hosting
```

---

## 📝 NOTES

- All routes now registered and protected with AuthGate ✅
- FirestoreService fully error-handled ✅
- Missing error handling in room_service.dart (critical)
- Model timestamp inconsistencies need addressing
- Consider creating barrel export files for cleaner imports
- Some duplicate page files should be removed

---

**Map Version:** 1.0
**Last Updated:** January 24, 2026
**Status:** Production Ready (with noted improvements)
