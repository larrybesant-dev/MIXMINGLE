
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Minimal Cohost model for placeholder
class Cohost {
	final String id;
	Cohost(this.id);
}

final coHostsProvider = StreamProvider.autoDispose.family<List<Cohost>, String>((ref, roomId) async* {
	// TODO: Replace with actual Firestore stream logic for co-hosts
	yield <Cohost>[];
});

final currentParticipantProvider = Provider.autoDispose.family<dynamic, Map<String, dynamic>>((ref, params) => null);
final participantsStreamProvider = Provider.autoDispose.family<dynamic, String>((ref, roomId) => null);
final participantCountProvider = StreamProvider.autoDispose.family<int, String>((ref, roomId) {
	// Listen to the participants collection and emit the count as a stream
	final participantsCollection = FirebaseFirestore.instance.collection('rooms').doc(roomId).collection('participants');
	return participantsCollection.snapshots().map((snapshot) => snapshot.size);
});
final isHostProvider = Provider.autoDispose.family<bool, dynamic>((ref, participant) => false);
final isCohostProvider = Provider.autoDispose.family<bool, dynamic>((ref, participant) => false);
