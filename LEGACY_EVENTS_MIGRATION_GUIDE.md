# Legacy Events Files Migration Guide

## Overview
The new Phase 5 Events Engine uses a completely rewritten EventsService with social graph integration. Two legacy files still reference old EventsService methods and need to be updated or deprecated.

---

## Legacy Files

### 1. lib/providers/event_dating_providers.dart
**Status:** Uses old EventsService methods ❌

**Old Methods Referenced:**
- `getEvent(eventId)` → Use `eventDetailsProvider(eventId)` instead
- `joinEvent(eventId)` → Use `rsvpToEvent(eventId, 'going')` instead
- `leaveEvent(eventId)` → Use `removeRsvp(eventId)` instead
- `getNearbyEvents(lat, lng, radius)` → Not implemented in Phase 5
- `getAllEvents()` → Use `upcomingEventsProvider` instead

**Recommendation:** Refactor this file to use the new Phase 5 providers:
- Replace `EventsService` method calls with Riverpod provider watches
- Use `ref.watch(eventDetailsProvider(eventId))` for event details
- Use `ref.read(eventsServiceProvider).rsvpToEvent()` for RSVP actions

### 2. lib/providers/events_controller.dart
**Status:** Duplicate provider definitions, uses old methods ❌

**Issues:**
- Redefines `eventsServiceProvider` (already in events_providers.dart)
- Redefines `upcomingEventsProvider` (already in events_providers.dart)
- Uses old stream methods:
  - `streamAllEvents()` → Use `watchUpcomingEvents()` instead
  - `streamMyEvents()` → Not in Phase 5, query user's RSVPs instead
  - `streamAttendingEvents()` → Use `watchUserEventRsvps(userId)` instead
  - `streamEventById(eventId)` → Use `watchEvent(eventId)` instead
  - `streamUpcomingEvents()` → Use `watchUpcomingEvents()` instead
- References `RSVPStatus` class which doesn't exist
- Uses `joinEvent()`, `leaveEvent()`, `updateRSVPStatus()` methods

**Recommendation:**
- **Option A:** Delete this file completely and use `events_providers.dart` instead
- **Option B:** Refactor to wrap Phase 5 providers with different names to avoid conflicts

---

## Migration Steps

### Quick Fix (Recommended)
1. Rename or comment out `event_dating_providers.dart` and `events_controller.dart`
2. Update any screens/widgets that import these files to use `events_providers.dart` instead
3. Replace method calls with new Phase 5 equivalents

### Full Migration
1. **Find all usages:**
   ```bash
   # Search for imports
   grep -r "event_dating_providers" lib/
   grep -r "events_controller" lib/
   ```

2. **Replace provider references:**
   - Old: `ref.watch(allEventsProvider)`
   - New: `ref.watch(upcomingEventsProvider)`

   - Old: `ref.watch(eventProvider(eventId))`
   - New: `ref.watch(eventDetailsProvider(eventId))`

3. **Replace RSVP logic:**
   - Old: `eventsService.joinEvent(eventId)`
   - New: `eventsService.rsvpToEvent(eventId, 'going')`

   - Old: `eventsService.leaveEvent(eventId)`
   - New: `eventsService.removeRsvp(eventId)`

4. **Update event queries:**
   - Old: `eventsService.streamMyEvents()`
   - New: `ref.watch(userEventRsvpsProvider(userId))`

---

## New Phase 5 API Reference

### Providers (lib/providers/events_providers.dart)
```dart
// Service
ref.watch(eventsServiceProvider)

// Event streams
ref.watch(upcomingEventsProvider)
ref.watch(eventDetailsProvider(eventId))
ref.watch(eventAttendeesProvider((eventId: id, status: 'going')))

// Social features
ref.watch(friendsEventsProvider)
ref.watch(recommendedEventsProvider)
ref.watch(friendsAttendingEventProvider((userId: uid, eventId: eid)))

// User RSVPs
ref.watch(userEventRsvpsProvider(userId))
ref.watch(userRsvpStatusProvider((userId: uid, eventId: eid)))

// Actions (Future providers)
ref.read(rsvpActionProvider((eventId: id, status: 'going')).future)
ref.read(removeRsvpActionProvider(eventId).future)
```

### EventsService Methods (lib/services/events_service.dart)
```dart
// Streams
watchUpcomingEvents() → Stream<List<Event>>
watchEvent(eventId) → Stream<Event?>
watchEventAttendees(eventId, {status}) → Stream<List<UserProfile>>
watchEventsFriendsAreAttending(userId) → Stream<List<Event>>
watchRecommendedEvents(userId) → Stream<List<Event>>
watchFriendsAttendingEvent(userId, eventId) → Stream<List<UserProfile>>
watchUserRsvpStatus(userId, eventId) → Stream<String?>
watchUserEventRsvps(userId) → Stream<List<Event>>

// Actions
rsvpToEvent(eventId, status) → Future<void>
removeRsvp(eventId) → Future<void>
createEvent(event) → Future<String>
updateEvent(event) → Future<void>
deleteEvent(eventId) → Future<void>

// Single reads
getUserRsvpStatus(eventId) → Future<String?>
getFriendsAttendingEvent(userId, eventId) → Future<List<UserProfile>>
```

---

## Status Summary

### ✅ Working (Phase 5)
- `lib/providers/events_providers.dart` - NEW, social-integrated
- `lib/services/events_service.dart` - Rewritten with social features
- `lib/shared/widgets/events_widgets.dart` - NEW, social widgets
- `lib/features/events/screens/event_details_page.dart` - Recreated
- `lib/features/events/screens/events_list_page.dart` - Recreated with tabs

### ⚠️ Legacy (Needs Update)
- `lib/providers/event_dating_providers.dart` - References old methods
- `lib/providers/events_controller.dart` - Duplicate providers, old methods

### 📝 Action Required
Either:
1. Delete/deprecate legacy files
2. Or refactor them to use Phase 5 API

---

## Testing After Migration

Once legacy files are updated:
```bash
# Run analysis
flutter analyze

# Check for undefined methods
grep -r "joinEvent\|leaveEvent\|getEvent\|streamAllEvents" lib/

# Run tests
flutter test

# Build
flutter build apk --debug
```

---

## Questions?

If unsure about migration path:
1. Check which screens import legacy providers
2. Decide if functionality is still needed
3. Either delete or refactor to Phase 5 API
4. Test thoroughly

**Recommendation:** Start by commenting out legacy files and seeing what breaks, then fix imports one by one.
