import 'package:flutter/material.dart';
import '../../models/user_profile_model.dart';

class UserCard extends StatelessWidget {
  final UserProfile profile;
  const UserCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(profile.avatarUrl),
        ),
        title: Text(profile.displayName),
        subtitle: Text(profile.bio),
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(profile.displayName),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(profile.avatarUrl),
                    radius: 40,
                  ),
                  Text(profile.bio),
                  Text('Interests: ${profile.interests.join(', ')}'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
