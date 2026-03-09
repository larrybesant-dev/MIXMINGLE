import '../../../providers/all_providers.dart';
import '../../../shared/widgets/loading_widgets.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class OnboardingPage extends ConsumerWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return profileAsync.when(
      loading: () => const FullScreenLoader(message: 'Completing onboarding...'),
      error: (_, __) => const FullScreenLoader(message: 'Onboarding error'),
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushNamed(context, AppRoutes.home);
    });
  }
}
