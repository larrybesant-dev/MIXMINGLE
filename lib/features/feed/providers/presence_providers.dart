import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../repository/presence_repository.dart';
import '../../../models/presence_model.dart';

final presenceRepositoryProvider = Provider<PresenceRepository>((ref) {
  return PresenceRepository(FirebaseFirestore.instance);
});

final presenceStreamProvider = StreamProvider.family<List<PresenceModel>, String>((ref, roomId) {
  return ref.read(presenceRepositoryProvider).presenceStream(roomId);
});
