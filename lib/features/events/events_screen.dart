import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../feed/providers/feed_providers.dart';


class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsStreamProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      body: eventsAsync.when(
        data: (events) => events.isEmpty
            ? const Center(child: Text('No events available.'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: events.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (context, i) {
                  final event = events[i];
                  return ListTile(
                    leading: const Icon(Icons.event),
                    title: Text(event.title),
                    subtitle: Text('Host: ${event.hostId} • ${event.date.toLocal().toString().split(' ')[0]}'),
                    trailing: ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(event.title),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Host: ${event.hostId}'),
                                const SizedBox(height: 8),
                                Text('Date: ${event.date.toLocal().toString().split(' ')[0]}'),
                                // No description field in EventModel
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Close'),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  final mounted = context.mounted;
                                  // Simulate join event logic (replace with backend call as needed)
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Join Event'),
                                      content: const Text('Do you want to join this event?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => Navigator.of(context).pop(true),
                                          child: const Text('Join'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (mounted && context.mounted) {
                                    Navigator.of(context).pop();
                                    if (confirm == true) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('You have joined the event!')),
                                      );
                                    }
                                  }
                                },
                                child: const Text('Join'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: const Text('Details'),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
