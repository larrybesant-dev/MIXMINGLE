import 'package:flutter/material.dart';
import '../widgets/main_navigation_bar.dart';
import '../../feed/pages/feed_page.dart';
import '../../friends/pages/friends_page.dart';
import '../../search/search_page.dart';
import '../../notifications/pages/notifications_page.dart';
import '../../discovery/pages/discovery_page.dart';
import '../../profile/pages/user_profile_page.dart';

class MainShellPage extends StatefulWidget {
  final String userId;
  const MainShellPage({required this.userId, Key? key}) : super(key: key);

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      FeedPage(userId: widget.userId),
      FriendsPage(userId: widget.userId),
      SearchPage(userId: widget.userId),
      NotificationsPage(userId: widget.userId),
      const DiscoveryPage(),
      UserProfilePage(userId: widget.userId),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: MainNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
