import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../repository/chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(FirebaseFirestore.instance);
});

final messageStreamProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, roomId) {
  return ref.read(chatRepositoryProvider).messageStream(roomId);
});
