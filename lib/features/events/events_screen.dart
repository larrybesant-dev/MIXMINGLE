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
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, i) {
                  final event = events[i];
                  return ListTile(
                    leading: const Icon(Icons.event),
                    title: Text(event.title),
                       subtitle: Text('Host: ${event.hostId} • ${event.date.toLocal().toString().split(' ')[0]}'),
                    trailing: ElevatedButton(
                      onPressed: () {
                        // TODO: Show event details or join logic
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
