import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_providers.dart';
import 'auth_gate.dart';

class AuthGateRoot extends ConsumerWidget {
  const AuthGateRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);

    return auth.when(
      data: (user) {
        if (user == null) {
          return const AuthGate();
        }
        return const AuthGate();
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const Scaffold(
        body: Center(child: Text('Auth error')),
      ),
    );
  }
}
