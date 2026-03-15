# MIXMINGLE — Full-Stack Debug Sweep Report

> **Final Status:** `flutter analyze --no-fatal-infos` → **No issues found!**
> **Bugs Fixed:** 10 confirmed bugs across 8 files

---

## Executive Summary

A comprehensive audit was performed across all 14 areas of the MIXMINGLE Flutter/Firebase app.
Ten bugs were identified and fully resolved, ranging from a critical Agora bridge mismatch
(100% of web video/audio calls were broken) to a chat collection split that caused messages
from the pop-out window and main chat to never appear in the same conversation.

---

## 1. Routing & Authentication

**File:** `lib/main.dart`

### Bug #3 — Unguarded `/feed` and `/speed-dating` routes

- **Severity:** HIGH
- **Problem:** The inline `onGenerateRoute` handler in `_AlwaysLandingApp` had explicit `case '/feed':` and `case '/speed-dating':` entries that returned raw `MaterialPageRoute` widgets, bypassing the `AuthGate + ProfileGuard` wrapping present in `AppRoutes.generateRoute()`. Unauthenticated or incomplete-profile users could navigate directly to these screens.
- **Fix:** Removed both `case` entries. Those routes now fall through to `AppRoutes.generateRoute(settings)`, which wraps every authenticated screen in the proper auth and profile guards.
- **Collateral repair:** Two orphan imports (`social_feed_page.dart`, `speed_dating_lobby_screen.dart`) were removed from `main.dart` since those routes are now handled exclusively by `AppRoutes`.

---

## 2. Providers / Riverpod

**File:** `lib/shared/providers/notifications_provider.dart`

### Bug #6 — `notificationBadgeProvider` queried wrong Firestore schema

- **Severity:** HIGH
- **Problem:** The provider for the alert badge count used three wrong identifiers:
  - Collection: `'chats'` → should be `'chatRooms'`
  - Query field: `'participantIds'` → should be `'participants'`
  - Count field: `'unreadCount'` (singular) → should be `'unreadCounts'` (plural map)
    Badge count always returned `0` regardless of actual unread messages.
- **Fix:** Corrected all three names. Added a safe cast: `(counts[userId] as num?)?.toInt() ?? 0` to handle the Firestore `num` → Dart `int` coercion.

---

## 3. Firestore / Data Layer

**Files:** `lib/services/chat/chat_service.dart`, `lib/features/chat/screens/chat_pop_out_screen.dart`

### Bug #2 — `FieldValue.increment` on a Map field crashed message sends

- **Severity:** CRITICAL
- **Problem:** `sendMessage()` wrote `'unreadCounts': FieldValue.increment(1)`. The Firestore field `unreadCounts` is a `Map<String, int>`, not a numeric scalar. Firestore rejects `FieldValue.increment` on a map field; the write operation throws and silently drops the message metadata update.
- **Fix:** Derived the receiver's UID from the deterministic `roomId` format (`uid1_uid2` sorted). Now writes `'unreadCounts.$receiverUid': FieldValue.increment(1)` — a dot-notation field path that targets only the receiver's counter inside the map.

### Bug #8 — `streamUserChatRooms()` broken error recovery

- **Severity:** MEDIUM
- **Problem:** Used `.handleError((error) => Stream.value([]))`. The return value of the `.handleError()` callback is **ignored** — it does not emit a new value; it continues to propagate the error downstream. Any Firestore permission error would crash the stream and put the chat list into an error state permanently.
- **Fix:** Replaced with a `StreamController.broadcast()` pattern that explicitly catches errors in a `try/catch`, appends `[]` to the controller, and keeps the stream alive.

### Bug #10 — Chat pop-out and main chat stored messages in different Firestore collections

- **Severity:** HIGH
- **Problem:** `ChatPopOutScreen` wrote all messages to `collection('chats')` with a schema of `{text, readBy, lastMessageTimestamp, participantIds}`. `ChatService` (used by the main `ChatListPage`) reads from `collection('chatRooms')` with a schema of `{content, isRead, lastMessageTime, participants, unreadCounts}`. Opening the same conversation in the pop-out window vs. in the full chat page showed completely different (empty) histories. Neither side could ever see the other's messages.
- **Fix:** Migrated `ChatPopOutScreen` to `collection('chatRooms')` with the unified schema:
  - Message field: `text` → `content`; `readBy: [uid]` → `isRead: false`
  - Room doc: `lastMessageTimestamp` → `lastMessageTime` (as `Timestamp`); `participantIds` → `participants` (sorted list); added `unreadCounts.$peerUid: FieldValue.increment(1)`
  - `_markRead`: replaced `readBy` array-union with `isRead: true` per-message update; added `unreadCounts.$myUid: 0` reset on the room doc
  - Typing subcollection: shifted from `chats/{id}/typing` to `chatRooms/{id}/typing`
  - `_messagesStream()`: now reads from `chatRooms/{id}/messages`

---

## 4. Authentication

**No additional bugs found.** The `RootAuthGate` → `_AuthenticatedAppGate` → `MixMingleApp` chain is correct. `authStateProvider` and `currentUserProvider` are properly watched. Profile-incomplete users are routed to `_ProfileIncompleteApp`. Auth state changes trigger full widget rebuilds.

---

## 5. Pop-Out Windows (Buddy Chat)

**File:** `lib/features/chat/screens/chat_pop_out_screen.dart`

Covered by Bug #10 above. All collection references, message fields, and read-receipt logic are now unified with the main chat schema.

---

## 6. Agora (Video/Audio)

**Files:** `web/index.html`, `web/agora_bridge.js`

### Bug #1 — Wrong Agora JS bridge loaded on Web (CRITICAL)

- **Severity:** CRITICAL
- **Problem:** `web/index.html` loaded `agora_web_v5_production.js`. That file exposes `window.agoraWebInit`, `window.agoraWebJoinChannel` as top-level globals but does NOT define `window.agoraWebBridge.*` and never sets `window.agoraBridgeReady`. The Dart service (`agora_service_web.dart`) uses `@JS('agoraWebBridge.init')`, `@JS('agoraWebBridge.joinChannel')` etc., and its `isBridgeReady` getter checks `window.agoraBridgeReady`. With the wrong file loaded, every single Agora call returned `null`/`undefined`. No user could ever join a call or room on the web.
- **Fix:** Changed `<script src="agora_web_v5_production.js">` to `<script src="agora_bridge.js">`. The `agora_bridge.js` file: (a) defines `window.agoraWebBridge.*`, (b) sets flat-style aliases (`window.agoraWebInit` etc. for backward compat), and (c) sets `window.agoraBridgeReady = true`.

### Bug #9 — Tab-visibility auto-mute missing from `agora_bridge.js`

- **Severity:** MEDIUM
- **Problem:** When a user switched browser tabs while in a video call, their local audio and video tracks kept streaming, wasting CPU and bandwidth. `agora_web_v5_production.js` had this feature; `agora_bridge.js` (the correct file) did not.
- **Fix:** Added a `document.addEventListener('visibilitychange', ...)` block to `agora_bridge.js`. On tab hide: mutes both `localTracks.audio` and `localTracks.video`. On tab show: unmutes. Guard: skips if no active channel (`!state.currentChannel`).

---

## 7. Speed Dating

**No critical bugs found.** `SpeedDatingLobbyScreen` uses `speedDatingSessionProvider` (Riverpod) correctly. `SpeedDatingSessionScreen` has placeholder Agora integration — a video call button that debugPrints instead of joining a channel — but this is not a breakage, just an unimplemented feature. Routing is now correctly guarded (Bug #3 fix removes the unguarded bypass).

---

## 8. Rooms

**No bugs found.** `RoomPage` uses `RoomFirestoreService` (legacy `Provider`) correctly. Agora integration uses `AgoraService` via `Provider.of<AgoraService>`. The Agora fix (Bug #1) unblocks ALL room video/audio functionality on web.

---

## 9. Chat (Main App)

**Files:** `lib/services/chat/chat_service.dart`

Covered by Bugs #2, #8, and #10 above. The chat service now:

- Writes unread counts correctly per-user with dot-notation paths
- Streams chat rooms with resilient error recovery
- Shares the same Firestore collection with the pop-out window

---

## 10. Feed

**No bugs found.** `SocialFeedPage` uses Riverpod providers cleanly. Routing is now properly guarded (Bug #3 fix). No broken Firestore queries found.

---

## 11. Profile

**No critical bugs found.** `ProfilePage` reads correctly from Riverpod `currentUserProvider`. One dead-code file (`lib/features/profile/profile_page.dart` at the root level, not under `screens/`) imports `dev_stubs.dart` and `presenceServiceProvider` but is never routed to — no runtime impact.

---

## 12. Notifications (FCM)

**Files:** `lib/app/app.dart`, `lib/shared/providers/notifications_provider.dart`

### Bug #4 — `MixMingleApp` had no `navigatorKey` — FCM taps did nothing

- **Severity:** HIGH
- **Problem:** `FcmNotificationService` holds a static `_navigatorKey` reference. `setNavigatorKey()` was never called because `MixMingleApp` was a `StatelessWidget` with no lifecycle. Even if notifications were received, `_navigatorKey.currentState` was always `null`. Every notification tap silently dropped navigation.
- **Fix:** Converted `MixMingleApp` to `StatefulWidget`. Added a top-level `appNavigatorKey` (`GlobalKey<NavigatorState>`). In `initState()`: calls `FcmNotificationService.setNavigatorKey(appNavigatorKey)`. Added `navigatorKey: appNavigatorKey` to `MaterialApp`.

### Bug #5 — FCM deep-link navigation was stubbed out

- **Severity:** HIGH
- **Problem:** `_handleBackgroundMessage()` in `notifications_provider.dart` had five `debugPrint('Navigate to ...')` TODO stubs. No notification type (message, match, room invite, speed-dating match) ever navigated anywhere.
- **Fix:** Replaced all stubs with real `appNavigatorKey.currentState?.pushNamed(AppRoutes.X)` calls for each notification type: `message` → `/chat`, `match` → `/matches`, `speed_dating_match` → `/speed-dating`, `room_invite` → `/rooms`.

---

## 13. Web Build / PWA Configuration

**No bugs found.** `firebase.json` serves `index.html` correctly for SPA routing. `manifest.json` is well-formed. `firebase-messaging-sw.js` registers the service worker for background FCM. CSP meta tag in `index.html` is present.

---

## 14. Performance & Shared Widgets

**File:** `lib/shared/widgets/presence_indicator.dart`

### Bug #7 — `PresenceIndicator` crashed at runtime with `NoSuchMethodError`

- **Severity:** HIGH
- **Problem:** `presence_indicator.dart` imported `dev_stubs.dart`, which declares `final presenceServiceProvider = Provider((ref) => null)`. Calling `presenceService.getUserPresence(userId)` on the `null` returned by the stub caused `NoSuchMethodError: Null has no method 'getUserPresence'` — crashing any screen that shows a presence dot (chat list, buddy list, profile headers).
- **Fix:** Changed the import from `dev_stubs.dart` to `user_providers.dart`, which provides the real `PresenceService` implementation.

---

## Files Modified

| File                                                 | Changes                                                                                                          |
| ---------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| `web/index.html`                                     | Load `agora_bridge.js` instead of `agora_web_v5_production.js`                                                   |
| `web/agora_bridge.js`                                | Added tab-visibility auto-mute event listener                                                                    |
| `lib/main.dart`                                      | Removed unguarded `/feed` and `/speed-dating` route cases; removed orphan imports                                |
| `lib/app/app.dart`                                   | `StatelessWidget` → `StatefulWidget`; added `appNavigatorKey`; wired `FcmNotificationService`                    |
| `lib/services/chat/chat_service.dart`                | Fixed `FieldValue.increment` on map field; fixed `streamUserChatRooms` error recovery; added `dart:async` import |
| `lib/shared/providers/notifications_provider.dart`   | Fixed FCM deep-link navigation stubs; fixed `notificationBadgeProvider` collection/fields                        |
| `lib/shared/widgets/presence_indicator.dart`         | Changed import from `dev_stubs.dart` to `user_providers.dart`                                                    |
| `lib/features/chat/screens/chat_pop_out_screen.dart` | Migrated all Firestore access from `chats` → `chatRooms`; aligned message schema                                 |

---

## Recommendations (Not Yet Implemented)

4. **Firestore security rules** — The `chatRooms` collection now uses `unreadCounts.$uid` dot-notation increments. Ensure Firestore rules permit `update` on `chatRooms` documents for participants (not just create/read).

5. ~~**Agora token provisioning for speed dating**~~ — **✅ Resolved in Production Readiness phase (see below).**

6. ~~**Platform view registration for remote video**~~ — **✅ Resolved in Production Readiness phase (see below).**

---

## Phase 2 Cleanup

> Applied after initial Phase 1 sweep. `flutter analyze --no-fatal-infos` → **No issues found!**
> `flutter build web --release` → **Build succeeded** (75.5s, zero errors or warnings).

### P2-1 — Deleted dead code: unused duplicate router + stale-collection chat screens

- **Files deleted:**
  - `lib/core/routing/app_routes.dart` — a second router file never referenced by any live code; imported `ChatsListPage` and `ChatConversationPage` which accessed the old `chats` collection
  - `lib/features/chat/screens/chats_list_page.dart` — queried `collection('chats')` with `participantIds`; dead code only reachable via the deleted router
  - `lib/features/chat/screens/chat_conversation_page.dart` — wrote to `collection('chats')` with `text`/`readBy` schema; also dead code, also had multiple `undefined_getter` analyzer errors against `DesignColors`

### P2-2 — Removed `presenceServiceProvider` null stub from `dev_stubs.dart`

- **File:** `lib/core/stubs/dev_stubs.dart`
- **Removed:** `final presenceServiceProvider = Provider((ref) => null)`
- The real `presenceServiceProvider` in `user_providers.dart` returns a live `PresenceService()`, not `null`. The stub had already been defused in Phase 1 (by changing the import in `presence_indicator.dart`), but the declaration remained as a landmine. It is now gone.
- Non-null stubs retained: `activeSpeedDatingSessionProvider`, `speedDatingMatchesProvider`, `SpeedDatingMatch`, `SpeedDatingResult` — still used by the dead-code `lib/features/profile/profile_page.dart`; not harmful.

### P2-3 — Wired `SpeedDatingSessionScreen` to real `AgoraService`

- **File:** `lib/features/speed_dating/screens/speed_dating_session_screen.dart`
- **State fields added:** `_agora = AgoraService()`, `_micMuted`, `_videoMuted`, `_agoraJoined`
- **`_buildVideoLayer()`:** Reflects `_agoraJoined` state; wired to real AgoraService (token provisioning and HtmlElementView video rendering completed in Production Readiness phase below)

### P2-4 — Migrated remaining `collection('chats')` references to `chatRooms`

`chatRooms` is now the single source of truth for all 1-on-1 direct-message data.

| File                                                              | Old                                                       | New                                                                                                           |
| ----------------------------------------------------------------- | --------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------- |
| `lib/shared/providers/user_safety_provider.dart`                  | `collection('chats').where('participantIds', ...)`        | `collection('chatRooms').where('participants', ...)`                                                          |
| `lib/services/social/match_service.dart` — `createMatch()`        | `collection('chats').doc()` with `participants: [u1, u2]` | `collection('chatRooms').doc()` with sorted `participants`, `unreadCounts`, `lastMessage`                     |
| `lib/services/social/match_service.dart` — `unmatch()`            | `collection('chats').doc(chatId).update(...)`             | `collection('chatRooms').doc(chatId).update(...)`                                                             |
| `lib/services/social/match_service.dart` — `createChatForMatch()` | `collection('chats').add({members: ...})`                 | `collection('chatRooms').doc(roomId).set(...)` with deterministic `uid1_uid2` room ID and full unified schema |

---

## Production Readiness

> Applied after Phase 2 Cleanup. `flutter analyze --no-fatal-infos` → **No issues found!**

### PR-1 — Agora Token Provisioning for Speed Dating (production mode)

**Files:** `lib/features/speed_dating/screens/speed_dating_session_screen.dart`, `lib/services/infra/token_service.dart`

**Problem (was):** `SpeedDatingSessionScreen._initAgora()` called `joinChannel(token: null, uid: _myUid)`.

- `token: null` works only when the Agora project is in **Test Mode** (no-auth). Production Agora projects require a valid RTC token or the channel join is rejected.
- `uid: _myUid` passed the Firebase UID string directly. The JS bridge converts it via `parseInt(uid) || 0`, making every speed-dating user join with Agora UID `0`. Agora tokens are uid-specific, so even a valid token for the correct uid would be rejected if `0` is used as the actual Agora uid.

**Fix:**

1. **`TokenService`** — Added `AgoraTokenData` class (`{token, uid, appId, channelName}`) and `generateAgoraTokenData()` method that calls the `generateAgoraToken` Cloud Function and returns the full response including the deterministic numeric Agora UID.
2. **`_initAgora()`** rewired to:
   - Call `TokenService().generateAgoraTokenData(channelName: sessionId, userId: _myUid)` first.
   - On failure: show a `SnackBar` with a human-readable error and a **Retry** action; return early so the rest of Agora init is skipped gracefully.
   - On success: pass `token: agoraToken` and `uid: agoraNumericUid` (the server-assigned numeric UID as a string) to `joinChannel()`.

**Error handling surface:**

- `[firebase_functions/unauthenticated]` → user session expired; SnackBar prompts retry.
- `[firebase_functions/unavailable]` → network issue; SnackBar prompts retry.
- `[firebase_functions/internal]` → server-side Agora credential misconfiguration; SnackBar shows trimmed message.
- Any other exception is caught and surfaced via SnackBar with a Retry action.

---

### PR-2 — Platform View Factory Registration + In-Widget Remote Video (speed dating)

**Files:** `lib/features/speed_dating/screens/speed_dating_session_screen.dart`, `lib/services/agora/agora_service_web.dart`, `web/agora_bridge.js`

**Problem (was):** The remote video layer in `_buildVideoLayer()` was a static `Container` with an icon placeholder. The local PiP was an icon. Neither rendered actual Agora video inside the Flutter widget tree on web.

**Fix — 3-layer approach:**

**Layer 1 — JS Bridge (`web/agora_bridge.js`)**

- Added `remoteVideoSubscriberElementId` and `pendingRemoteTracks` fields to `agoraBridgeState`.
- Updated `user-published` handler: after subscribing the remote track, tries `remote-video-<numericUid>` first (rooms path), then the registered subscriber element ID (speed-dating / 1-on-1 path), then stores the track in `pendingRemoteTracks` if no element exists yet.
- Added `subscribeRemoteVideoTo(elementId)` function: registers a target element ID and immediately drains any pending remote track into it if one already arrived.
- `leaveChannel()` clears both fields so state is clean for the next session.

**Layer 2 — Dart service (`agora_service_web.dart`)**

- Added `@JS('agoraWebBridge.subscribeRemoteVideoTo')` external interop declaration.
- Added `Future<bool> subscribeRemoteVideoTo(String elementId)` method.
- Added no-op stub in `agora_service_io.dart` for non-web builds.

**Layer 3 — Screen (`speed_dating_session_screen.dart`)**

- **Platform view factories** registered inside `_initAgora()` (after token fetch, before SDK init):
  - `'agora-local-speed-dating-$_myUid'` → creates `<div id="agora-local-speed-dating-$_myUid">` for local camera.
  - `'agora-remote-speed-dating-video'` → creates `<div id="agora-remote-speed-dating-video">` for remote camera.
- After `joinChannel()` succeeds and mic/camera are started, calls `subscribeRemoteVideoTo('agora-remote-speed-dating-video')`.
- **`_buildVideoLayer()`**: When `kIsWeb && _agoraJoined`, returns `const SizedBox.expand(child: HtmlElementView(viewType: 'agora-remote-speed-dating-video'))` — the Agora bridge plays the partner's video directly into this Flutter widget. Pre-join / non-web falls back to the existing icon placeholder.
- **`_buildLocalPip()`**: When `kIsWeb && _agoraJoined && !_videoMuted`, renders `HtmlElementView(viewType: 'agora-local-speed-dating-$_myUid')` inside a `ClipRRect` for rounded corners; mic/video toggle icons remain as a `Positioned` overlay. Falls back to icon when Agora is not yet joined or video is muted.

**Resize & cleanup behaviour:**
`HtmlElementView` fills its parent via CSS `width:100%; height:100%; object-fit:cover` (set by `registerVideoViewFactory`). On `dispose()` / `_endSession()`, `leaveChannel()` is called, which stops and closes both local tracks, leaves the Agora channel, and clears the remote subscription state — ensuring no orphaned media streams remain after the round ends.

**Multi-stream correctness for rooms:**
The existing rooms path (`voice_room_page.dart`) is unaffected — it registers and renders `remote-video-<numericUid>` elements keyed by each participant's numeric Agora UID. The bridge change is additive: the `user-published` handler still checks `remote-video-<numericUid>` first, so Rooms continue to render multiple remote streams correctly.

---

## Files Modified (Production Readiness)

| File                                                                 | Changes                                                                                                                                                                                                                                                                |
| -------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `lib/services/infra/token_service.dart`                              | Added `AgoraTokenData` class; added `generateAgoraTokenData()` method returning token + numeric uid                                                                                                                                                                    |
| `lib/services/agora/agora_service_web.dart`                          | Added `@JS` interop for `subscribeRemoteVideoTo`; added `subscribeRemoteVideoTo(String)` method                                                                                                                                                                        |
| `lib/services/agora/agora_service_io.dart`                           | Added no-op `subscribeRemoteVideoTo()` stub                                                                                                                                                                                                                            |
| `lib/features/speed_dating/screens/speed_dating_session_screen.dart` | Rewired `_initAgora()` with Cloud Function token + error handling; registered platform view factories; wired `subscribeRemoteVideoTo`; replaced video placeholder with `HtmlElementView`; replaced local PiP icon with `HtmlElementView`; added `_shortError()` helper |
| `web/agora_bridge.js`                                                | Added `remoteVideoSubscriberElementId`/`pendingRemoteTracks` to state; updated `user-published` handler; added `subscribeRemoteVideoTo()` function; cleanup in `leaveChannel()`                                                                                        |

---

## Agora Production Integration Sweep

_Completed after Production Readiness phase. Covers token refresh, pop-out video window, and cross-context channel joining._

### Changes Made

#### Gap A — `live_agora_client.dart` Web Join Path (CRITICAL FIX)

**Root cause:** The cost-optimized room client set `_inChannel = true` without actually calling the Agora web bridge, so web users were never in the Agora channel.

**Fix:** The web join path now calls `AgoraPlatformService.joinChannel()` with the fetched token, which routes through `AgoraWebBridgeV3` → `agora_bridge.js` → Agora RTC JS SDK. After a successful join, the token refresh timer starts.

Also stored `_lastToken` and `_lastUserId` fields to support re-fetch at renewal time.

#### Gap B — Token Refresh (All Paths)

Agora tokens are 24-hour by default. Long-running sessions (social rooms, concerts) had no renewal mechanism.

**New infrastructure chain:**

| Layer                                              | Addition                                                                                                                                                                                                                             |
| -------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `web/agora_bridge.js`                              | `renewToken(newToken)` — calls `client.renewToken(newToken)` on the Agora JS client                                                                                                                                                  |
| `web/agora_bridge.js`                              | `window.agoraWebRenewToken(newToken)` flat-style wrapper                                                                                                                                                                             |
| `lib/services/agora/agora_web_bridge_v3_web.dart`  | `@JS` external getter + `static bool renewToken(String)` method                                                                                                                                                                      |
| `lib/services/agora/agora_web_bridge_v3_stub.dart` | No-op `renewToken(String)` stub                                                                                                                                                                                                      |
| `lib/services/agora/agora_platform_service.dart`   | `static Future<bool> renewToken(String token)` — web: `AgoraWebBridgeV3.renewToken()`; native: `_engine!.renewToken()`                                                                                                               |
| `lib/services/agora/agora_service_web.dart`        | `@JS` external `_jsRenewToken` + `Future<bool> renewToken(String)`                                                                                                                                                                   |
| `lib/services/agora/agora_service_io.dart`         | No-op `Future<bool> renewToken(String)` stub                                                                                                                                                                                         |
| `lib/features/room/live/live_agora_client.dart`    | `_tokenRefreshTimer` (23h `Timer`) started on join (both web and native paths); `_startTokenRefreshTimer()` + `_refreshAndRenewToken()` helpers; `onTokenPrivilegeWillExpire` native event handler; timer cancelled on leave/dispose |
| `lib/services/agora/agora_video_service.dart`      | `dart:async` import; `_tokenRefreshTimer` field; `_startTokenRefreshTimer()` + `_renewAgoraToken()` helpers; timer started after successful `joinRoom()`; cancelled in `leaveRoom()`                                                 |

**Token refresh strategy:**

- Timer fires at 23h (1h before the 24h Agora token expiry)
- On fire: re-calls `generateAgoraToken` Cloud Function, then `AgoraPlatformService.renewToken()`
- After renewal, reschedules itself for the next 23h cycle
- Native path additionally handles `onTokenPrivilegeWillExpire` for server-driven renewal signals

#### Gap C — `video_window_screen.dart` Live Video Rendering

**Before:** Static `StatelessWidget` showing only an avatar/name placeholder with the `AgoraVideoView` commented out.

**After:** `StatefulWidget` with full Agora lifecycle:

- Accepts optional `channelId` (String?) and `agoraUid` (int?) parameters
- When both are provided (web): calls `TokenService.generateAgoraTokenData()`, registers a platform view factory, calls `AgoraService.init()` + `joinChannel()` + `subscribeRemoteVideoTo()`
- Shows `HtmlElementView('video-window-remote-<agoraUid>')` once joined
- On dispose: calls `AgoraService.leaveChannel()` for clean disconnect
- Falls back to avatar/name placeholder (with "Video unavailable" badge) on error or missing params

**`WebWindowService.openVideoWindow()`** updated to accept optional `channelId` and `agoraUid` and forward them as URL query parameters (`&channelId=…&agoraUid=…`).

**`main.dart` route handler** updated to extract and parse `channelId` / `agoraUid` from `routeParams` and pass them to `VideoWindowScreen`.

---

## Files Modified (Agora Production Integration Sweep)

| File                                                       | Changes                                                                                                                                                                  |
| ---------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `web/agora_bridge.js`                                      | Added `renewToken(newToken)` to bridge object; added `window.agoraWebRenewToken` flat-style wrapper                                                                      |
| `lib/services/agora/agora_web_bridge_v3_web.dart`          | `@JS` external getter `_jsAgoraWebRenewToken`; `static bool renewToken(String)` method                                                                                   |
| `lib/services/agora/agora_web_bridge_v3_stub.dart`         | No-op `renewToken(String)` stub                                                                                                                                          |
| `lib/services/agora/agora_platform_service.dart`           | `static Future<bool> renewToken(String)` routing web→bridge / native→engine                                                                                              |
| `lib/services/agora/agora_service_web.dart`                | `@JS` `_jsRenewToken` declaration; `Future<bool> renewToken(String)` method                                                                                              |
| `lib/services/agora/agora_service_io.dart`                 | No-op `Future<bool> renewToken(String)` stub                                                                                                                             |
| `lib/features/room/live/live_agora_client.dart`            | Fixed web join path; added `_lastToken`, `_lastUserId`; added timer + refresh helpers + `onTokenPrivilegeWillExpire` handler; cancelled timer on leave/dispose           |
| `lib/services/agora/agora_video_service.dart`              | `dart:async` import; `_tokenRefreshTimer`; `_startTokenRefreshTimer()` + `_renewAgoraToken()` helpers; token refresh started in `joinRoom()`, cancelled in `leaveRoom()` |
| `lib/features/video_room/screens/video_window_screen.dart` | Rewritten as `StatefulWidget`; added Agora join/leave lifecycle; `HtmlElementView` rendering; `channelId` + `agoraUid` params                                            |
| `lib/core/web/web_window_service.dart`                     | `openVideoWindow` updated to accept and forward `channelId` + `agoraUid` URL params                                                                                      |
| `lib/main.dart`                                            | `/video-window` route handler now extracts and passes `channelId` + `agoraUid` to `VideoWindowScreen`                                                                    |

---

_Report last updated after `flutter analyze --no-fatal-infos` → **No issues found!** (Agora Production Integration Sweep)_

---

## Friend System Implementation

**Date:** February 25, 2026
**Status:** ✅ Complete

### Overview

A full bidirectional Friend System was implemented end-to-end across Firestore, Dart services, Riverpod providers, and Flutter UI.

### Firestore Schema

```
/users/{uid}/friendRequests/{requestId}
  requestId, senderId, receiverId, status, timestamp,
  senderName, senderAvatarUrl, receiverName, receiverAvatarUrl

/users/{uid}/friends/{friendUid}
  since: Timestamp, displayName?, avatarUrl?

/friendRequests/{requestId}  ← top-level for cross-user queries (same fields)
```

### New Files Created

| File                                                      | Description                                                                                                                                                                                                                     |
| --------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `lib/shared/models/friend_request.dart`                   | `FriendRequest` + `FriendEntry` models with Firestore serialisation                                                                                                                                                             |
| `lib/services/social/friend_service.dart`                 | `FriendService.instance` singleton — full CRUD: send, cancel, accept, decline, unfriend, autoFriend, isFriend, isPending, hasIncomingRequest, pendingRequestId, incomingRequestId, streamFriends, streamPendingCount            |
| `lib/shared/providers/friend_providers.dart`              | Riverpod providers: incomingFriendRequestsProvider, sentFriendRequestsProvider, myFriendsProvider, friendsOfUserProvider, pendingFriendRequestCountProvider, friendRelationshipProvider, and action providers for all mutations |
| `lib/features/profile/widgets/friend_request_button.dart` | Adaptive `FriendRequestButton` — renders Add Friend / Pending / Accept+Decline / Friends ✓ based on live relationship state                                                                                                     |
| `lib/features/profile/screens/friends_list_page.dart`     | `FriendsListPage` — searchable, with unfriend + message actions                                                                                                                                                                 |

### Existing Files Modified

| File                                                                 | Changes                                                                                                        |
| -------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| `lib/features/profile/user_profile_page.dart`                        | Added `FriendRequestButton` below the Follow/Message row                                                       |
| `lib/features/speed_dating/screens/speed_dating_session_screen.dart` | Added `_handleMutualMatch()` — calls `FriendService.autoFriend()` and sends match notifications on mutual like |
| `lib/shared/providers/all_providers.dart`                            | Exports `friend_providers.dart`                                                                                |
| `firestore.rules`                                                    | Added rules for `/users/{uid}/friends/`, `/users/{uid}/friendRequests/`, and top-level `/friendRequests/`      |

---

## Notification System Implementation

**Date:** February 25, 2026
**Status:** ✅ Complete

### Overview

A complete in-app Notification System was built using Firestore subcollections for per-user isolation, with real-time streaming, unread badge counts, grouped UI, deep-link navigation, and typed convenience senders for every integration point.

### Firestore Schema

```
/users/{uid}/notifications/{notificationId}
  type          : AppNotificationType (chatMessage|like|comment|friendRequest|
                  friendAccepted|roomInvite|roomLive|speedDatingMatch|tip|
                  newFollower|system)
  receiverId    : String
  senderId?     : String
  senderName?   : String
  senderAvatarUrl? : String
  body          : String   ← human-readable copy
  metadata      : Map      ← deep-link params (chatId, roomId, postId…)
  isRead        : bool
  timestamp     : Timestamp
```

### New Files Created

| File                                                        | Description                                                                                                                                                                                                                                                                                                                                                        |
| ----------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `lib/shared/models/app_notification.dart`                   | `AppNotification` model with `groupLabel` + `route` computed properties                                                                                                                                                                                                                                                                                            |
| `lib/services/notifications/app_notification_service.dart`  | `AppNotificationService.instance` singleton — `sendNotification`, `markAsRead`, `markAllAsRead`, `deleteNotification`, `streamUserNotifications`, `streamUnreadCount`, plus typed helpers: `notifyNewChatMessage`, `notifyFriendRequest`, `notifyFriendAccepted`, `notifyLike`, `notifyComment`, `notifyRoomInvite`, `notifySpeedDatingMatch`, `notifyNewFollower` |
| `lib/shared/providers/notification_providers.dart`          | Riverpod providers: `appNotificationsProvider`, `unreadNotificationCountProvider`, `hasUnreadNotificationsProvider`, `groupedNotificationsProvider`, `totalBadgeCountProvider`, `markNotificationReadProvider`, `markAllNotificationsReadProvider`, `deleteNotificationProvider`                                                                                   |
| `lib/shared/widgets/notification_bell.dart`                 | `NotificationBell` widget with live gradient badge; `CountBadge` reusable chip                                                                                                                                                                                                                                                                                     |
| `lib/features/notifications/widgets/notification_tile.dart` | `NotificationTile` — swipe-to-dismiss, avatar/icon, body, relative timestamp, unread dot, deep-link tap navigation                                                                                                                                                                                                                                                 |

### Existing Files Modified

| File                                                                 | Changes                                                                                                                                                                |
| -------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `lib/features/notifications/notifications_page.dart`                 | Fully rewritten — grouped sections (Chats, Friend Requests, Matches, Feed, Room Invites, Tips, Followers, System), mark-all-read action, empty state, real-time stream |
| `lib/features/chat/screens/chat_page.dart`                           | Send button calls `AppNotificationService.notifyNewChatMessage()` for direct chats                                                                                     |
| `lib/features/speed_dating/screens/speed_dating_session_screen.dart` | `_handleMutualMatch()` calls `AppNotificationService.notifySpeedDatingMatch()` for both participants                                                                   |
| `lib/shared/providers/all_providers.dart`                            | Exports `notification_providers.dart`                                                                                                                                  |
| `firestore.rules`                                                    | Added `/users/{uid}/notifications/{notificationId}` subcollection rules with owner-read / any-authenticated-write-for-notify / owner-update-delete pattern             |

### Integration Points

| System       | Trigger             | Notification Type                                              |
| ------------ | ------------------- | -------------------------------------------------------------- |
| Chat         | Direct message sent | `chatMessage`                                                  |
| Speed Dating | Mutual like         | `speedDatingMatch` → both users                                |
| Friends      | Request sent        | `friendRequest`                                                |
| Friends      | Request accepted    | `friendAccepted`                                               |
| Feed         | Post liked          | `like` (via `AppNotificationService.notifyLike`)               |
| Feed         | Post commented      | `comment` (via `AppNotificationService.notifyComment`)         |
| Rooms        | Invite sent         | `roomInvite` (via `AppNotificationService.notifyRoomInvite`)   |
| Social       | Follow action       | `newFollower` (via `AppNotificationService.notifyNewFollower`) |

---

## Match Inbox Implementation

> **Date:** February 25, 2026
> **Status:** ✅ Complete — `flutter analyze --no-fatal-infos` → **No issues found!**

### Overview

The Match Inbox is the connective tissue between speed‑dating, chat, notifications, and the social graph. Every mutual match — whether from speed dating or the discovery/like flow — is now automatically stored per‑user and surfaced in a dedicated tab with live badge counts.

### Firestore Schema

```
/users/{uid}/matches/{matchId}
  matchedUserId   : String      — UID of the other user
  timestamp       : Timestamp   — when the match was created
  lastInteraction : Timestamp?  — last chat/activity time
  isNew           : bool        — unseen until user opens the inbox
  source          : String      — 'speedDating' | 'discovery' | 'manual'
  metadata        : Map         — extra data (roundId, globalMatchId, etc.)
```

Notifications written alongside each match:

```
/users/{uid}/notifications/{notificationId}
  type            : 'speedDatingMatch'
  body            : "You matched with <name>! 🎉"
  metadata.matchId: <matchId>
  metadata.source : <source>
```

### New Files Created

| File                                                            | Purpose                                                                                                                                                                                                        |
| --------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `lib/features/match_inbox/models/match_inbox_item.dart`         | `MatchInboxItem` model — `fromDoc`, `fromMap`, `toMap`, `copyWith`; `MatchSource` enum                                                                                                                         |
| `lib/features/match_inbox/services/match_inbox_service.dart`    | `MatchInboxService` singleton — `createMatch`, `markMatchAsSeen`, `markAllMatchesSeen`, `removeMatch`, `streamUserMatches`, `streamMatchesForUser`, `updateLastInteraction`                                    |
| `lib/features/match_inbox/providers/match_inbox_providers.dart` | Riverpod providers: `matchInboxServiceProvider`, `matchInboxProvider`, `newMatchCountProvider`, `hasNewMatchesProvider`, `singleMatchProvider`, `speedDatingMatchInboxProvider`, `discoveryMatchInboxProvider` |
| `lib/features/match_inbox/screens/match_inbox_page.dart`        | `MatchInboxPage` — tabbed (All / New / Speed Date), responsive grid (≥600px) or list, mark-all-seen, badge in app bar                                                                                          |
| `lib/features/match_inbox/widgets/match_tile.dart`              | `MatchTile` — avatar with NEW badge, source icon badge (bolt/explore/heart), name, relative timestamp, Message button                                                                                          |

### Existing Files Modified

| File                                                                 | Changes                                                                                                                                                                                                     |
| -------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `lib/features/home/home_page_electric.dart`                          | Added **Matches** (♥) as nav tab index 1; heart-coloured selection state; live pink badge showing new match count; `_buildMatchInboxTab()` method; updated all hardcoded index references                   |
| `lib/app/app_routes.dart`                                            | Added `matchInbox = '/match-inbox'` constant; import for `MatchInboxPage`; `case matchInbox:` route handler with `AuthGate + ProfileGuard`                                                                  |
| `lib/shared/providers/all_providers.dart`                            | Exports `match_inbox_providers.dart`                                                                                                                                                                        |
| `lib/services/social/match_service.dart`                             | `_createMatch` now calls `MatchInboxService.instance.createMatch(..., source: MatchSource.discovery)` after a mutual like match is created                                                                  |
| `lib/features/speed_dating/screens/speed_dating_session_screen.dart` | `_handleMutualMatch()` calls `MatchInboxService.instance.createMatch(..., source: MatchSource.speedDating)` with session metadata                                                                           |
| `lib/services/chat/chat_service.dart`                                | `sendMessage()` now calls `MatchInboxService.instance.updateLastInteraction(senderUid, receiverUid)` non-blocking after every DM send — keeps `lastInteraction` fresh so `MatchTile` shows accurate timeago |
| `firestore.rules`                                                    | Added `/users/{uid}/matches/{matchId}` subcollection rules — owner-read, any-authenticated-create (for bidirectional batch writes), owner-update (mark seen), owner-delete (remove match)                   |

### Integration Points

| System            | Trigger                                 | Action                                                                             |
| ----------------- | --------------------------------------- | ---------------------------------------------------------------------------------- |
| Speed Dating      | Mutual like in session                  | `MatchInboxService.createMatch(source: speedDating)` + notification for both users |
| Discovery / Likes | Mutual like via `MatchService.likeUser` | `MatchInboxService.createMatch(source: discovery)` non-blocking                    |
| Chat (open)       | Tap MatchTile → open chat               | `markMatchAsSeen` called before navigation — clears NEW badge                      |
| Chat (send)       | Every DM message sent                   | `updateLastInteraction` called non-blocking — keeps MatchTile timeago accurate     |
| Profile           | Tap avatar on MatchTile                 | Navigates to `/profile/user?userId=...`                                            |
| Home Nav          | New unseen matches                      | Live pink badge on Matches tab (0–9+)                                              |

### Nav Bar Update

The bottom nav was extended from **6** to **7** tabs:

| Index | Tab         | Icon                 | Badge               |
| ----- | ----------- | -------------------- | ------------------- |
| 0     | Home        | `Icons.home`         | —                   |
| **1** | **Matches** | `Icons.favorite`     | ✅ Pink count badge |
| 2     | Speed       | `Icons.bolt`         | —                   |
| 3     | Rooms       | `Icons.video_call`   | —                   |
| 4     | Feed        | `Icons.dynamic_feed` | —                   |
| 5     | Chats       | `Icons.chat_bubble`  | —                   |
| 6     | Profile     | `Icons.person`       | —                   |

---

## Room Discovery Implementation

> **Date:** February 2026
> **Status:** ✅ Complete — `flutter analyze --no-fatal-infos` → **No issues found!**

### Overview

The Rooms tab was fully rebuilt from scratch with the design system, Riverpod 3-compatible providers, and a polished neon UI. The old implementation (red `#FF4C4C` styling, no design system, basic list) was replaced with a feature-complete discovery experience.

### New Files Created

| File                                                            | Purpose                                                                                                                                                    |
| --------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `lib/features/discover/providers/room_discovery_providers.dart` | All Riverpod state: vibe filter, category filter, search query, filtered rooms, heating-up rail, featured rooms, category room counts                      |
| `lib/features/discover/widgets/room_discovery_card.dart`        | `RoomDiscoveryCard` (full-width list card) + `RoomDiscoveryCardCompact` (160px horizontal rail card) with 6 badge sub-widgets and vibe/type colour helpers |

### Existing Files Replaced / Modified

| File                                                      | Changes                                                                                                                                                                                                  |
| --------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `lib/features/discover/room_discovery_page_complete.dart` | **Full rewrite** — design-system colours, vibe chip row, category chip row with live counts, Heating Up horizontal rail, Featured banner, filtered SliverList, empty state with Go Live CTA, error state |
| `lib/shared/providers/all_providers.dart`                 | Exports `room_discovery_providers.dart`                                                                                                                                                                  |

### Room Discovery UI Sections

1. **Search Bar + Go Live Button** — sticky header; search updates `discoverySearchQueryProvider` live
2. **Vibe Filter Chips** — `[All, Chill, Hype, Deep Talk, Late Night, Study, Party]` with neon accent colours per vibe
3. **Category Chips** — `[All, Music, Gaming, Chat, Entertainment, Education, Sports, Technology, Lifestyle]` with live room counts
4. **🔥 Heating Up Rail** — horizontal rail of `RoomDiscoveryCardCompact` from `heatingUpRoomsProvider`
5. **Featured Banner** — gold gradient card for the top boosted room (hidden when filtering)
6. **Section Header** — "All Live Rooms" or active filter label with Clear button
7. **Filtered Room List** — `SliverList` of `RoomDiscoveryCard` from `filteredLiveRoomsProvider`
8. **Empty State** — contextual message + Clear Filters or Go Live CTA

### Riverpod 3 Note

`StateProvider` was removed in Riverpod 3.x. Discovery providers use `NotifierProvider.autoDispose` with a shared `_StringNotifier extends Notifier<String>` helper exposing a `set(String v)` method.

---

## Social Heartbeat Sweep

> **Date:** February 25, 2026
> **Status:** ✅ Complete — `flutter analyze --no-fatal-infos` → **No issues found!**

### Overview

Wired the Friend System, Notification System, and User Discovery into the Home tab to establish the social presence layer that makes the app feel alive.

### New Files Created

| File                                                                 | Purpose                                                                                                                                                                                                                                                                                                 |
| -------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `lib/features/discover_users/providers/active_friends_provider.dart` | `activeFriendsProvider` — real-time StreamProvider; opens one Firestore listener per friend's `/user_presence/{uid}` doc, merges with combine-latest pattern, sorts online first. `onlineFriendCountProvider` (int) and `activeOnlyFriendsProvider` (online+away only) derived providers also included. |

### Existing Files Modified

| File                                        | Changes                                                                                                                                                                                                                                                               |
| ------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `lib/features/home/home_page_electric.dart` | Added notification bell badge (live pink `9+` badge from `unreadNotificationCountProvider`); wired `ActiveFriendsRow` into Home tab driven by `activeFriendsProvider`; expanded CTA row to 3 cards: Start a Room, Speed Dating, **Find People** (→ `/discover-users`) |
| `lib/shared/providers/all_providers.dart`   | Exports `active_friends_provider.dart`                                                                                                                                                                                                                                |

### Home Tab Layout (after sweep)

```
┌─ Greeting + Vibe chip
│
├─ ● Active Now  ○ Friend1  ○ Friend2  ○ Friend3 …  (ActiveFriendsRow)
│
├─ [🔴 Start a Room] [⚡ Speed Dating] [👥 Find People]  (3-card CTA row)
│
├─ 💡 Vibe suggestion banner (dismissable)
│
└─ 🔥 Heating Up — room cards rail
```

### AppBar Badge

The notification bell now shows a live pink `●` badge using `unreadNotificationCountProvider` (exported from `notification_providers.dart`). Badge shows 1–9, then "9+". Hides when count is 0.

### `activeFriendsProvider` Architecture

- Watches `myFriendsProvider` (FriendEntry list) to get friend UIDs
- Opens one `snapshots()` listener per friend uid on `/user_presence/{uid}`
- Maps Firestore snap → `UserPresence` with status heuristic: explicit status field → recently active (< 2h lastSeen) → offline
- StreamController merges all listeners; emits sorted list (online → away → DND → offline) when all slots have data
- All subscriptions cancelled on `ref.onDispose`
- `activeOnlyFriendsProvider` filters to online + away (suited for compact UI use)

---

## ✅ Room Discovery Completion Sweep

**Status:** Complete — `flutter analyze` passes with no errors.

### New Files

| File                                                    | Purpose                                                                                                                                                                                                                                                                                     |
| ------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `lib/features/discover/widgets/room_preview_sheet.dart` | Full bottom-sheet room preview (~400 lines). Shows drag handle, LIVE/type/vibe/premium/hot badges, title, description, viewer/velocity stats, host row, friends-in-room strip, tags cloud, and Join/Request button. Used via `RoomPreviewSheet.show(context, room: room, onJoin: () => …)`. |

### Modified Files

| File                                                            | Changes                                                                                                                                                                                                                                                                                                                                              |
| --------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `lib/features/discover/providers/room_discovery_providers.dart` | Added `friendsInRoomProvider` (family by roomId — cross-references `liveRoomsProvider` participant list with `myFriendsProvider`); added `recommendedRoomsProvider` (scores rooms: `(friendsHere × 15) + (joinVelocity × 3) + (viewerCount × 0.2) + boostScore`, returns top 10)                                                                     |
| `lib/features/discover/widgets/room_discovery_card.dart`        | Upgraded from `StatelessWidget` → `ConsumerWidget`; watches `myFriendsProvider` to compute `friendsHere`; shows `_FriendsStrip` (stacked 20 px avatars + "X friends here" label) in card footer when ≥ 1 friend is present                                                                                                                           |
| `lib/features/discover/room_discovery_page_complete.dart`       | Added `_previewRoom(Room)` method (all card taps now open preview sheet before join); added `recommended = ref.watch(recommendedRoomsProvider)`; added **"For You"** sliver section (gradient badge + compact card horizontal rail) between Heating Up and Featured; updated heating-up, for-you, featured, and main list taps to use `_previewRoom` |

### New Providers

| Provider                   | Type                                                     | Description                                                                  |
| -------------------------- | -------------------------------------------------------- | ---------------------------------------------------------------------------- |
| `friendsInRoomProvider`    | `Provider.autoDispose.family<List<FriendEntry>, String>` | Friends of current user present in a specific room (keyed by roomId)         |
| `recommendedRoomsProvider` | `Provider.autoDispose<List<Room>>`                       | Top-10 rooms sorted by composite score (friends weight × 15 dominant factor) |

### Discovery Page Layout (after sweep)

```
┌─ Search bar + Invite friends button
│
├─ 🎨 Vibe filter chips (horizontal scroll)
│
├─ 🔥 Heating Up  ──  compact card rail (each → preview sheet)
│
├─ ✨ For You  ──  personalised compact card rail (friends × 15 score)
│   (hidden when filters are active)
│
├─ 🎯 Featured  ──  large banner card (→ preview sheet)
│
└─ All Rooms list  ──  full-width cards (each → preview sheet)
```

### Room Preview Sheet — Content Structure

```
drag handle
── badges row ──────────────────────────────────────
  🔴 LIVE  │ 🎯 Type  │  VibeTag  │ ⭐ Premium  │ 🔥 Hot
──────────────────────────────────────────────────
  Room Title (large)
  Room description (clamped to 3 lines)
── stats row ────────────────────────────────────────
  👁 viewers   ⚡ /min velocity   👥 capacity
── host row ─────────────────────────────────────────
  Avatar  Hosted by HostName
── friends here (if any) ───────────────────────────
  🟣 [ avatar ] [ avatar ] [ avatar ] + 2 friends here
── tags ─────────────────────────────────────────────
  #tag1  #tag2  #tag3 …
── action ───────────────────────────────────────────
  [ Join Room ] / [ Request to Join ] (locked rooms)
```

---

## ✅ UI Polish Sweep

**Status:** Complete — `flutter analyze` passes with no errors.

### Skeleton Loaders

| File                                                        | Change                                                                                                                  |
| ----------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| `lib/features/feed/social_feed_page.dart`                   | Loading state replaced with 5× SkeletonTile list; RefreshIndicator wraps ListView; HapticFeedback.lightImpact() on like |
| `lib/features/chat/screens/chat_list_page.dart`             | Loading state replaced with 5× SkeletonTile; EmptyState widget with "Find People" CTA → AppRoutes.discoverUsers         |
| `lib/features/profile/screens/user_discovery_page_new.dart` | Loading grid replaced with 6× SkeletonCard; empty state colors fixed to DesignColors.textPrimary/textGray               |

### Haptic Feedback Added

| Location                | Trigger                       |
| ----------------------- | ----------------------------- |
| Social feed like button | HapticFeedback.lightImpact()  |
| Room discovery join     | HapticFeedback.mediumImpact() |
| Chat send button        | HapticFeedback.lightImpact()  |

---

## ✅ Onboarding Routing Fix (Critical Bug)

**Status:** Complete.

### Problem

Both neon_signup_page.dart and create_profile_page.dart navigated to /app after completion. /app is NOT a registered route in AppRoutes — every new user saw a "Route not found" black screen.

### Fixes Applied

| File                     | Old Route | New Route               |
| ------------------------ | --------- | ----------------------- |
| neon_signup_page.dart    | /app      | AppRoutes.createProfile |
| create_profile_page.dart | /app      | AppRoutes.home          |
| splash_page.dart         | /login    | AppRoutes.onboarding    |

Correct new-user flow: Splash → Onboarding → /signup → /create-profile → /home

---

## ✅ Error Handling

**Status:** Complete.

- **Offline Banner**: home_page_electric.dart \_buildBody() wraps body in Column([OfflineBanner(), Expanded(child: body)])
- **Web-Safe Connectivity**: connectivity_provider.dart skips dns lookup on web (kIsWeb guard)
- **Chat Send Error Recovery**: send is async, text cleared before write (optimistic), try/catch restores text and shows SnackBar on failure

---

## ✅ Analytics Integration

**Status:** Complete.

| File                              | Events                                           |
| --------------------------------- | ------------------------------------------------ |
| room_discovery_page_complete.dart | trackRoomJoined, logEvent('room_preview_opened') |
| home_page_electric.dart           | trackScreenView per tab (7 tabs)                 |
| match_inbox_service.dart          | logEvent('match_created') after batch.commit()   |

---

## ✅ Security Hardening

**Status:** Complete.

### Input Length Limits

| Field            | File                           | Limit                         |
| ---------------- | ------------------------------ | ----------------------------- |
| Chat message     | chat_page.dart                 | maxLength: 1000               |
| Display name     | create_profile_page.dart       | maxLength: 40 + validator     |
| Username         | neon_signup_page.dart          | maxLength: 30                 |
| Email            | neon_signup_page.dart          | maxLength: 254                |
| Post content     | create_post_dialog.dart        | maxLength: 500 (pre-existing) |
| Room title       | create_room_page_complete.dart | maxLength: 50 (pre-existing)  |
| Room description | create_room_page_complete.dart | maxLength: 200 (pre-existing) |

### NeonInputField Enhancement

lib/shared/widgets/neon_components.dart: Added optional int? maxLength parameter. When null (default) counter is hidden via no-op buildCounter. When set the counter shows.

### Firestore Rules Audit

No open rules found. Message 5000-char limit confirmed in rules.

```

---

## ANALYTICS COVERAGE AUDIT — February 25, 2026

> **Status:** Complete. All 8 phases implemented. `flutter analyze --no-fatal-infos` → 0 errors, 0 warnings.

---

### PHASE 1 — Audit Results

**Screens already instrumented (pre-existing):**
`screen_home`, `screen_discover`, `screen_room_discovery`, `screen_chat`, `screen_profile` (own), `screen_match_inbox`, `screen_notifications`, `screen_friends_list`, `screen_speed_dating_session`, `screen_feed`, `screen_settings`, `screen_ads_admin`, `screen_onboarding_step_0..4`

**Gaps identified (resolved below):**
- `UserProfilePage` — missing screen_profile + profile_viewed
- `RoomPage` — missing screen_room + room_join_success + room_leave
- `FriendRequestButton` — missing friend_request_sent + friend_request_accepted

---

### PHASE 2 — Screen View Events Added

| Screen | File | Event |
|--------|------|-------|
| UserProfilePage | `profile/screens/user_profile_page.dart` | `screen_profile` |
| RoomPage | `room/screens/room_page.dart` | `screen_room` |

`UserProfilePage` converted from `ConsumerWidget` → `ConsumerStatefulWidget` for proper `initState` hook.

---

### PHASE 3 — Funnel Events

Pre-existing: `onboarding_started`, `onboarding_step_viewed`, `onboarding_step_completed`, `onboarding_completed`, `age_verified`.

New (SharedPreferences once-only guards):

| Milestone | Guard Key | Auto-trigger |
|-----------|-----------|-------------|
| `first_room_join` | `analytics_first_room_join_done` | — |
| `first_chat_sent` | `analytics_first_chat_sent_done` | — |
| `first_friend_added` | *(none)* | — |
| `activation_completed` | `analytics_activation_completed_done` | when room + chat both done |

Methods: `logFirstRoomJoinOnce`, `logFirstChatSentOnce`, `logFirstFriendAddedOnce`, `_checkActivationOnce`.

---

### PHASE 4 — Engagement Events

| Event | Status | Where |
|-------|--------|-------|
| `room_join_success` | **NEW** | `RoomPage._initializeVideo()` |
| `room_join_failed` | **NEW** | `RoomPage._initializeVideo()` catch |
| `room_leave` | **NEW** | `RoomPage.dispose()` |
| `chat_message_sent` | pre-existing | `ChatPage` send |
| `feed_post_liked` | pre-existing | `SocialFeedPage._toggleLike()` |
| `feed_post_commented` | pre-existing | `SocialFeedPage._showComments()` |
| `match_tile_opened` | pre-existing | `MatchInboxPage` |
| `match_message_button_tapped` | pre-existing | `MatchInboxPage` |
| `friend_request_sent` | **NEW** | `FriendRequestButton` |
| `friend_request_accepted` | **NEW** | `FriendRequestButton` |
| `discover_user_liked` | pre-existing | `DiscoverUsersPage._flyOut()` |
| `discover_user_viewed` (skip) | pre-existing | `DiscoverUsersPage._flyOut()` |
| `profile_viewed` | **NEW** | `UserProfilePage.initState()` |
| `speed_dating_round_started` | pre-existing | `SpeedDatingSessionScreen` |
| `speed_dating_match_created` | pre-existing | `SpeedDatingSessionScreen` |

---

### PHASE 5 — Ads Analytics

Pre-existing in `AdTileWidget`: `ad_impression(adId, advertiserId, placement)` + `ad_click(...)` — both impressions and clicks fully wired on both tile types.

---

### PHASE 6 — Error & Retry Analytics

Pre-existing: `async_value_view_enhanced.dart` (P2F layer), `ChatPage` catch → `logNetworkError`.
Available service methods: `logFirestoreWriteError`, `logFirestoreReadError`, `logNetworkError`, `logRetryTapped`, `logOfflineModeEntered`, `logOfflineModeExited`.

---

### PHASE 7 — AnalyticsService Enhancements

File: `lib/core/analytics/analytics_service.dart`

- Added `shared_preferences` import
- Added `logFirstRoomJoinOnce`, `logFirstChatSentOnce`, `logFirstFriendAddedOnce`
- Added `_checkActivationOnce` (auto-fires `activation_completed`)
- All calls non-blocking (try/catch), debug logging via `debugPrint` (release-safe)
- Typed helpers confirmed: `logScreenView`, `logFunnelMilestone`, `logEngagement`, `logAdEvent`

---

### Files Modified

| File | Change |
|------|--------|
| `lib/core/analytics/analytics_service.dart` | SharedPreferences milestones + once-only helpers |
| `lib/features/room/screens/room_page.dart` | screen_room, room join/leave analytics |
| `lib/features/profile/screens/user_profile_page.dart` | ConsumerStateful + screen_profile + profile_viewed |
| `lib/features/profile/widgets/friend_request_button.dart` | friend_request_sent/accepted + first_friend_added |
| `lib/features/chat/screens/chat_page.dart` | first_chat_sent_once milestone |

### flutter analyze
```

flutter analyze --no-fatal-infos → 0 errors, 0 warnings
18 pre-existing prefer_const_constructors infos (unrelated to analytics sweep)

```

---

## Room Discovery Implementation Sweep — 8-Phase Complete

**Date:** Phase complete (continuation session)
**Status:** ✅ All 8 phases implemented. `flutter analyze --no-fatal-infos` → 0 errors.

### Phase 1 — Firestore Queries & Riverpod Providers

**`lib/services/room/room_discovery_service.dart`**
- Added `getTrendingRoomsTyped({int limit})` — `isActive==true` ordered by `viewerCount` desc
- Added `getNewRoomsTyped({int limit})` — `isActive==true` ordered by `createdAt` desc
- Added `getFriendsInRoomsTyped(List<String> friendIds)` — `array-contains-any` with 30-item chunk support
- Added `getRecommendedRoomsTyped({interests, categories})` — category/tag filters with trending fallback

**`lib/features/discover/providers/room_discovery_providers.dart`**
- Added `trendingRoomsProvider` — top 20 rooms by `viewerCount` desc
- Added `newRoomsProvider` — 20 most recently created rooms by `createdAt` desc
- Added `friendsInRoomsProvider` — rooms where any `participantId` is in the user's friends set
- Added `DiscoveryCombinedData` class — bundles trending/new/friends/recommended + isLoading
- Added `roomDiscoveryCombinedProvider` — single provider combining all 4 data sources for UI

### Phase 2 — UI Components

**`lib/features/discover/widgets/room_preview_card.dart`** *(new file)*
- Compact 180×220 horizontal-scroll card with glow animation on hover (web) + haptic tap (mobile)
- Contains: `_LiveBadge`, `_TypeIconBadge`, `_ViewerCount`, thumbnail fallback with initials

**`lib/features/discover/widgets/room_discovery_section.dart`** *(new file)*
- Reusable section widget: gradient title header + horizontal `ListView` rail
- Skeleton shimmer loaders (`_SkeletonRow` / `_SkeletonCard`) while data loads
- Empty state with icon + message; error state with retry `OutlinedButton`
- `AdTileWidget` injected every N cards (`adEvery`, default 8)

**`lib/features/discover/widgets/room_preview_sheet.dart`** *(modified)*
- Added `discovery_room_preview_opened` analytics event on sheet open
- Added `discovery_room_join_tapped` analytics event on Join button tap

**`lib/features/discover/room_discovery_page.dart`** *(rewritten)*
- 4-section `CustomScrollView`: 🔥 Trending Now, ✨ New Rooms, 👥 Friends in Rooms, ⭐ Recommended
- Sticky `SliverAppBar` with ShaderMask gradient title + Go Live CTA
- `_SectionWrapper` widget fires `discovery_section_viewed` on first render (Phase 5)
- Scroll depth milestones (25/50/75/100%) logged via `discovery_scroll_depth` event

### Phase 3 — Ads Integration

- `AdBannerWidget(placement: AdPlacement.discover, height: 72)` at top and between each section
- `AdTileWidget(placement: AdPlacement.discover)` embedded in card rails every 8 cards
- `userIsAdult` flag wired; ready to connect to user profile age check

### Phase 4 — Navigation & Routing

**`lib/features/home/home_page_electric.dart`**
- Import changed from `room_discovery_page_complete.dart` → `room_discovery_page.dart`
- `_buildRoomsTab()` now returns `const RoomDiscoveryPage()` (was `RoomDiscoveryPageComplete`)
- `/discover-rooms` route in `app_routes.dart` already mapped to `RoomDiscoveryPage()` — no change needed

### Phase 5 — Analytics Events

| Event | Trigger |
|-------|---------|
| `screen_room_discovery` | Page `initState` (screen view) |
| `discovery_section_viewed` | First render of each section |
| `discovery_scroll_depth` | 25/50/75/100% scroll milestones |
| `discovery_room_preview_opened` | Bottom-sheet opened for a room |
| `discovery_room_join_tapped` | Join button tapped in sheet |

All events use `core_analytics.AnalyticsService.instance` (singleton, `lib/core/analytics/`).

### Phase 6 — Error Handling & Loading States

- `RoomDiscoverySection` shows animated skeleton cards while `isLoading == true`
- Error message + retry button shown when `errorMessage != null`
- Empty state shown when room list is empty and not loading
- All analytics calls wrapped in implicit try/catch via `AnalyticsService.instance`

### Phase 7 — UI Polish

- Neon gradient title with `ShaderMask` (pink → purple) on discovery page header
- Go Live CTA button with gradient + glow shadow in app bar
- `RoomPreviewCard` hover glow animation using `AnimationController`
- `BouncingScrollPhysics` on horizontal rails and main scroll view
- Dark card background with `DesignColors.surfaceLight` and `DesignColors.accent` accents

### Phase 8 — Documentation

**Files created/modified in this sweep:**

| File | Action |
|------|--------|
| `lib/services/room/room_discovery_service.dart` | Modified — 4 typed query methods added |
| `lib/features/discover/providers/room_discovery_providers.dart` | Modified — 5 new providers + DiscoveryCombinedData |
| `lib/features/discover/widgets/room_preview_card.dart` | Created |
| `lib/features/discover/widgets/room_discovery_section.dart` | Created |
| `lib/features/discover/widgets/room_preview_sheet.dart` | Modified — analytics events |
| `lib/features/discover/room_discovery_page.dart` | Rewritten — 4-section discovery page |
| `lib/features/home/home_page_electric.dart` | Modified — `_buildRoomsTab` updated |

### flutter analyze (post-sweep)
```

flutter analyze --no-fatal-infos → 0 errors
19 issues: 1 warning (pre-existing unused_field removed), 18 infos (pre-existing prefer_const_constructors)
Final: 0 errors, 0 warnings after sweep fixes applied

```

---

## UI Polish Sweep — Session Log

### Overview
Full 6-phase UI polish run across all primary user-facing screens. No renames, no breaking changes, source of truth = existing codebase.

---

### Phase 1 — Profile Polish ✅
**File:** `lib/features/profile/screens/profile_page.dart`
- Added `_buildGallerySection(UserProfile p)`: 3-column `GridView.builder`, max 6 photos, "+N more" dark overlay on the 6th tile when gallery has more
- Added `_viewGalleryPhoto(String url)`: full-screen `Dialog` with `Image.network` hero viewer
- Wired into `_buildContent` after the bio section
- Existing features preserved: neon glow avatar ring, neon dividers, vibe chips, badges section

---

### Phase 2 — Feed Polish ✅
**File:** `lib/features/feed/social_feed_page.dart`
- Added import for `app_routes.dart`
- Changed `AlwaysScrollableScrollPhysics()` → `BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics())`
- Added `_EmojiReactionBar` StatefulWidget: 4 emojis (❤️ 😂 🔥 😮), local state, animated neon highlight on active emoji
- Analytics: `feed_reaction_tapped` logged on emoji tap
- Wired share `IconButton` to `showModalBottomSheet` with `_PostShareSheet`
- `_PostShareSheet`: "Share to Chat" → `AppRoutes.chats`, "Share to Room" → `AppRoutes.discoverRooms`
- Analytics: `feed_share_to_chat`, `feed_share_to_room` logged on selection
- Added `_ShareOption` reusable tile widget with neon border + icon

---

### Phase 3 — Chat Polish ✅
**File:** `lib/features/chat/screens/chat_page.dart`
- Added `import 'package:mixmingle/core/design_system/design_constants.dart'`
- Added state: `ChatMessage? _replyToMsg`, `bool _hasText`
- Added `_hasText` listener in `initState` for animated send button
- `ListView.builder` physics: `BouncingScrollPhysics()`
- **Neon gradient message bubbles**: own messages → blue→purple `LinearGradient` with accent glow shadow; others → `DesignColors.surfaceLight` with `bottomLeft` tail
- **Long-press reply**: `GestureDetector.onLongPress` sets `_replyToMsg`, logs `chat_reply_used`
- **Reply preview bar**: amber left-border container shown above input when replying, with close button
- **Animated send button**: `AnimatedScale(scale: _hasText ? 1.0 : 0.82)` wrapping gradient circle with `Icons.send_rounded`
- **Fix**: `ScaffoldMessenger` captured before `await` to resolve `use_build_context_synchronously` warning

---

### Phase 4 — Room Polish ✅
**Files:** `lib/features/room/screens/room_page.dart`, `lib/features/room/widgets/participant_list_sidebar.dart`

**room_page.dart:**
- Added `_RoomTypeBadge` widget: neon pill chip with color-coded icon/label per `RoomType` (`video` = pink, `text` = blue, `voice` = cyan)
- Inserted `_RoomTypeBadge(roomType: currentRoom.roomType)` in the app bar row after the lock badge

**participant_list_sidebar.dart:**
- **Host Spotlight Card**: when `isHost == true`, replaces the generic `ListTile` with a premium amber-gradient `Container`:
  - Amber gradient border (`Colors.amber.withValues(alpha: 0.55)`)
  - Amber box glow shadow
  - `CircleAvatar(radius: 24)` with `Icons.workspace_premium`
  - `👑` badge Positioned above-right of the avatar
  - Bold white name + "Host 👑" amber subtitle label
  - "Host · You" shown for current user who is host
- All other participants: unchanged `ListTile` (moderator, speaker, listener roles)

---

### Phase 5 — Global Scroll Physics ✅
Added `BouncingScrollPhysics` to all unpolished scroll views:

| File | Location |
|------|----------|
| `lib/features/match_inbox/screens/match_inbox_page.dart` | `GridView.builder` main grid |
| `lib/features/discover/screens/browse_rooms_page.dart` | Horizontal categories `ListView` + main rooms `ListView.builder` |
| `lib/features/discover/screens/discover_users_page.dart` | Search results `ListView.builder` + suggested users `ListView.builder` |

Already-polished (confirmed no change needed):
- `room_discovery_page.dart` — `CustomScrollView` had `BouncingScrollPhysics` ✅
- `room_discovery_section.dart` — horizontal rail had `BouncingScrollPhysics` ✅
- `post_auth_onboarding.dart` — primary button already has `boxShadow` glow ✅
- `room_preview_card.dart` — `AnimationController` hover glow already implemented ✅

---

### Phase 6 — Analytics Events Summary

| Event Name | File | Trigger |
|---|---|---|
| `feed_reaction_tapped` | `social_feed_page.dart` | Emoji reaction tapped on a post |
| `feed_share_to_chat` | `social_feed_page.dart` | "Share to Chat" selected in share sheet |
| `feed_share_to_room` | `social_feed_page.dart` | "Share to Room" selected in share sheet |
| `chat_reply_used` | `chat_page.dart` | Long-press on a message to reply |

All events use `AnalyticsService.instance.logEvent(name:, parameters:)`.

---

### flutter analyze (post-UI-polish-sweep)
```

flutter analyze --no-fatal-infos
18 issues found:

- 0 errors
- 1 warning: unused_field '\_hovered' in room_preview_card.dart (stale — field not present in current file)
- 17 infos: prefer_const_constructors in onboarding + admin pages (non-breaking style hints)

Result: ✅ Zero hard errors. Sweep complete.

```

---

## Launch Prep Sweep — 2026-02-25

### Files Modified

| File | Action |
|---|---|
| `flutter_launcher_icons.yaml` | Created — standalone icon config (Android adaptive, iOS, Web icons, iOS alpha removal) |
| `flutter_native_splash.yaml` | Updated — activated logo image, background `#080C14`, Android 12 support |
| `pubspec.yaml` | Added `flutter_native_splash: ^2.4.3` to dev_dependencies |
| `web/index.html` | Added `theme-color` meta, improved description, og: meta tags, Twitter card |
| `web/manifest.json` | Updated `short_name`, `background_color` (#080C14), `theme_color` (#080C14), description |
| `STORE_METADATA.md` | Created — full store listing copy, keywords, age rating, screenshot checklist |
| `LAUNCH_PREP_REPORT.md` | Created — all build outputs, manual steps, file manifest |

### Build Outputs

| Target | Result | Output Path | Size |
|---|---|---|---|
| `flutter build web --release` | ✅ Success | `build/web/` | 44.1 MB total / 4.52 MB main.dart.js |
| `flutter build apk --release` | ✅ Success | `build/app/outputs/flutter-apk/app-release.apk` | 277.2 MB |
| `flutter build ipa --release` | ⏳ Manual step — requires macOS | N/A | — |

### Issues Found & Fixed

| Issue | Fix |
|---|---|
| `flutter_native_splash.yaml` had commented-out image and wrong background color (#0D0D0D) | Updated to `#080C14` and activated `app_logo.png` |
| `web/manifest.json` had stale theme/background colors (#1a1a2e / #0A0A18) | Corrected to `#080C14` |
| `web/index.html` missing og:/Twitter meta tags | Added full social meta block |
| No standalone `flutter_launcher_icons.yaml` (web icons disabled) | Created standalone YAML with web icons enabled |
| `flutter_native_splash` missing from dev_dependencies | Added `^2.4.3` |

### flutter analyze (post-launch-prep)
```

flutter analyze --no-fatal-infos
24 issues found:

- 0 errors
- 0 warnings
- 24 infos: prefer_const_constructors (non-breaking style hints in onboarding/admin/discover files)

Result: ✅ Zero hard errors. Builds green. Launch Prep Sweep complete.

```

---

## 🚀 Launch Prep Sweep — Complete ✅

**Date:** 2026-02-25
All 6 phases delivered.

### Phase 1 — App Icon
- `flutter_launcher_icons.yaml` created with Android adaptive icon (`#080C14` background), iOS (alpha removed), and Web icons enabled
- All icon sizes generated: Android `mipmap-*`, iOS `xcassets`, `web/icons/` folder

### Phase 2 — Splash Screen
- `flutter_native_splash.yaml` updated: background `#080C14`, `app_logo.png` activated, Android 12 SplashScreen API support added
- `pubspec.yaml`: `flutter_native_splash: ^2.4.3` added to `dev_dependencies`
- Splash generated across Android, iOS, and Web

### Phase 3 — Branding & Web Metadata
- `web/index.html`: `theme-color` meta, improved description, full `og:` block, Twitter card tags added
- `web/manifest.json`: `short_name` → `"MixMingle"`, both color fields corrected to `#080C14`
- Android (`"Mix & Mingle"`), iOS (`"Mix & Mingle"`), `main.dart` — all confirmed correct, no changes needed

### Phase 4 — Builds

| Target | Result | Size |
|---|---|---|
| `flutter build web --release` | ✅ | 44.1 MB / 4.52 MB JS |
| `flutter build apk --release` | ✅ | 277.2 MB |
| `flutter analyze --no-fatal-infos` | ✅ 0 errors | 24 infos only |

### Phase 5 & 6 — Documentation
- `STORE_METADATA.md` created
- `LAUNCH_PREP_REPORT.md` created
- `FULLSTACK_DEBUG_REPORT.md` updated (this entry)

### ⚠️ 3 Critical Manual Steps Before Store Submission

| # | Action |
|---|---|
| 1 | Replace `assets/images/app_logo.png` with final 1024×1024 production PNG, then re-run `dart run flutter_launcher_icons` and `dart run flutter_native_splash:create` |
| 2 | Build IPA on macOS: `flutter build ipa --release` |
| 3 | Swap `google-services.json` / `GoogleService-Info.plist` to **production** Firebase project before signing and submitting |

```
