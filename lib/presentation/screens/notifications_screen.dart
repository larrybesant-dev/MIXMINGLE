import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.purple),
              child: const Text('MixVy Navigation', style: TextStyle(color: Colors.white, fontSize: 20)),
            ),
            ListTile(title: const Text('Home Feed'), onTap: () => context.go('/home')),
            ListTile(title: const Text('Chats'), onTap: () => context.go('/chats')),
            ListTile(title: const Text('Friends'), onTap: () => context.go('/friends')),
            ListTile(title: const Text('Profile'), onTap: () => context.go('/profile/${'userId'}')),
            ListTile(title: const Text('Payments'), onTap: () => context.go('/payments-demo')),
            ListTile(title: const Text('Notifications'), onTap: () => context.go('/notifications')),
            ListTile(title: const Text('Live Room'), onTap: () => context.go('/live/${'roomId'}')),
            ListTile(title: const Text('Settings'), onTap: () => context.go('/settings')),
            ListTile(title: const Text('Moderation'), onTap: () => context.go('/moderation')),
            ListTile(title: const Text('Search'), onTap: () => context.go('/search')),
            ListTile(title: const Text('Invite Friends'), onTap: () => context.go('/invite')),
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
                  icon: const Icon(Icons.notifications_active),
                  label: const Text('Mark All Read'),
                  onPressed: () {},
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.settings),
                  label: const Text('Notification Settings'),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance.collection('notifications').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = (snapshot.data as QuerySnapshot).docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) => Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: Icon(Icons.notifications, color: Colors.purple),
                      title: Text(docs[index]['title'] ?? 'Notification'),
                      subtitle: Text(docs[index]['body'] ?? ''),
                      trailing: IconButton(icon: const Icon(Icons.check), onPressed: () {}),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    // ...existing code...
    );
  }
}
