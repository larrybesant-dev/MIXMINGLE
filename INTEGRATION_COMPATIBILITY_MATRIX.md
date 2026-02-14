# 🔗 INTEGRATION COMPATIBILITY MATRIX
**Quick Reference for Frontend-Backend Alignment**

Generated: January 31, 2026

---

## LAYER-BY-LAYER FIELD VERIFICATION

### LAYER 1: Frontend Room Model
**File:** `lib/shared/models/room.dart` (Lines 1-371)

**Constructor Required Parameters:**
```
✅ id (String)
✅ title (String)
✅ description (String)
✅ hostId (String)
✅ tags (List<String>)
✅ category (String)
✅ createdAt (DateTime)
✅ isLive (bool)
✅ viewerCount (int)
```

**Constructor Optional Parameters (58 total):**
All other fields have defaults - see full audit for complete list

---

### LAYER 2: Firestore Storage
**File:** `firestore.rules` (Lines 1-337)

**Validation on CREATE:**
```firerules
✅ title - String, 3-100 characters required
✅ All other fields - No validation, stored as-is
```

**Security Rules Check These Fields:**
```
✅ hostId - Used in update/delete authorization
✅ moderators - Used in update/delete authorization (⚠️ DOESN'T check admins!)
⚠️ privacy - Used indirectly in tests
```

**Subcollections:**
```
✅ /rooms/{roomId}/participants/{userId} - Join/leave tracking
✅ /rooms/{roomId}/messages/{msgId} - Room chat
✅ /rooms/{roomId}/events/{eventId} - Activity logs
✅ /rooms/{roomId}/analytics_events/{eventId} - Analytics
```

---

### LAYER 3: Cloud Functions
**Files:**
- `functions/index.js` (HTTP endpoint)
- `functions/lib/index.js` (Callable function)

#### HTTP Function: `getAgoraToken`
**Expects Query/Body Parameters:**
```javascript
✅ channelName (string) - Room ID
✅ uid (number) - User ID
⚠️ role (string, optional) - broadcaster|audience
```

**Loads from Firestore:**
```javascript
✅ roomData.privacy - Checked: 'private' check
✅ roomData.isPrivate - Checked: alternative privacy
✅ roomData.hostId - Checked: access verification
```

#### Callable Function: `generateAgoraToken`
**Expects Data:**
```typescript
✅ roomId (string)
✅ userId (string)
```

**REQUIRES in Firestore - CRITICAL:**
```typescript
✅ isLive (boolean) - MUST be true
✅ status (string) - MUST be 'live'
✅ bannedUsers (array) - MUST include user check
✅ kickedUsers (array) - MUST include user check
✅ hostId (string) - MUST be present
✅ moderators OR admins (array) - For role determination
✅ speakers (array) - For broadcaster role
```

**🚨 IF MISSING:** Returns error "Room has ended"

---

### LAYER 4: VoiceRoomPage
**File:** `lib/features/room/screens/voice_room_page.dart` (Lines 1-2723)

**Directly Accesses:**
```dart
✅ room.id (12x) - Essential for all operations
✅ room.turnBased (1x) - Speaking mode flag
✅ room.turnDurationSeconds (1x) - Speaker timeout
```

**Indirectly Uses (via RoomService):**
```dart
✅ All participant lists (speakers, listeners, participants)
✅ bannedUsers - Verified before joining
✅ All state tracking fields
```

**Optional (nice-to-have but not required):**
```dart
❌ title - Not displayed
❌ description - Not displayed
❌ hostName - Not displayed
❌ viewerCount - Not displayed
❌ category - Not displayed
❌ tags - Not displayed
```

---

## CRITICAL FIELD FLOW ANALYSIS

### Path 1: Room Creation → Storage → Token Generation

```
CreateRoomPageComplete
  ↓
  Input: title, description, category, roomType, isPrivate, tags
  ↓
  RoomManagerService.createRoom()
    ↓
    Creates Room object with:
    ✅ isLive: true
    ✅ status: 'live'
    ✅ moderators: [hostId]
    ✅ admins: [hostId]
    ✅ bannedUsers: []
    ✅ speakers: [hostId]
    ✓ (All fields present)
    ↓
  room.toJson()
    ↓
  _firestore.collection('rooms').doc(roomId).set(roomData)
    ↓
  ✅ Firestore Stored Successfully
    ↓
  VoiceRoomPage receives room object
    ↓
  agoraService.joinRoom(room.id)
    ↓
  generateAgoraToken(roomId, userId)
    ↓
  Cloud Function queries Firestore for room
    ↓
    Retrieves: isLive ✅, status ✅, bannedUsers ✅, speakers ✅
    ↓
  ✅ Token Generated Successfully
```

---

## FIELD RESPONSIBILITY MATRIX

| Field | Created By | Stored In | Used By | Required? |
|-------|-----------|-----------|---------|-----------|
| `id` | RoomManagerService | Firestore | CloudFn, VoiceRoom | ✅ YES |
| `title` | User input | Firestore | Display (unused in VoiceRoom) | ✅ YES |
| `description` | User input | Firestore | Display (unused in VoiceRoom) | ✅ YES |
| `hostId` | Firebase Auth | Firestore | CloudFn role check, Rules | ✅ YES |
| `category` | User select | Firestore | Display/filtering | ✅ YES |
| `tags` | User input | Firestore | Search/filtering | ✅ YES |
| `createdAt` | Server | Firestore | Analytics | ✅ YES |
| `updatedAt` | Server | Firestore | Analytics | ✅ YES |
| `isLive` | RoomManagerService | Firestore | **CloudFn (CRITICAL)** | ✅ YES |
| `status` | RoomManagerService | Firestore | **CloudFn (CRITICAL)** | ✅ YES |
| `privacy` | RoomManagerService | Firestore | CloudFn privacy check | ✅ YES |
| `moderators` | RoomManagerService | Firestore | Rules authorization | ✅ YES |
| `admins` | RoomManagerService | Firestore | Alias for moderators | ✅ YES |
| `bannedUsers` | RoomService | Firestore | **CloudFn ban check** | ✅ YES |
| `speakers` | RoomManagerService | Firestore | **CloudFn role** | ✅ YES |
| `participantIds` | RoomService | Firestore | Participant tracking | ✅ YES |
| `turnBased` | RoomManagerService | Firestore | **VoiceRoom** | ❌ NO |
| `turnDurationSeconds` | RoomManagerService | Firestore | **VoiceRoom** | ❌ NO |
| `hostName` | Firebase Auth | Firestore | Display | ❌ NO |
| `thumbnailUrl` | User | Firestore | Display | ❌ NO |
| `roomType` | User select | Firestore | Behavior control | ❌ NO |
| `listeners` | RoomService | Firestore | Role tracking | ❌ NO |
| `raisedHands` | User action | Firestore | Moderation | ❌ NO |
| `speakerQueue` | User action | Firestore | Moderation | ❌ NO |
| `currentSpeakerId` | Moderator | Firestore | Spotlight tracking | ❌ NO |
| `agoraChannelName` | RoomManagerService | Firestore | Channel reference | ❌ NO |
| `mutedUsers` | RoomService | Firestore | Audio moderation | ❌ NO |
| `kickedUsers` | RoomService | Firestore | **CloudFn kick check** | ✅ YES |
| `viewerCount` | RoomService | Firestore | Display | ❌ NO |
| `camCount` | RoomManagerService | Firestore | Unused (broadcaster mode) | ❌ NO |
| `isLocked` | RoomManagerService | Firestore | Access control | ❌ NO |
| `passwordHash` | RoomManagerService | Firestore | Access control | ❌ NO |
| `maxUsers` | RoomManagerService | Firestore | Capacity | ❌ NO |
| `isNSFW` | RoomManagerService | Firestore | Content filtering | ❌ NO |
| `isHidden` | RoomManagerService | Firestore | Listing filtering | ❌ NO |
| `slowModeSeconds` | RoomManagerService | Firestore | Rate limiting | ❌ NO |
| `allowSpeakerRequests` | RoomManagerService | Firestore | Moderation | ❌ NO |
| `maxBroadcasters` | RoomManagerService | Firestore | Unused (broadcaster mode) | ❌ NO |
| `activeBroadcasters` | RoomManagerService | Firestore | Unused (broadcaster mode) | ❌ NO |

---

## INTEGRATION RISK SCORECARD

### Critical Path Risks (Token Generation)

| Risk | Probability | Impact | Status |
|------|-------------|--------|--------|
| `isLive` missing when needed | 🟢 LOW | 🔴 BREAKS | ✅ Mitigated (always set) |
| `status` missing when needed | 🟢 LOW | 🔴 BREAKS | ✅ Mitigated (always set) |
| `bannedUsers` missing | 🟢 LOW | 🟡 ERROR | ✅ Mitigated (defaults to []) |
| `moderators` missing | 🟢 LOW | 🟡 ERROR | ⚠️ Risky (only sets one) |
| `admins` ignored by Rules | 🟠 MED | 🟡 ERROR | ❌ **NEEDS FIX** |

### Firestore Rules Risks

| Risk | Issue | Status |
|------|-------|--------|
| Admin field not checked in rules | Line 143-149 | ❌ **NEEDS FIX** |
| Privacy dual fields | Lines 67, 143 | ⚠️ Works but fragile |
| No schema validation | Throughout | ✅ OK (flexibility) |

### Frontend Risks

| Risk | Issue | Status |
|------|-------|--------|
| VoiceRoomPage only uses 3 fields | Tight coupling avoided | ✅ OK |
| Room object always required | No null safety | ✅ OK (passed in constructor) |
| turnBased/turnDurationSeconds needed | Used in initState | ✅ Always set |

---

## QUICK TROUBLESHOOTING GUIDE

### "Room has ended" Error During Token Generation

**Cause:** One of these is missing or false in Firestore:
- `isLive !== true`
- `status !== 'live'`

**Check:**
1. Look in `functions/lib/index.js` Line 64-65
2. Verify room document has:
   - `"isLive": true`
   - `"status": "live"`

**Prevention:**
- RoomManagerService ALWAYS sets these ✅

---

### "Access Denied" on Room Update

**Cause:** Firestore rules can't find moderators

**Check:**
1. Look in `firestore.rules` Line 143-149
2. Verify room document has:
   - `"moderators": [userId, ...]` OR
   - `"admins": [userId, ...]` ← NOT CHECKED!

**Fix:**
- Update rules to check `admins` field too
- OR ensure `moderators` field is always set

---

### VoiceRoomPage Crashes on Access

**Most Likely:** Never happens - constructor requires room object

**If Happens:**
- Check that room.id is present
- Check that room.turnBased defaults to false
- Check that room.turnDurationSeconds defaults to 60

---

### Agora Token Generation Rejects User

**Causes:**
1. User in `bannedUsers` ✅ Working as intended
2. User in `kickedUsers` ✅ Working as intended
3. User not host/moderator/speaker but role=broadcaster ✅ Working as intended

**Check in `functions/lib/index.js`:**
- Line 78-85: User role determination logic

---

## DEPLOYMENT CHECKLIST

- [ ] All 57 Room fields are being serialized (toJson/toFirestore)
- [ ] Firestore rules check BOTH `moderators` AND `admins`
- [ ] Test room creation sets: isLive, status, bannedUsers, speakers
- [ ] Cloud Functions have access to all required fields
- [ ] VoiceRoomPage has room.id, room.turnBased, room.turnDurationSeconds
- [ ] Navigation always passes Room object to VoiceRoomPage
- [ ] Firebase Auth matches expected user in Cloud Functions
- [ ] Agora credentials in environment: AGORA_APP_ID, AGORA_APP_CERTIFICATE

---

## RECOMMENDED FIXES (PRIORITY ORDER)

### 🔴 P1: Critical (Do First)

**Fix #1: Update Firestore Rules**
- File: `firestore.rules` Line 143-149
- Add check for `admins` field
- Impact: Enables moderators with only `admins` field to update rooms

**Fix #2: Update Test Room**
- File: `functions/create_test_room.js` Lines 11-15
- Add: isLive, status, bannedUsers, moderators
- Impact: Test room will generate tokens successfully

### 🟡 P2: Important (Do Soon)

**Fix #3: Standardize Privacy Fields**
- Choose ONE: `privacy: string` OR `isPrivate: boolean`
- Remove the other
- Impact: Cleaner codebase

**Fix #4: Document Broadcaster Mode**
- Mark activeBroadcasters, maxBroadcasters, camCount as "reserved for broadcaster mode"
- Add comments about when to implement
- Impact: Clarity for future developers

### 🟢 P3: Nice-to-Have (Do Later)

**Fix #5: Deprecation Path for Legacy Fields**
- Create migration guide for: name→title, isActive→isLive, participants→participantIds
- Impact: Modernize codebase over time

---

## VERIFICATION COMMANDS

### Check Room Document in Firestore

```firebase
// Should see all these fields with correct types
{
  "id": "room_abc123",
  "title": "Room Name",
  "hostId": "user_xyz",
  "isLive": true,            ← CRITICAL
  "status": "live",           ← CRITICAL
  "moderators": ["user_xyz"], ← CRITICAL (or admins)
  "admins": ["user_xyz"],     ← Check both
  "speakers": ["user_xyz"],   ← CRITICAL
  "bannedUsers": [],          ← CRITICAL
  "kickedUsers": [],          ← CRITICAL
  "privacy": "public",
  ... (50+ more fields)
}
```

### Test Token Generation

```bash
# Call Cloud Function
curl -X POST https://us-central1-PROJECTID.cloudfunctions.net/generateAgoraToken \
  -H "Content-Type: application/json" \
  -d '{"roomId": "room_abc123", "userId": "user_xyz"}'

# Expected response:
# {"token": "abc123xyz...", "appId": "...", "uid": 12345, "expiresAt": 1234567890}

# If error "Room has ended":
# → isLive or status field missing/false in Firestore
```

---

**END OF COMPATIBILITY MATRIX**

