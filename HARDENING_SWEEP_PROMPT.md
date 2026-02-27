# 🛡️ Pre-Launch Hardening Sweep — VS Code Copilot Chat Command

Copy the prompt below and paste it into VS Code Copilot Chat to run the Pre-Launch Hardening Sweep.

---

```
@workspace

You are performing the Pre-Launch Hardening Sweep for MixMingle — a Flutter/Firebase social app.
This sweep focuses on platform safety, resilience, and production-readiness.
It is not a feature sweep — it is a protection sweep.

The goal: make the platform safe, stable, and resilient before public users arrive.

For each area below:
1. Identify the relevant source files
2. Check current implementation status
3. If missing or incomplete, provide the exact implementation to add
4. Prioritize: 🔴 Critical (must fix before launch) | 🟡 High (fix before beta) | 🟠 Medium (fix in v1.1)

---

## Hardening Areas

### 1. Rate Limiting
- Firebase Functions: add rate limiting to generateAgoraToken (max N calls per user per minute)
- Firestore: add write throttle guards on high-frequency collections (messages, room_events)
- Client: add debounce on all button actions (send, join, match, like)
- Client: add cooldown on room creation (prevent spam room creation)

### 2. Abuse Reporting
- Report user flow: UI button → Firestore `reports` collection write → admin dashboard visible
- Report content flow: flag a message or room → same collection
- Auto-flag: if a user is reported N times, auto-flag for admin review
- Block list: blocked users cannot see each other in discovery, rooms, or chat

### 3. Block & Mute
- Block user: removes from discovery, removes from room suggestions, prevents chat initiation
- Mute user: hides their chat messages without blocking
- Block/mute stored in Firestore under user profile
- Firestore rules: blocked users cannot read each other's profiles

### 4. Crash Fallback Screens
- Every Navigator.push wrapped in try/catch or GoRouter error handler
- ErrorBoundary widget (or equivalent) on RoomPage, ChatPage, AdminPage
- Agora crash → show "Video unavailable" screen, not blank white screen
- Firestore permission denied → show "Something went wrong" screen with retry button
- Auth failure on cold start → redirect to LoginPage, not crash

### 5. Offline Mode Polish
- Connectivity check on app launch (connectivity_plus or similar)
- Offline banner shown when connection lost
- Firestore offline persistence: verify `Settings(persistenceEnabled: true)` configured
- Queue outgoing messages when offline, retry on reconnect
- Room join blocked with "No internet connection" message (not silent failure)

### 6. Retry Logic
- Agora token fetch: 3 retry attempts with exponential backoff
- Firestore reads: retry on network error (not on permission error)
- Image uploads: retry on failure with progress indicator
- Firebase Auth: handle token refresh automatically

### 7. Firestore Security Rules — Production Tightening
Review and harden all rules:

```

rules_version = '2';
service cloud.firestore {
match /databases/{database}/documents {

    // Users: read own profile + public fields only; write own only
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }

    // Rooms: authenticated read; create by auth user; update/delete by creator only
    match /rooms/{roomId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth.uid == resource.data.creatorId;
    }

    // Messages: participants only
    match /chats/{chatId}/messages/{msgId} {
      allow read, write: if request.auth.uid in resource.data.participants
                         || request.auth.uid in get(/databases/.../documents/chats/$(chatId)).data.participants;
    }

    // Matches: participants only
    match /matches/{matchId} {
      allow read: if request.auth.uid in resource.data.users;
      allow write: if request.auth != null;
    }

    // Reports: authenticated write (any user can report); admin read only
    match /reports/{reportId} {
      allow create: if request.auth != null;
      allow read, update, delete: if request.auth.token.admin == true;
    }

    // Admin: admin UID only
    match /admin/{doc} {
      allow read, write: if request.auth.token.admin == true;
    }

}
}

```

Verify these rules match the actual Firestore collections used in the codebase.
Flag any collection that has no rule or is open to unauthenticated access.

### 8. Analytics Funnels — Finalization
- Verify funnel: install → onboarding_complete → first_room_join → first_chat_sent → first_friend_added → activation_completed
- Verify no events fire before auth is confirmed
- Verify no duplicate events (de-duplication flags in Firestore)
- Verify screen_view events on all major screens
- Verify AdMob events: ad_impression, ad_click, rewarded_ad_complete

### 9. Error Boundaries & Logging
- All async functions in initState have try/catch
- All FirebaseException caught and logged (not swallowed)
- debugPrint replaced with proper logging (or removed in release builds)
- No print() statements in production code (use kDebugMode guard)
- Sentry or Firebase Crashlytics integrated for production crash reporting

### 10. Input Validation & Sanitization
- All user text inputs trimmed and length-limited before Firestore write
- Room names: max 60 chars, no script injection
- Chat messages: max 1000 chars, no script injection
- Profile bio: max 300 chars
- Age field: integer validation, min 18 enforced

### 11. Auth Guards on All Routes
- Every page that requires auth has a guard (redirect to login if unauthenticated)
- Admin pages: double-guard (auth + admin role check)
- Deep links: auth state checked before navigating to protected route

### 12. Firebase Production Configuration
- Confirm `google-services.json` is the PRODUCTION project (not dev/staging)
- Confirm `GoogleService-Info.plist` is the PRODUCTION project
- Confirm Firebase App Check is enabled in production
- Confirm Firebase Auth: only required providers enabled (disable test providers)
- Confirm Firestore indexes built for all active queries

---

Return findings as:

## Hardening Sweep Results

### 🔴 Blockers (must fix before any public launch)
[Issue → File → Suggested fix]

### 🟡 High Priority (fix before beta)
[Issue → File → Suggested fix]

### 🟠 Medium Priority (fix in v1.1)
[Issue → File → Suggested fix]

### ✅ Already Hardened
[Systems that are already production-ready]

### 📋 Manual / Infrastructure Steps
[Things that require Firebase Console, App Store Connect, or Google Play Console actions]
```
