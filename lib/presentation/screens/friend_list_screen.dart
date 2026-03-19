import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FriendListScreen extends StatelessWidget {
  const FriendListScreen({super.key});
    @override
    Widget build(BuildContext context) {
        return Scaffold(
          appBar: AppBar(title: const Text('Friends')),
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
                      icon: const Icon(Icons.person_add),
                      label: const Text('Add Friend'),
                      onPressed: () {},
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.group_add),
                      label: const Text('Invite'),
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
                      leading: CircleAvatar(child: Text('F$index')),
                      title: Text('Friend $index'),
                      subtitle: Text('Status: Online'),
                      trailing: IconButton(icon: const Icon(Icons.message), onPressed: () {}),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
    }
}
