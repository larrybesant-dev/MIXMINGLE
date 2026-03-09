import 'package:flutter/material.dart';

import 'package:mixvy/router/app_routes.dart';

class UserProfilePage extends ConsumerWidget {
  final String userId;
  const UserProfilePage({required this.userId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Fetch user profile data from Firestore
    // TODO: Fetch interests, bio, join date, etc.

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Column(
        children: [
          // Placeholder for ProfileHeaderWidget
          Container(
            height: 80,
            color: Colors.grey[300],
            child: Center(child: Text('ProfileHeaderWidget Placeholder')),
          ),
          // Placeholder for ProfileStatsWidget
          Container(
            height: 60,
            color: Colors.grey[200],
            child: Center(child: Text('ProfileStatsWidget Placeholder')),
          ),
          // Placeholder for FollowButtonWidget
          Container(
            height: 40,
            color: Colors.grey[100],
            child: Center(child: Text('FollowButtonWidget Placeholder')),
          ),
          // Placeholder for ProfileRoomsWidget
          Container(
            height: 60,
            color: Colors.grey[200],
            child: Center(child: Text('ProfileRoomsWidget Placeholder')),
          ),
          // Placeholder for ProfileActivityWidget
          Container(
            height: 60,
            color: Colors.grey[300],
            child: Center(child: Text('ProfileActivityWidget Placeholder')),
          ),
        ],
      ),
    );
  }
}
