import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';
import '../providers/room_provider.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Consumer(builder: (context, ref, _) {
        final user = ref.watch(userProvider);
        final rooms = ref.watch(roomListProvider);
        return Column(
          children: [
            if (user != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null,
                      child: user.avatarUrl.isEmpty ? Text(user.username) : null,
                    ),
                    const SizedBox(width: 12),
                    Text(user.username),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: rooms.length,
                itemBuilder: (context, index) => Card(
                  margin: const EdgeInsets.all(16),
                  child: ListTile(
                    title: Text(rooms[index].name ?? 'Room $index'),
                    subtitle: Text('Host: ${rooms[index].hostId ?? 'N/A'}'),
                    trailing: rooms[index].isLive == true ? const Icon(Icons.live_tv, color: Colors.red) : null,
                    onTap: () {},
                  ),
                ),
              ),
            ),
          ],
        );
      }),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Friends'),
        ],
        currentIndex: 0,
        onTap: (index) {},
      ),
    );
  }
}
