# MIX & MINGLE — DESIGN BIBLE

**Version 1.0** | Effective February 2026 | Binding for all UI/UX decisions

---

## A. PRODUCT PERSONALITY

### Core Identity

**Social. Welcoming. Real. Fast. Human.**

Mix & Mingle is a real-time social platform where people _arrive, participate, and leave_—not a chat app where they _login and type_.

### Tone Rules (Non-Negotiable)

1. **Never use system language**
   - ❌ "Connection established"
   - ✅ "You're live with Sarah, James, and 4 others"

2. **Never expose implementation details**
   - ❌ "Firebase error: permission_denied"
   - ✅ "Something went wrong. Try joining again."

3. **Always describe actions as human events**
   - ❌ "Toggle input state"
   - ✅ "Mute your mic"
   - ❌ "Presence document updated"
   - ✅ "Emma just arrived"

4. **Voice is conversational, not corporate**
   - ❌ "Kindly enable your audio input device"
   - ✅ "We need your mic on. Ready?"

5. **Copy acknowledges time and emotion**
   - ❌ "Loading…" (after 2s)
   - ✅ "This is taking a moment…" (after 2s)
   - ✅ "Just a few more seconds…" (after 5s)

---

## B. VISUAL HIERARCHY RULES

### What Must Always Be Visible First

1. **People (presence)**
   - Who's here now
   - Who's speaking
   - Recent arrivals
2. **What's happening**
   - Room topic/activity
   - Call status (connecting, live, ended)
3. **Action buttons** (minimal set)
   - Mute/unmute
   - Leave
   - Settings (secondary)

### What Is Secondary

- Room description
- Participant list (if >5 people)
- Chat history
- Settings

### What Should Fade Into Background

- Technical stats
- Debug info
- Empty calendar states
- Rarely-used settings

---

## C. MOTION PHILOSOPHY

### Core Principle

**Every motion communicates something. No motion is free.**

### Rules

1. **Micro-delays are intentional**
   - Join button clicked → 150ms before spinner shows (feels responsive)
   - Spinner shows → 300ms minimum (feels deliberate, not instant)
   - Joining notification → fade in slowly (feels like arrival, not data update)

2. **Joining a room is ceremonial**
   - Not: instant join, no feedback
   - But: "Entering room…" (150ms) → "Connecting audio…" (400ms) → "You're live" (fade in)
   - Total: 700ms minimum, visible every step

3. **Presence must be animated**
   - User joins → their card **slides in from left** (250ms easing: easeOutCubic)
   - User leaves → their card **fades out + slides away** (200ms)
   - User speaks → their card **pulses once** (gentle scale 1.0 → 1.05)
   - Never: instant disappear, no animation

4. **No gratuitous animations**
   - If something moves, it must answer: "Why?"
   - If no answer, remove the motion
   - Acceptable reasons: "Shows arrival", "Indicates activity", "Provides feedback"

5. **Color shifts happen, not flashes**
   - Status change (speaking) → color transitions over 200ms
   - Not: instant color change

---

## D. SOCIAL PROOF DOCTRINE

### Principle

**Users should NEVER feel alone. Always show presence, activity, and momentum.**

### What Must Always Display

1. **Current participant count** (with real-time updates)
   - "You're here with 7 others" (not "7 active users")

2. **Who just arrived** (notification + card animation)
   - "Sarah just joined" → her card appears

3. **Who's speaking** (visual indicator + label)
   - Speaking participant highlighted, name shown
   - Icon shows they're transmitting audio

4. **Energy level of room**
   - Visual cue: calm (gray/blue), active (amber), buzzing (red/pink)
   - Based on: speech frequency, participant count, duration

5. **Recent activity in room description**
   - "🔥 Buzzing | 12 people | Started 4 min ago"

6. **Absence should trigger reflection, not emptiness**
   - Empty room: "Be the first to join—start the conversation"
   - Not: blank screen

---

---

# 2. SCREEN-BY-SCREEN UI & UX UPGRADE PLAN

## A. AUTH / ENTRY FLOW

### Non-Negotiable Sequence

```
User lands on app
    ↓
[IF LOGGED OUT] → Welcome screen (context, not pitch)
    ↓
Auth (login/signup)
    ↓
Username/display name (lightweight, 1 field)
    ↓
Room discovery
    ↓
[NEVER]: Jump straight into a room
[NEVER]: Force 10-field form on new users
```

### Welcome Screen Changes

- **What it shows**: App tagline + one screenshot of a live room
- **What it doesn't show**: Feature list, why you need it, testimonials
- **Tone**: "Real people, real-time. No performance."
- **Button copy**: "Sign up" or "Join in" (not "Get started")

### Signup Copy Overhaul

- ❌ "Create your account"
- ✅ "Who are you?"
- ❌ "Enter your email"
- ✅ "Your email" (neutral label, no copy)

### Display Name Screen

- **One field only**: "What should we call you?"
- **Help text**: "First name works great"
- **Character limit**: 20 (hard limit, no explanation needed)
- **Validation**: Real-time (show immediately if <2 chars, "Need at least 2 letters")

---

## B. ROOM DISCOVERY (CRITICAL REDESIGN)

### Room Card Must Display (in order of visual hierarchy)

#### 1. Room Name (Large, prominent)

- Font: Bold, 18px minimum
- Color: Primary (not gray)

#### 2. Live Participant Count (Visual badge)

- Icon: Person + count
- Color: Green if >0, gray if 0
- Text: "7 active" (not "7 people", not "participant_count: 7")
- Animate: If count changes, badge glows once (50ms pulse)

#### 3. Room Energy Level (Visual indicator)

```
Calm      = Blue pulse (1 update per 10s or less)
Active    = Amber pulse (1-2 updates per second)
Buzzing   = Red/pink pulse (3+ updates per second)
```

- Don't show % or numeric data
- Show only the visual pulse

#### 4. Speaking Indicator (Animated)

- If someone is speaking: Show their avatar + name fading in/out (sync to audio)
- Text: "Sarah is speaking…" (not "active speaker")

#### 5. Room Topic/Description (Secondary)

- Single line, truncated
- Font: 12px, gray
- Example: "Music production talk"

#### 6. Last Activity Time (Tertiary, subtle)

- "Started 4 minutes ago" (not "4m" timestamp)
- Font: 10px, very light gray

### Card Visual Design

- Border: Subtle gradient left edge (room's dominant color)
- Background: Slightly transparent (white/light theme friendly)
- On hover: Lift effect (transform: translateY(-4px)), shadow increase
- Spacing: 16px padding inside, 12px between cards
- No "Join" button on card—card itself is clickable (entire area)

### Empty State (No Rooms)

- Icon: Calendar or door with smile
- Heading: "No rooms right now"
- Subtext: "Be the first to create one—or check back in a few minutes"
- Button: "Create a room" (primary), "Back to home" (secondary)

---

## C. JOIN FLOW (3-Stage Ritual)

### Stage 1: "Entering room…"

- Duration: 150ms
- User sees: Room name, participant list (grayed out), controls disabled
- What happens (silent): Auth check, Firestore read for room metadata
- Feeling: Anticipation

### Stage 2: "Connecting audio & video…"

- Duration: 400–1000ms (depends on network)
- User sees:
  - Spinner (centered, blue)
  - Underneath: "Requesting camera & microphone…"
  - Participant list (if ready) starts fading in
- What happens: Agora SDK init, permission dialog (if needed), join channel
- Feeling: Loading with context

### Stage 3: "You're live"

- Duration: 400ms fade-in
- User sees:
  - Participant cards animate in (staggered, 50ms apart)
  - Their local video appears in corner
  - Controls all active (mute, leave, ...)
  - "You're live with Emma" notification (top, fade in 400ms, stay 3s, fade out)
- What happens: Final checks, Firestore presence write, stream listeners active
- Feeling: Arrival, celebration

### Failure States (in join flow)

**Permission Denied**

- Stage: During stage 2
- You see:
  - Icon: Blocked camera/mic
  - Text: "We need your camera. Check if it's blocked in your browser settings."
  - Buttons: "Retry" (primary), "Join without video" (secondary, if app allows)
- What happens: Show FAQ link, offer retry in 5s

**Network Timeout**

- Stage: Stage 2, after 10s
- You see:
  - Icon: Connection broke
  - Text: "Your connection is slow. We'll keep trying…"
  - Beneath: "You'll join as soon as it's ready"
- What happens: Retry every 3s (exponential backoff), show attempt #1, #2, #3

**Room Full**

- Stage: Stage 1
- You see:
  - Icon: House overflow
  - Text: "This room is full (50 max people)."
  - Suggestion: "Try [BrowseOtherRoomsBtn] or wait for someone to leave"
- What happens: Redirect to room discovery, highlight similar rooms

---

## D. IN-ROOM EXPERIENCE

### Participant Card (In-Room)

**Always shows (in order)**

1. Avatar (large, 48px)
2. Display name (bold, 14px)
3. Mute indicator (icon below name if mic off)
4. Speaker indicator (animated pulse if speaking)
5. Join time (subtle: "5 min ago")

**On speaker activity:**

- Card **glows** (box-shadow: 0 0 12px rgba(255, 79, 79, 0.5)) for 200ms
- Background slightly lightens
- Speaker name **bolds** (if not already)

**On arrival:**

- Card slides in from left (250ms, easeOutCubic)
- "Emma just joined" notification (top-right, fade in 150ms, auto-dismiss 3s)

**On departure:**

- Card fades out (200ms)
- Card slides down slightly (200ms)
- "Emma left the room" notification (top-right, subtle)

### Control Bar (Bottom)

**Layout:** Horizontal, centered, 4 controls maximum

1. **Mute Audio** (left-most)
   - Icon: Mic (filled) or mic-off
   - Color: Green (active) / Gray (muted)
   - Label below: "Mic" (small)
   - On click: Instant visual change + 100ms delay before muting (so user sees feedback)

2. **Mute Video** (2nd)
   - Icon: Video camera or camera-off
   - Color: Green (active) / Gray (muted)
   - Label: "Video"

3. **Settings** (3rd, only on desktop)
   - Icon: Gear / Settings
   - Label: "Settings"
   - Opens drawer (not modal)

4. **Leave** (right-most, prominent)
   - Icon: Door / exit
   - Color: Red (#FF4C4C)
   - Label: "Leave"
   - On click: Modal confirmation "Ready to go?" with "Leave" (red) and "Stay" buttons

### Status Bar (Top of Room)

**Left side:**

- Room name
- Participant count badge (updates real-time)
- Energy level indicator (pulse)

**Right side:**

- Call duration timer (if >2 min: "15:24 / 1 hr 30 min", else hidden)
- Room info button (icon: info-circle)

### Empty Seats (If <5 participants)

- Show 1–2 empty avatar placeholders
- Text: "Room for [X] more"
- Placeholder color: Light gray, dashed border
- Encourages inviting friends

---

---

# 3. OUTGROW PALTALK STRATEGY

## A. Positioning (Not Copying)

### Paltalk (Old Paradigm)

- Dense, information-heavy interface
- User feels like they're managing a system
- Lots of buttons, menus, settings visible
- Asynchronous conversation (users scroll, type slowly)
- Visual noise (colored backgrounds, excessive text)

### Mix & Mingle (New Paradigm)

- **Clarity-first**: Only what matters is visible
- **Presence-driven**: You feel the people, not the interface
- **Real-time-native**: Built for live conversation, not chat
- **Intentional slowness**: Join feels ceremonial, not instant
- **Visual calm**: Lots of white space, single color accent (#FF4C4C)

---

## B. Explicit Differentiators

| Dimension            | Paltalk                       | Mix & Mingle                                               |
| -------------------- | ----------------------------- | ---------------------------------------------------------- |
| **Layout**           | Sidebar + room + chat sidebar | Full-screen room, presence cards centered                  |
| **Participant list** | Scrollable text list on side  | Large animated cards, max 8 visible, rest in drawer        |
| **Onboarding**       | 3–5 screens of features       | 1 welcome, 1 auth, 1 name field → rooms                    |
| **Copy**             | Technical, formal             | Conversational, human                                      |
| **Animation**        | Rare, feels clunky            | Frequent, emotional (arrivals, speaking)                   |
| **Room discovery**   | Browse rooms → instantly join | Browse rooms → see energy → ceremonial join                |
| **Status**           | Static participant count      | Real-time pulse, speaking indicator, arrival notifications |
| **Visual feel**      | Dense, gray/blue, corporate   | Clean, white/light, accent color only                      |

---

## C. What NOT to Copy

1. ❌ Sidebar layout (cramped)
2. ❌ Text-heavy room description
3. ❌ Scrolling participant lists
4. ❌ Outdated onboarding flows
5. ❌ Multiple windows (chat, room, settings all open)
6. ❌ Instant joins (no transition)
7. ❌ Monochrome color scheme
8. ❌ Technical error messages

---

---

# 4. IMPLEMENTATION GUIDELINES (FLUTTER-SPECIFIC)

## A. Where to Add AnimatedPresence / Motion

### AnimatedOpacity + Transform (Arrival)

```dart
Participant card appears
→ Use: AnimationController + Tween(Offset.zero, Offset(-1, 0))
→ Duration: 250ms
→ Curve: easeOutCubic
→ Trigger: On Firestore presence.create event
```

### Pulsing (Speaking)

```dart
Speaker active
→ Use: Opacity + Transform(scale) animation
→ Duration: 200ms per pulse
→ Curve: easeInOut
→ Repeat: While audioLevel > threshold
```

### Fade + Slide (Departure)

```dart
User leaves room
→ Use: AnimatedOpacity + Transform(translateY)
→ Duration: 200ms
→ Curve: easeInCubic
→ Trigger: On presence.delete
```

---

## B. Join State Controller (Explicit Phases)

```dart
enum JoinPhase {
  entering,      // Stage 1: "Entering room…"
  connecting,    // Stage 2: "Connecting audio…"
  live,          // Stage 3: "You're live"
  error,         // Failed
  left,          // Left room
}

class JoinStateController extends StateNotifier<JoinPhase> {
  JoinStateController() : super(JoinPhase.entering);

  Future<void> performJoin() async {
    state = JoinPhase.entering;
    await Future.delayed(Duration(milliseconds: 150));

    state = JoinPhase.connecting;
    // Initialize Agora, request permissions
    await agoraInit(); // Takes 400–1000ms

    state = JoinPhase.live;
    // Show "You're live" notification (fade in)
  }
}
```

**In UI:**

```dart
switch(joinPhase) {
  case JoinPhase.entering:
    return buildEnteringUI();
  case JoinPhase.connecting:
    return buildConnectingUI();
  case JoinPhase.live:
    return buildLiveUI();
  // ...
}
```

---

## C. Presence Updates (Animated)

### Listen to Firestore Presence

```dart
// In VideoRoomLifecycle or similar
presenceStream = FirebaseFirestore.instance
  .collection('rooms/${roomId}/members')
  .snapshots()
  .listen((snapshot) {
    for (var docChange in snapshot.docChanges) {
      if (docChange.type == DocumentChangeType.added) {
        // New user joined → trigger slide-in animation
        _onUserArrived(docChange.doc);
      } else if (docChange.type == DocumentChangeType.removed) {
        // User left → trigger fade-out
        _onUserLeft(docChange.doc);
      }
    }
  });
```

### Display Arrival Notification

```dart
void _onUserArrived(DocumentSnapshot doc) {
  final userName = doc['displayName'];

  // Show "Emma just joined" (top-right, fade in, auto-dismiss)
  showArrivalNotification('$userName just joined');
}
```

---

## D. Audio Activity Detection (For Speaking Indicator)

```dart
// Use WebRTC stats on web, or Agora onRemoteAudioStateChanged on native
// Detect when audioLevel > threshold (e.g., -50dB)

void _onAudioActivity(String userId) {
  // Trigger pulse animation on that user's card
  // Update their presence card opacity/scale for 200ms
}

// Firestore-backed alternative:
// Store last_spoke: Timestamp in each presence doc
// Build UI with: "Speaking since 2 seconds ago"
```

---

## E. Intentional Delays (Non-Negotiable Timing)

### Join Button Click

```dart
onPressed: () async {
  await Future.delayed(Duration(milliseconds: 150)); // Feel response
  setState(() => joinPhase = JoinPhase.entering);
  await Future.delayed(Duration(milliseconds: 150)); // See change
  // Then proceed to connecting
}
```

### Mute Toggle

```dart
onPressed: () async {
  setState(() => isMuted = !isMuted); // Instant visual feedback
  await Future.delayed(Duration(milliseconds: 100)); // Psychological delay
  await agoraToggleMic(isMuted); // Actual action
}
```

### Join Notification (Arrival)

```dart
Future<void> _showArrivalNotification(String name) async {
  setState(() => showNotification = true);
  await Future.delayed(Duration(milliseconds: 150)); // Fade in
  await Future.delayed(Duration(seconds: 3)); // Visible for 3s
  setState(() => showNotification = false);
  // Fade out (handled by AnimatedOpacity)
}
```

---

## F. Avoiding Material Defaults (Visual Consistency)

### Don't Use:

- ❌ Material `FloatingActionButton` (outdated for this app)
- ❌ Standard `AppBar` (use custom top bar)
- ❌ Material card shadows (too heavy)
- ❌ Blue accent colors (use #FF4C4C)

### Do Use:

- ✅ Custom button with rounded corners (12px radius)
- ✅ Subtle border instead of shadow
- ✅ White/light backgrounds with accent color for active states
- ✅ Custom `AnimatedContainer` for state changes

### Example Custom Button

```dart
Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(12),
    color: isMuted ? Colors.gray[300] : Colors.green,
  ),
  child: InkWell(
    onTap: toggleMic,
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Icon(isMuted ? Icons.mic_off : Icons.mic),
          SizedBox(width: 8),
          Text('Mic'),
        ],
      ),
    ),
  ),
)
```

---

## G. Firestore + Agora State Surfacing

### Display Room Energy

```dart
double calculateRoomEnergy() {
  // Based on: message frequency, presence count, audio activity
  final messageRate = messagesInLast30Seconds / 30;
  final participantBonus = presentCount * 0.1;
  final audioBonus = activeSpeakers > 0 ? 0.5 : 0;
  return messageRate + participantBonus + audioBonus;
}

Color getRoomPulseColor(double energy) {
  if (energy < 0.5) return Colors.blue;
  if (energy < 2.0) return Colors.amber;
  return Colors.red;
}
```

### Display Recent Activity

```dart
String getRecentActivity() {
  final recent = messages.where((m) => m.createdAt.difference(now) < Duration(seconds: 10));
  if (recent.isEmpty) return 'Room started';
  return '${messages.last.senderName} spoke 3 seconds ago';
}
```

---

---

# 5. FINAL CHECKLIST (ENFORCEMENT)

## A. Design Bible Enforcement

- [ ] All copy reviewed against "Tone Rules"—no system language
- [ ] All buttons have explicit intention (250ms min delay + visual feedback)
- [ ] All animations answer "Why?" before being kept
- [ ] No empty states without reassurance
- [ ] Presence always shows: count, speaking, recent arrival
- [ ] Color palette: White/light + #FF4C4C accent only (no blues, grays, multi-colors)

## B. Auth & Entry Flow

- [ ] No direct room URL access (auth gate first)
- [ ] Welcome screen shows app once before auth
- [ ] Signup is: email → password → display name (3 screens max)
- [ ] Display name field: "What should we call you?" (not "Display Name")

## C. Room Discovery

- [ ] Room cards show: name, participant count, energy, speaking indicator
- [ ] Room cards animate on hover (lift + shadow)
- [ ] Entire card is clickable (not just "Join" button)
- [ ] Energy level shows pulse (not number)
- [ ] Empty state has reassuring copy

## D. Join Flow

- [ ] 3 visible stages: "Entering…" → "Connecting…" → "You're live"
- [ ] Minimum 700ms total join time
- [ ] Each failure state has friendly copy + retry option
- [ ] "You're live" notification fades in and auto-dismisses

## E. In-Room

- [ ] Participant cards animate in on arrival (slide from left)
- [ ] Participant cards animate out on departure (fade + slide)
- [ ] Speaking indicator pulses (not static)
- [ ] All controls feel like actions, not toggles
- [ ] Leave button requires confirmation
- [ ] Mute/video provide instant visual feedback + 100ms delay before actual mute

## F. Positioning

- [ ] No Paltalk layouts copied
- [ ] Copy is conversational (not technical)
- [ ] Presence-driven (people first, interface second)
- [ ] Real-time native (live conversation, not chat)

---

**This Design Bible is binding. Deviations require documented approval.**

**Last Updated:** February 2026
**Owned By:** Product + Design Leadership
