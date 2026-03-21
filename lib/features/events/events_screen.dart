import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Replace with real event list from provider
    final events = [
      {'title': 'Speed Dating', 'date': '2026-04-01'},
      {'title': 'Live Music', 'date': '2026-04-10'},
      {'title': 'Trivia Night', 'date': '2026-04-15'},
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, i) {
          final event = events[i];
          return ListTile(
            leading: const Icon(Icons.event),
            title: Text(event['title'] as String),
            subtitle: Text('Date: ${event['date']}'),
            trailing: ElevatedButton(
              onPressed: () {},
              child: const Text('Details'),
            ),
          );
        },
      ),
    );
  }
}
