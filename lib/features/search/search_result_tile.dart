import 'package:flutter/material.dart';
import 'search_service.dart';

class SearchResultTile extends StatelessWidget {
  final UserProfile user;
  const SearchResultTile({required this.user, super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(), // TODO: Load profile picture
      title: Text(user.username),
      subtitle: Text(user.displayName),
      trailing: Text(user.interests.join(', ')),
      onTap: () {
        // TODO: Navigate to user profile
      },
    );
  }
}
