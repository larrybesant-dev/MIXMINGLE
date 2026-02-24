import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/events_providers.dart';
import '../../../shared/providers/auth_providers.dart';
import '../../../shared/widgets/events_widgets.dart';
import '../../../shared/widgets/club_background.dart';

class EventsPage extends ConsumerStatefulWidget {
  const EventsPage({super.key});

  @override
  ConsumerState<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends ConsumerState<EventsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClubBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Events'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {
                Navigator.of(context).pushNamed('/create-event');
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Friends'),
              Tab(text: 'Recommended'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _AllEventsTab(),
            _FriendsEventsTab(),
            _RecommendedEventsTab(),
          ],
        ),
      ),
    );
  }
}

// Tab 1: All Upcoming Events
class _AllEventsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(upcomingEventsProvider);

    return eventsAsync.when(
      data: (events) {
        if (events.isEmpty) {
          return _buildEmptyState(
            context,
            icon: Icons.event,
            title: 'No upcoming events',
            subtitle: 'Be the first to create an event!',
            actionLabel: 'Create Event',
            onAction: () => Navigator.of(context).pushNamed('/create-event'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: EventCard(
                event: event,
                onTap: () {
                  Navigator.of(context).pushNamed(
                    '/event-details',
                    arguments: {'eventId': event.id},
                  );
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _buildErrorState(
        context,
        error: error.toString(),
        onRetry: () => ref.invalidate(upcomingEventsProvider),
      ),
    );
  }
}

// Tab 2: Events Friends Are Attending
class _FriendsEventsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).value;

    if (currentUser == null) {
      return _buildEmptyState(
        context,
        icon: Icons.login,
        title: 'Not logged in',
        subtitle: 'Sign in to see events your friends are attending',
        actionLabel: 'Sign In',
        onAction: () => Navigator.of(context).pushNamed('/login'),
      );
    }

    final eventsAsync = ref.watch(friendsEventsProvider);

    return eventsAsync.when(
      data: (events) {
        if (events.isEmpty) {
          return _buildEmptyState(
            context,
            icon: Icons.people_outline,
            title: 'No events from friends',
            subtitle: 'Your friends haven\'t RSVPed to any upcoming events yet',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.people, color: Color(0xFFFFD700), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${events.length} event${events.length != 1 ? 's' : ''} from your network',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: EventCard(
                      event: event,
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          '/event-details',
                          arguments: {'eventId': event.id},
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _buildErrorState(
        context,
        error: error.toString(),
        onRetry: () => ref.invalidate(friendsEventsProvider),
      ),
    );
  }
}

// Tab 3: Recommended Events
class _RecommendedEventsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).value;

    if (currentUser == null) {
      return _buildEmptyState(
        context,
        icon: Icons.login,
        title: 'Not logged in',
        subtitle: 'Sign in to see personalized event recommendations',
        actionLabel: 'Sign In',
        onAction: () => Navigator.of(context).pushNamed('/login'),
      );
    }

    final eventsAsync = ref.watch(recommendedEventsProvider);

    return eventsAsync.when(
      data: (events) {
        if (events.isEmpty) {
          return _buildEmptyState(
            context,
            icon: Icons.lightbulb_outline,
            title: 'No recommendations yet',
            subtitle:
                'Update your interests to get personalized event suggestions',
            actionLabel: 'Update Profile',
            onAction: () => Navigator.of(context).pushNamed('/edit-profile'),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Color(0xFFFFD700), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Picked for you',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: EventCard(
                      event: event,
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          '/event-details',
                          arguments: {'eventId': event.id},
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _buildErrorState(
        context,
        error: error.toString(),
        onRetry: () => ref.invalidate(recommendedEventsProvider),
      ),
    );
  }
}

// Helper: Empty State Widget
Widget _buildEmptyState(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(actionLabel),
            ),
          ],
        ],
      ),
    ),
  );
}

// Helper: Error State Widget
Widget _buildErrorState(
  BuildContext context, {
  required String error,
  required VoidCallback onRetry,
}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red,
          ),
          const SizedBox(height: 24),
          const Text(
            'Something went wrong',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            error,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    ),
  );
}
