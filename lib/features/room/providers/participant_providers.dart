import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/room_participant_model.dart';
import 'room_firestore_provider.dart';

class CurrentParticipantParams {
	final String roomId;
	final String userId;

	const CurrentParticipantParams({required this.roomId, required this.userId});

	@override
	bool operator ==(Object other) {
		return identical(this, other) ||
				(other is CurrentParticipantParams && other.roomId == roomId && other.userId == userId);
	}

	@override
	int get hashCode => Object.hash(roomId, userId);
}

class Cohost {
	final String id;

	const Cohost(this.id);
}

final coHostsProvider = StreamProvider.autoDispose.family<List<Cohost>, String>((ref, roomId) {
	final firestore = ref.watch(roomFirestoreProvider);
	return firestore
			.collection('rooms')
			.doc(roomId)
			.collection('participants')
			.where('role', isEqualTo: 'cohost')
			.snapshots()
			.map(
				(snapshot) => snapshot.docs
						.map((doc) => Cohost(doc.id))
						.toList(growable: false),
			);
});

final currentParticipantProvider =
		StreamProvider.autoDispose.family<RoomParticipantModel?, CurrentParticipantParams>((ref, params) {
	final firestore = ref.watch(roomFirestoreProvider);
	return firestore
			.collection('rooms')
			.doc(params.roomId)
			.collection('participants')
			.doc(params.userId)
			.snapshots()
			.map((doc) {
		if (!doc.exists) {
			return null;
		}
		return RoomParticipantModel.fromMap(doc.data() ?? <String, dynamic>{});
	});
});

/// Staleness window: a participant whose lastActiveAt has not been updated
/// within this duration is considered offline (browser closed / crashed).
const Duration _kParticipantStaleness = Duration(seconds: 90);

bool _isParticipantFresh(RoomParticipantModel p) {
	return DateTime.now().difference(p.lastActiveAt) < _kParticipantStaleness;
}

final participantsStreamProvider =
		StreamProvider.autoDispose.family<List<RoomParticipantModel>, String>((ref, roomId) {
	final firestore = ref.watch(roomFirestoreProvider);
	return firestore
			.collection('rooms')
			.doc(roomId)
			.collection('participants')
			.orderBy('joinedAt')
			.snapshots()
			.map(
				(snapshot) => snapshot.docs
						.map((doc) => RoomParticipantModel.fromMap(doc.data()))
						.where(_isParticipantFresh)
						.toList(growable: false),
			);
});

final participantCountProvider = StreamProvider.autoDispose.family<int, String>((ref, roomId) {
	final firestore = ref.watch(roomFirestoreProvider);
	return firestore
			.collection('rooms')
			.doc(roomId)
			.collection('participants')
			.snapshots()
			.map((snapshot) => snapshot.docs
					.map((doc) => RoomParticipantModel.fromMap(doc.data()))
					.where(_isParticipantFresh)
					.length);
});

final isHostProvider = Provider.autoDispose.family<bool, RoomParticipantModel?>((ref, participant) {
	final role = participant?.role;
	return role == 'host' || role == 'owner';
});

final isCohostProvider = Provider.autoDispose.family<bool, RoomParticipantModel?>((ref, participant) {
	return participant?.role == 'cohost';
});
