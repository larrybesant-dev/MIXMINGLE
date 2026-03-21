import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LiveRoomScreen extends StatefulWidget {
  const LiveRoomScreen({super.key});
  @override
  State<LiveRoomScreen> createState() => _LiveRoomScreenState();
}

class _LiveRoomScreenState extends State<LiveRoomScreen> {
  // Example: This would come from your backend/room model
  int slowModeSeconds = 10; // Set to 0 to disable slow mode
  DateTime? lastMessageTime;
  bool isSending = false;
  String cooldownMessage = '';

  void _trySendMessage() {
    final now = DateTime.now();
    if (slowModeSeconds == 0 || lastMessageTime == null) {
      _sendMessage();
      return;
    }
    final diff = now.difference(lastMessageTime!).inSeconds;
    if (diff >= slowModeSeconds) {
      _sendMessage();
    } else {
      setState(() {
        cooldownMessage = 'Please wait [1m${slowModeSeconds - diff}s[0m before sending another message.';
      });
    }
  }

  void _sendMessage() {
    setState(() {
      isSending = true;
      cooldownMessage = '';
    });
    // Simulate sending message
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        lastMessageTime = DateTime.now();
        isSending = false;
        cooldownMessage = '';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Room')),
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
                  icon: const Icon(Icons.play_circle),
                  label: const Text('Host Room'),
                  onPressed: () {},
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.group),
                  label: const Text('Join Room'),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          if (cooldownMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                cooldownMessage,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    enabled: !isSending,
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: isSending ? null : _trySendMessage,
                  child: isSending
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Send'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 3,
              itemBuilder: (context, index) => Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Icon(Icons.meeting_room, color: Colors.blue),
                  title: Text('Live Room $index'),
                  subtitle: Text('Room description placeholder.'),
                  trailing: IconButton(icon: const Icon(Icons.arrow_forward), onPressed: () {}),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
