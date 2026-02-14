# Phase 5 Events Engine Architecture

## System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                           PRESENTATION LAYER                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌────────────────────┐  ┌────────────────────┐  ┌──────────────┐ │
│  │  EventsPage        │  │ EventDetailsPage   │  │ EventCard    │ │
│  │  (3 Tabs)          │  │                    │  │ Widget       │ │
│  │  • All             │  │  • Event Info      │  │              │ │
│  │  • Friends         │  │  • Host Profile    │  │ • Title/Time │ │
│  │  • Recommended     │  │  • RSVP Buttons    │  │ • Location   │ │
│  │                    │  │  • Friends Banner  │  │ • Stats      │ │
│  │  Uses:             │  │  • Attendees List  │  │ • Friends    │ │
│  │  EventCard widget  │  │  • Join Room       │  │              │ │
│  └────────┬───────────┘  └─────────┬──────────┘  └──────┬───────┘ │
│           │                        │                     │         │
└───────────┼────────────────────────┼─────────────────────┼─────────┘
            │                        │                     │
            ▼                        ▼                     ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         PROVIDER LAYER (Riverpod)                    │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  StreamProviders (Real-time):                                       │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ • upcomingEventsProvider          → List<Event>              │  │
│  │ • eventDetailsProvider(id)        → Event?                   │  │
│  │ • friendsEventsProvider           → List<Event> (Social)     │  │
│  │ • recommendedEventsProvider       → List<Event> (AI-scored)  │  │
│  │ • friendsAttendingEventProvider   → List<UserProfile>        │  │
│  │ • eventAttendeesProvider          → List<UserProfile>        │  │
│  │ • userRsvpStatusProvider          → String?                  │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  FutureProviders (Actions):                                         │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ • rsvpActionProvider((id, status))                           │  │
│  │ • removeRsvpActionProvider(id)                               │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
└───────────────────────────────────┬─────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         SERVICE LAYER                                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  EventsService (400+ lines)                                         │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                                                              │  │
│  │  Event Queries:                                             │  │
│  │  • watchUpcomingEvents()                                    │  │
│  │  • watchEvent(eventId)                                      │  │
│  │  • watchEventAttendees(eventId, status)                     │  │
│  │                                                              │  │
│  │  Social Graph Integration:                                  │  │
│  │  • watchEventsFriendsAreAttending(userId)                   │  │
│  │    └─> Queries following subcollection                      │  │
│  │    └─> Finds events friends RSVPed to                       │  │
│  │                                                              │  │
│  │  • watchFriendsAttendingEvent(userId, eventId)              │  │
│  │    └─> Queries following subcollection                      │  │
│  │    └─> Checks event attendees                               │  │
│  │                                                              │  │
│  │  AI Recommendations:                                         │  │
│  │  • watchRecommendedEvents(userId)                           │  │
│  │    └─> Fetches user interests                               │  │
│  │    └─> Scores events by category match                      │  │
│  │    └─> Boosts score if friends attending                    │  │
│  │    └─> Returns top 20                                       │  │
│  │                                                              │  │
│  │  RSVP Management:                                            │  │
│  │  • rsvpToEvent(eventId, status)                             │  │
│  │    └─> Batched write to 2 locations                         │  │
│  │    └─> Increments counters                                  │  │
│  │  • removeRsvp(eventId)                                      │  │
│  │    └─> Batched delete from 2 locations                      │  │
│  │    └─> Decrements counters                                  │  │
│  │                                                              │  │
│  │  User RSVP Tracking:                                         │  │
│  │  • watchUserRsvpStatus(userId, eventId)                     │  │
│  │  • watchUserEventRsvps(userId)                              │  │
│  │                                                              │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
└───────────────────────────────────┬─────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         FIREBASE LAYER                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Firestore Collections:                                             │
│                                                                      │
│  events/{eventId}/                                                  │
│  ├── title, description, location, category                         │
│  ├── hostId, date, startTime, endTime                               │
│  ├── isOnline, roomId                                               │
│  ├── attendeesCount, interestedCount                                │
│  └── attendees/{userId}/                                            │
│      ├── status: "going" | "interested"                             │
│      └── timestamp: serverTimestamp()                               │
│                                                                      │
│  users/{userId}/                                                    │
│  ├── displayName, photoUrl, bio, interests[]                        │
│  ├── event_rsvps/{eventId}/                                         │
│  │   ├── status: "going" | "interested"                             │
│  │   └── timestamp: serverTimestamp()                               │
│  ├── following/{followingId}/                                       │
│  │   └── timestamp                                                  │
│  └── followers/{followerId}/                                        │
│      └── timestamp                                                  │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Data Flow Examples

### 1. Viewing Events Friends Are Attending

```
User opens "Friends" tab
         │
         ▼
EventsPage watches friendsEventsProvider
         │
         ▼
Provider calls service.watchEventsFriendsAreAttending(userId)
         │
         ▼
Service queries: users/{userId}/following (get friend IDs)
         │
         ▼
Service queries: users/{friendId}/event_rsvps (for each friend)
         │
         ▼
Service fetches: events/{eventId} (full event data)
         │
         ▼
Service deduplicates and returns Stream<List<Event>>
         │
         ▼
Provider emits AsyncValue<List<Event>>
         │
         ▼
EventsPage builds EventCard for each event
         │
         ▼
EventCard shows friends attending via friendsAttendingEventProvider
         │
         ▼
User sees events with friend avatars
```

### 2. RSVPing to an Event

```
User clicks "Going" button on event
         │
         ▼
EventRsvpButtons calls rsvpActionProvider with (eventId, 'going')
         │
         ▼
Provider calls service.rsvpToEvent(eventId, 'going')
         │
         ▼
Service performs batched write:
  1. events/{eventId}/attendees/{userId}
     { status: 'going', timestamp: now }
  2. users/{userId}/event_rsvps/{eventId}
     { status: 'going', timestamp: now }
  3. Increment events/{eventId}/attendeesCount
         │
         ▼
Write succeeds
         │
         ▼
Provider invalidates:
  - eventDetailsProvider(eventId)
  - eventAttendeesProvider
  - userEventRsvpsProvider
         │
         ▼
All watching widgets rebuild with new data
         │
         ▼
Button shows selected state (gold background)
Event card shows updated attendeesCount
```

### 3. Getting Event Recommendations

```
User opens "Recommended" tab
         │
         ▼
EventsPage watches recommendedEventsProvider
         │
         ▼
Provider calls service.watchRecommendedEvents(userId)
         │
         ▼
Service queries users/{userId} (get interests array)
         │
         ▼
Service queries events/ where date > now
         │
         ▼
Service scores each event:
  For each event:
    score = 0
    if event.category in user.interests → score += 2
    if any friend attending → score += 1
  Sort by score DESC
  Take top 20
         │
         ▼
Service returns Stream<List<Event>> (sorted by score)
         │
         ▼
Provider emits AsyncValue<List<Event>>
         │
         ▼
EventsPage builds list with "Picked for you" header
         │
         ▼
User sees personalized event recommendations
```

---

## Key Integration Points

### Social Graph Integration
- **Following/Followers** from Phase 4 used to find friends
- `watchEventsFriendsAreAttending()` queries following subcollection
- `watchFriendsAttendingEvent()` checks which friends are at event
- Presence indicators show friend online status

### Presence Integration
- `PresenceIndicator` widget overlaid on avatars
- Shows online/away/busy/offline status
- Integrated in attendees list on EventDetailsPage

### Room Integration
- Events can have `isOnline: true` and `roomId: "abc123"`
- "Join Room" button navigates to `/room` route
- Allows users to join video/audio room for virtual events

---

## Widget Component Hierarchy

```
EventsPage (TabBarView)
├── Tab 1: All Events
│   └── ListView
│       └── EventCard (for each event)
│           ├── Title, time, location
│           ├── Stats (attendeesCount, interestedCount)
│           └── EventAttendeesStrip (friends attending)
│
├── Tab 2: Friends Events
│   ├── Header: "N events from your network"
│   └── ListView
│       └── EventCard (for each event)
│
└── Tab 3: Recommended Events
    ├── Header: "Picked for you"
    └── ListView
        └── EventCard (for each event)

EventDetailsPage
├── ClubBackground
├── AppBar
└── SingleChildScrollView
    ├── Event Image (if available)
    ├── Title + Online Badge
    ├── Host Profile
    │   ├── Avatar
    │   └── "Hosted by {name}"
    ├── Date/Time Info
    ├── Location Info
    ├── Category
    ├── Stats Chips (attendeesCount, interestedCount)
    ├── Description
    ├── FriendsAttendingBanner (if friends present)
    │   ├── Gold border
    │   ├── "3 friends attending"
    │   └── EventAttendeesStrip
    ├── EventRsvpButtons (Going / Interested / Remove)
    ├── Join Room Button (if online event)
    └── Attendees List
        └── For each attendee:
            ├── Avatar + PresenceIndicator overlay
            ├── Display name
            ├── Bio
            └── FollowButton
```

---

## Performance Considerations

### Real-time Updates
- All providers use `StreamProvider` for live data
- Firestore snapshots provide instant updates
- UI rebuilds automatically on data changes

### Caching
- Riverpod caches provider results
- Same eventId → same provider instance
- Reduces redundant Firestore queries

### Batched Writes
- RSVP uses `WriteBatch` for atomicity
- Updates 2 locations + counter in 1 operation
- Rollback on failure

### Query Optimization
- Friends query limited by following count
- Recommendations limited to top 20
- Attendees paginated if needed

---

## Security Rules (Recommended)

```javascript
// events/{eventId}/attendees/{userId}
match /events/{eventId}/attendees/{userId} {
  allow read: if request.auth != null;
  allow write: if request.auth.uid == userId;
}

// users/{userId}/event_rsvps/{eventId}
match /users/{userId}/event_rsvps/{eventId} {
  allow read: if request.auth.uid == userId;
  allow write: if request.auth.uid == userId;
}

// events/{eventId}
match /events/{eventId} {
  allow read: if request.auth != null;
  allow create: if request.auth != null;
  allow update: if request.auth.uid == resource.data.hostId;
  allow delete: if request.auth.uid == resource.data.hostId;
}
```

---

## Future Enhancements

### Phase 6 Ideas
1. **Event Chat** - Group chat for attendees
2. **Push Notifications** - Friend RSVPs, event reminders
3. **Event Photos** - Upload/share photos from event
4. **Check-ins** - Verify attendance with location
5. **Recurring Events** - Weekly/monthly events
6. **Paid Events** - Stripe integration for tickets
7. **Waitlist** - When event reaches capacity
8. **Co-hosts** - Multiple hosts per event
9. **Event Series** - Link related events
10. **Advanced Filters** - Search by date range, location, price

---

## Summary

Phase 5 Events Engine provides:
- ✅ Real-time event discovery
- ✅ Social graph integration (friends attending)
- ✅ AI-powered recommendations
- ✅ RSVP system with atomic writes
- ✅ Presence indicators
- ✅ Online event support
- ✅ Beautiful, responsive UI
- ✅ Robust error handling

**Total Architecture Layers:** 4 (Presentation → Provider → Service → Firebase)
**Total Integration Points:** 3 (Social Graph, Presence, Rooms)
**Total Lines of Code:** ~2,000
**Real-time Streams:** 8+
**Action Providers:** 2
**Widgets Created:** 4
