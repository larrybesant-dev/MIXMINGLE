# Mix & Mingle - Firestore Security Architecture

**Visual Reference** | Version 2.0 | January 24, 2026

---

## 🏗️ Security Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     CLIENT APPLICATION                           │
│  (Flutter Web App - Authenticated via Firebase Auth)            │
└───────────────────────┬─────────────────────────────────────────┘
                        │
                        │ All requests include auth token
                        │
                        ▼
┌─────────────────────────────────────────────────────────────────┐
│                   FIRESTORE SECURITY RULES                       │
│                     (firestore.rules v2.0)                       │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐   │
│  │  Helper Functions (17 total)                            │   │
│  │  • isAuthenticated()  • isAdmin()  • isPremiumUser()   │   │
│  │  • isOwner()  • isMatchedWith()  • hasNotBlocked()     │   │
│  └────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐   │
│  │  Access Control Checks                                  │   │
│  │  1. Authentication ────► User has valid token?         │   │
│  │  2. Authorization ─────► User has permission?          │   │
│  │  3. Validation ────────► Data meets requirements?      │   │
│  └────────────────────────────────────────────────────────┘   │
└───────────────────────┬─────────────────────────────────────────┘
                        │
                        │ ✅ Allow / ❌ Deny
                        │
                        ▼
┌─────────────────────────────────────────────────────────────────┐
│                    FIRESTORE DATABASE                            │
│                    (20+ Collections)                             │
└─────────────────────────────────────────────────────────────────┘
```

---

## 👥 User Access Hierarchy

```
                    ┌─────────────┐
                    │   ADMIN     │ role: 'admin'
                    │   🔑 Full   │
                    │   Access    │
                    └──────┬──────┘
                           │
                ┌──────────┴──────────┐
                │                     │
         ┌──────▼──────┐      ┌──────▼──────┐
         │  MODERATOR  │      │  ADMIN OPS  │
         │  🛡️ Moderate │      │  • Events   │
         │   Content   │      │  • Reports  │
         └─────────────┘      │  • Payouts  │
                              └─────────────┘

    ┌───────────────────────────────────────────┐
    │           AUTHENTICATED USERS             │
    └───────────────┬───────────────────────────┘
                    │
        ┌───────────┼───────────┐
        │                       │
  ┌─────▼─────┐         ┌──────▼──────┐
  │  PREMIUM  │         │    FREE     │
  │  💎 Extra │         │  👤 Basic   │
  │  Features │         │   Access    │
  └───────────┘         └─────────────┘
  • DM anyone           • Own data only
  • Larger uploads      • Matched DMs
  • Enhanced limits     • Standard limits
```

---

## 🔐 Collection Access Patterns

### Pattern 1: Owner-Only Access

```
┌──────────┐    Ownership Check    ┌──────────┐
│  USER A  │ ────────────────────► │  Doc A   │ ✅ Allow
│  uid: 1  │                       │ uid: 1   │
└──────────┘                       └──────────┘

┌──────────┐    Ownership Check    ┌──────────┐
│  USER B  │ ────────────────────► │  Doc A   │ ❌ Deny
│  uid: 2  │                       │ uid: 1   │
└──────────┘                       └──────────┘

Collections: users, user_profiles, user_presence,
             notifications, activities, subscriptions
```

### Pattern 2: Match-Based Access

```
┌──────────┐                       ┌──────────┐
│  USER A  │◄──────── Match ──────►│  USER B  │
│  uid: 1  │                       │  uid: 2  │
└────┬─────┘                       └─────┬────┘
     │                                   │
     │     ✅ Can send DM to each other  │
     │                                   │
     └────────────────┬──────────────────┘
                      │
                      ▼
              ┌───────────────┐
              │ Direct Message│
              │ sender: 1     │
              │ receiver: 2   │
              └───────────────┘

Collections: direct_messages, chat_rooms
```

### Pattern 3: Participant-Based Access

```
                ┌────────────────┐
                │   ROOM/EVENT   │
                │   id: room123  │
                └────────┬───────┘
                         │
         ┌───────────────┼───────────────┐
         │               │               │
    ┌────▼────┐     ┌────▼────┐    ┌────▼────┐
    │ USER A  │     │ USER B  │    │ USER C  │
    │ uid: 1  │     │ uid: 2  │    │ uid: 3  │
    └─────────┘     └─────────┘    └─────────┘
         │               │               │
         │  participantIds: [1, 2, 3]   │
         │                               │
         └───────────┬───────────────────┘
                     │
                     ▼
              ✅ All can read/write

Collections: rooms, events, speed_dating_sessions
```

### Pattern 4: Capacity-Enforced Access

```
┌─────────────────────────────────────────┐
│            EVENT                        │
│  maxAttendees: 10                       │
│  attendees: [1, 2, 3, 4, 5, 6, 7, 8, 9]│
│  Current: 9/10                          │
└────────────────┬────────────────────────┘
                 │
         ┌───────┴───────┐
         │               │
    ┌────▼────┐     ┌────▼────┐
    │ USER 10 │     │ USER 11 │
    └────┬────┘     └────┬────┘
         │               │
         ▼               ▼
    ✅ Allowed      ❌ Denied
    (9 < 10)       (10 >= 10)

Collections: events
```

---

## 🔄 Request Flow Diagram

```
┌──────────────┐
│ Client App   │
└──────┬───────┘
       │
       │ 1. User attempts operation
       ▼
┌──────────────────────────────────┐
│ Firebase Authentication          │
│ Validates: Auth token valid?     │
└──────┬───────────────────────────┘
       │
       │ 2. ✅ Valid token
       ▼
┌──────────────────────────────────┐
│ Firestore Security Rules         │
│                                  │
│ Step 1: Check isAuthenticated()  │
│         ├─ ❌ Deny ──────────────┤─► 403 Error
│         └─ ✅ Continue           │
│                                  │
│ Step 2: Check ownership/role     │
│         ├─ isOwner()?            │
│         ├─ isAdmin()?            │
│         ├─ isMatchedWith()?      │
│         └─ hasPermission?        │
│         ├─ ❌ Deny ──────────────┤─► 403 Error
│         └─ ✅ Continue           │
│                                  │
│ Step 3: Validate data            │
│         ├─ Required fields?      │
│         ├─ Valid types?          │
│         ├─ Within limits?        │
│         └─ Meets constraints?    │
│         ├─ ❌ Deny ──────────────┤─► 403 Error
│         └─ ✅ Allow              │
└──────┬───────────────────────────┘
       │
       │ 3. ✅ Operation allowed
       ▼
┌──────────────────────────────────┐
│ Firestore Database               │
│ Executes operation               │
└──────┬───────────────────────────┘
       │
       │ 4. Return result
       ▼
┌──────────────┐
│ Client App   │
└──────────────┘
```

---

## 🛡️ Security Layers

```
┌─────────────────────────────────────────────────────────┐
│  Layer 1: Authentication                                │
│  ✅ Firebase Auth validates user identity               │
│  ❌ Unauthenticated users → Blocked at this layer      │
└─────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│  Layer 2: Authorization (Role-Based)                    │
│  • Admin role → Full access                            │
│  • Moderator role → Content moderation                 │
│  • Premium tier → Enhanced features                    │
│  • Standard user → Basic access                        │
└─────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│  Layer 3: Ownership Verification                        │
│  • Can only modify own documents                       │
│  • isOwner(userId) check enforced                      │
│  • Cross-user access blocked                           │
└─────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│  Layer 4: Relationship Verification                     │
│  • Match required for DMs (unless premium)             │
│  • Block detection prevents contact                    │
│  • Participant verification for rooms/events           │
└─────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│  Layer 5: Data Validation                               │
│  • Required fields present                             │
│  • Valid data types                                    │
│  • Within size/count limits                            │
│  • Business rules enforced                             │
└─────────────────────────────────────────────────────────┘
                         │
                         ▼
                   ✅ ALLOW ACCESS
```

---

## 💬 Message Flow Security

```
┌──────────┐                               ┌──────────┐
│  USER A  │                               │  USER B  │
└────┬─────┘                               └─────┬────┘
     │                                           │
     │ 1. Attempt to send message                │
     │                                           │
     ▼                                           │
┌─────────────────────────────────────────┐     │
│ Security Checks:                        │     │
│ ✅ A is authenticated                   │     │
│ ✅ A & B are matched OR A is premium    │     │
│ ✅ A has not blocked B                  │     │
│ ✅ B has not blocked A                  │     │
│ ✅ Message content valid                │     │
│ ✅ Message length < 2000 chars          │     │
└─────────────────┬───────────────────────┘     │
                  │                             │
                  ▼                             │
         ✅ Message created                      │
                  │                             │
                  └─────────────────────────────┤
                                                │
                                  2. Notification sent
                                                │
                                                ▼
```

---

## 🎫 Event Registration Flow

```
┌────────────────────────────────────────────┐
│  EVENT                                     │
│  maxAttendees: 100                         │
│  attendees: [1, 2, 3, ..., 98]            │
│  Current: 98/100                           │
└──────────────────┬─────────────────────────┘
                   │
         ┌─────────┼─────────┐
         │         │         │
    ┌────▼────┐   │    ┌────▼────┐
    │ USER A  │   │    │ USER B  │
    └────┬────┘   │    └────┬────┘
         │        │         │
         ▼        │         ▼
    ┌─────────┐  │    ┌─────────┐
    │ Check   │  │    │ Check   │
    │ Space   │  │    │ Space   │
    └────┬────┘  │    └────┬────┘
         │       │         │
         ▼       │         ▼
    98 < 100     │    99 < 100
    ✅ Allow     │    ✅ Allow
         │       │         │
         └───────┼─────────┘
                 │
                 ▼
    ┌──────────────────────┐
    │ NOW: 100/100         │
    │ FULL EVENT           │
    └──────────────────────┘
                 │
                 ▼
          ┌──────────┐
          │ USER C   │
          └─────┬────┘
                │
                ▼
          100 >= 100
          ❌ Deny
```

---

## 🔐 Block Detection System

```
┌──────────┐                    ┌──────────┐
│  USER A  │                    │  USER B  │
│  uid: 1  │                    │  uid: 2  │
└────┬─────┘                    └─────┬────┘
     │                                │
     │ Blocks User B                  │
     ▼                                │
┌──────────────────────────────┐     │
│ /blocks/1_2                  │     │
│ blockerId: 1                 │     │
│ blockedUserId: 2             │     │
└──────────────────────────────┘     │
     │                                │
     │                                │
     │ A attempts to send message to B│
     ▼                                │
┌──────────────────────────────┐     │
│ Security Rule Check:         │     │
│ hasNotBlockedUser(2)?        │     │
│ → exists(/blocks/1_2)?       │     │
│ → ✅ Yes, block exists       │     │
│ → ❌ DENY message            │     │
└──────────────────────────────┘     │
                                     │
     ┌───────────────────────────────┘
     │
     │ B attempts to send message to A
     ▼
┌──────────────────────────────┐
│ Security Rule Check:         │
│ isNotBlocked()?              │
│ → exists(/blocks/1_2)?       │
│ → ✅ Yes, block exists       │
│ → ❌ DENY message            │
└──────────────────────────────┘
```

---

## 📊 Data Validation Pipeline

```
┌─────────────────────────────────────────────────────────┐
│  Incoming Document Data                                 │
│  { field1: value1, field2: value2, ... }               │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌────────────────────────────────────────────────────┐
│  Validation Step 1: Required Fields                │
│  ✅ All required fields present?                   │
│  ❌ Missing field → Reject                         │
└────────────────────┬───────────────────────────────┘
                     ▼
┌────────────────────────────────────────────────────┐
│  Validation Step 2: Data Types                     │
│  ✅ All fields correct type?                       │
│  ❌ Wrong type → Reject                            │
└────────────────────┬───────────────────────────────┘
                     ▼
┌────────────────────────────────────────────────────┐
│  Validation Step 3: Value Constraints              │
│  • Strings: min/max length                         │
│  • Numbers: min/max value                          │
│  • Arrays: size limits                             │
│  • Enums: allowed values                           │
│  ❌ Violation → Reject                             │
└────────────────────┬───────────────────────────────┘
                     ▼
┌────────────────────────────────────────────────────┐
│  Validation Step 4: Business Rules                 │
│  • Capacity limits                                 │
│  • Relationship requirements                       │
│  • Time constraints                                │
│  • Ownership rules                                 │
│  ❌ Violation → Reject                             │
└────────────────────┬───────────────────────────────┘
                     ▼
              ✅ VALIDATION PASSED
                     │
                     ▼
┌────────────────────────────────────────────────────┐
│  Write to Firestore Database                       │
└────────────────────────────────────────────────────┘
```

---

## 📈 Security Metrics Dashboard

```
┌───────────────────────────────────────────────────┐
│  Security Monitoring                              │
├───────────────────────────────────────────────────┤
│                                                   │
│  Permission Denials by Collection:                │
│  ████████░░ users: 80%                           │
│  ██████░░░░ direct_messages: 60%                 │
│  ████░░░░░░ events: 40%                          │
│  ██░░░░░░░░ rooms: 20%                           │
│                                                   │
│  Top Denial Reasons:                              │
│  1. Not authenticated (35%)                       │
│  2. Not matched for DM (25%)                      │
│  3. Not room member (20%)                         │
│  4. Event at capacity (10%)                       │
│  5. Missing required fields (10%)                 │
│                                                   │
│  Admin Operations (Last 24h):                     │
│  • Events created: 12                             │
│  • Reports reviewed: 8                            │
│  • Users moderated: 3                             │
│                                                   │
└───────────────────────────────────────────────────┘
```

---

## 🎯 Security Implementation Checklist

```
✅ Authentication Layer
   ├─ ✅ Firebase Auth integration
   ├─ ✅ Token validation
   └─ ✅ Session management

✅ Authorization Layer
   ├─ ✅ Role-based access (Admin, Moderator)
   ├─ ✅ Tier-based features (Premium, Free)
   └─ ✅ Ownership verification

✅ Relationship Security
   ├─ ✅ Match-based DM access
   ├─ ✅ Block detection system
   └─ ✅ Participant verification

✅ Data Validation
   ├─ ✅ Required fields enforcement
   ├─ ✅ Type checking
   ├─ ✅ Size/length limits
   └─ ✅ Enum validation

✅ Business Rules
   ├─ ✅ Event capacity enforcement
   ├─ ✅ Speed dating constraints
   ├─ ✅ Media upload limits
   └─ ✅ Coin balance protection

✅ Documentation
   ├─ ✅ Security rules file
   ├─ ✅ Deployment guide
   ├─ ✅ Testing procedures
   └─ ✅ Troubleshooting guide
```

---

**Architecture Status:** ✅ Complete
**Security Level:** 🔒 Enterprise-Grade
**Last Updated:** January 24, 2026
