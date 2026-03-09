import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/providers/auth_providers.dart';

final hasVerifiedAgeProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.asData?.value?.ageVerified ?? false;
});

final hasCompletedOnboardingProvider = Provider<AsyncValue<bool>>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) {
      if (user == null) return const AsyncValue.data(false);
      return AsyncValue.data(user.onboardingComplete == true);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => const AsyncValue.data(false),
  );
});
