import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../repository/typing_repository.dart';

final typingRepositoryProvider = Provider<TypingRepository>((ref) {
  return TypingRepository(FirebaseFirestore.instance);
});

final typingStreamProvider = StreamProvider.family<Map<String, bool>, String>((ref, roomId) {
  return ref.read(typingRepositoryProvider).typingStream(roomId);
});
