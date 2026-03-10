import 'package:mixmingle/providers/all_providers.dart';
import '../../../shared/widgets/loading_widgets.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mixmingle/core/routing/app_routes.dart';

class OnboardingPage extends ConsumerWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return profileAsync.when(
      loading: () => const FullScreenLoader(message: 'Completing MixVy onboarding...'),
      error: (_, __) => const FullScreenLoader(message: 'MixVy onboarding error'),
      data: (profile) {
        return ElevatedButton(
          onPressed: () async {
            await _completeOnboarding(ref);
          },
          child: const Text('Complete Onboarding'),
        );
      },
    );
  }

  Future<void> _completeOnboarding(WidgetRef ref) async {
    // After onboarding mutation:
    ref.invalidate(currentUserProfileProvider); // Force reload profile
    final profile = await ref.read(currentUserProfileProvider.future);
    // Use context from build method
    // For now, just navigate to home
    // Use GoRouter with context from build method
    GoRouter.of(ref.context).go(AppRoutes.home);
  }
}
