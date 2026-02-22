import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';
import '../providers/events_controller.dart';
import 'event_details_page.dart';
import 'create_event_page.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Events'),
            Tab(text: 'My Events'),
            Tab(text: 'Attending'),
          ],
        ),
        actions: [
          Semantics(
            label: 'Search Events',
            button: true,
            child: IconButton(
              key: const Key('searchEventsButton'),
              icon: const Icon(Icons.search),
              onPressed: () => _showSearchDialog(context),
            ),
          ),
          Semantics(
            label: 'Filter Events',
            button: true,
            child: IconButton(
              key: const Key('filterEventsButton'),
              icon: const Icon(Icons.filter_list),
              onPressed: () => _showFilterDialog(context),
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllEventsTab(),
          _buildMyEventsTab(),
          _buildAttendingEventsTab(),
        ],
      ),
      floatingActionButton: Semantics(
        label: 'Create Event',
        button: true,
        child: FloatingActionButton(
          key: const Key('createEventButton'),
          onPressed: () => _navigateToCreateEvent(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildAllEventsTab() {
    final eventsAsync = ref.watch(allEventsProvider);

    return eventsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error loading events: $error'),
            ElevatedButton(
              onPressed: () => ref.invalidate(allEventsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (events) => events.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_note, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No events available',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async => ref.invalidate(allEventsProvider),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return EventCard(
                    event: event,
                    onTap: () => _navigateToEventDetails(context, event),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildMyEventsTab() {
    final eventsAsync = ref.watch(myEventsProvider);

    return eventsAsync.when(
      data: (events) => events.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_available, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'You haven\'t created any events yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap + to create your first event!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async => ref.invalidate(myEventsProvider),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return EventCard(
                    event: event,
                    onTap: () => _navigateToEventDetails(context, event),
                    showEditButton: true,
                  );
                },
              ),
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error loading your events: $error'),
      ),
    );
  }

  Widget _buildAttendingEventsTab() {
    final eventsAsync = ref.watch(attendingEventsProvider);

    return eventsAsync.when(
      data: (events) => events.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'You\'re not attending any events',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Browse events to find something interesting!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async => ref.invalidate(attendingEventsProvider),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return EventCard(
                    event: event,
                    onTap: () => _navigateToEventDetails(context, event),
                  );
                },
              ),
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error loading attending events: $error'),
      ),
    );
  }

  void _navigateToEventDetails(BuildContext context, Event event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailsPage(event: event),
      ),
    );
  }

  void _navigateToCreateEvent(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateEventPage(),
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const EventSearchDialog(),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const EventFilterDialog(),
    );
  }
}

class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;
  final bool showEditButton;

  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
    this.showEditButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isPast = event.endTime.isBefore(now);
    final isOngoing =
        event.startTime.isBefore(now) && event.endTime.isAfter(now);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (showEditButton)
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        // TODO: Navigate to edit event page
                      },
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                event.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      event.location,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${DateFormat('MMM dd, HH:mm').format(event.startTime)} - ${DateFormat('HH:mm').format(event.endTime)}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(isPast, isOngoing),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(isPast, isOngoing),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${event.attendees.length}/${event.maxAttendees} attending',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(bool isPast, bool isOngoing) {
    if (isPast) return Colors.grey;
    if (isOngoing) return Colors.green;
    return Colors.blue;
  }

  String _getStatusText(bool isPast, bool isOngoing) {
    if (isPast) return 'Past';
    if (isOngoing) return 'Ongoing';
    return 'Upcoming';
  }
}

class EventSearchDialog extends ConsumerStatefulWidget {
  const EventSearchDialog({super.key});

  @override
  ConsumerState<EventSearchDialog> createState() => _EventSearchDialogState();
}

class _EventSearchDialogState extends ConsumerState<EventSearchDialog> {
  final _searchController = TextEditingController();
  final List<String> _categories = [
    'Social',
    'Networking',
    'Sports',
    'Music',
    'Food',
    'Art',
    'Technology'
  ];
  String? _selectedCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Search Events'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Search by title or description',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            items: _categories.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedCategory = value),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // TODO: Implement search functionality
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Search functionality not implemented yet')),
            );
          },
          child: const Text('Search'),
        ),
      ],
    );
  }
}

class EventFilterDialog extends StatefulWidget {
  const EventFilterDialog({super.key});

  @override
  State<EventFilterDialog> createState() => _EventFilterDialogState();
}

class _EventFilterDialogState extends State<EventFilterDialog> {
  bool _upcomingOnly = true;
  bool _nearbyOnly = false;
  double _radiusKm = 10.0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter Events'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: const Text('Upcoming events only'),
            value: _upcomingOnly,
            onChanged: (value) => setState(() => _upcomingOnly = value),
          ),
          SwitchListTile(
            title: const Text('Nearby events only'),
            value: _nearbyOnly,
            onChanged: (value) => setState(() => _nearbyOnly = value),
          ),
          if (_nearbyOnly)
            Slider(
              value: _radiusKm,
              min: 1,
              max: 100,
              divisions: 99,
              label: '${_radiusKm.round()} km',
              onChanged: (value) => setState(() => _radiusKm = value),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // TODO: Implement filter functionality
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Filter functionality not implemented yet')),
            );
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
