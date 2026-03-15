# 🧪 Final QA Sweep — VS Code Copilot Chat Command

Copy the prompt below and paste it into VS Code Copilot Chat to run the Final QA Sweep.

---

```
@workspace

You are performing the Final QA Sweep for MixMingle — a Flutter/Firebase social app with video rooms, chat, matching, speed dating, ads, onboarding, analytics, and an admin dashboard.

The app targets Web and Android. Firebase is the backend (Firestore, Auth, Functions, Storage). Agora is used for WebRTC video/audio. AdMob is used for ads.

Perform a complete QA sweep across every major system. For each area:
1. Identify the relevant source files
2. Check for runtime errors, broken flows, null safety issues, or missing guards
3. Flag anything that would cause a crash, blank screen, or bad UX in production
4. Suggest fixes for any issue found

## Scope of the QA Sweep

### 1. Onboarding Flow
- Registration screen (email/password)
- Profile setup (name, age, gender, interests, photo upload)
- Age verification gate
- First-launch analytics events (logFirstRoomJoinOnce, logFirstChatSentOnce, logFirstFriendAddedOnce)
- Navigation to home after completion

### 2. Room Discovery & Join
- Home screen room list (Firestore query, real-time updates)
- Room creation flow
- Room join flow (Agora token fetch, channel join)
- Room leave / dispose flow
- Room page error states (token failure, network failure)
- room_join_success / room_join_failed / room_leave analytics events

### 3. Video & Audio (Agora)
- AgoraEngine initialization (web vs Android platform detection)
- Local video preview
- Remote user join/leave
- Mute/unmute audio
- Camera toggle
- Screen share (web only)
- Agora token expiry handling
- Dispose and cleanup (no memory leaks, no double-dispose)

### 4. Chat System
- Chat list screen
- Chat thread screen
- Send message
- Receive message (real-time)
- Chat notification badge
- Empty state
- Blocked user flow

### 5. Matching System
- Swipe/like flow
- Match detection
- Match popup / celebration
- Match list screen
- Unmatch flow

### 6. Speed Dating
- Speed date room creation
- Timer display
- Auto-advance to next partner
- End of session summary

### 7. Ads (AdMob)
- Banner ad initialization and display
- Interstitial ad load and show trigger
- Rewarded ad load, show, and reward callback
- Ad-free premium bypass
- Age-restricted ad flag (COPPA / age gate)
- Ad failure fallback (no crash if ad fails to load)

### 8. Monetization
- Promo code input and validation
- Premium unlock flow
- Coin system (earn, spend, display)
- Purchase flow (if in-app purchase connected)

### 9. Admin Dashboard
- Login guard (admin-only)
- User list
- Room list
- Ban user action
- Flag review action
- Analytics overview

### 10. Analytics (Firebase Analytics)
- screen_view events firing on navigation
- Custom events (room_join_success, room_join_failed, room_leave, first_room_join_done, first_chat_sent_done, first_friend_added_done, activation_completed)
- No duplicate event calls
- No events fired before user is authenticated

### 11. Firestore Security Rules
- Authenticated read/write guards on all collections
- Users can only write their own profile
- Rooms: creator can delete, all authenticated users can read
- Chats: participants only
- Matches: participants only
- Admin: admin UID whitelist only
- No public write access anywhere

### 12. Error States & Edge Cases
- No internet connection: graceful fallback message, no crash
- Firestore permission denied: caught and shown as user-friendly error
- Agora failure: room page shows error + back button, no infinite loading
- Auth token expired: redirected to login
- Image upload failure: retry option shown
- Empty collections: empty state widgets shown (no null errors)

### 13. Pop-outs & Multi-window (Web)
- Pop-out window opens correctly
- Pop-out closes and state restores
- Multiple windows don't conflict on Agora channel
- BroadcastChannel or equivalent used for cross-window messaging

### 14. Web-Specific
- PWA installable (manifest.json valid)
- Splash screen shows on first load
- Theme color correct in browser chrome
- og: meta tags present in index.html
- Web icons correct (192, 512, maskable)
- No dart2js errors in browser console

### 15. Performance Flags
- No widgets rebuilding unnecessarily on stream updates
- No setState called after dispose
- No unawaited futures in initState
- Images cached (CachedNetworkImage or equivalent)
- Large list views using ListView.builder (not ListView with children:[])

---

Return your findings as a structured report:

## QA Sweep Results

### ✅ Passing
[List of systems that look clean]

### ⚠️ Warnings
[Issues that won't crash but should be fixed before launch]

### 🔴 Blockers
[Anything that would cause a crash, blank screen, or bad UX in production — with file/line references and suggested fix]

### 📋 Manual Test Steps Required
[Anything that can only be verified by running the app, not by static analysis]
```
