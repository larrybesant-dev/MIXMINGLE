import 'package:flutter/material.dart';

import '../panes/friends_pane_view.dart';

class FriendListScreen extends StatelessWidget {
  const FriendListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: _FriendsAppBar(),
      body: FriendsPaneView(showHeader: false),
    );
  }
}

class _FriendsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _FriendsAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(title: const Text('Friends'));
  }
}
