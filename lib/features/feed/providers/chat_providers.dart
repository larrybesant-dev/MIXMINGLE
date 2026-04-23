import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mixvy/core/providers/firebase_providers.dart';
import '../repository/chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(firestoreProvider));
});

final messagetreamProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, roomId) {
  return ref.read(chatRepositoryProvider).messagetream(roomId);
});
