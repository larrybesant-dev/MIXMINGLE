import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../repository/reaction_repository.dart';
import '../../../models/reaction_model.dart';

final reactionRepositoryProvider = Provider<ReactionRepository>((ref) {
  return ReactionRepository(FirebaseFirestore.instance);
});

final reactionsStreamProvider = StreamProvider.family<List<ReactionModel>, ({String roomId, String messageId})>((ref, params) {
  return ref.read(reactionRepositoryProvider).reactionsStream(params.roomId, params.messageId);
});
