# Video Chat Features - Testing & Validation Guide

## 🧪 Comprehensive Testing Guide

### Test Environment Setup

```bash
# 1. Clean project
cd c:\Users\LARRY\MIXMINGLE
flutter clean

# 2. Get dependencies
flutter pub get

# 3. Run on Chrome
flutter run -d chrome --release
```

---

## ✅ Feature Test Matrix

### 1. RESPONSIVE VIDEO GRID

#### Test Case 1.1: Display Participants
- **Expected**: See 3 mock participants in grid
- **Verify**:
  - ✅ Alex Johnson card visible
  - ✅ Sarah Chen card visible
  - ✅ Jordan Taylor card visible
  - ✅ All names displayed
  - ✅ All avatars loaded

#### Test Case 1.2: Grid Responsiveness
- **Desktop (1200px+)**:
  - [ ] 3 videos should fit in row
  - [ ] 16:9 aspect ratio maintained
  - [ ] Padding/spacing correct (12px)

- **Tablet (800-1200px)**:
  - [ ] 2 videos per row
  - [ ] Larger tiles for visibility
  - [ ] Still readable text

- **Mobile (<800px)**:
  - [ ] 1 video per row
  - [ ] Full width tiles
  - [ ] Accessible controls

#### Test Case 1.3: Video Status Indicators
- **Each tile shows**:
  - [ ] Participant name at bottom
  - [ ] Mute/Unmute icon (green if on, red if off)
  - [ ] Camera on/off icon (green if on, red if off)
  - [ ] Last seen timestamp
  - [ ] Avatar when camera is off

#### Test Case 1.4: Pin Functionality
- **Action**: Long-press on a video tile
- **Expected**:
  - [ ] Border changes to pink
  - [ ] Border thickness increases (3px)
  - [ ] Pinned status persists during session
  - [ ] Can unpin by long-pressing again

#### Test Case 1.5: Screen Share Indicator
- **Expected**: Blue "Sharing" badge appears when detected
  - [ ] Badge positioned at top-left
  - [ ] Badge shows screen share icon
  - [ ] Badge dismisses when no longer sharing

---

### 2. FRIENDS SIDEBAR

#### Test Case 2.1: Display Friends List
- **Expected**: See all 6 mock friends
- **Verify**:
  - [ ] Alex Johnson (Online, green dot)
  - [ ] Sarah Chen (Online, unread badge "2")
  - [ ] Jordan Taylor (Offline, gray dot)
  - [ ] Morgan Williams (Online, unread "5")
  - [ ] Casey Brown (Offline, favorite star)
  - [ ] Riley Davis (Online)

#### Test Case 2.2: Online Status Indicator
- **Green Dot** (Online friends):
  - [ ] Visible at bottom-right of avatar
  - [ ] Positioned correctly with white border
  - [ ] Size: 12px diameter

- **Gray Dot** (Offline friends):
  - [ ] Same positioning as online
  - [ ] Gray color indicates offline
  - [ ] Shows relative time: "Offline" or "Active 2h ago"

#### Test Case 2.3: Search Functionality
- **Action**: Type "alex" in search
- **Expected**:
  - [ ] List filters to show only Alex Johnson
  - [ ] Search is case-insensitive
  - [ ] Clear search shows all friends again

#### Test Case 2.4: Filter by Online
- **Action**: Click "Online" chip
- **Expected**:
  - [ ] Shows only 4 online friends (Alex, Sarah, Morgan, Riley)
  - [ ] Hides offline friends (Jordan, Casey)
  - [ ] Chip shows highlighted/selected state

#### Test Case 2.5: Filter by Favorites
- **Action**: Click "⭐ Favorites" chip
- **Expected**:
  - [ ] Shows only 2 starred friends (Alex, Casey)
  - [ ] Other friends hidden
  - [ ] Can combine with other filters

#### Test Case 2.6: Star Toggle
- **Action**: Click star icon on a friend
- **Expected**:
  - [ ] Star fills in (yellow color)
  - [ ] Friend added to favorites
  - [ ] Click again to remove from favorites
  - [ ] Star becomes outline (empty)

#### Test Case 2.7: Unread Badge
- **Verify**:
  - [ ] Orange badge shows unread count
  - [ ] Sarah Chen shows "2"
  - [ ] Morgan Williams shows "5"
  - [ ] Others show no badge (0 unread)
  - [ ] Total shows in sidebar header

#### Test Case 2.8: Friend Click Action
- **Action**: Click on a friend item
- **Expected**:
  - [ ] Toast/snackbar shows "Opening chat with [name]"
  - [ ] Friend row highlights on hover
  - [ ] Cursor changes to pointer

#### Test Case 2.9: Sidebar Collapse
- **Action**: Click "X" button in header
- **Expected**:
  - [ ] Sidebar slides out smoothly
  - [ ] Video grid expands to fill space
  - [ ] Can't see friends list

#### Test Case 2.10: Sidebar Expand (if collapsed)
- **Note**: After collapsing, would need expand button (future feature)

---

### 3. GROUPS SIDEBAR

#### Test Case 3.1: Display Groups List
- **Expected**: See all 5 mock groups
- **Verify**:
  - [ ] Daily Standup (4 participants)
  - [ ] Game Night (4 participants, unread "3")
  - [ ] Creative Studio (3 participants, unread "5")
  - [ ] Language Exchange (2 participants)
  - [ ] Fitness Buddies (5 participants, unread "2")

#### Test Case 3.2: Group Info Display
- **Each group tile shows**:
  - [ ] Group avatar/image
  - [ ] Group name
  - [ ] Description (truncated to 1 line)
  - [ ] Participant count badge (e.g., "4/20")
  - [ ] Join button (if not joined) or Exit button (if joined)
  - [ ] Unread count badge (if any)

#### Test Case 3.3: Join Group
- **Action**: Click "Join" button on a group
- **Expected**:
  - [ ] Button changes to "Exit"
  - [ ] Toast shows "Joined [group name]"
  - [ ] Button color changes to red
  - [ ] Participant count increases by 1

#### Test Case 3.4: Leave Group
- **Action**: Click "Exit" button on joined group
- **Expected**:
  - [ ] Button changes to "Join"
  - [ ] Toast shows "[group name] left"
  - [ ] Participant count decreases by 1

#### Test Case 3.5: Create Group
- **Action**: Click "+" button in header
- **Expected**:
  - [ ] Dialog appears with "Create New Group"
  - [ ] "Group Name" field (text input)
  - [ ] "Description" field (multi-line)
  - [ ] "Create" and "Cancel" buttons

#### Test Case 3.6: Create Group (Submit)
- **Action**: Fill name "Test Group", description "Test", click Create
- **Expected**:
  - [ ] Dialog closes
  - [ ] Toast shows "Group created!"
  - [ ] New group appears in list at bottom
  - [ ] Shows as "joined" with Exit button

#### Test Case 3.7: Group Search
- **Action**: Type "game" in search
- **Expected**:
  - [ ] Shows only "Game Night"
  - [ ] Other groups hidden
  - [ ] Search is case-insensitive

#### Test Case 3.8: Filter "My Groups"
- **Action**: Click "My Groups" chip
- **Expected**:
  - [ ] Shows only groups you've joined
  - [ ] All others hidden
  - [ ] Can toggle back to "All"

#### Test Case 3.9: Unread Badge
- **Verify**:
  - [ ] Game Night shows "3"
  - [ ] Creative Studio shows "5"
  - [ ] Fitness Buddies shows "2"
  - [ ] Total shown in header

#### Test Case 3.10: Open Group
- **Action**: Click on a joined group
- **Expected**:
  - [ ] Toast shows "Opening group: [name]"
  - [ ] (Future: would open group chat)

---

### 4. TOP NAVIGATION BAR

#### Test Case 4.1: Live Indicator
- **Expected**: Shows "LIVE • 3 participants"
- **Verify**:
  - [ ] Pink pulsing dot
  - [ ] Correct participant count
  - [ ] Text updates if participants change

#### Test Case 4.2: Logo/Title
- **Expected**: "Mix & Mingle" text visible
- **Verify**:
  - [ ] Pink color
  - [ ] Bold font
  - [ ] Left-aligned

#### Test Case 4.3: Notifications Bell
- **Expected**: Bell icon with badge
- **Verify**:
  - [ ] Icon visible
  - [ ] Badge shows unread count (if any)
  - [ ] Badge is red with white number

#### Test Case 4.4: Notifications Panel
- **Action**: Click bell icon
- **Expected**:
  - [ ] Dialog opens
  - [ ] Shows title "Notifications"
  - [ ] If no notifications: "No notifications" message
  - [ ] Can close dialog

#### Test Case 4.5: Video Quality Menu
- **Action**: Click video camera icon
- **Expected**:
  - [ ] Menu appears with 3 options:
    - Low Quality (180p)
    - Medium Quality (360p)
    - High Quality (720p)
  - [ ] Can select any option
  - [ ] Setting changes (in provider)

#### Test Case 4.6: Dark/Light Mode Toggle
- **Action**: Click moon/sun icon
- **Expected**:
  - [ ] Theme toggles immediately
  - [ ] All UI updates to dark or light
  - [ ] Icon changes (moon → sun or vice versa)
  - [ ] Persistence across navigation

#### Test Case 4.7: Settings Menu
- **Action**: Click three-dot menu
- **Expected**:
  - [ ] Menu appears with 2 options:
    - Camera Settings
    - Audio Settings
  - [ ] Can select camera settings

#### Test Case 4.8: Camera Settings Dialog
- **Action**: Click "Camera Settings" from menu
- **Expected**:
  - [ ] Dialog opens
  - [ ] Shows title "Camera Approval Settings"
  - [ ] 3 radio button options:
    - Ask each time (default)
    - Allow all
    - Deny all
  - [ ] Can toggle each option
  - [ ] "Close" button to dismiss

---

### 5. CHAT BOX

#### Test Case 5.1: Send Text Message
- **Action**: Type "Hello!" and click send
- **Expected**:
  - [ ] Message appears in chat above input
  - [ ] Message shows: "You" as sender, message content, timestamp
  - [ ] Input field clears
  - [ ] Message bubble is pink (sent)

#### Test Case 5.2: Message Timestamp
- **Expected**: Each message shows relative time
- **Verify**:
  - [ ] "now" for very recent
  - [ ] "2m ago" for old messages
  - [ ] "5h ago" format for older

#### Test Case 5.3: Emoji Picker
- **Action**: Click emoji button (😊 icon)
- **Expected**:
  - [ ] Emoji grid appears above input
  - [ ] Shows 16 popular emojis
  - [ ] 8 columns layout
  - [ ] 200px height

#### Test Case 5.4: Send Emoji
- **Action**: Click an emoji in picker
- **Expected**:
  - [ ] Emoji inserted into input field
  - [ ] Picker closes
  - [ ] Can send emoji as message

#### Test Case 5.5: Sticker Picker
- **Action**: Click sticker button (🎨)
- **Expected**:
  - [ ] Sticker grid appears
  - [ ] Shows 8 stickers
  - [ ] 150px height
  - [ ] 8 columns layout

#### Test Case 5.6: Send Sticker
- **Action**: Click a sticker
- **Expected**:
  - [ ] Sticker inserted into input
  - [ ] Picker closes
  - [ ] Can send as message

#### Test Case 5.7: File Upload Menu
- **Action**: Click attachment icon
- **Expected**:
  - [ ] Menu appears with 2 options:
    - Share File
    - Share Image
  - [ ] Can select (shows toast for now)

#### Test Case 5.8: Multi-line Input
- **Action**: Type message spanning multiple lines
- **Expected**:
  - [ ] Input expands up to 3 lines
  - [ ] Scrolls if more than 3 lines
  - [ ] Send button still accessible

#### Test Case 5.9: Empty Message Prevention
- **Action**: Click send with empty input
- **Expected**:
  - [ ] Nothing happens
  - [ ] No error message
  - [ ] Input stays empty

#### Test Case 5.10: Message History
- **Expected**: Chat shows previous messages
- **Verify**:
  - [ ] 5+ mock messages visible
  - [ ] Messages are reversed (newest at bottom)
  - [ ] Different senders shown correctly
  - [ ] File messages show attachment icon
  - [ ] Scrollable if many messages

#### Test Case 5.11: Message Scrolling
- **Action**: Scroll in chat area
- **Expected**:
  - [ ] Can scroll up to see older messages
  - [ ] Smooth scrolling
  - [ ] Pull-to-refresh not needed

---

### 6. NOTIFICATIONS

#### Test Case 6.1: Display in Floating ActionButton Area
- **Expected**: Notifications show in top-right corner
- **Verify**:
  - [ ] Stack visible with up to 3 notifications
  - [ ] Color-coded by type
  - [ ] Close button on each notification

#### Test Case 6.2: Friend Request Notification
- **Color**: Blue
- **Icon**: Person with plus
- **Verify**:
  - [ ] Shows "Friend Request" title
  - [ ] Shows "[Name] sent you a friend request"
  - [ ] Has "View" action button

#### Test Case 6.3: Message Notification
- **Color**: Green
- **Icon**: Mail envelope
- **Verify**:
  - [ ] Shows "New Message" title
  - [ ] Shows "[Name] sent you a message"

#### Test Case 6.4: Video Request Notification
- **Color**: Purple
- **Icon**: Video camera
- **Verify**:
  - [ ] Shows "Video Call" title
  - [ ] Shows "[Name] is calling you"

#### Test Case 6.5: Room Invite Notification
- **Color**: Orange
- **Icon**: People group
- **Verify**:
  - [ ] Shows "Room Invite" title
  - [ ] Shows "[Name] invited you to join a room"

#### Test Case 6.6: Auto-dismiss Notification
- **Expected**: Notification disappears after 5 seconds
- **Verify**:
  - [ ] Timer starts immediately
  - [ ] Disappears smoothly
  - [ ] Can manually dismiss with X button

---

### 7. DARK/LIGHT MODE

#### Test Case 7.1: Dark Mode (Default)
- **Expected**: App starts in dark mode
- **Verify**:
  - [ ] Background is dark gray (#1a1a1a area)
  - [ ] Text is white
  - [ ] Buttons have dark styling
  - [ ] Icons are light colored

#### Test Case 7.2: Toggle to Light Mode
- **Action**: Click sun/moon icon in top bar
- **Expected**:
  - [ ] All backgrounds become light
  - [ ] Text becomes dark
  - [ ] Buttons styled for light mode
  - [ ] Transitions smoothly

#### Test Case 7.3: Toggle Back to Dark
- **Action**: Click icon again
- **Expected**:
  - [ ] Returns to dark mode
  - [ ] All elements update
  - [ ] Smooth transition

#### Test Case 7.4: Persistence
- **Expected**: Mode remembered across page reloads
  - [ ] Close and reopen browser
  - [ ] Should remain in selected mode

---

### 8. CAMERA APPROVAL

#### Test Case 8.1: Default Mode
- **Expected**: "Ask each time" is default
- **Verify**:
  - [ ] Radio button selected
  - [ ] All other options unselected

#### Test Case 8.2: Allow All
- **Action**: Select "Allow all" radio button
- **Expected**:
  - [ ] Selection updates
  - [ ] Other options deselect
  - [ ] Setting persists in provider state

#### Test Case 8.3: Deny All
- **Action**: Select "Deny all"
- **Expected**:
  - [ ] Selection updates
  - [ ] Persists in provider

#### Test Case 8.4: Pending Badge
- **Verify**: Video tiles show "Camera Pending" orange badge
- **When**: cameraApprovalStatus is 'pending'

#### Test Case 8.5: Approval Status Display
- **In participants tile**:
  - [ ] Shows approval badge
  - [ ] Updates when status changes
  - [ ] Correct color (orange for pending)

---

### 9. RESPONSIVE DESIGN

#### Test Case 9.1: Desktop (1400px+)
```
┌─────────────────────────────────────────┐
│ Top Bar (logo, live, buttons)           │
├──────┬──────────────────┬───────────────┤
│      │                  │               │
│ 320px│   Video Grid     │    320px      │
│  F   │   (3x3 or 4x4)   │    Groups     │
│  r   │  + Chat Below    │    Sidebar    │
│  i   │                  │               │
│  e   ├──────────────────┤               │
│  n   │   Chat Box       │               │
│  d   │                  │               │
│  s   └──────────────────┴───────────────┘
```

#### Test Case 9.2: Tablet (800-1200px)
```
┌─────────────────────────────┐
│ Top Bar                     │
├──────┬──────────────────────┤
│      │  Video Grid (2x2)    │
│ 320px│  + Chat Below        │
│      │                      │
│Friends│Groups visible below │
│Sidebar│ or in scrollable    │
```

#### Test Case 9.3: Mobile (<800px)
```
┌──────────────────┐
│ Compact Top Bar  │
├──────────────────┤
│ Video Grid (1x1) │
├──────────────────┤
│  Chat Box        │
├──────────────────┤
│ Friends Tab      │
├──────────────────┤
│ Groups Tab       │
```

#### Test Case 9.4: Sidebar Collapse on Mobile
- **Expected**: Sidebars may collapse automatically on small screens
- **Or**: Tabs to switch between Friends/Groups/Video

---

### 10. PERFORMANCE TESTS

#### Test Case 10.1: Initial Load Time
- **Expected**: < 2 seconds to interactive
- **Measure**:
  ```bash
  # Open DevTools (F12) → Network tab
  # Reload page, check load times
  ```

#### Test Case 10.2: Smooth Animations
- **Expected**: No jank/stuttering
- **Test**:
  - [ ] Sidebar collapse/expand smooth
  - [ ] Emoji picker animation smooth
  - [ ] Notification fade in/out smooth
  - [ ] Video grid layout changes smooth

#### Test Case 10.3: Memory Usage
- **Expected**: No memory leaks
- **Check**: DevTools → Performance → Memory usage over time

#### Test Case 10.4: Large Member List
- **Action**: Scroll through friends list of 50+ friends
- **Expected**:
  - [ ] Smooth scrolling
  - [ ] No lag
  - [ ] All items render correctly

#### Test Case 10.5: Many Messages
- **Action**: Scroll through 100+ messages in chat
- **Expected**:
  - [ ] Smooth scrolling
  - [ ] No lag
  - [ ] Messages load correctly

---

### 11. INTERACTION TESTS

#### Test Case 11.1: Hover Effects
- **Expected**: Hover highlights on all clickable items
- **Test**:
  - [ ] Friend tiles highlight on hover
  - [ ] Group tiles highlight on hover
  - [ ] Buttons change color on hover
  - [ ] Proper cursor (pointer) on hover

#### Test Case 11.2: Focus States (Keyboard)
- **Expected**: All elements keyboard accessible
- **Test**:
  - [ ] Tab through all buttons
  - [ ] Tab through input fields
  - [ ] Enter key activates buttons
  - [ ] Escape closes dialogs

#### Test Case 11.3: Click Outside to Close
- **Expected**: Dialogs close when clicking outside
- **Test**:
  - [ ] Notifications panel
  - [ ] Camera settings dialog
  - [ ] Create group dialog

---

### 12. ERROR STATES

#### Test Case 12.1: Empty Friend List
- **If**: No friends loaded
- **Expected**: "No friends found" message centered

#### Test Case 12.2: Empty Group List
- **If**: No groups loaded
- **Expected**: "No groups found" message

#### Test Case 12.3: No Participants
- **If**: No one in video room
- **Expected**: "No active video calls" message with icon

#### Test Case 12.4: Network Image Failure
- **If**: Avatar URL fails to load
- **Expected**: Fallback icon (person icon) shown

#### Test Case 12.5: Invalid Search Query
- **Expected**: No results shown, message displayed

---

## 🎬 End-to-End User Flows

### Flow 1: Join Video Call & Chat
1. [ ] Navigate to /video-chat
2. [ ] See video grid with 3 participants
3. [ ] Click on a message input field
4. [ ] Type "Hi everyone!" and send
5. [ ] Message appears in chat history
6. [ ] See from another friend in sidebar
7. [ ] Click on friend to open chat

### Flow 2: Manage Friends
1. [ ] Open friends sidebar
2. [ ] Search for "alex"
3. [ ] See only Alex Johnson
4. [ ] Click star to favorite
5. [ ] Filter by favorites
6. [ ] See only starred friends
7. [ ] Clear search
8. [ ] See all friends again

### Flow 3: Create & Join Group
1. [ ] Open groups sidebar
2. [ ] Click "+" button
3. [ ] Fill name "My Group"
4. [ ] Fill description "Test group"
5. [ ] Click Create
6. [ ] See new group in list
7. [ ] See it's joined (Exit button visible)
8. [ ] Click another unjoinedgroup's Join button
9. [ ] See participant count increase

### Flow 4: Manage Permissions
1. [ ] Click three-dot menu in top bar
2. [ ] Select "Camera Settings"
3. [ ] Select "Allow all"
4. [ ] Close dialog
5. [ ] See badge on video tiles changed
6. [ ] Reopen settings
7. [ ] Select "Ask each time"
8. [ ] Close

---

## 📊 Test Results Template

```
Test Suite: Video Chat Features
Date: _______________
Tester: ________________
Platform: Chrome Desktop (1280×720) / Other: ___________

RESULTS SUMMARY:
- Total Tests: 120
- Passed: ___
- Failed: ___
- Blocked: ___
- Skipped: ___

FEATURE BREAKDOWN:
✅ Responsive Video Grid: __/15
✅ Friends Sidebar: __/10
✅ Groups Sidebar: __/10
✅ Top Navigation Bar: __/8
✅ Chat Box: __/11
✅ Notifications: __/6
✅ Dark/Light Mode: __/4
✅ Camera Approval: __/5
✅ Responsive Design: __/4
✅ Performance: __/5
✅ Interactions: __/3
✅ Error States: __/5
✅ User Flows: __/4

CRITICAL ISSUES:
1. ________________
2. ________________
3. ________________

NOTES:
_________________________
_________________________

SIGN-OFF:
Tester Signature: ___________  Date: _________
QA Lead Approval: ___________  Date: _________
```

---

## ✅ Ready for Testing!

All 120+ test cases defined. Execute systematically for comprehensive feature validation.

Start with **Section 1** (Video Grid) and work through in order for logical flow.

Good luck! 🚀
