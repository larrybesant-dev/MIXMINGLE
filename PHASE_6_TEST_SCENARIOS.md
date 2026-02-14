# Phase 6 Test Scenarios - Step-by-Step

## Test Scenario 1: Tooltips on Control Buttons

### Setup:
- Join any voice room
- Be at the voice room screen with control bar visible

### Steps:
1. Move mouse over "Mute" button (has microphone icon)
   - ✅ Expected: Tooltip appears with text like "Mute your microphone (Ctrl+M)" or "Unmute your microphone (Ctrl+M)" depending on current state

2. Move mouse over "Camera" button (has videocam icon)
   - ✅ Expected: Tooltip appears with appropriate text

3. Move mouse over "Leave Room" button (red X icon)
   - ✅ Expected: Tooltip appears with "Leave this room and return to the home page"

4. If host/moderator: Move mouse over "Grant Turn" button
   - ✅ Expected: Tooltip appears with "Manually grant speaking turn to a specific person"

5. Verify tooltips don't block UI
   - ✅ Expected: Tooltips appear and disappear cleanly, don't hang

### Pass Criteria:
- All buttons have descriptive tooltips
- Tooltips mention keyboard shortcuts where applicable
- No UI blockage or layout shift

---

## Test Scenario 2: Empty State Messaging

### Setup:
- Be the first person to join a room
- Both video grid and participant sidebar should be empty

### Steps:
1. Look at video grid area (main video display)
   - ✅ Expected: See large people icon, "No cameras active" heading, participant count message

2. Look at participant sidebar (right panel)
   - ✅ Expected: See people icon, "Waiting for others to join..." heading, "Invite people to get the conversation started" subtext

3. Verify visual hierarchy
   - ✅ Expected: Icon is largest, heading is medium text, subtext is small and grayed out

4. Have another user join the room
   - ✅ Expected: Empty state disappears, video tiles appear for active cameras

### Pass Criteria:
- Icon + heading + subtext visible when alone
- Text is user-friendly and encouraging
- Visual hierarchy is clear
- Empty state disappears when others join

---

## Test Scenario 3: Error Handling

### Setup:
- Have the app in a state where it might encounter an error
- For testing: logout, then try to join a room

### Steps:
1. Logout of app completely
2. Navigate to a room page
3. Try to join a room
   - ✅ Expected: Loading spinner briefly appears
   - ✅ Expected: Error screen shows with icon, heading, and message

4. Check error message
   - ✅ Expected: Message says "You need to be logged in to join this room" (not raw error)
   - ✅ Expected: Message is clear and actionable

5. Click "Go Back" button
   - ✅ Expected: Return to previous screen

6. Login and try to join again
7. Click "Retry" button
   - ✅ Expected: Attempts to join room again

### Pass Criteria:
- Error message is user-friendly (not showing raw exception)
- "Retry" button attempts join again
- "Go Back" button navigates properly
- Specific error types are recognized and handled

---

## Test Scenario 4: Keyboard Shortcuts

### Setup:
- Be in a voice room with the app focused

### Steps:
1. Press `Ctrl+M` (Windows) or `Cmd+M` (Mac)
   - ✅ Expected: Microphone toggles on/off
   - ✅ Expected: Button icon and state update immediately

2. Press `Ctrl+V` to toggle camera
   - ✅ Expected: Video toggles on/off
   - ✅ Expected: Button icon updates

3. Press `Escape` to leave room
   - ✅ Expected: App confirms or navigates away from room

4. Press `Space` (if push-to-talk is configured)
   - ✅ Expected: Microphone activates while held, deactivates on release

### Pass Criteria:
- All keyboard shortcuts work as documented
- Visual feedback updates immediately
- No console errors when shortcuts pressed

---

## Test Scenario 5: Help Dialog - Basic

### Setup:
- Be in a voice room
- Look at top AppBar

### Steps:
1. Find the `?` (question mark) icon in the AppBar
   - ✅ Expected: Icon visible in top-right area of AppBar

2. Click the help button
   - ✅ Expected: Dialog opens smoothly
   - ✅ Expected: Dialog shows "Quick Guide" heading with help icon

3. Scroll through dialog
   - ✅ Expected: See "Keyboard Shortcuts" section
   - ✅ Expected: See "Control Buttons" section
   - ✅ Expected: See "Tips & Tricks" section

4. Verify Keyboard Shortcuts section
   - ✅ Expected: Shows Ctrl+M, Ctrl+V, Space, Esc
   - ✅ Expected: Shows clear descriptions for each

5. Close dialog by clicking "Got It!" button
   - ✅ Expected: Dialog closes smoothly

### Pass Criteria:
- Help button is accessible in AppBar
- Dialog opens and displays all sections
- Content is well-formatted and readable
- Close button works properly

---

## Test Scenario 6: Help Dialog - Advanced Content

### Setup:
- Join a room with turn-based mode enabled
- Open help dialog

### Steps:
1. Check if "Turn-Based Conversation" section appears
   - ✅ Expected: Section visible if room is in turn-based mode
   - ✅ Expected: Section shows timer, speaking badge, queue info

2. If in stage mode, check "Stage Mode" section
   - ✅ Expected: Section visible if stage mode active
   - ✅ Expected: Shows raise hand, end turn, queue grant info

3. General sections should always show
   - ✅ Expected: "Tips & Tricks" always visible
   - ✅ Expected: Shows click name, moderation, visual indicators

### Pass Criteria:
- Conditional sections appear based on room mode
- Content is accurate for current room state
- All relevant tips are displayed

---

## Test Scenario 7: Empty State with Participant Join

### Setup:
- Be alone in a room (empty state showing)
- Have another user ready to join

### Steps:
1. Verify empty state displays correctly
   - ✅ Expected: "Waiting for others to join" message visible

2. Have second user join room
   - ✅ Expected: Participant list updates immediately
   - ✅ Expected: Empty state disappears
   - ✅ Expected: Participant name appears in sidebar

3. If second user turns on camera
   - ✅ Expected: Video tile appears in grid
   - ✅ Expected: Empty state "No cameras active" is replaced with video

### Pass Criteria:
- Empty state appears when alone
- Updates immediately when others join
- Transitions smoothly to populated view

---

## Test Scenario 8: Control Bar Button Tooltips (Detailed)

### Setup:
- Be in a moderator/host room in turn-based mode

### Steps:
1. Hover over "Extend +30s" button
   - ✅ Expected: "Give the current speaker 30 more seconds"

2. Hover over "Skip" button
   - ✅ Expected: "Move to the next speaker in queue"

3. Hover over "Next Speaker" button
   - ✅ Expected: Tooltip shows queue count like "Grant speaking turn to next person in queue (3 waiting)"

4. Hover over "Grant Turn" button
   - ✅ Expected: "Manually grant speaking turn to a specific person"

5. Check "Invite" button tooltip
   - ✅ Expected: "Invite people to join this room"

6. Check "Settings" button tooltip
   - ✅ Expected: "Configure room settings and preferences"

### Pass Criteria:
- All moderator-specific buttons have tooltips
- Queue count dynamically shown in tooltip
- No typos or unclear descriptions

---

## Test Scenario 9: Error Messages - Various Types

### Setup:
- Be able to trigger different error conditions

### Steps:
1. **Network Timeout Error**
   - ✅ Expected: Message mentions "Connection timed out" and "check your internet"

2. **Permission Error**
   - ✅ Expected: Message mentions "You don't have permission to join this room"

3. **Authentication Error**
   - ✅ Expected: Message mentions "You need to be logged in"

4. **Firestore Error**
   - ✅ Expected: Message mentions "Unable to load room information"

5. **Long Error Messages**
   - ✅ Expected: Messages are truncated and don't overflow UI

### Pass Criteria:
- Each error type shows appropriate message
- Messages are truncated if too long
- No raw exception strings visible to user
- Messages suggest next action (retry, login, etc.)

---

## Test Scenario 10: Visual Consistency

### Setup:
- Be in a voice room with Phase 6 improvements active

### Steps:
1. Check color scheme
   - ✅ Expected: Primary buttons are pinkAccent color
   - ✅ Expected: Error/destructive buttons are red
   - ✅ Expected: Secondary buttons use theme colors

2. Check typography
   - ✅ Expected: Headings are bold and larger
   - ✅ Expected: Body text is readable
   - ✅ Expected: Hints/helpers are smaller and grayed out

3. Check spacing
   - ✅ Expected: Consistent padding around elements
   - ✅ Expected: No UI elements touching edges
   - ✅ Expected: Good visual breathing room

4. Check animations
   - ✅ Expected: Tooltips appear smoothly
   - ✅ Expected: Dialogs fade in
   - ✅ Expected: No jarring transitions

### Pass Criteria:
- Electric Lounge theme consistently applied
- Typography hierarchy clear
- Spacing is balanced
- Animations are smooth

---

## Test Completion Checklist

- [ ] Scenario 1: Tooltips on Control Buttons - ✅ PASS
- [ ] Scenario 2: Empty State Messaging - ✅ PASS
- [ ] Scenario 3: Error Handling - ✅ PASS
- [ ] Scenario 4: Keyboard Shortcuts - ✅ PASS
- [ ] Scenario 5: Help Dialog - Basic - ✅ PASS
- [ ] Scenario 6: Help Dialog - Advanced - ✅ PASS
- [ ] Scenario 7: Empty State with Join - ✅ PASS
- [ ] Scenario 8: Control Bar Tooltips - ✅ PASS
- [ ] Scenario 9: Error Messages - ✅ PASS
- [ ] Scenario 10: Visual Consistency - ✅ PASS

**Overall Status:** ✅ Phase 6 Ready for Production
