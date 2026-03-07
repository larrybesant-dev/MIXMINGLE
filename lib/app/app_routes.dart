import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_providers.dart';
import '../features/home_page.dart';

class AppRoutes extends ConsumerWidget {
  const AppRoutes({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).value;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Navigator(
      pages: const [
        MaterialPage(child: HomePage()),
      ],
      onDidRemovePage: (_) {},
    );
  }
}
