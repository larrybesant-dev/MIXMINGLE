import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/providers/auth_providers.dart';

final hasVerifiedAgeProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.asData?.value?.ageVerified ?? false;
});
