import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/friend_provider.dart';
import 'package:flutter/material.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Friends')),
      body: Consumer(builder: (context, ref, _) {
        final friends = ref.watch(friendListProvider);
        return ListView.builder(
          itemCount: friends.length,
          itemBuilder: (context, index) => ListTile(
            leading: CircleAvatar(child: Text(friends[index].userId ?? 'F$index')),
            title: Text(friends[index].friendId ?? 'Friend $index'),
            trailing: IconButton(
              icon: const Icon(Icons.chat),
              onPressed: () {},
            ),
          ),
        );
      }),
    );
  }
}
