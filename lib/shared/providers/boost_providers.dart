import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/payments/boost_service.dart';
import 'auth_providers.dart';

final boostServiceProvider = Provider<BoostService>((ref) => BoostService());

/// Whether the current user's profile boost is active.
final myProfileBoostProvider = StreamProvider<bool>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value(false);
  return ref.watch(boostServiceProvider).profileBoostStream(user.id);
});

/// Whether a given user's profile boost is active.
final profileBoostProvider =
    StreamProvider.family<bool, String>((ref, userId) {
  return ref.watch(boostServiceProvider).profileBoostStream(userId);
});

/// Whether a given room is currently boosted.
final roomBoostProvider =
    StreamProvider.family<bool, String>((ref, roomId) {
  return ref.watch(boostServiceProvider).roomBoostStream(roomId);
});

/// Whether the current user has an active premium subscription.
final isPremiumProvider = StreamProvider<bool>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value(false);
  return ref.watch(boostServiceProvider).isPremiumStream(user.id);
});
