import 'package:flutter/material.dart';

class HomeFeedScreen extends StatelessWidget {
  const HomeFeedScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Feed')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.purple),
              child: const Text('MixVy Navigation', style: TextStyle(color: Colors.white, fontSize: 20)),
            ),
            ListTile(title: const Text('Home Feed'), onTap: () => Navigator.pushNamed(context, '/home')),
            ListTile(title: const Text('Chats'), onTap: () => Navigator.pushNamed(context, '/chats')),
            ListTile(title: const Text('Friends'), onTap: () => Navigator.pushNamed(context, '/friends')),
            ListTile(title: const Text('Profile'), onTap: () => Navigator.pushNamed(context, '/profile')),
            ListTile(title: const Text('Payments'), onTap: () => Navigator.pushNamed(context, '/payments')),
            ListTile(title: const Text('Notifications'), onTap: () => Navigator.pushNamed(context, '/notifications')),
            ListTile(title: const Text('Live Room'), onTap: () => Navigator.pushNamed(context, '/live-room')),
            ListTile(title: const Text('Settings'), onTap: () => Navigator.pushNamed(context, '/settings')),
            ListTile(title: const Text('Moderation'), onTap: () => Navigator.pushNamed(context, '/moderation')),
            ListTile(title: const Text('Search'), onTap: () => Navigator.pushNamed(context, '/search')),
            ListTile(title: const Text('Invite Friends'), onTap: () => Navigator.pushNamed(context, '/invite-friends')),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('New Post'),
                  onPressed: () {},
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.meeting_room),
                  label: const Text('Create Room'),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) => Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(child: Text('U$index')),
                  title: Text('Post Title $index'),
                  subtitle: Text('This is a placeholder for a live post or event.'),
                  trailing: IconButton(icon: const Icon(Icons.chat), onPressed: () {}),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
