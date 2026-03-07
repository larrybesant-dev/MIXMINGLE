
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event.dart';
import '../../services/events/events_service.dart';
import 'auth_providers.dart';

// Events service provider
final eventsServiceProvider = Provider<EventsService>((ref) {
  return EventsService();
});

// All events provider - REAL-TIME STREAM
final allEventsProvider = StreamProvider<List<Event>>((ref) {
  final eventsService = ref.watch(eventsServiceProvider);
  return eventsService.watchUpcomingEvents();
});

// My events provider - REAL-TIME STREAM (user's created events)
final myEventsProvider = StreamProvider<List<Event>>((ref) {
  final eventsService = ref.watch(eventsServiceProvider);
  // For now, return upcoming events. TODO: Add separate method for user's created events
  return eventsService.watchUpcomingEvents();
});

// Attending events provider - REAL-TIME STREAM
final attendingEventsProvider = StreamProvider<List<Event>>((ref) {
  final eventsService = ref.watch(eventsServiceProvider);
  final userId = ref.watch(currentUserProvider).value?.id;
  if (userId == null) return Stream.value([]);
  return eventsService.watchUserEventRsvps(userId);
});

// Event by ID provider - REAL-TIME STREAM
final eventProvider = StreamProvider.family<Event?, String>((ref, eventId) {
  final eventsService = ref.watch(eventsServiceProvider);
  return eventsService.watchEvent(eventId);
});

// Upcoming events provider - REAL-TIME STREAM
final upcomingEventsProvider = StreamProvider<List<Event>>((ref) {
  final eventsService = ref.watch(eventsServiceProvider);
  return eventsService.watchUpcomingEvents();
});

// Nearby events provider — fetches all future events and filters by distance client-side
final nearbyEventsProvider =
    FutureProvider.family<List<Event>, Map<String, dynamic>>((ref, params) async {
  final lat = (params['latitude'] as num?)?.toDouble() ?? 0.0;
  final lon = (params['longitude'] as num?)?.toDouble() ?? 0.0;
  final radiusKm = (params['radiusKm'] as num?)?.toDouble() ?? 50.0;
  final snap = await FirebaseFirestore.instance
      .collection('events')
      .where('startTime', isGreaterThanOrEqualTo: DateTime.now().toIso8601String())
      .limit(100)
      .get();
  final events = snap.docs.map((d) => Event.fromMap(d.data())).toList();
  return events.where((e) {
    final dist = _haversineKm(lat, lon, e.latitude, e.longitude);
    return dist <= radiusKm;
  }).toList();
});

// Equirectangular approximation — accurate enough for nearby events (< 200 km)
double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371.0;
  final dLat = (lat2 - lat1) * math.pi / 180.0;
  final dLon = (lon2 - lon1) * math.pi / 180.0;
  final avgLat = (lat1 + lat2) / 2.0 * math.pi / 180.0;
  final x = dLon * math.cos(avgLat) * r;
  final y = dLat * r;
  return math.sqrt(x * x + y * y);
}

// Events by category provider
final eventsByCategoryProvider =
    FutureProvider.family<List<Event>, String>((ref, category) async {
  final snap = await FirebaseFirestore.instance
      .collection('events')
      .where('category', isEqualTo: category)
      .orderBy('startTime')
      .limit(50)
      .get();
  return snap.docs.map((d) => Event.fromMap(d.data())).toList();
});

// Events controller for mutations
final eventsControllerProvider = Provider<EventsController>((ref) {
  return EventsController(ref.read(eventsServiceProvider));
});

class EventsController {
  final EventsService _eventsService;

  EventsController(this._eventsService);

  Future<void> createEvent(Event event) async {
    try {
      await _eventsService.createEvent(event);
    } catch (e) {
      debugPrint('Failed to create event: $e');
      rethrow;
    }
  }

  Future<void> updateEvent(Event event) async {
    try {
      await _eventsService.updateEvent(event);
    } catch (e) {
      debugPrint('Failed to update event: $e');
      rethrow;
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      await _eventsService.deleteEvent(eventId);
    } catch (e) {
      debugPrint('Failed to delete event: $e');
      rethrow;
    }
  }

  Future<void> joinEvent(String eventId) async {
    try {
      await _eventsService.rsvpToEvent(eventId, 'going');
    } catch (e) {
      debugPrint('Failed to join event: $e');
      rethrow;
    }
  }

  Future<void> leaveEvent(String eventId) async {
    try {
      await _eventsService.removeRsvp(eventId);
    } catch (e) {
      debugPrint('Failed to leave event: $e');
      rethrow;
    }
  }

  Future<void> updateRSVPStatus(String eventId, String status) async {
    try {
      await _eventsService.rsvpToEvent(eventId, status);
    } catch (e) {
      debugPrint('Failed to update RSVP status: $e');
      rethrow;
    }
  }
}

// Filtered events provider - defaults to showing all events
final filteredEventsProvider = Provider<List<Event>>((ref) {
  final eventsAsync = ref.watch(allEventsProvider);
  final searchState = ref.watch(eventSearchProvider);

  return eventsAsync.when(
    data: (events) {
      var filtered = events;

      // Filter by search query
      if (searchState.query.isNotEmpty) {
        final query = searchState.query.toLowerCase();
        filtered = filtered
            .where((event) =>
                event.title.toLowerCase().contains(query) ||
                event.description.toLowerCase().contains(query) ||
                event.location.toLowerCase().contains(query))
            .toList();
      }

      // Filter by category
      if (searchState.category != null && searchState.category!.isNotEmpty) {
        filtered = filtered.where((event) => event.category == searchState.category).toList();
      }

      return filtered;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Search and filter state providers
final eventSearchProvider = NotifierProvider<EventSearchNotifier, EventSearch>(
  EventSearchNotifier.new,
);

class EventSearchNotifier extends Notifier<EventSearch> {
  @override
  EventSearch build() {
    return const EventSearch(query: '', category: null);
  }

  void setQuery(String query) {
    state = EventSearch(query: query, category: state.category);
  }

  void setCategory(String? category) {
    state = EventSearch(query: state.query, category: category);
  }

  void clearFilters() {
    state = const EventSearch(query: '', category: null);
  }

  void clearSearch() {
    state = const EventSearch(query: '', category: null);
  }
}

class EventSearch {
  final String query;
  final String? category;

  const EventSearch({
    required this.query,
    required this.category,
  });
}
