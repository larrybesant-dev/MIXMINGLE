import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Loading user...')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Welcome, '),
          ),
          body: Center(
            child: Text(
              'User ID: \n'
              'Vibe: \n'
              'Onboarding: ',
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const Scaffold(
        body: Center(child: Text('Error loading user')),
      ),
    );
  }
}
