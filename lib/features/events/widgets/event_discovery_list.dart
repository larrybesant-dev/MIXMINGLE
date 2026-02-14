// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/event.dart';
import '../../../core/services/ab_testing_service.dart';
import '../../../providers/events_controller.dart';
import '../../../providers/gamification_payment_providers.dart';
import 'event_card_horizontal.dart';
import 'event_card_vertical.dart';

/// Event discovery list with A/B testing for layout
/// Shows either horizontal scroll or vertical list based on Remote Config
class EventDiscoveryList extends ConsumerStatefulWidget {
  const EventDiscoveryList({super.key});

  @override
  ConsumerState<EventDiscoveryList> createState() => _EventDiscoveryListState();
}

class _EventDiscoveryListState extends ConsumerState<EventDiscoveryList> {
  bool _exposureLogged = false;

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(upcomingEventsProvider);
    final abService = ref.watch(abTestingServiceProvider);
    final layout = abService.getEventLayout();

    // Log experiment exposure once
    if (!_exposureLogged) {
      _logExperimentExposure(layout);
      _exposureLogged = true;
    }

    return eventsAsync.when(
      data: (events) {
        if (events.isEmpty) {
          return _buildEmptyState();
        }

        if (layout == 'horizontal') {
          return _buildHorizontalLayout(events);
        } else {
          return _buildVerticalLayout(events);
        }
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stackTrace) => _buildErrorState(error),
    );
  }

  Widget _buildHorizontalLayout(List<Event> events) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            'Upcoming Events',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        SizedBox(
          height: 380,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return EventCardHorizontal(event);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalLayout(List<Event> events) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Upcoming Events',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return EventCardVertical(event);
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No upcoming events',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back soon for new events!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load events',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(upcomingEventsProvider);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _logExperimentExposure(String layout) {
    ref.read(analyticsServiceProvider).logEvent(
      'experiment_exposure',
      parameters: {
        'experiment_name': 'event_layout_v1',
        'variant': layout,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
}
