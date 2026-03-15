import 'package:flutter/material.dart';

class LeaderboardWidget extends StatelessWidget {
  const LeaderboardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Stubbed leaderboard UI
    return const Card(
      child: ListTile(
        title: Text('Leaderboard'),
        subtitle: Text('Top contributors will appear here.'),
      ),
    );
  }
}
