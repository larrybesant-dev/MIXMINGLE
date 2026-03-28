import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/friend_request_model.dart';
import '../../models/user_model.dart';
import '../../services/friend_service.dart';
import 'user_provider.dart';

final friendFirestoreProvider = Provider<FirebaseFirestore>((ref) {
	return FirebaseFirestore.instance;
});

final friendServiceProvider = Provider<FriendService>((ref) {
	return FriendService(firestore: ref.watch(friendFirestoreProvider));
});

final currentFriendUserIdProvider = Provider<String?>((ref) {
	return ref.watch(userProvider)?.id;
});

final friendSearchQueryProvider = StateProvider<String>((ref) => '');

final currentFriendIdsProvider = FutureProvider<List<String>>((ref) async {
	final userId = ref.watch(currentFriendUserIdProvider);
	if (userId == null) {
		return const [];
	}

	return ref.watch(friendServiceProvider).getFriendIds(userId);
});

final friendsListProvider = FutureProvider<List<UserModel>>((ref) async {
	final userId = ref.watch(currentFriendUserIdProvider);
	if (userId == null) {
		return const [];
	}

	return ref.watch(friendServiceProvider).getFriends(userId);
});

class IncomingFriendRequestEntry {
	final FriendRequestModel request;
	final UserModel? fromUser;

	const IncomingFriendRequestEntry({required this.request, required this.fromUser});
}

final incomingFriendRequestsProvider = StreamProvider<List<IncomingFriendRequestEntry>>((ref) {
	final userId = ref.watch(currentFriendUserIdProvider);
	if (userId == null) {
		return const Stream<List<IncomingFriendRequestEntry>>.empty();
	}

	final service = ref.watch(friendServiceProvider);
	return service.incomingRequests(userId).asyncMap((requests) async {
		final users = await service.getUsersByIds(
			requests.map((request) => request.fromUserId).toList(growable: false),
		);
		final usersById = {
			for (final user in users) user.id: user,
		};

		return requests
				.map(
					(request) => IncomingFriendRequestEntry(
						request: request,
						fromUser: usersById[request.fromUserId],
					),
				)
				.toList(growable: false);
	});
});

final pendingOutgoingFriendRequestIdsProvider = StreamProvider<Set<String>>((ref) {
	final userId = ref.watch(currentFriendUserIdProvider);
	if (userId == null) {
		return const Stream<Set<String>>.empty();
	}

	return ref.watch(friendServiceProvider).outgoingPendingRequestIds(userId).map(
				(ids) => ids.toSet(),
			);
});

final friendCandidateSearchProvider = FutureProvider<List<UserModel>>((ref) async {
	final userId = ref.watch(currentFriendUserIdProvider);
	if (userId == null) {
		return const [];
	}

	final query = ref.watch(friendSearchQueryProvider);
	final service = ref.watch(friendServiceProvider);
	final friendIds = await ref.watch(currentFriendIdsProvider.future);
	final incomingRequesterIds = await service.getIncomingRequesterIds(userId);
	final outgoingPendingIds = await service.getOutgoingPendingRequestIds(userId);

	return service.searchUsers(
				query,
				currentUserId: userId,
				excludeUserIds: [...friendIds, ...incomingRequesterIds, ...outgoingPendingIds],
			);
});
