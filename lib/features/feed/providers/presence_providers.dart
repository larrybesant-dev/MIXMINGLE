import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mixvy/core/providers/firebase_providers.dart';
import '../repository/presence_repository.dart';
import '../../../models/presence_model.dart';

final presenceRepositoryProvider = Provider<PresenceRepository>((ref) {
  return PresenceRepository(ref.watch(firestoreProvider));
});

final presenceStreamProvider = StreamProvider.family<List<PresenceModel>, String>((ref, roomId) {
  return ref.read(presenceRepositoryProvider).presenceStream(roomId);
});
