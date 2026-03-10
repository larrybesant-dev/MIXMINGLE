import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/social_providers.dart';
import '../../../../shared/providers/auth_providers.dart';

/// Shows user suggestions based on matching interests/categories.
class RecommendedUsersSection extends ConsumerWidget {
  final String currentUserId;

  const RecommendedUsersSection({Key? key, required this.currentUserId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendedAsync = ref.watch(recommendedUsersProvider(currentUserId));
    final currentUserAsync = ref.watch(currentUserProfileProvider);
    final currentUser = currentUserAsync.value;

    return recommendedAsync.when(
      data: (users) {
        if (users.isEmpty) return const SizedBox();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Recommended Users',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: user.photoUrl != null
                              ? NetworkImage(user.photoUrl!)
                              : null,
                        ),
                        const SizedBox(height: 4),
                        Text(user.displayName ?? 'Unknown'),
                        if (user.vipTier != null)
                          Text('VIP: ${user.vipTier}'),
                        if (currentUser != null && currentUser.id != user.id)
                          ElevatedButton(
                            onPressed: () {},
                            child: const Text('Connect'),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Text('Error loading recommended users'),
    );
  }
}
