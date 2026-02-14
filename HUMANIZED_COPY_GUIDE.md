# 🎨 MIX & MINGLE — HUMANIZED COPY GUIDE

**Goal:** Transform every text string from generic/robotic to conversational, personality-driven, and emotionally resonant.

**Philosophy:** Humans feel before they think. Your copy should make people feel welcome, safe, and excited to connect.

---

## 1️⃣ AUTHENTICATION & ONBOARDING

### Splash Screen

**Current:**
```
🎵
MIX & MINGLE
(loading spinner)
```

**Humanized:**
```
🎵
MIX & MINGLE
Finding your people...
```

---

### Login Screen

**Current:**
- Title: "MIX & MINGLE"
- Email placeholder: "(empty)"
- Password placeholder: "(empty)"
- Button: "Login"
- Error: "Login failed: [error]"
- Sign up link: "Don't have an account? Sign up"

**Humanized:**

| Element | Current | Humanized |
|---------|---------|-----------|
| **Screen Title** | MIX & MINGLE | Hey again 👋 |
| **Subtitle** | (none) | Let's get you back in the room |
| **Email field hint** | (empty) | Your email |
| **Email field label** | (empty) | Email address |
| **Password hint** | (empty) | Your password |
| **Password label** | (empty) | Password |
| **Sign in button** | Login | Sign In |
| **Forgot password** | (none) | Forgot your password? |
| **Success feedback** | (redirect) | Welcome back! Loading your room... |
| **Error (wrong email)** | Login failed: user-not-found | Hmm, we don't recognize that email. Mind double-checking? |
| **Error (wrong password)** | Login failed: wrong-password | Wrong password. Give it another shot? |
| **Error (network)** | Login failed: network-request-failed | Can't reach our servers right now. Check your connection and try again. |
| **Sign up link** | Don't have an account? Sign up | New here? Create an account |

**Extra microcopy:**
- Under login button: "Takes about 2 seconds"
- After tapping sign in: "Signing you in..." (before loading spinner)

---

### Sign Up Screen

**Current:**
- Title: "JOIN MIX & MINGLE"
- Name placeholder: "(empty)"
- Email placeholder: "(empty)"
- Password placeholder: "(empty)"
- Confirm password: "(empty)"
- Button: "Sign Up"
- Error: "Please fill in all fields" / "Password validation failed"

**Humanized:**

| Element | Current | Humanized |
|---------|---------|-----------|
| **Screen Title** | JOIN MIX & MINGLE | Let's get you started 🎉 |
| **Subtitle** | (none) | It only takes 30 seconds, we promise |
| **Name field label** | Name | What's your name? |
| **Name field hint** | (empty) | e.g., Alex |
| **Email field label** | Email | Your email |
| **Email field hint** | (empty) | you@example.com |
| **Password label** | Password | Create a password |
| **Password hint** | (empty) | Min. 6 characters |
| **Confirm label** | Confirm Password | Confirm password |
| **Sign up button** | Sign Up | Create My Account |
| **Error (empty fields)** | Please fill in all fields | Oops — we need all the info 👆 |
| **Error (short password)** | Password must be at least 6 chars | Your password needs at least 6 characters |
| **Error (email taken)** | Email already registered | That email's already taken. Want to log in instead? |
| **Error (network)** | Signup failed: [error] | Can't connect right now. Try again in a sec? |
| **Success feedback** | (redirect) | Welcome to the party! 🎊 Setting up your profile... |
| **Login link** | Already have an account? Log in | Already have an account? Sign in here |

**Extra touches:**
- Progress indicator: "Step 1 of 2" (if multi-step)
- Character count for password: "6+ characters — you're good!" (when valid)

---

## 2️⃣ HOME SCREEN

**Current:**
- Title: "MIX & MINGLE"
- Welcome text: "Welcome to Mix & Mingle"
- User Profile Header
- Nav cards: "Rooms", "Speed Dating", "Messages", "Events", "Profile", "Notifications"
- Recent Activity title: "Recent Activity"

**Humanized:**

| Element | Current | Humanized |
|---------|---------|-----------|
| **App Bar Title** | MIX & MINGLE | (remove — show profile badge instead) |
| **Welcome Section** | Welcome to Mix & Mingle | Hey, [name]! 👋 |
| **Welcome Subtitle** | (none) | Ready to meet someone new? |
| **Rooms Card Title** | Rooms | Rooms |
| **Rooms Card Subtitle** | Join live rooms | Jump into a live room |
| **Speed Dating Title** | Speed Dating | Speed Dating |
| **Speed Dating Subtitle** | Play speed dating | Match & date in 60 seconds |
| **Messages Title** | Messages | Messages |
| **Messages Subtitle** | Chat with friends | Talk to your matches |
| **Events Title** | Events | Events |
| **Events Subtitle** | Upcoming events | See what's happening |
| **Profile Title** | Profile | Profile |
| **Profile Subtitle** | Your profile | Edit your vibe |
| **Notifications Title** | Notifications | Notifications |
| **Notifications Subtitle** | Updates & alerts | See what's new |
| **Activity Section** | Recent Activity | What's happening |
| **Settings button** | ⚙️ | (keep, but add tooltip) |
| **Logout button** | 🚪 | (keep, but tooltip: "Leave for now") |
| **Bottom nav** | Home, Rooms, Chat, Likes | Home, Rooms, Chat, Favorites |

**Microcopy:**
- Hover on settings: "Tune your experience"
- Hover on logout: "See you soon!"

---

## 3️⃣ BROWSE ROOMS

**Current:**
- Title: "Browse Rooms"
- Search placeholder: "Search rooms..."
- Category chips: "All", "Music", "Gaming", "Chat", "Live"
- Empty state title: "No rooms found"
- Empty state message: "Be the first to start a session!"
- Room count: "2 people hanging out"

**Humanized:**

| Element | Current | Humanized |
|---------|---------|-----------|
| **Page Title** | Browse Rooms | Jump into a room |
| **Page Subtitle** | (none) | Pick one — or start your own |
| **Search placeholder** | Search rooms... | Looking for something specific? |
| **Filter button tooltip** | (none) | Narrow it down |
| **Category: All** | All | All vibes |
| **Category: Music** | Music | 🎵 Music |
| **Category: Gaming** | Gaming | 🎮 Gaming |
| **Category: Chat** | Chat | 💬 Chat |
| **Category: Live** | Live | 🔴 Live |
| **Create Room button** | Create Room | Start your room |
| **Empty state title** | No rooms found | Looks quiet... |
| **Empty state message** | Be the first to start a session! | Why not break the silence? Start a room. |
| **Empty state button** | Create Room | Launch a room |
| **Room card title** | [Room name] | [Room name] |
| **Room viewers** | 2 people hanging out | 2 chilling here |
| **Join button** | Join | Join the fun |

**Microcopy:**
- Room card hover: "Tap to join"
- Before joining: "You're about to join [room name]..."
- After joining (loading): "Finding your seat..."

---

## 4️⃣ CHAT / MESSAGES

**Current:**
- Empty state: "No Messages"
- Empty state message: "Start a conversation and break the ice!"
- Typing indicator: (none visible)
- Message input placeholder: "Type a message..."
- Send button: (arrow icon)

**Humanized:**

| Element | Current | Humanized |
|---------|---------|-----------|
| **Empty state title** | No Messages | Your inbox is empty |
| **Empty state message** | Start a conversation and break the ice! | Go find someone to chat with 👉 |
| **Message input hint** | Type a message... | Say hi 👋 ... or share a vibe |
| **Send button tooltip** | (none) | Send your magic ✨ |
| **Typing indicator** | (none) | Alex is typing... |
| **Typing (long)** | (none) | Alex is thinking of something good... |
| **Online status** | (none) | Online now |
| **Offline status** | (none) | Was here 2m ago |
| **Conversation header** | [Name] | [Name] · Online now |
| **Date divider** | Today / Yesterday | Today at 2:30pm |
| **Pinned message label** | Pinned message | 📌 Pinned — read first |
| **Delete message** | Delete | Unsend |
| **Block option** | Block User | Block this person |
| **Report option** | Report | Report & block |

**Microcopy:**
- Sending: "Sending..." (before checkmark)
- Sent: ✔️ (single checkmark)
- Delivered: ✔✔ (double checkmark with soft gray)
- Read: ✔✔ (double checkmark, bright)
- Unsend tooltip: "You can unsend for 5 minutes"

---

## 5️⃣ ERRORS & VALIDATION

**Current (Generic):**
- "An error occurred. Please try again."
- "Network error"
- "Permission denied"
- "Failed to load"

**Humanized:**

| Error Type | Current | Humanized |
|------------|---------|-----------|
| **Generic error** | An error occurred. Please try again. | Oops — something went wrong. Mind trying again? |
| **Network error** | Network error | Can't reach the server right now. Check your connection? |
| **Permission denied** | Permission denied | We need your permission for this one. Check your settings? |
| **Failed to load** | Failed to load | Hmm, we can't load this. Refresh the page? |
| **Timeout** | Request timeout | Taking too long. Try again? |
| **404 Not found** | Not found | This doesn't exist anymore... but something else might surprise you |
| **Connection lost** | Connection lost | Lost connection. Reconnecting... |
| **Room full** | This room is full | That room's packed right now. Try another? |
| **User blocked** | Cannot message this user | They've blocked messages. Respect that. |
| **Already in room** | Already in this room | You're already in this room! |

---

## 6️⃣ EMPTY STATES (Pre-built Components)

### No Events

**Current:**
- Title: "No Events Yet"
- Message: "Be the first to create an exciting event and bring people together!"
- Button: "Create Event"

**Humanized:**
- Title: "No events yet"
- Message: "Start planning. Get people excited. Make it happen."
- Button: "Start an event"

---

### No Users / No Matches

**Current:**
- Title: "No Matches Yet"
- Message: "Keep swiping and connecting to find your perfect match!"
- Button: (none)

**Humanized:**
- Title: "No one yet"
- Message: "Keep exploring. Your person is out there."
- Subtitle: "Ready to mingle? Jump into a room."

---

### No Rooms

**Current:**
- Title: "No Active Rooms"
- Message: "Create a room and start connecting with people live!"
- Button: "Create Room"

**Humanized:**
- Title: "No rooms live right now"
- Message: "Why wait? Go live and start the party."
- Button: "Start a room"

---

### No Notifications

**Current:**
- Title: "No Notifications"
- Message: "Nothing here yet"

**Humanized:**
- Title: "All caught up!"
- Message: "You're not missing anything. Yet 😉"

---

## 7️⃣ BUTTONS & ACTIONS

### Primary Action Buttons

| Context | Current | Humanized |
|---------|---------|-----------|
| **Join a room** | Join | Join the fun |
| **Start a room** | Create Room | Go live |
| **Send message** | Send | Send |
| **Create account** | Sign Up | Create Account |
| **Log in** | Login | Sign In |
| **Save profile** | Save | Save my vibe |
| **Edit profile** | Edit | Edit profile |
| **Delete** | Delete | Remove |
| **Cancel** | Cancel | Cancel |
| **Confirm** | OK / Confirm | Sounds good |

---

### Secondary Actions

| Context | Current | Humanized |
|---------|---------|-----------|
| **Leave room** | Leave | Leave quietly |
| **Block user** | Block | Block this person |
| **Report user** | Report | Report & block |
| **Skip** | Skip | Skip this one |
| **Later** | Later | Ask me later |
| **Not now** | Not now | Maybe next time |
| **Learn more** | Learn More | Tell me more |

---

## 8️⃣ FORM FIELD LABELS & HINTS

### Profile Form

| Field | Current Label | Current Hint | Humanized Label | Humanized Hint |
|-------|---|---|---|---|
| **Name** | Name | (empty) | What's your name? | First name is fine |
| **Bio** | Bio | (empty) | Tell us about you | What do people need to know? |
| **Age** | Age | (empty) | Your age | Just for matching |
| **Location** | Location | (empty) | Where are you? | City or neighborhood |
| **Interests** | Interests | (empty) | What do you love? | Pick as many as you want |
| **Gender** | Gender | (empty) | (keep neutral) | (keep neutral) |
| **Looking for** | Looking For | (empty) | What are you here for? | Friends? Dating? Both? |

---

## 9️⃣ SETTINGS & PREFERENCES

**Current:**
- Title: "Settings"
- Options: "Account", "Notifications", "Privacy", "Blocked Users", "Help", "Logout"

**Humanized:**

| Option | Current | Humanized |
|--------|---------|-----------|
| **Account** | Account Settings | Your account |
| **Notifications** | Notifications | Notify me when... |
| **Privacy** | Privacy Settings | Who can see you |
| **Blocked** | Blocked Users | People you've blocked |
| **Help** | Help & Support | Need help? |
| **Logout** | Logout | Leave Mix & Mingle |
| **Delete Account** | Delete Account | Delete everything |

**Microcopy:**
- Before logout: "You'll be able to come back anytime."
- Before delete: "This is permanent. We'll delete everything."

---

## 🔟 LOADING & WAITING STATES

| State | Current | Humanized |
|-------|---------|-----------|
| **Loading** | Loading... | One sec... |
| **Loading rooms** | Loading rooms... | Finding rooms... |
| **Loading profile** | Loading profile... | Grabbing your profile... |
| **Joining room** | Joining... | Getting your seat ready... |
| **Sending message** | Sending... | Sending... |
| **Uploading photo** | Uploading... | Making you look good... |
| **Saving** | Saving... | Saving your changes... |

---

## 🔟 + 1️⃣ NOTIFICATIONS & ALERTS

### In-App Notifications

| Event | Current | Humanized |
|-------|---------|-----------|
| **New message** | New message from [Name] | [Name]: [preview of message] |
| **Someone joined room** | [Name] joined the room | [Name] just hopped in |
| **Room host is live** | [Host] is now broadcasting | [Host] just went live 🔴 |
| **Match found** | You have a new match | It's a match! 🎉 |
| **Friend request** | [Name] sent you a friend request | [Name] wants to connect |
| **Birthday** | Happy birthday! | Happy birthday, [Name]! 🎂 |

---

## IMPLEMENTATION CHECKLIST

### Phase 1: Core Screens (Immediate)
- [ ] Splash Screen
- [ ] Login Screen
- [ ] Sign Up Screen
- [ ] Home Screen

### Phase 2: Discovery & Rooms
- [ ] Browse Rooms Page
- [ ] Create Room Page
- [ ] Room Join Flow

### Phase 3: Chat & Messages
- [ ] Chat List Screen
- [ ] Chat Room Screen
- [ ] Typing indicators

### Phase 4: Errors & Empty States
- [ ] All error messages
- [ ] All empty state components

### Phase 5: Polish
- [ ] Loading states
- [ ] Button tooltips
- [ ] Notifications
- [ ] Success messages

---

## DESIGN PERSONALITY FOR MIX & MINGLE

### Tone: **Playful, Safe, Inclusive**

- ✅ Use contractions ("you're", "it's", "can't")
- ✅ Keep sentences short (under 15 words)
- ✅ Use emojis sparingly (one per screen max)
- ✅ Be honest about errors
- ✅ Add gentle humor where appropriate
- ✅ Never use robotic language ("submit", "proceed", "access")
- ❌ Avoid all-caps headings
- ❌ Don't over-explain
- ❌ No corporate jargon

### Color Association
- 🎵 Gold: Excitement, warmth, welcome
- 🩷 Pink: Connection, human, playful
- 🔵 Cyan: Safety, calm, trust
- ⚫ Black: Sleek, inclusive, intimate

---

# 📝 READY TO IMPLEMENT?

Once you approve this guide, I'll:

1. Create a centralized **`copy_constants.dart`** file with all strings
2. Update **all screens** to use humanized copy
3. Add **loading state copy** with character
4. Implement **error handling copy** with personality
5. Test the entire user flow with new copy

**Approve this guide and let's make Mix & Mingle feel human.** ✨
