import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () => GoRouter.of(context).go('/admin/users'),
            child: const Text('User Management'),
          ),
          ElevatedButton(
            onPressed: () => GoRouter.of(context).go('/admin/rooms'),
            child: const Text('Room Management'),
          ),
          ElevatedButton(
            onPressed: () => GoRouter.of(context).go('/admin/content'),
            child: const Text('Content Moderation'),
          ),
          // ...overview widgets for rooms, users, sessions, reports
        ],
      ),
    );
  }
}
