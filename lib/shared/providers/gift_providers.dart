import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/social/gift_service.dart';
import '../models/gift.dart';
import 'auth_providers.dart';

final giftServiceProvider = Provider<GiftService>((ref) => GiftService());

/// Full gift catalog (future) — auto-seeds Firestore on first load.
final giftCatalogProvider = FutureProvider<List<Gift>>((ref) {
  return ref.read(giftServiceProvider).getCatalog();
});

/// Real-time coin balance for the current user.
final coinBalanceProvider = StreamProvider<int>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value(0);
  return ref.watch(giftServiceProvider).coinBalanceStream(user.id);
});

/// Gifts received by the current user.
final receivedGiftsProvider =
    StreamProvider.family<List<SentGift>, String>((ref, userId) {
  return ref.watch(giftServiceProvider).receivedGiftsStream(userId);
});

/// Gifts sent in a room (for floating overlay animations).
final roomGiftsProvider =
    StreamProvider.family<List<SentGift>, String>((ref, roomId) {
  return ref.watch(giftServiceProvider).roomGiftStream(roomId);
});
