import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_providers.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);

    return auth.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Not signed in')),
          );
        }
        // User is authenticated — let AuthGateRoot handle routing
        return const FullScreenLoader(message: 'Loading...');
      },
      loading: () => const FullScreenLoader(message: 'Checking authentication...'),
      error: (_, __) => const Scaffold(
        body: Center(child: Text('Auth error')),
      ),
    );
  }
}
