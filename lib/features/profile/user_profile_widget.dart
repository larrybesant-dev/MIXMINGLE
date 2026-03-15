// Basic UI widget for UserProfile
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'user_profile_provider.dart';

class UserProfileWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    if (profile == null) {
      return Center(child: Text('No profile loaded'));
    }
    return Column(
      children: [
        CircleAvatar(
          backgroundImage: NetworkImage(profile.avatarUrl),
          radius: 40,
        ),
        SizedBox(height: 16),
        Text(profile.displayName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text(profile.bio),
      ],
    );
  }
}
