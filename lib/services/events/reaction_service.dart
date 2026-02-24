// lib/services/reaction_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/models/reaction_model.dart';

class ReactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<ReactionModel>> reactionStream(String roomId) {
    return _firestore.collection('rooms').doc(roomId).collection('reactions')
      .orderBy('timestamp', descending: false)
      .snapshots()
      .map((snap) => snap.docs.map((doc) => ReactionModel.fromMap(doc.data())).toList());
  }

  Future<void> sendReaction(String roomId, ReactionModel reaction) async {
    await _firestore.collection('rooms').doc(roomId).collection('reactions').add(reaction.toMap());
  }
}
