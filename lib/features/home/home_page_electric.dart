/// Home Page Electric
/// Main landing page after onboarding completion
library;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mixmingle/providers/all_providers.dart'; // currentUserProfileProvider

class HomePageElectric extends ConsumerStatefulWidget {
  const HomePageElectric({super.key});

  @override
  ConsumerState<HomePageElectric> createState() => _HomePageElectricState();
}

class _HomePageElectricState extends ConsumerState<HomePageElectric> {
  // Removed unused _selectedIndex and legacy tab builders

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    return profileAsync.when(
      data: (profile) {
        // Onboarding overlay logic placeholder
        return Scaffold(
          appBar: AppBar(title: const Text('HomePageElectric')), // Unique identifier
          body: const Center(child: Text('Home Content - Arrived at HomePageElectric')), // Unique content
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Scaffold(
        body: Center(child: Text('Error loading profile: $e')),
      ),
    );
  }

}


@immutable


