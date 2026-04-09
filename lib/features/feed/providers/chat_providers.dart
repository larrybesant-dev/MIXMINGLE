import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mixvy/core/providers/firebase_providers.dart';
import '../repository/chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(firestoreProvider));
});

final messageStreamProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, roomId) {
  return ref.read(chatRepositoryProvider).messageStream(roomId);
});
