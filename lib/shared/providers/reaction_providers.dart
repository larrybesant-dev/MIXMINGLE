// lib/providers/reaction_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/events/reaction_service.dart';
import '../models/reaction_model.dart';

final reactionServiceProvider =
    Provider<ReactionService>((ref) => ReactionService());

final reactionStreamProvider =
    StreamProvider.family<List<ReactionModel>, String>((ref, roomId) {
  return ref.read(reactionServiceProvider).reactionStream(roomId);
});
