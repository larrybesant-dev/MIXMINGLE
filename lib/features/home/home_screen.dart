
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Feed'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () => Navigator.pushNamed(context, '/chats'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Create Post'),
        onPressed: () {}, // Add post creation logic
      ),
      body: ListView(
        padding: const EdgeInsets.all(32),
        children: [
          const SizedBox(height: 24),
          Text(
            'Welcome to MixVy!',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Live posts, rooms, and events will appear here.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Card(
            color: Colors.deepPurple.shade50,
            child: ListTile(
              leading: const Icon(Icons.event, color: Colors.deepPurple),
              title: const Text('Upcoming Event: MixVy Launch Party'),
              subtitle: const Text('March 25, 2026 • 7:00 PM'),
              trailing: ElevatedButton(
                child: const Text('Join'),
                onPressed: () {}, // Add join event logic
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.blue.shade50,
            child: ListTile(
              leading: const Icon(Icons.room, color: Colors.blue),
              title: const Text('Live Room: Chill Vibes'),
              subtitle: const Text('Join now and meet new people!'),
              trailing: ElevatedButton(
                child: const Text('Enter'),
                onPressed: () {}, // Add enter room logic
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.orange.shade50,
            child: ListTile(
              leading: const Icon(Icons.star, color: Colors.orange),
              title: const Text('Featured Post: Welcome to MixVy!'),
              subtitle: const Text('Check out our new features and connect.'),
              trailing: ElevatedButton(
                child: const Text('View'),
                onPressed: () {}, // Add view post logic
              ),
            ),
          ),
        ],
      ),
    );
  }
}
