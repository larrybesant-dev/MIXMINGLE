
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/events_service.dart';
import '../shared/models/event.dart';
import '../shared/models/user_profile.dart';
import 'auth_providers.dart';

// Service provider
final eventsServiceProvider = Provider<EventsService>((ref) => EventsService());

// Upcoming events provider
final upcomingEventsProvider = StreamProvider<List<Event>>((ref) {
  final service = ref.watch(eventsServiceProvider);
  return service.watchUpcomingEvents();
});

// Event details provider by ID
final eventDetailsProvider = StreamProvider.family<Event?, String>((ref, eventId) {
  final service = ref.watch(eventsServiceProvider);
  return service.watchEvent(eventId);
});

// Event attendees provider (all attendees or filtered by status)
final eventAttendeesProvider =
    StreamProvider.family<List<UserProfile>, ({String eventId, String? status})>((ref, params) {
  final service = ref.watch(eventsServiceProvider);
  return service.watchEventAttendees(params.eventId, status: params.status);
});

// Friends' events provider (events that friends are attending)
final friendsEventsProvider = StreamProvider<List<Event>>((ref) {
  final currentUser = ref.watch(currentUserProvider).value;
  if (currentUser == null) return Stream.value([]);

  final service = ref.watch(eventsServiceProvider);
  return service.watchEventsFriendsAreAttending(currentUser.id);
});

// Recommended events provider (based on interests and social graph)
final recommendedEventsProvider = StreamProvider<List<Event>>((ref) {
  final currentUser = ref.watch(currentUserProvider).value;
  if (currentUser == null) return Stream.value([]);

  final service = ref.watch(eventsServiceProvider);
  return service.watchRecommendedEvents(currentUser.id);
});

// User event RSVPs provider
final userEventRsvpsProvider = StreamProvider.family<List<Event>, String>((ref, userId) {
  final service = ref.watch(eventsServiceProvider);
  return service.watchUserEventRsvps(userId);
});

// User's RSVP status for specific event
final userRsvpStatusProvider = StreamProvider.family<String?, ({String userId, String eventId})>((ref, params) {
  final service = ref.watch(eventsServiceProvider);
  return service.watchUserRsvpStatus(params.userId, params.eventId);
});

// Friends attending specific event
final friendsAttendingEventProvider =
    StreamProvider.family<List<UserProfile>, ({String userId, String eventId})>((ref, params) {
  final service = ref.watch(eventsServiceProvider);
  return service.watchFriendsAttendingEvent(params.userId, params.eventId);
});

// RSVP action provider
final rsvpActionProvider = FutureProvider.family<void, ({String eventId, String status})>((ref, params) async {
  final service = ref.watch(eventsServiceProvider);
  await service.rsvpToEvent(params.eventId, params.status);

  // Invalidate related providers to trigger refresh
  ref.invalidate(eventDetailsProvider(params.eventId));
  ref.invalidate(eventAttendeesProvider((eventId: params.eventId, status: null)));
  ref.invalidate(userEventRsvpsProvider);
});

// Remove RSVP action provider
final removeRsvpActionProvider = FutureProvider.family<void, String>((ref, eventId) async {
  final service = ref.watch(eventsServiceProvider);
  await service.removeRsvp(eventId);

  // Invalidate related providers to trigger refresh
  ref.invalidate(eventDetailsProvider(eventId));
  ref.invalidate(eventAttendeesProvider((eventId: eventId, status: null)));
  ref.invalidate(userEventRsvpsProvider);
});


