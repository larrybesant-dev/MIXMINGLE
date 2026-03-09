/// Home Page Electric
/// Main landing page after onboarding completion
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/providers/user_providers.dart';

class HomePageElectric extends ConsumerStatefulWidget {
  const HomePageElectric({Key? key}) : super(key: key);

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
          body: Center(child: Text('Home Content')), // Simple placeholder
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


